import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:porcupine_flutter/porcupine_error.dart';
import 'package:porcupine_flutter/porcupine_manager.dart';
import 'live_service.dart';
import 'phone_control.dart';
import 'settings_service.dart';

enum WakeState { off, listening, awake }

/// "Wake up Zoya" sunna. Naam sunte hi Zoya jaag jaati hai (Gemini Live shuru),
/// aur baat khatam hone par ya chup rehne par wapas so jaati hai.
class WakeService {
  WakeService._();
  static final instance = WakeService._();

  /// Picovoice Console se banayi hui file, repo ke assets folder me.
  static const _asset = 'assets/zoya_wake.ppn';

  /// Itni der koi baat na ho to Zoya wapas so jaati hai.
  static const idleTimeout = Duration(seconds: 25);

  final _settings = SettingsService();
  final _pc = PhoneControl();
  final state = ValueNotifier<WakeState>(WakeState.off);

  PorcupineManager? _porcupine;
  LiveService? _live;
  Timer? _idle;
  bool _enabled = false;
  bool _paused = false;
  bool _awake = false;

  /// Shuru karo. Sab theek ho to null, warna error ka message.
  Future<String?> start() async {
    final key = await _settings.getPicoKey();
    if (key == null || key.isEmpty) {
      return 'Pehle Settings me Picovoice AccessKey daalo.';
    }
    if (!await _pc.startForeground()) {
      return 'Background service shuru nahi hui. Mic aur notification '
          'permission dekho.';
    }
    _enabled = true;
    try {
      _porcupine ??= await PorcupineManager.fromKeywordPaths(
        key,
        [_asset],
        _onWake,
        errorCallback: (e) => debugPrint('Porcupine: ${e.message}'),
      );
      if (!_paused) await _porcupine!.start();
      state.value = WakeState.listening;
      return null;
    } on PorcupineException catch (e) {
      await stop();
      return 'Wake word shuru nahi hua: ${e.message}';
    } catch (e) {
      await stop();
      return 'Wake word shuru nahi hua (assets/zoya_wake.ppn file hai?): $e';
    }
  }

  /// App khulne par, agar wake ON tha to dobara chalu karo.
  Future<void> ensureRunning() async {
    if (_enabled || _porcupine != null) return;
    if (await _settings.getWake() && await _settings.getActive()) {
      await start();
    }
  }

  Future<void> stop() async {
    _enabled = false;
    _idle?.cancel();
    await _live?.stop();
    _awake = false;
    try {
      await _porcupine?.stop();
      await _porcupine?.delete();
    } catch (_) {}
    _porcupine = null;
    await _pc.stopForeground();
    state.value = WakeState.off;
  }

  /// Voice screen khuli ho to mic usko do.
  Future<void> pause() async {
    _paused = true;
    try {
      await _porcupine?.stop();
    } catch (_) {}
  }

  Future<void> resume() async {
    _paused = false;
    if (_enabled && !_awake) {
      try {
        await _porcupine?.start();
      } catch (_) {}
    }
  }

  Future<void> _onWake(int index) async {
    if (_awake || _paused || !_enabled) return;
    _awake = true;
    state.value = WakeState.awake;
    try {
      await _porcupine?.stop();
    } catch (_) {}

    final live = _live ??= LiveService();
    live.onTranscript = (_, __) => _touch();
    live.onTurnComplete = _touch;
    live.onState = (s) {
      if (s == LiveState.speaking) _touch();
    };
    live.onError = (_) => _sleep();
    live.onSleep = _sleep;
    live.bargeIn = await _pc.hasHeadphones();

    await live.start();
    _touch();
  }

  void _touch() {
    _idle?.cancel();
    _idle = Timer(idleTimeout, _sleep);
  }

  Future<void> _sleep() async {
    _idle?.cancel();
    if (!_awake) return;
    await _live?.stop();
    _awake = false;
    if (_enabled && !_paused) {
      try {
        await _porcupine?.start();
        state.value = WakeState.listening;
      } catch (_) {}
    }
  }
}

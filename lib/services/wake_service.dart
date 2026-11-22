import 'dart:async';
import 'package:flutter/foundation.dart';
import 'live_service.dart';
import 'phone_control.dart';
import 'settings_service.dart';

/// "Hey Sara" sunna. Asli sunne ka kaam native (Vosk, offline) karta hai.
/// Naam sunte hi native yahan khabar deta hai, aur Sara jaag jaati hai
/// (Gemini Live shuru). Baat khatam ya chup rehne par wapas so jaati hai.
class WakeService {
  WakeService._();
  static final instance = WakeService._();

  final _settings = SettingsService();
  final _pc = PhoneControl();

  /// Aakhri ghatnayein (jaanch ke liye), Wake Word screen par dikhti hain.
  final log = ValueNotifier<List<String>>([]);

  void _log(String msg) {
    final t = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    final line = '${two(t.hour)}:${two(t.minute)}:${two(t.second)}  $msg';
    final list = [...log.value, line];
    log.value = list.length > 12 ? list.sublist(list.length - 12) : list;
  }

  /// Bina bole jagane ka test (wake word ke bina session chalta hai ya nahi).
  Future<void> testWake() async {
    _log('Test: haath se jagaya');
    await _onWake();
  }

  LiveService? _live;
  Timer? _idle;
  bool _paused = false;
  bool _awake = false;
  int _stopSec = 10;

  /// App shuru hote hi ek baar chalao.
  Future<void> init() async {
    _pc.setWakeHandler(_onWake);
    _log('App shuru');
    try {
      // App wake word sunke khuli ho to seedha jaag jao.
      if (await _pc.wakeConsumePending()) {
        _log('App wake word se khuli');
        await _onWake();
        return;
      }
      if (await _settings.getWake() && await _settings.getActive()) {
        await _pc.wakeStart(
          await _settings.getWakePhrases(),
          await _settings.getWakeFree(),
        );
      }
    } catch (_) {}
  }

  /// Background sunna shuru. Sab theek ho to null, warna error ka message.
  Future<String?> start() async {
    final ok = await _pc.wakeStart(
          await _settings.getWakePhrases(),
          await _settings.getWakeFree(),
        );
    return ok
        ? null
        : 'Background service shuru nahi hui. App permissions me Mic aur '
            'Notification dekho.';
  }

  Future<void> stop() async {
    _idle?.cancel();
    _awake = false;
    await _live?.stop();
    await _pc.wakeStop();
  }

  /// Voice screen khuli ho to mic usko do.
  Future<void> pause() async {
    _paused = true;
    await _pc.wakePause();
  }

  Future<void> resume() async {
    _paused = false;
    if (!_awake && await _settings.getWake()) {
      await _pc.wakeResume();
    }
  }

  Future<void> _onWake() async {
    _log('Wake word suna gaya');
    if (_awake) {
      _log('Pehle se jaagi hui hai');
      return;
    }
    if (_paused) {
      _log('Voice screen khuli hai, isliye chhoda');
      await _pc.wakeResume();
      return;
    }
    _awake = true;
    _stopSec = await _settings.getAutoStop();

    final live = _live ??= LiveService();
    live.onTranscript = (_, isUser) {
      if (isUser) _touch();
    };
    live.onState = (s) {
      _log('Sara: ${s.name}');
      if (s == LiveState.listening) {
        _touch();
      } else if (s == LiveState.speaking || s == LiveState.connecting) {
        _idle?.cancel();
      }
    };
    live.onError = (m) {
      _log('DIKKAT: $m');
      _sleep();
    };
    live.onSleep = _sleep;
    live.enableSleepTool = true;
    live.bargeIn = await _pc.hasHeadphones();

    _log('Session shuru kar rahi hai');
    await live.start();
  }

  /// Itni der koi na bole to Sara so jaaye.
  void _touch() {
    _idle?.cancel();
    _idle = Timer(Duration(seconds: _stopSec), _sleep);
  }

  Future<void> _sleep() async {
    _idle?.cancel();
    if (!_awake) return;
    _log('So gayi, wapas sun rahi hai');
    _awake = false;
    await _live?.stop();
    await _pc.wakeResume();
  }
}

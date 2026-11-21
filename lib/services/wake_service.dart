import 'dart:async';
import 'live_service.dart';
import 'phone_control.dart';
import 'settings_service.dart';

/// "Hey Zoya" sunna. Asli sunne ka kaam native (Vosk, offline) karta hai.
/// Naam sunte hi native yahan khabar deta hai, aur Zoya jaag jaati hai
/// (Gemini Live shuru). Baat khatam ya chup rehne par wapas so jaati hai.
class WakeService {
  WakeService._();
  static final instance = WakeService._();

  final _settings = SettingsService();
  final _pc = PhoneControl();

  LiveService? _live;
  Timer? _idle;
  bool _paused = false;
  bool _awake = false;
  int _stopSec = 10;

  /// App shuru hote hi ek baar chalao.
  Future<void> init() async {
    _pc.setWakeHandler(_onWake);
    try {
      // App wake word sunke khuli ho to seedha jaag jao.
      if (await _pc.wakeConsumePending()) {
        await _onWake();
        return;
      }
      if (await _settings.getWake() && await _settings.getActive()) {
        await _pc.wakeStart(await _settings.getWakePhrases());
      }
    } catch (_) {}
  }

  /// Background sunna shuru. Sab theek ho to null, warna error ka message.
  Future<String?> start() async {
    final ok = await _pc.wakeStart(await _settings.getWakePhrases());
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
    if (_awake) return;
    if (_paused) {
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
      if (s == LiveState.listening) {
        _touch();
      } else if (s == LiveState.speaking || s == LiveState.connecting) {
        _idle?.cancel();
      }
    };
    live.onError = (_) => _sleep();
    live.onSleep = _sleep;
    live.bargeIn = await _pc.hasHeadphones();

    await live.start();
  }

  /// Itni der koi na bole to Zoya so jaaye.
  void _touch() {
    _idle?.cancel();
    _idle = Timer(Duration(seconds: _stopSec), _sleep);
  }

  Future<void> _sleep() async {
    _idle?.cancel();
    if (!_awake) return;
    _awake = false;
    await _live?.stop();
    await _pc.wakeResume();
  }
}

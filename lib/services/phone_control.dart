import 'package:flutter/services.dart';

/// Phone control (Android Accessibility Service) se baat karne ka pul.
/// Asli kaam native Kotlin code me hota hai.
class PhoneControl {
  static const _ch = MethodChannel('zoya/control');

  Future<bool> isEnabled() async {
    try {
      return (await _ch.invokeMethod<bool>('isEnabled')) ?? false;
    } on PlatformException {
      return false;
    }
  }

  Future<void> openAccessibilitySettings() async {
    try {
      await _ch.invokeMethod('openSettings');
    } on PlatformException {
      // ignore
    }
  }

  Future<bool> _call(String method, [String? arg]) async {
    try {
      return (await _ch.invokeMethod<bool>(method, arg)) ?? false;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> home() => _call('home');
  Future<bool> back() => _call('back');
  Future<bool> recents() => _call('recents');
  Future<bool> notifications() => _call('notifications');
  Future<bool> scrollDown() => _call('scrollDown');
  Future<bool> scrollUp() => _call('scrollUp');
  Future<bool> tapText(String text) => _call('tapText', text);
  Future<bool> openApp(String name) => _call('openApp', name);

  Future<bool> hasMic() async {
    try {
      return (await _ch.invokeMethod<bool>('hasMic')) ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Background (foreground service) shuru/band, notification permission.
  Future<bool> startForeground() async {
    try {
      return (await _ch.invokeMethod<bool>('startForeground')) ?? false;
    } on PlatformException {
      return false;
    }
  }

  Future<void> stopForeground() async {
    try {
      await _ch.invokeMethod('stopForeground');
    } on PlatformException {
      // ignore
    }
  }

  Future<void> requestNotif() async {
    try {
      await _ch.invokeMethod('requestNotif');
    } on PlatformException {
      // ignore
    }
  }

  /// Earphones/bluetooth headset laga hai ya nahi.
  Future<bool> hasHeadphones() async {
    try {
      return (await _ch.invokeMethod<bool>('hasHeadphones')) ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Rangeen border dikhana/chhupana (Sara Active ke hisaab se).
  Future<void> refreshBorder() async {
    try {
      await _ch.invokeMethod('refreshBorder');
    } on PlatformException {
      // ignore
    }
  }

  Future<bool> _ask(String method) async {
    try {
      return (await _ch.invokeMethod<bool>(method)) ?? false;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> hasCamera() => _ask('hasCamera');
  Future<bool> hasNotif() => _ask('hasNotif');
  Future<bool> hasCall() => _ask('hasCall');
  Future<bool> hasContacts() => _ask('hasContacts');
  Future<bool> hasBattery() => _ask('hasBattery');
  Future<bool> openBattery() => _ask('openBattery');
  Future<bool> openAppSettings() => _ask('openAppSettings');

  /// Mic, camera aur notification ki permission ek saath maango.
  Future<bool> requestAll() => _ask('requestAll');

  // ---------- Wake word ("Hey Sara") ----------
  /// Native se aane wale 'onWake' (wake word suna gaya) ko sunne ke liye.
  void setWakeHandler(Future<void> Function() onWake) {
    _ch.setMethodCallHandler((call) async {
      if (call.method == 'onWake') await onWake();
      return null;
    });
  }

  Future<bool> wakeStart(List<String> phrases, bool free) async {
    try {
      return (await _ch.invokeMethod<bool>(
              'wakeStart', {'phrases': phrases, 'free': free})) ??
          false;
    } on PlatformException {
      return false;
    }
  }

  /// Voice session ke dauran Sara ko background me zinda rakho.
  Future<bool> keepAliveStart() => _ask('keepAliveStart');
  Future<bool> keepAliveStop() => _ask('keepAliveStop');

  Future<bool> wakeStop() => _ask('wakeStop');
  Future<bool> wakePause() => _ask('wakePause');
  Future<bool> wakeResume() => _ask('wakeResume');
  Future<bool> wakeConsumePending() => _ask('wakeConsumePending');

  /// Vosk ne aakhri baar kya suna (jaanch ke liye).
  Future<String> wakeHeard() async {
    try {
      return (await _ch.invokeMethod<String>('wakeHeard')) ?? '';
    } on PlatformException {
      return '';
    }
  }

  Future<String> wakeStatus() async {
    try {
      return (await _ch.invokeMethod<String>('wakeStatus')) ?? 'off';
    } on PlatformException {
      return 'off';
    }
  }

  /// Alarm, timer, torch, volume, call, link, WhatsApp, battery jaise kaam.
  Future<String> tool(String name, Map<String, dynamic> args) async {
    try {
      return (await _ch.invokeMethod<String>('phoneTool', {'name': name, ...args})) ??
          'nahi ho paya';
    } on PlatformException catch (e) {
      return 'nahi ho paya: ${e.message}';
    }
  }

  // ---------- WhatsApp auto-reply ----------
  Future<bool> autoAccess() => _ask('autoAccess');
  Future<bool> openNotifAccess() => _ask('openNotifAccess');
  Future<bool> autoLogClear() => _ask('autoLogClear');

  Future<String> autoLog() async {
    try {
      return (await _ch.invokeMethod<String>('autoLog')) ?? '';
    } on PlatformException {
      return '';
    }
  }
}

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

  /// Rangeen border dikhana/chhupana (Zoya Active ke hisaab se).
  Future<void> refreshBorder() async {
    try {
      await _ch.invokeMethod('refreshBorder');
    } on PlatformException {
      // ignore
    }
  }
}

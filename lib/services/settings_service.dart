import 'package:shared_preferences/shared_preferences.dart';

/// Phone me chhoti cheezein save karta hai (API key, mode waghera).
/// Key sirf tumhare phone me rehti hai, GitHub par nahi jaati.
class SettingsService {
  static const _apiKey = 'gemini_api_key';
  static const _modeKey = 'mode_id';

  Future<String?> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_apiKey);
  }

  Future<void> setApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKey, key.trim());
  }

  Future<String?> getMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_modeKey);
  }

  Future<void> setMode(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modeKey, id);
  }

  /// Zoya Active switch. Native code bhi ye 'zoya_active' key padhta hai.
  Future<bool> getActive() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('zoya_active') ?? false;
  }

  Future<void> setActive(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('zoya_active', v);
  }
}

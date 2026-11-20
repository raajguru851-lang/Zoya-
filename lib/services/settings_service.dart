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
}

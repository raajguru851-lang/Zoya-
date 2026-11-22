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

  Future<String?> getPicoKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('picovoice_key');
  }

  Future<void> setPicoKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('picovoice_key', key.trim());
  }

  /// "Wake up Zoya" background sunna ON hai ya nahi.
  Future<bool> getWake() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('wake_on') ?? false;
  }

  Future<void> setWake(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('wake_on', v);
  }

  /// Gola (orb) design number (0-9).
  Future<int> getOrb() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('orb_design') ?? 0;
  }

  Future<void> setOrb(int i) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('orb_design', i);
  }

  /// Kitne second chup rehne par Zoya so jaye (5, 10 ya 15).
  Future<int> getAutoStop() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('auto_stop') ?? 10;
  }

  Future<void> setAutoStop(int sec) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('auto_stop', sec);
  }

  /// Chuni hui doll ka number. -1 ka matlab sirf gola.
  Future<int> getDoll() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('doll_index') ?? 0;
  }

  Future<void> setDoll(int i) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('doll_index', i);
  }

  /// Wake word ke shabd (comma se alag). "wake up zoya" me "wake up" sunte
  /// hi Zoya jaag jati hai, kyunki "zoya" naam model ko aksar alag sunai deta hai.
  static const defaultWakePhrases = 'wake up zoya';

  Future<String> getWakePhrasesText() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('wake_phrases_v2') ?? defaultWakePhrases;
  }

  Future<List<String>> getWakePhrases() async {
    final t = await getWakePhrasesText();
    final list = t
        .split(',')
        .map((e) => e.trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .toList();
    return list.isEmpty ? ['hey zoya'] : list;
  }

  /// true: Vosk sab kuch sunta hai (jaanch aasan, par zyada battery).
  /// false: sirf wake shabd sunta hai (halka).
  Future<bool> getWakeFree() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('wake_free_v2') ?? false;
  }

  Future<void> setWakeFree(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('wake_free_v2', v);
  }

  Future<void> setWakePhrases(String text) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('wake_phrases_v2', text.trim());
  }
}

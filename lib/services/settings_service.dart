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

  /// Sara Active switch. Native code bhi ye 'zoya_active' key padhta hai.
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

  /// "Wake up Sara" background sunna ON hai ya nahi.
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

  /// Kitne second chup rehne par Sara so jaye (5, 10 ya 15).
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

  /// Wake word ke shabd (comma se alag). "wake up sara" me "wake up" sunte
  /// hi Sara jaag jati hai, kyunki "sara" naam model ko aksar alag sunai deta hai.
  static const defaultWakePhrases = 'wake up sara, hey sara';

  Future<String> getWakePhrasesText() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('wake_phrases_v3') ?? defaultWakePhrases;
  }

  Future<List<String>> getWakePhrases() async {
    final t = await getWakePhrasesText();
    final list = t
        .split(',')
        .map((e) => e.trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .toList();
    return list.isEmpty ? ['hey sara'] : list;
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
    await prefs.setString('wake_phrases_v3', text.trim());
  }

  /// Chat me "kaunsa tool chala" ki line dikhao (jaanch ke liye).
  Future<bool> getToolLog() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('tool_log') ?? true;
  }

  Future<void> setToolLog(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tool_log', v);
  }

  // ---------- WhatsApp auto-reply ----------
  Future<SharedPreferences> get _pp => SharedPreferences.getInstance();

  Future<bool> getAutoOn() async => (await _pp).getBool('auto_on') ?? false;
  Future<void> setAutoOn(bool v) async => (await _pp).setBool('auto_on', v);

  /// false: sirf list ke log. true: sabko (group chat phir bhi nahi).
  Future<bool> getAutoAll() async => (await _pp).getBool('auto_all') ?? false;
  Future<void> setAutoAll(bool v) async => (await _pp).setBool('auto_all', v);

  /// Chune hue logon ke naam, har naam nayi line me (WhatsApp me jaisa dikhta hai).
  Future<List<String>> getAutoContacts() async {
    final t = (await _pp).getString('auto_contacts') ?? '';
    return t.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }

  Future<void> setAutoContacts(List<String> v) async =>
      (await _pp).setString('auto_contacts', v.join('\n'));

  /// 'ai' ya 'fixed'
  Future<String> getAutoStyle() async => (await _pp).getString('auto_style') ?? 'ai';
  Future<void> setAutoStyle(String v) async => (await _pp).setString('auto_style', v);

  Future<String> getAutoFixed() async =>
      (await _pp).getString('auto_fixed') ?? 'Main abhi busy hoon, thodi der me baat karta hoon.';
  Future<void> setAutoFixed(String v) async => (await _pp).setString('auto_fixed', v);

  /// Jawab ke neeche judne wali line (batati hai ki ye AI ne likha hai).
  Future<String> getAutoSig() async =>
      (await _pp).getString('auto_sig') ?? '— Sara (AI assistant)';
  Future<void> setAutoSig(String v) async => (await _pp).setString('auto_sig', v);

  Future<String> getAutoOwner() async => (await _pp).getString('auto_owner') ?? 'Kuldeep';
  Future<void> setAutoOwner(String v) async => (await _pp).setString('auto_owner', v);

  Future<int> getAutoCooldown() async => (await _pp).getInt('auto_cooldown') ?? 10;
  Future<void> setAutoCooldown(int v) async => (await _pp).setInt('auto_cooldown', v);

  /// Jawab banate waqt Memory ki yaadein bhi use karo (nijii baatein leak ho sakti hain).
  Future<bool> getAutoMem() async => (await _pp).getBool('auto_mem') ?? false;
  Future<void> setAutoMem(bool v) async => (await _pp).setBool('auto_mem', v);

  /// Auto-reply ka andaaz (AI ko batane ke liye).
  Future<String> getAutoTone() async =>
      (await _pp).getString('auto_tone') ??
      'Dosti bhare, chhote aur natural andaaz me';
  Future<void> setAutoTone(String v) async => (await _pp).setString('auto_tone', v);
}

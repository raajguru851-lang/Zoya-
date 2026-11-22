import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Yaadein badalne par screens ko khabar dene ke liye.
class MemoryEvents {
  static final ValueNotifier<int> tick = ValueNotifier<int>(0);
}

/// Pichhli baat-cheet ki ek line.
class MemoryLine {
  final String text;
  final bool isUser;
  MemoryLine(this.text, this.isUser);
}

/// Sara ki yaaddaasht:
/// 1. Facts: user ke bare me zaroori baatein (naam, pasand, birthday...).
/// 2. Recent: pichhli baat-cheet ki lines (Chat aur Voice dono ki).
/// Sab kuch sirf phone me rehta hai. Prompt me jaata hai, isliye Gemini ko
/// bheja jata hai.
class MemoryService {
  static const _factsKey = 'mem_facts';
  static const _recentKey = 'mem_recent';
  static const _onKey = 'mem_on';
  static const maxFacts = 60;
  static const maxRecent = 60;

  Future<SharedPreferences> get _p => SharedPreferences.getInstance();

  Future<bool> isOn() async => (await _p).getBool(_onKey) ?? true;

  Future<void> setOn(bool v) async {
    await (await _p).setBool(_onKey, v);
    MemoryEvents.tick.value++;
  }

  // ---------------- facts ----------------
  Future<List<String>> getFacts() async {
    final raw = (await _p).getString(_factsKey);
    if (raw == null) return [];
    try {
      return List<String>.from(jsonDecode(raw) as List);
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveFacts(List<String> f) async {
    await (await _p).setString(_factsKey, jsonEncode(f));
    MemoryEvents.tick.value++;
  }

  /// Nayi yaad jodo. Pehle se ho to false.
  Future<bool> addFact(String text) async {
    var t = text.trim();
    if (t.isEmpty) return false;
    if (t.length > 300) t = t.substring(0, 300);
    final facts = await getFacts();
    if (facts.any((x) => x.toLowerCase() == t.toLowerCase())) return false;
    facts.add(t);
    if (facts.length > maxFacts) facts.removeAt(0);
    await _saveFacts(facts);
    return true;
  }

  Future<void> removeFactAt(int i) async {
    final facts = await getFacts();
    if (i < 0 || i >= facts.length) return;
    facts.removeAt(i);
    await _saveFacts(facts);
  }

  /// Jis yaad me ye shabd ho, wo hata do. Kitni hatayi, wo wapas deta hai.
  Future<int> forgetMatching(String q) async {
    final s = q.trim().toLowerCase();
    if (s.isEmpty) return 0;
    final facts = await getFacts();
    final keep = facts.where((f) => !f.toLowerCase().contains(s)).toList();
    final removed = facts.length - keep.length;
    if (removed > 0) await _saveFacts(keep);
    return removed;
  }

  Future<void> clearFacts() => _saveFacts([]);

  // ---------------- recent baat-cheet ----------------
  Future<List<MemoryLine>> getRecent() async {
    final raw = (await _p).getString(_recentKey);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => MemoryLine(
              '${(e as Map)['t']}', e['r'] == 'u'))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> appendRecent(String text, bool isUser) async {
    var t = text.trim();
    if (t.isEmpty) return;
    if (t.length > 500) t = t.substring(0, 500);
    final list = await getRecent();
    list.add(MemoryLine(t, isUser));
    final trimmed =
        list.length > maxRecent ? list.sublist(list.length - maxRecent) : list;
    await (await _p).setString(
      _recentKey,
      jsonEncode([
        for (final l in trimmed) {'r': l.isUser ? 'u' : 'z', 't': l.text}
      ]),
    );
  }

  Future<void> clearRecent() async {
    await (await _p).remove(_recentKey);
    MemoryEvents.tick.value++;
  }

  // ---------------- prompt ke liye ----------------
  Future<String> promptBlock({int recentLines = 0}) async {
    if (!await isOn()) return '';
    final b = StringBuffer();

    final facts = await getFacts();
    if (facts.isNotEmpty) {
      b.writeln('User ke bare me jo tumhe yaad hai:');
      for (final f in facts) {
        b.writeln('- $f');
      }
    }

    if (recentLines > 0) {
      final r = await getRecent();
      final last = r.length > recentLines ? r.sublist(r.length - recentLines) : r;
      if (last.isNotEmpty) {
        b.writeln('\nPichhli baat-cheet (sabse nayi neeche):');
        for (final l in last) {
          b.writeln('${l.isUser ? 'User' : 'Sara'}: ${l.text}');
        }
      }
    }
    return b.toString().trim();
  }
}

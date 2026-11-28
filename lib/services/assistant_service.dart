import 'dart:convert';
import 'package:http/http.dart' as http;
import '../features/modes/modes.dart';
import 'memory_service.dart';
import 'phone_tools.dart';
import 'settings_service.dart';

class _Hit {
  final String name;
  final String number;
  _Hit(this.name, this.number);
}

class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage(this.text, this.isUser);
}

/// Gemini se baat karne ka kaam yahin hota hai.
class AssistantService {
  // Model ka naam badalna ho to sirf yahan badlo.
  static const model = 'gemini-3.8-flash';

  static const basePrompt =
      'Tumhara naam Sara hai, tum user ki personal assistant ho. User jis '
      'bhasha me likhe, usi me chhota aur saaf jawab do. '
      'Agar koi poochhe ki tumhe kisne banaya ya build kiya hai, to batao: '
      '"Mujhe Mr ZX KD ne banaya hai, unka poora naam Kuldeep Gautam hai."';

  final _settings = SettingsService();

  // "Rahul ko call lagao" jaise hukm AI ke bina chalte hain.
  static _Hit? _pending;
  static List<_Hit>? _choices;

  static const _end = r'(?=\s|$|[,.!?])';
  static final _yes = RegExp(
      r'^\s*(haan|han|ha|yes|yeah|yup|ok|okay|theek hai|kar do|kardo|laga do|lagao|हाँ|हां|हा)' + _end,
      caseSensitive: false);
  static final _no = RegExp(
      r'^\s*(nahi|nahin|no|mat|cancel|rehne do|ruko|नहीं)' + _end,
      caseSensitive: false);
  static final _callKo = RegExp(
      r'^\s*(?:please\s+)?(.+?)\s+(?:ko|को)\s+(?:phone|fone|call|कॉल|फोन|फ़ोन)' + _end,
      caseSensitive: false);
  static final _callX = RegExp(
      r'^\s*(?:please\s+)?(?:call|phone|कॉल|फोन)\s+(?:karo\s+|kar\s+|lagao\s+)?(.+?)\s*$',
      caseSensitive: false);
  static final _numberOf = RegExp(
      r'^\s*(.+?)\s+(?:ka|का|की)\s+(?:phone\s+)?(?:number|no\.?|नंबर)' + _end,
      caseSensitive: false);

  String _clean(String s) =>
      s.replaceAll(RegExp(r'[.,!?]'), '').replaceAll(RegExp(r'\s+'), ' ').trim();

  List<_Hit> _parseHits(String res) {
    final out = <_Hit>[];
    for (final line in res.split('\n')) {
      final i = line.lastIndexOf(': ');
      if (i <= 0) continue;
      final number = line.substring(i + 2).trim();
      if (!RegExp(r'^\+?\d{5,}$').hasMatch(number)) continue;
      out.add(_Hit(line.substring(0, i).trim(), number));
    }
    return out;
  }

  Future<String> _doCall(_Hit h) async {
    final r = await PhoneTools.run('make_call', {'number': h.number});
    return r == 'call laga di' ? '${h.name} ko call laga di.' : r;
  }

  Future<String?> _contactCommand(String text) async {
    if (_pending != null) {
      final p = _pending!;
      _pending = null;
      if (_yes.hasMatch(text)) return _doCall(p);
      if (_no.hasMatch(text)) return 'Theek hai, call nahi lagayi.';
    }
    if (_choices != null) {
      final c = _choices!;
      _choices = null;
      final n = int.tryParse(text.trim());
      if (n != null && n >= 1 && n <= c.length) return _doCall(c[n - 1]);
    }

    final nm = _numberOf.firstMatch(text);
    if (nm != null) {
      final name = _clean(nm.group(1)!);
      if (name.isNotEmpty && name.length <= 40) {
        return PhoneTools.run('find_contact', {'name': name, 'alt_name': ''});
      }
    }

    final ko = _callKo.firstMatch(text);
    final cx = ko == null ? _callX.firstMatch(text) : null;
    final raw = ko?.group(1) ?? cx?.group(1);
    if (raw == null) return null;
    final name = _clean(raw);
    if (name.isEmpty || name.length > 40) return null;

    final res = await PhoneTools.run('find_contact', {'name': name, 'alt_name': ''});
    final hits = _parseHits(res);
    if (hits.isEmpty) return ko != null ? res : null;
    if (hits.length == 1) {
      _pending = hits.first;
      return '${hits.first.name} (${hits.first.number}) ko call lagau? (haan / nahi)';
    }
    _choices = hits;
    final list = [
      for (var i = 0; i < hits.length; i++)
        '${i + 1}. ${hits[i].name}: ${hits[i].number}'
    ].join('\n');
    return 'Kaunsa? Number likho:\n$list';
  }

  Future<String> _systemPrompt() async {
    final mode = Modes.byId(await _settings.getMode());
    final mem = await MemoryService().promptBlock();
    return '$basePrompt\n\n'
        'Abhi ka mode: ${mode.name}. ${mode.prompt}\n\n'
        '${PhoneTools.prompt}'
        '${mem.isEmpty ? '' : '\n\n$mem'}';
  }

  Future<String> reply(List<ChatMessage> history) async {
    // Manager: "gf mode lagao" jaisa hukm turant, bina AI ke, chalta hai.
    if (history.isNotEmpty && history.last.isUser) {
      final cmd = Modes.parseCommand(history.last.text);
      if (cmd != null) {
        await _settings.setMode(cmd.id);
        ModeEvents.tick.value++;
        final short = cmd.name.replaceAll(' Mode', '');
        return '${cmd.name} active kar diya hai. Ab sirf $short bolegi.';
      }
    }

    if (history.isNotEmpty && history.last.isUser) {
      final c = await _contactCommand(history.last.text);
      if (c != null) return c;
    }

    final key = await _settings.getApiKey();
    if (key == null || key.isEmpty) {
      return 'Pehle Settings me Gemini API key daalo.';
    }


    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent',
    );

    final contents = <Map<String, dynamic>>[
      for (final m in history)
        {
          'role': m.isUser ? 'user' : 'model',
          'parts': [
            {'text': m.text}
          ],
        }
    ];

    try {
      // Tool chalane ke baad AI ko natija dena padta hai, isliye loop.
      final toolLog = <String>[];
      for (var step = 0; step < 12; step++) {
        final res = await http
            .post(
              uri,
              headers: {
                'Content-Type': 'application/json',
                'x-goog-api-key': key,
              },
              body: jsonEncode({
                'system_instruction': {
                  'parts': [
                    {'text': await _systemPrompt()}
                  ]
                },
                'tools': [
                  {'functionDeclarations': PhoneTools.declarations}
                ],
                'contents': contents,
              }),
            )
            .timeout(const Duration(seconds: 60));

        final data = jsonDecode(utf8.decode(res.bodyBytes));

        if (res.statusCode != 200) {
          final msg = data['error']?['message'] ?? 'Error ${res.statusCode}';
          return 'Error: $msg';
        }

        final content = data['candidates']?[0]?['content'];
        if (content == null) return 'Jawab nahi mila, dobara try karo.';

        final parts = (content['parts'] as List?) ?? [];
        final calls =
            parts.where((p) => p is Map && p['functionCall'] != null).toList();

        if (calls.isEmpty) {
          var text = parts.map((p) => p['text'] ?? '').join();
          if (text.isEmpty) text = 'Ho gaya.';
          if (toolLog.isNotEmpty && await _settings.getToolLog()) {
            text += '\n\n\u{1F527} ${toolLog.join('\n')}';
          }
          return text;
        }

        // AI ka poora message jaise ka taisa wapas bhejna zaroori hai.
        contents.add(Map<String, dynamic>.from(content));

        final responses = <Map<String, dynamic>>[];
        for (final c in calls) {
          final fc = c['functionCall'];
          final args = Map<String, dynamic>.from((fc['args'] as Map?) ?? {});
          final result = await PhoneTools.run('${fc['name']}', args);
          final shown =
              result.length > 160 ? '${result.substring(0, 160)}...' : result;
          toolLog.add('${fc['name']}(${args.values.join(', ')}) -> $shown');
          responses.add({
            'functionResponse': {
              'name': fc['name'],
              'response': {'result': result},
            }
          });
        }
        contents.add({'role': 'user', 'parts': responses});
      }
      return 'Kaam poora nahi ho paya, dobara try karo.';
    } catch (e) {
      return 'Internet ya connection me dikkat: $e';
    }
  }
}

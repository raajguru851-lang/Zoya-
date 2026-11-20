import 'dart:convert';
import 'package:http/http.dart' as http;
import '../features/modes/modes.dart';
import 'phone_tools.dart';
import 'settings_service.dart';

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
      'Tumhara naam Zoya hai, tum user ki personal assistant ho. User jis '
      'bhasha me likhe, usi me chhota aur saaf jawab do. '
      'Agar koi poochhe ki tumhe kisne banaya ya build kiya hai, to batao: '
      '"Mujhe Mr ZX KD ne banaya hai, unka poora naam Kuldeep Gautam hai."';

  final _settings = SettingsService();

  Future<String> reply(List<ChatMessage> history) async {
    final key = await _settings.getApiKey();
    if (key == null || key.isEmpty) {
      return 'Pehle Settings me Gemini API key daalo.';
    }

    final mode = Modes.byId(await _settings.getMode());
    final systemPrompt = '$basePrompt\n\n'
        'Abhi ka mode: ${mode.name}. ${mode.prompt}\n\n'
        '${PhoneTools.prompt}';

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
      for (var step = 0; step < 5; step++) {
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
                    {'text': systemPrompt}
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
          final text = parts.map((p) => p['text'] ?? '').join();
          return text.isEmpty ? 'Ho gaya.' : text;
        }

        // AI ka poora message jaise ka taisa wapas bhejna zaroori hai.
        contents.add(Map<String, dynamic>.from(content));

        final responses = <Map<String, dynamic>>[];
        for (final c in calls) {
          final fc = c['functionCall'];
          final args = Map<String, dynamic>.from((fc['args'] as Map?) ?? {});
          final result = await PhoneTools.run('${fc['name']}', args);
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

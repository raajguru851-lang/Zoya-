import 'dart:convert';
import 'package:http/http.dart' as http;
import 'settings_service.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage(this.text, this.isUser);
}

/// Gemini se baat karne ka kaam yahin hota hai.
class AssistantService {
  // Model ka naam badalna ho to sirf yahan badlo.
  static const model = 'gemini-2.5-flash';

  static const systemPrompt =
      'Tum ek helpful assistant ho. User jis bhasha me likhe, usi me chhota '
      'aur saaf jawab do.';

  final _settings = SettingsService();

  Future<String> reply(List<ChatMessage> history) async {
    final key = await _settings.getApiKey();
    if (key == null || key.isEmpty) {
      return 'Pehle Settings me Gemini API key daalo.';
    }

    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent',
    );

    try {
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
              'contents': [
                for (final m in history)
                  {
                    'role': m.isUser ? 'user' : 'model',
                    'parts': [
                      {'text': m.text}
                    ],
                  }
              ],
            }),
          )
          .timeout(const Duration(seconds: 60));

      final data = jsonDecode(utf8.decode(res.bodyBytes));

      if (res.statusCode != 200) {
        final msg = data['error']?['message'] ?? 'Error ${res.statusCode}';
        return 'Error: $msg';
      }

      final parts = data['candidates']?[0]?['content']?['parts'];
      if (parts == null) return 'Jawab nahi mila, dobara try karo.';
      return parts.map((p) => p['text'] ?? '').join();
    } catch (e) {
      return 'Internet ya connection me dikkat: $e';
    }
  }
}

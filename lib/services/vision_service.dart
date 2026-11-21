import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../features/modes/modes.dart';
import 'assistant_service.dart';
import 'settings_service.dart';

/// Photo Gemini ko dikhakar sawal poochhna (camera vision).
class VisionService {
  final _settings = SettingsService();

  Future<String> ask(Uint8List jpeg, String question) async {
    final key = await _settings.getApiKey();
    if (key == null || key.isEmpty) {
      return 'Pehle Gemini settings me API key daalo.';
    }

    final mode = Modes.byId(await _settings.getMode());
    final system = '${AssistantService.basePrompt}\n\n'
        'Abhi ka mode: ${mode.name}. ${mode.prompt}\n\n'
        'User ne camera se photo kheechi hai. Photo dekhkar user ke sawal ka '
        'chhota aur saaf jawab do. Jo photo me saaf nahi dikh raha, uska '
        'andaza mat lagao, bas bol do ki saaf nahi dikh raha.';

    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/'
      '${AssistantService.model}:generateContent',
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
                  {'text': system}
                ]
              },
              'contents': [
                {
                  'role': 'user',
                  'parts': [
                    {
                      'inlineData': {
                        'mimeType': 'image/jpeg',
                        'data': base64Encode(jpeg),
                      }
                    },
                    {'text': question},
                  ],
                }
              ],
            }),
          )
          .timeout(const Duration(seconds: 90));

      final data = jsonDecode(utf8.decode(res.bodyBytes));
      if (res.statusCode != 200) {
        return 'Error: ${data['error']?['message'] ?? res.statusCode}';
      }
      final parts = data['candidates']?[0]?['content']?['parts'];
      if (parts == null) return 'Jawab nahi mila, dobara try karo.';
      final text = parts.map((p) => p['text'] ?? '').join();
      return text.isEmpty ? 'Jawab nahi mila, dobara try karo.' : text;
    } catch (e) {
      return 'Internet ya connection me dikkat: $e';
    }
  }
}

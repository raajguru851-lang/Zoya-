import 'package:flutter/material.dart';
import '../../services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _service = SettingsService();
  final _controller = TextEditingController();
  bool _hide = true;
  bool _toolLog = true;

  @override
  void initState() {
    super.initState();
    _service.getApiKey().then((k) {
      if (mounted) _controller.text = k ?? '';
    });
    _service.getToolLog().then((v) {
      if (mounted) setState(() => _toolLog = v);
    });
  }

  Future<void> _save() async {
    await _service.setApiKey(_controller.text);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Key save ho gayi')));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gemini settings')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Gemini API key'),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              obscureText: _hide,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: 'AIza...',
                suffixIcon: IconButton(
                  icon: Icon(_hide ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _hide = !_hide),
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: _save, child: const Text('Save')),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Chat me "tool log" dikhao'),
              subtitle: const Text(
                  'Jawab ke neeche dikhta hai ki Sara ne kaunsa kaam/tool '
                  'chalaya aur uska natija kya aaya (jaanch ke liye).'),
              value: _toolLog,
              onChanged: (v) async {
                await _service.setToolLog(v);
                setState(() => _toolLog = v);
              },
            ),
          ],
        ),
      ),
    );
  }
}

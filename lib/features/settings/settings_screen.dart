import 'package:flutter/material.dart';
import '../../services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _service = SettingsService();
  final _gemini = TextEditingController();
  final _pico = TextEditingController();
  bool _hide = true;

  @override
  void initState() {
    super.initState();
    _service.getApiKey().then((k) {
      if (mounted) _gemini.text = k ?? '';
    });
    _service.getPicoKey().then((k) {
      if (mounted) _pico.text = k ?? '';
    });
  }

  Future<void> _save() async {
    await _service.setApiKey(_gemini.text);
    await _service.setPicoKey(_pico.text);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Save ho gaya')));
  }

  @override
  void dispose() {
    _gemini.dispose();
    _pico.dispose();
    super.dispose();
  }

  Widget _field(String label, TextEditingController c, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 8),
        TextField(
          controller: c,
          obscureText: _hide,
          autocorrect: false,
          enableSuggestions: false,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            hintText: hint,
            suffixIcon: IconButton(
              icon: Icon(_hide ? Icons.visibility : Icons.visibility_off),
              onPressed: () => setState(() => _hide = !_hide),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _field('Gemini API key', _gemini, 'AIza...'),
          _field('Picovoice AccessKey ("Wake up Zoya" ke liye)', _pico,
              'Picovoice Console se'),
          FilledButton(onPressed: _save, child: const Text('Save')),
        ],
      ),
    );
  }
}

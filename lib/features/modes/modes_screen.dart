import 'package:flutter/material.dart';
import '../../services/settings_service.dart';
import 'modes.dart';

class ModesScreen extends StatefulWidget {
  const ModesScreen({super.key});

  @override
  State<ModesScreen> createState() => _ModesScreenState();
}

class _ModesScreenState extends State<ModesScreen> {
  final _settings = SettingsService();
  String _current = Modes.all.first.id;

  @override
  void initState() {
    super.initState();
    _settings.getMode().then((id) {
      if (mounted) setState(() => _current = Modes.byId(id).id);
    });
  }

  Future<void> _select(AssistantMode m) async {
    await _settings.setMode(m.id);
    if (!mounted) return;
    setState(() => _current = m.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${m.emoji} ${m.name} mode chalu')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Modes')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          for (final m in Modes.all)
            Card(
              color: m.id == _current ? cs.primaryContainer : null,
              child: ListTile(
                leading: Text(m.emoji, style: const TextStyle(fontSize: 28)),
                title: Text(m.name),
                subtitle: Text(m.description),
                trailing:
                    m.id == _current ? const Icon(Icons.check_circle) : null,
                onTap: () => _select(m),
              ),
            ),
        ],
      ),
    );
  }
}

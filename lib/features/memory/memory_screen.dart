import 'package:flutter/material.dart';
import '../../services/memory_service.dart';
import '../../widgets/neon.dart';

/// Zoya ne user ke bare me kya yaad rakha hai, yahan dikhta hai.
class MemoryScreen extends StatefulWidget {
  const MemoryScreen({super.key});

  @override
  State<MemoryScreen> createState() => _MemoryScreenState();
}

class _MemoryScreenState extends State<MemoryScreen> {
  final _mem = MemoryService();
  final _add = TextEditingController();
  List<String> _facts = [];
  bool _on = true;

  @override
  void initState() {
    super.initState();
    _load();
    MemoryEvents.tick.addListener(_load);
  }

  @override
  void dispose() {
    MemoryEvents.tick.removeListener(_load);
    _add.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final f = await _mem.getFacts();
    final on = await _mem.isOn();
    if (!mounted) return;
    setState(() {
      _facts = f;
      _on = on;
    });
  }

  Future<void> _addFact() async {
    final t = _add.text.trim();
    if (t.isEmpty) return;
    _add.clear();
    await _mem.addFact(t);
  }

  Future<void> _confirm(String title, String body, Future<void> Function() ok) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Nahi')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Haan')),
        ],
      ),
    );
    if (yes == true) await ok();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Memory')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          NeonBorder(
            radius: 20,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text('Yaad rakhna',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w700)),
                      ),
                      Switch(
                        value: _on,
                        onChanged: (v) => _mem.setOn(v),
                      ),
                    ],
                  ),
                  const Text(
                    'Zoya tumhari zaroori baatein aur pichhli baat-cheet yaad '
                    'rakhti hai. Ye phone me rehti hain, par jawab banane ke '
                    'liye Gemini (Google) ko bheji jaati hain. Password, card '
                    'ya OTP yahan mat likhna.',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _add,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _addFact(),
                  decoration: InputDecoration(
                    hintText: 'Zoya ko kuch yaad karao...',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                  onPressed: _addFact, icon: const Icon(Icons.add)),
            ],
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'YAADEIN · ${_facts.length}',
              style: const TextStyle(
                  fontSize: 12, letterSpacing: 1.6, color: Colors.white60),
            ),
          ),
          if (_facts.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Abhi kuch yaad nahi.\nZoya se bolo: "mera naam ... hai, yaad rakhna".',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white60),
                ),
              ),
            ),
          for (var i = 0; i < _facts.length; i++)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(_facts[i]),
                trailing: IconButton(
                  tooltip: 'Bhool jao',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _mem.removeFactAt(i),
                ),
              ),
            ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _facts.isEmpty
                ? null
                : () => _confirm('Sab yaadein bhoolein?',
                    'Zoya tumhare bare me sab kuch bhool jayegi.', _mem.clearFacts),
            icon: const Icon(Icons.delete_sweep_outlined),
            label: const Text('Sab yaadein bhoolo'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _confirm('Baat-cheet ka itihaas saaf karein?',
                'Chat aur Voice ki pichhli baatein hat jayengi.', _mem.clearRecent),
            icon: const Icon(Icons.history_toggle_off),
            label: const Text('Baat-cheet ka itihaas saaf karo'),
          ),
        ],
      ),
    );
  }
}

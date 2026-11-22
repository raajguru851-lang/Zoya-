import 'package:flutter/material.dart';
import '../../services/phone_control.dart';

class ControlScreen extends StatefulWidget {
  const ControlScreen({super.key});

  @override
  State<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen>
    with WidgetsBindingObserver {
  final _pc = PhoneControl();
  final _appCtrl = TextEditingController();
  final _tapCtrl = TextEditingController();
  bool _enabled = false;
  String _msg = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _appCtrl.dispose();
    _tapCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final e = await _pc.isEnabled();
    if (mounted) setState(() => _enabled = e);
  }

  Future<void> _run(String label, Future<bool> Function() action) async {
    final ok = await action();
    if (!mounted) return;
    setState(() => _msg = ok ? '$label: ho gaya' : '$label: nahi ho paya');
  }

  Widget _btn(String label, IconData icon, Future<bool> Function() action) {
    return FilledButton.tonalIcon(
      onPressed: _enabled ? () => _run(label, action) : null,
      icon: Icon(icon),
      label: Text(label),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Phone Control')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: _enabled ? cs.primaryContainer : cs.errorContainer,
            child: ListTile(
              leading: Icon(_enabled ? Icons.check_circle : Icons.warning),
              title: Text(_enabled ? 'Control chalu hai' : 'Control band hai'),
              subtitle: Text(_enabled
                  ? 'Sara phone ko control kar sakti hai'
                  : 'Neeche button se Accessibility me Sara ko ON karo'),
            ),
          ),
          if (!_enabled)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: FilledButton(
                onPressed: _pc.openAccessibilitySettings,
                child: const Text('Accessibility Settings kholo'),
              ),
            ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _btn('Home', Icons.home_outlined, _pc.home),
              _btn('Back', Icons.arrow_back, _pc.back),
              _btn('Recents', Icons.view_carousel_outlined, _pc.recents),
              _btn('Notifications', Icons.notifications_none,
                  _pc.notifications),
              _btn('Scroll neeche', Icons.keyboard_arrow_down, _pc.scrollDown),
              _btn('Scroll upar', Icons.keyboard_arrow_up, _pc.scrollUp),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _appCtrl,
            decoration: const InputDecoration(
              labelText: 'App ka naam (jaise WhatsApp)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          _btn('App kholo', Icons.open_in_new,
              () => _pc.openApp(_appCtrl.text)),
          const SizedBox(height: 20),
          TextField(
            controller: _tapCtrl,
            decoration: const InputDecoration(
              labelText: 'Screen par jis text par tap karna hai',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          _btn('Tap karo', Icons.touch_app_outlined,
              () => _pc.tapText(_tapCtrl.text)),
          const SizedBox(height: 16),
          Text(_msg),
        ],
      ),
    );
  }
}

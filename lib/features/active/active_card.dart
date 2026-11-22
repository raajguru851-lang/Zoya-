import 'package:flutter/material.dart';
import 'package:record/record.dart';
import '../../services/phone_control.dart';
import '../../services/settings_service.dart';
import '../../services/wake_service.dart';
import '../../widgets/neon.dart';

/// Sara Active switch. Permissions poori hon aur switch ON ho, tabhi
/// screen ke kinare rangeen light ghoomti hai.
class ActiveCard extends StatefulWidget {
  const ActiveCard({super.key});

  @override
  State<ActiveCard> createState() => _ActiveCardState();
}

class _ActiveCardState extends State<ActiveCard> with WidgetsBindingObserver {
  final _pc = PhoneControl();
  final _settings = SettingsService();
  bool _acc = false;
  bool _mic = false;
  bool _on = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final acc = await _pc.isEnabled();
    final mic = await _pc.hasMic();
    var on = await _settings.getActive();
    if (on && !(acc && mic)) {
      on = false;
      await _settings.setActive(false);
      await _settings.setWake(false);
      await WakeService.instance.stop();
    }
    if (!mounted) return;
    setState(() {
      _acc = acc;
      _mic = mic;
      _on = on;
    });
    await _pc.refreshBorder();
  }

  Future<void> _toggle(bool v) async {
    if (v && !(_acc && _mic)) return;
    await _settings.setActive(v);
    if (!v) {
      await _settings.setWake(false);
      await WakeService.instance.stop();
    }
    await _pc.refreshBorder();
    if (mounted) setState(() => _on = v);
  }

  Future<void> _askMic() async {
    final r = AudioRecorder();
    await r.hasPermission(); // permission ka popup yahin aata hai
    await r.dispose();
    _refresh();
  }

  Widget _row(String label, bool ok, VoidCallback fix) {
    return Row(
      children: [
        Icon(ok ? Icons.check_circle : Icons.cancel,
            size: 20, color: ok ? Colors.greenAccent : Colors.redAccent),
        const SizedBox(width: 8),
        Expanded(child: Text(label)),
        if (!ok) TextButton(onPressed: fix, child: const Text('ON karo')),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final ready = _acc && _mic;
    final msg = _on
        ? 'Sara active hai. Screen ke kinare rangeen light ghoom rahi hai.'
        : ready
            ? 'Switch ON karo, Sara active ho jayegi.'
            : 'Pehle neeche ki permissions do.';

    return NeonBorder(
      radius: 20,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text('Sara Active',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                ),
                Switch(value: _on, onChanged: ready ? _toggle : null),
              ],
            ),
            Text(msg, style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 8),
            _row('Accessibility (phone control)', _acc,
                _pc.openAccessibilitySettings),
            _row('Microphone', _mic, _askMic),
          ],
        ),
      ),
    );
  }
}

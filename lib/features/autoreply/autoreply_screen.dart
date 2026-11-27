import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/auto_reply_service.dart';
import '../../services/phone_control.dart';
import '../../services/settings_service.dart';
import '../../widgets/neon.dart';

/// WhatsApp par chune hue logon ke message ka jawab Sara apne aap bheje.
class AutoReplyScreen extends StatefulWidget {
  const AutoReplyScreen({super.key});

  @override
  State<AutoReplyScreen> createState() => _AutoReplyScreenState();
}

class _AutoReplyScreenState extends State<AutoReplyScreen>
    with WidgetsBindingObserver {
  final _pc = PhoneControl();
  final _settings = SettingsService();
  final _add = TextEditingController();
  final _fixed = TextEditingController();
  final _sig = TextEditingController();
  final _owner = TextEditingController();
  final _tone = TextEditingController();

  bool _access = false;
  bool _on = false;
  bool _all = false;
  bool _mem = false;
  String _style = 'ai';
  List<String> _contacts = [];
  int _cool = 10;
  String _log = '';
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
    _poll = Timer.periodic(const Duration(seconds: 3), (_) => _refreshLog());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _poll?.cancel();
    for (final c in [_add, _fixed, _sig, _owner, _tone]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshAccess();
  }

  Future<void> _load() async {
    _fixed.text = await _settings.getAutoFixed();
    _sig.text = await _settings.getAutoSig();
    _owner.text = await _settings.getAutoOwner();
    _tone.text = await _settings.getAutoTone();
    final on = await _settings.getAutoOn();
    final all = await _settings.getAutoAll();
    final mem = await _settings.getAutoMem();
    final style = await _settings.getAutoStyle();
    final contacts = await _settings.getAutoContacts();
    final cool = await _settings.getAutoCooldown();
    if (!mounted) return;
    setState(() {
      _on = on;
      _all = all;
      _mem = mem;
      _style = style;
      _contacts = contacts;
      _cool = cool;
    });
    _refreshAccess();
    _refreshLog();
    AutoReplyService.instance.sync();
  }

  Future<void> _refreshAccess() async {
    final a = await _pc.autoAccess();
    if (mounted) setState(() => _access = a);
  }

  Future<void> _refreshLog() async {
    final l = await _pc.autoLog();
    if (mounted && l != _log) setState(() => _log = l);
  }

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _toggle(bool v) async {
    if (v && !_access) {
      _snack('Pehle Notification access do.');
      await _pc.openNotifAccess();
      return;
    }
    await _settings.setAutoOn(v);
    await AutoReplyService.instance.sync();
    setState(() => _on = v);
  }

  Future<void> _addContact() async {
    final t = _add.text.trim();
    if (t.isEmpty || _contacts.contains(t)) return;
    _add.clear();
    final list = [..._contacts, t];
    await _settings.setAutoContacts(list);
    setState(() => _contacts = list);
  }

  Future<void> _removeContact(String c) async {
    final list = _contacts.where((e) => e != c).toList();
    await _settings.setAutoContacts(list);
    setState(() => _contacts = list);
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 20, 0, 8),
        child: Text(t,
            style: const TextStyle(
                fontSize: 12, letterSpacing: 1.4, color: Colors.white60)),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('WhatsApp auto-reply')),
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
                      Icon(_access ? Icons.check_circle : Icons.cancel,
                          color:
                              _access ? Colors.greenAccent : Colors.redAccent),
                      const SizedBox(width: 8),
                      const Expanded(child: Text('Notification access')),
                      if (!_access)
                        TextButton(
                          onPressed: _pc.openNotifAccess,
                          child: const Text('ON karo'),
                        ),
                    ],
                  ),
                  const Text(
                    'Settings me "Sara" ko ON karo. Android 13+ par sideload ki '
                    'hui app me pehle: Phone Settings → Apps → Sara → ⋮ → '
                    '"Allow restricted settings".',
                    style: TextStyle(fontSize: 12, color: Colors.white60),
                  ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      const Expanded(
                        child: Text('Auto-reply ON',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700)),
                      ),
                      Switch(value: _on, onChanged: _toggle),
                    ],
                  ),
                ],
              ),
            ),
          ),
          _label('KIN LOGON KO JAWAB DENA HAI'),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Sabko jawab do'),
            subtitle: const Text(
                'Band rakhna behtar hai. Group chat me kabhi jawab nahi jata.'),
            value: _all,
            onChanged: (v) async {
              await _settings.setAutoAll(v);
              setState(() => _all = v);
            },
          ),
          if (!_all) ...[
            Wrap(
              spacing: 8,
              children: [
                for (final c in _contacts)
                  InputChip(label: Text(c), onDeleted: () => _removeContact(c)),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _add,
                    onSubmitted: (_) => _addContact(),
                    decoration: InputDecoration(
                      hintText: 'Naam (WhatsApp me jaisa dikhta hai)',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                    onPressed: _addContact, icon: const Icon(Icons.add)),
              ],
            ),
          ],
          _label('JAWAB KAISE'),
          Wrap(
            spacing: 10,
            children: [
              ChoiceChip(
                label: const Text('AI se likhwao'),
                selected: _style == 'ai',
                onSelected: (_) async {
                  await _settings.setAutoStyle('ai');
                  setState(() => _style = 'ai');
                },
              ),
              ChoiceChip(
                label: const Text('Tay message'),
                selected: _style == 'fixed',
                onSelected: (_) async {
                  await _settings.setAutoStyle('fixed');
                  setState(() => _style = 'fixed');
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_style == 'fixed')
            TextField(
              controller: _fixed,
              maxLines: 2,
              onChanged: _settings.setAutoFixed,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            )
          else ...[
            TextField(
              controller: _owner,
              onChanged: (v) async {
                await _settings.setAutoOwner(v.trim().isEmpty ? 'Kuldeep' : v.trim());
                AutoReplyService.instance.sync();
              },
              decoration: InputDecoration(
                labelText: 'Tumhara naam',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _tone,
              onChanged: (v) async {
                await _settings.setAutoTone(v);
                AutoReplyService.instance.sync();
              },
              decoration: InputDecoration(
                labelText: 'Jawab ka andaaz',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Memory ki yaadein bhi use karo'),
              subtitle: const Text(
                  'Band rakhna behtar: nahi to tumhari nijii baatein dusron ko jaa sakti hain.'),
              value: _mem,
              onChanged: (v) async {
                await _settings.setAutoMem(v);
                await AutoReplyService.instance.sync();
                setState(() => _mem = v);
              },
            ),
          ],
          const SizedBox(height: 10),
          TextField(
            controller: _sig,
            onChanged: _settings.setAutoSig,
            decoration: InputDecoration(
              labelText: 'Jawab ke neeche judne wali line',
              helperText: 'Batati hai ki jawab AI ne likha hai. Khali chhodne par nahi judegi.',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
          ),
          _label('EK HI BANDE KO DUBARA JAWAB (minute baad)'),
          Wrap(
            spacing: 10,
            children: [
              for (final m in [5, 10, 30, 60])
                ChoiceChip(
                  label: Text('$m'),
                  selected: _cool == m,
                  onSelected: (_) async {
                    await _settings.setAutoCooldown(m);
                    setState(() => _cool = m);
                  },
                ),
            ],
          ),
          Row(
            children: [
              const Expanded(
                child: Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: Text('LOG',
                      style: TextStyle(
                          fontSize: 12,
                          letterSpacing: 1.4,
                          color: Colors.white60)),
                ),
              ),
              TextButton(
                onPressed: () async {
                  await _pc.autoLogClear();
                  _refreshLog();
                },
                child: const Text('Saaf'),
              ),
            ],
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: NeonColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: NeonColors.purple.withAlpha(90)),
            ),
            child: Text(
              _log.isEmpty ? 'Abhi kuch nahi.' : _log,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Ye sirf WhatsApp ki notification ke "Reply" button se chalta hai, '
            'to jawab tabhi jayega jab us chat ki notification aaye (chat khuli '
            'ho ya mute ho to nahi). Paise, OTP, password jaisi baaton par jawab '
            'nahi bhejta. Jawab tumhari taraf se jaate hain, isliye signature '
            'line rakhna behtar hai. Message ka text jawab banane ke liye Gemini '
            '(Google) ko jaata hai.',
            style: TextStyle(fontSize: 12, color: Colors.white60),
          ),
        ],
      ),
    );
  }
}

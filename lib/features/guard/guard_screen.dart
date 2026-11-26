import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../services/phone_control.dart';
import '../../services/settings_service.dart';
import '../../widgets/neon.dart';

/// Touch Guard: phone lock karke chhodo. Koi chhuye to siren, photo aur chetavni.
class GuardScreen extends StatefulWidget {
  const GuardScreen({super.key});

  @override
  State<GuardScreen> createState() => _GuardScreenState();
}

class _GuardScreenState extends State<GuardScreen>
    with WidgetsBindingObserver {
  final _pc = PhoneControl();
  final _settings = SettingsService();
  final _owner = TextEditingController();

  int _sens = 1;
  int _delay = 3;
  String _status = 'idle';
  List<String> _photos = [];
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _settings.getGuardOwner().then((v) {
      if (mounted) _owner.text = v;
    });
    _settings.getGuardSens().then((v) {
      if (mounted) setState(() => _sens = v);
    });
    _settings.getGuardDelay().then((v) {
      if (mounted) setState(() => _delay = v);
    });
    _refresh();
    _poll = Timer.periodic(const Duration(seconds: 1), (_) => _refresh());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _poll?.cancel();
    _owner.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final s = await _pc.guardStatus();
    final p = await _pc.guardPhotos();
    if (!mounted) return;
    setState(() {
      _status = s;
      _photos = p;
    });
  }

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  bool get _running => _status != 'idle' && _status != 'error';

  Future<bool> _ensureCamera() async {
    if (await _pc.hasCamera()) return true;
    await _pc.requestAll();
    _snack('Camera ki permission do (Allow dabao), fir dobara try karo.');
    return false;
  }

  Future<void> _start({String action = 'arm'}) async {
    if (!await _ensureCamera()) return;
    await _settings.setGuardOwner(_owner.text);
    final ok = await _pc.guardStart(
      _owner.text.trim().isEmpty ? 'Mr ZX KD' : _owner.text.trim(),
      _sens,
      _delay,
      action: action,
    );
    if (!ok) {
      _snack('Guard shuru nahi hua. App permissions me Camera aur Notification dekho.');
    } else if (action == 'arm') {
      _snack('Ab phone lock karo. 10 second baad guard lag jayega.');
    }
    _refresh();
  }

  Future<void> _stop() async {
    await _pc.guardStop();
    _refresh();
  }

  String get _statusText {
    switch (_status) {
      case 'waiting':
        return 'Phone lock karo (power button). 10 second baad guard lagega.';
      case 'grace':
        return 'Guard lag raha hai... phone neeche rakh do.';
      case 'armed':
        return 'Guard chalu hai. Koi hilayega to siren bajega.';
      case 'trigger':
        return 'Kuch hila! Unlock nahi hua to siren bajega.';
      case 'alarm':
        return 'ALARM! Siren baj raha hai. Phone unlock karo.';
      case 'test':
        return 'Test chal raha hai...';
      case 'error':
        return 'Guard shuru nahi ho paya.';
      default:
        return 'Guard band hai';
    }
  }

  Widget _chips(String label, List<String> names, int value, void Function(int) on) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12, letterSpacing: 1.4, color: Colors.white60)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            children: [
              for (var i = 0; i < names.length; i++)
                ChoiceChip(
                  label: Text(names[i]),
                  selected: value == i,
                  onSelected: _running ? null : (_) => on(i),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _viewPhoto(String path) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: InteractiveViewer(child: Image.file(File(path)))),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () async {
                    await _pc.guardDeletePhoto(path);
                    if (ctx.mounted) Navigator.pop(ctx);
                    _refresh();
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Hatao'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Band'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final alarm = _status == 'alarm' || _status == 'trigger';
    return Scaffold(
      appBar: AppBar(title: const Text('Touch Guard')),
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
                      Icon(alarm ? Icons.warning_amber : Icons.shield_outlined,
                          color: alarm ? Colors.redAccent : NeonColors.cyan,
                          size: 30),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text('Touch Guard',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(_statusText,
                      style: TextStyle(
                          fontSize: 13,
                          color: alarm ? Colors.redAccent : NeonColors.cyan)),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: _running
                        ? FilledButton.icon(
                            onPressed: _stop,
                            icon: const Icon(Icons.stop),
                            label: const Text('Guard band karo'),
                          )
                        : FilledButton.icon(
                            onPressed: _start,
                            icon: const Icon(Icons.lock_outline),
                            label: const Text('Guard chalu karo'),
                          ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _owner,
            enabled: !_running,
            decoration: InputDecoration(
              labelText: 'Phone ke maalik ka naam (chetavni me bolega)',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
          ),
          _chips('SENSITIVITY', ['Kam', 'Madhyam', 'Zyada'], _sens, (v) async {
            await _settings.setGuardSens(v);
            setState(() => _sens = v);
          }),
          _chips('HILNE KE BAAD SIREN SE PEHLE', ['Turant', '3 sec', '5 sec'],
              _delay == 0 ? 0 : (_delay == 3 ? 1 : 2), (v) async {
            final d = v == 0 ? 0 : (v == 1 ? 3 : 5);
            await _settings.setGuardDelay(d);
            setState(() => _delay = d);
          }),
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text(
              'Chetavni ka mauka: tum phone uthakar itni der me unlock kar lo to '
              'siren nahi bajega aur photo hat jayegi. "Turant" me siren seedha bajta hai.',
              style: TextStyle(fontSize: 12, color: Colors.white60),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _running ? null : () => _start(action: 'test'),
            icon: const Icon(Icons.volume_up_outlined),
            label: const Text('Siren aur awaaz ka test (4 second)'),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text(
              'Kaise kaam karta hai: "Guard chalu karo" dabao, phir phone lock karo. '
              '10 second baad guard lag jata hai. Koi phone uthaye ya hilaye to siren '
              'bajta hai, front camera se photo khichti hai, aur chetavni bolti hai. '
              'Tumhare unlock karte hi sab band. Isliye phone me PIN ya fingerprint '
              'lock zaroor rakho. Photos sirf is phone me rehti hain.',
              style: TextStyle(fontSize: 12, color: Colors.white60),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  'PAKDE GAYE · ${_photos.length}',
                  style: const TextStyle(
                      fontSize: 12, letterSpacing: 1.6, color: Colors.white60),
                ),
              ),
              if (_photos.isNotEmpty)
                TextButton(
                  onPressed: () async {
                    await _pc.guardClearPhotos();
                    _refresh();
                  },
                  child: const Text('Sab hatao'),
                ),
            ],
          ),
          if (_photos.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text('Abhi koi photo nahi.',
                    style: TextStyle(color: Colors.white60)),
              ),
            )
          else
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: [
                for (final p in _photos)
                  GestureDetector(
                    onTap: () => _viewPhoto(p),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(File(p), fit: BoxFit.cover),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

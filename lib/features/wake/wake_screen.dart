import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/phone_control.dart';
import '../../services/settings_service.dart';
import '../../services/wake_service.dart';
import '../../widgets/neon.dart';
import '../../widgets/zoya_orb.dart';

class WakeScreen extends StatefulWidget {
  const WakeScreen({super.key});

  @override
  State<WakeScreen> createState() => _WakeScreenState();
}

class _WakeScreenState extends State<WakeScreen> {
  final _settings = SettingsService();
  final _pc = PhoneControl();
  final _phrases = TextEditingController();

  int _orb = 0;
  int _stop = 10;
  bool _on = false;
  bool _active = false;
  String _status = 'off';
  String _heard = '';
  bool _free = false;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _settings.getOrb().then((v) {
      if (mounted) setState(() => _orb = v);
    });
    _settings.getAutoStop().then((v) {
      if (mounted) setState(() => _stop = v);
    });
    _settings.getWake().then((v) {
      if (mounted) setState(() => _on = v);
    });
    _settings.getActive().then((v) {
      if (mounted) setState(() => _active = v);
    });
    _settings.getWakePhrasesText().then((v) {
      if (mounted) _phrases.text = v;
    });
    _settings.getWakeFree().then((v) {
      if (mounted) setState(() => _free = v);
    });
    _poll = Timer.periodic(const Duration(seconds: 1), (_) async {
      final s = await _pc.wakeStatus();
      final h = await _pc.wakeHeard();
      if (mounted) {
        setState(() {
          _status = s;
          _heard = h;
        });
      }
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    _phrases.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _toggle(bool v) async {
    if (v) {
      await _pc.requestNotif();
      final err = await WakeService.instance.start();
      if (err != null) {
        _snack(err);
        return;
      }
      await _settings.setWake(true);
    } else {
      await WakeService.instance.stop();
      await _settings.setWake(false);
    }
    if (mounted) setState(() => _on = v);
  }

  Future<void> _savePhrases() async {
    await _settings.setWakePhrases(_phrases.text);
    if (_on) {
      await WakeService.instance.stop();
      final err = await WakeService.instance.start();
      if (err != null) _snack(err);
    }
    _snack('Save ho gaya');
  }

  String get _statusText {
    if (_status == 'loading') {
      return 'Model load ho raha hai... (pehli baar thoda time lagta hai)';
    }
    if (_status == 'listening') return 'Sun rahi hai... bolo: "Wake up Zoya"';
    if (_status == 'awake') return 'Jaag gayi!';
    if (_status == 'paused') return 'Abhi baat chal rahi hai.';
    if (_status.startsWith('error')) return 'Dikkat: $_status';
    return 'Band hai';
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 20, 0, 10),
        child: Text(
          text,
          style: const TextStyle(
              fontSize: 12, letterSpacing: 1.6, color: Colors.white60),
        ),
      );

  Widget _orbTile(int i) {
    final d = OrbDesigns.all[i];
    final selected = i == _orb;
    return Material(
      color: NeonColors.card,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: selected ? NeonColors.cyan : NeonColors.purple.withAlpha(110),
          width: selected ? 2.4 : 1.2,
        ),
      ),
      child: InkWell(
        onTap: () async {
          await _settings.setOrb(i);
          if (mounted) setState(() => _orb = i);
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OrbBall(design: d, size: 72),
            const SizedBox(height: 12),
            Text(d.name,
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: selected ? NeonColors.cyan : Colors.white)),
            Text(selected ? '✓ Selected' : 'Tap to select',
                style: const TextStyle(fontSize: 12, color: Colors.white60)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canToggle = _on || _active;
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Wake Word'),
            Text('OFFLINE VOSK · WAKE UP ZOYA',
                style: TextStyle(
                    fontSize: 12, letterSpacing: 2, color: Colors.white60)),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: NeonColors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: NeonColors.purple.withAlpha(110)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text('Background wake word detection',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    Switch(
                      value: _on,
                      onChanged: canToggle ? _toggle : null,
                    ),
                  ],
                ),
                Text(_statusText,
                    style: const TextStyle(
                        fontSize: 13, color: NeonColors.cyan)),
                if (_status == 'listening' || _status == 'awake')
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _heard.isEmpty ? 'Suna: (abhi kuch nahi)' : 'Suna: "$_heard"',
                      style: const TextStyle(
                          fontSize: 12, color: Colors.white70),
                    ),
                  ),
                if (!canToggle)
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Text(
                      'Pehle Home par Zoya Active ON karo.',
                      style: TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ),
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text(
                    'ON karne par notification dikhegi. Naam sunte hi Zoya '
                    'jaag jati hai. Naam pehchanne ka kaam phone par hi hota '
                    'hai, jaagne se pehle awaaz internet par nahi jaati.',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
          _label('WAKE SHABD · comma se alag'),
          TextField(
            controller: _phrases,
            autocorrect: false,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16)),
              hintText: 'wake up zoya',
              suffixIcon: IconButton(
                icon: const Icon(Icons.save_outlined),
                onPressed: _savePhrases,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text(
              '"Wake up" sunte hi Zoya jaag jati hai, naam chahe kuch bhi sunai '
              'de (soy, julia, zulia...). Isliye kisi aur ke "wake up" kehne '
              'par bhi jaag sakti hai.',
              style: TextStyle(fontSize: 12, color: Colors.white60),
            ),
          ),
          Row(
            children: [
              const Expanded(
                child: Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Text(
                    'Sab suno (jaanch mode): "Suna:" me dikhta hai Zoya kya '
                    'sun rahi hai. Zyada battery lagti hai. Naam pakda jaane '
                    'lage to ise band kar dena.',
                    style: TextStyle(fontSize: 12, color: Colors.white60),
                  ),
                ),
              ),
              Switch(
                value: _free,
                onChanged: (v) async {
                  await _settings.setWakeFree(v);
                  setState(() => _free = v);
                  if (_on) {
                    await WakeService.instance.stop();
                    final err = await WakeService.instance.start();
                    if (err != null) _snack(err);
                  }
                },
              ),
            ],
          ),
          _label('AUTO STOP · koi na bole to'),
          Wrap(
            spacing: 10,
            children: [
              for (final s in [5, 10, 15])
                ChoiceChip(
                  label: Text('$s sec'),
                  selected: _stop == s,
                  onSelected: (_) async {
                    await _settings.setAutoStop(s);
                    if (mounted) setState(() => _stop = s);
                  },
                ),
            ],
          ),
          _label('GOLA DESIGNS · choose one of 10'),
          neonRows(
            [for (var i = 0; i < OrbDesigns.all.length; i++) _orbTile(i)],
            height: 170,
          ),
        ],
      ),
    );
  }
}

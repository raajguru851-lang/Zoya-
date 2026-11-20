import 'package:flutter/material.dart';
import '../../services/settings_service.dart';
import '../../widgets/neon.dart';
import '../../widgets/zoya_orb.dart';

class WakeScreen extends StatefulWidget {
  const WakeScreen({super.key});

  @override
  State<WakeScreen> createState() => _WakeScreenState();
}

class _WakeScreenState extends State<WakeScreen> {
  final _settings = SettingsService();
  int _orb = 0;
  int _stop = 10;

  @override
  void initState() {
    super.initState();
    _settings.getOrb().then((v) {
      if (mounted) setState(() => _orb = v);
    });
    _settings.getAutoStop().then((v) {
      if (mounted) setState(() => _stop = v);
    });
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
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Wake Word'),
            Text('HEY ZOYA',
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
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('Background wake word detection',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    Switch(value: false, onChanged: null),
                  ],
                ),
                Text(
                  'Offline Vosk engine agle step me judega. Tab tak neeche '
                  'Auto stop aur Gola design chun sakte ho.',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
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

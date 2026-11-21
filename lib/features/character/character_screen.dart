import 'package:flutter/material.dart';
import '../../services/settings_service.dart';
import '../../widgets/neon.dart';
import '../../widgets/zoya_doll.dart';
import '../../widgets/zoya_orb.dart';

/// Character chuno: koi doll, ya sirf gola (-1).
class CharacterScreen extends StatefulWidget {
  const CharacterScreen({super.key});

  @override
  State<CharacterScreen> createState() => _CharacterScreenState();
}

class _CharacterScreenState extends State<CharacterScreen> {
  final _settings = SettingsService();
  int _doll = 0;
  int _orb = 0;

  @override
  void initState() {
    super.initState();
    _settings.getDoll().then((v) {
      if (mounted) setState(() => _doll = v);
    });
    _settings.getOrb().then((v) {
      if (mounted) setState(() => _orb = v);
    });
  }

  Future<void> _pick(int i) async {
    await _settings.setDoll(i);
    if (mounted) setState(() => _doll = i);
  }

  Widget _tile({
    required Widget preview,
    required String name,
    required bool selected,
    required VoidCallback onTap,
  }) {
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
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            preview,
            const SizedBox(height: 8),
            Text(name,
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
    final tiles = <Widget>[
      for (var i = 0; i < Dolls.all.length; i++)
        _tile(
          preview: DollPreview(design: Dolls.all[i], height: 150),
          name: Dolls.all[i].name,
          selected: _doll == i,
          onTap: () => _pick(i),
        ),
      _tile(
        preview: Padding(
          padding: const EdgeInsets.symmetric(vertical: 36),
          child: OrbBall(design: OrbDesigns.at(_orb), size: 72),
        ),
        name: 'Sirf Gola',
        selected: _doll < 0,
        onTap: () => _pick(-1),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Character'),
            Text('CHOOSE YOUR ZOYA · ${Dolls.all.length} LOOK',
                style: const TextStyle(
                    fontSize: 12, letterSpacing: 2, color: Colors.white60)),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [neonRows(tiles, height: 230)],
      ),
    );
  }
}

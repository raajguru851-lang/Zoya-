import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/routes.dart';
import '../../services/settings_service.dart';
import '../../widgets/neon.dart';
import '../active/active_card.dart';
import '../modes/modes.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _modeName = '';

  @override
  void initState() {
    super.initState();
    _load();
    ModeEvents.tick.addListener(_load);
  }

  @override
  void dispose() {
    ModeEvents.tick.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final id = await SettingsService().getMode();
    if (mounted) setState(() => _modeName = Modes.byId(id).name);
  }

  Future<void> _go(String route) async {
    await Navigator.pushNamed(context, route);
    _load();
  }

  void _soon(String name) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('$name jaldi aayega')));
  }

  void _about() {
    showDialog<void>(
      context: context,
      builder: (_) => const AlertDialog(
        title: Text('Sara'),
        content: Text('Sara ko Mr ZX KD (Kuldeep Gautam) ne banaya hai.'),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 16, 0, 10),
        child: Text(
          text,
          style: const TextStyle(
              fontSize: 12, letterSpacing: 1.6, color: Colors.white60),
        ),
      );

  Widget _tile(IconData icon, String title,
      {String? sub, String? route, VoidCallback? onTap, bool soon = false}) {
    return NeonGridTile(
      icon: icon,
      title: title,
      subtitle: soon ? 'Jaldi aayega' : sub,
      dim: soon,
      onTap: soon
          ? () => _soon(title)
          : (onTap ?? () => _go(route!)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ClipOval(
              child: Image.asset(
                'assets/sara_logo.png',
                width: 40,
                height: 40,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            ShaderMask(
              shaderCallback: (r) => const LinearGradient(
                colors: [NeonColors.cyan, NeonColors.magenta],
              ).createShader(r),
              child: const Text(
                AppConstants.appName,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          const ActiveCard(),
          _label('ASSISTANT'),
          neonRows([
            _tile(Icons.chat_bubble_outline, 'Chat', route: AppRoutes.chat),
            _tile(Icons.mic_none, 'Voice', route: AppRoutes.voice),
            _tile(Icons.favorite_border, 'Modes',
                sub: _modeName.isEmpty ? null : _modeName,
                route: AppRoutes.modes),
            _tile(Icons.person_outline, 'Character', route: AppRoutes.character),
            _tile(Icons.photo_camera_outlined, 'Camera vision',
                route: AppRoutes.camera),
            _tile(Icons.settings_outlined, 'Gemini settings',
                route: AppRoutes.settings),
          ]),
          _label('PHONE & AUTOMATION'),
          neonRows([
            _tile(Icons.phone_android, 'Phone control',
                route: AppRoutes.control),
            _tile(Icons.forum_outlined, 'WhatsApp Automation', soon: true),
            _tile(Icons.hearing, 'Wake Word',
                sub: 'Wake up Sara', route: AppRoutes.wake),
            _tile(Icons.terminal, 'Termux agent', soon: true),
            _tile(Icons.security, 'App permissions',
                route: AppRoutes.permissions),
          ]),
          _label('PERSONAL'),
          neonRows([
            _tile(Icons.psychology_outlined, 'Memory', route: AppRoutes.memory),
            _tile(Icons.info_outline, 'About', onTap: _about),
          ]),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/routes.dart';
import '../../widgets/neon.dart';
import '../active/active_card.dart';

/// Naya feature = features list me ek line.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final features = <_Feature>[
      _Feature('Chat', Icons.chat_bubble_outline, AppRoutes.chat),
      _Feature('Voice (Zoya se bolkar baat)', Icons.mic_none, AppRoutes.voice),
      _Feature('Phone Control', Icons.phone_android, AppRoutes.control),
      _Feature('Modes', Icons.face_outlined, AppRoutes.modes),
      _Feature('Settings', Icons.settings_outlined, AppRoutes.settings),
      // Naye features yahan add honge
    ];

    return Scaffold(
      appBar: AppBar(
        title: ShaderMask(
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
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          const ActiveCard(),
          const SizedBox(height: 8),
          for (final f in features)
            NeonTile(
              icon: f.icon,
              title: f.title,
              onTap: () => Navigator.pushNamed(context, f.route),
            ),
        ],
      ),
    );
  }
}

class _Feature {
  final String title;
  final IconData icon;
  final String route;
  _Feature(this.title, this.icon, this.route);
}

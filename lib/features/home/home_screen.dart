import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/routes.dart';

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
      appBar: AppBar(title: const Text(AppConstants.appName)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final f in features)
            Card(
              child: ListTile(
                leading: Icon(f.icon),
                title: Text(f.title),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pushNamed(context, f.route),
              ),
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

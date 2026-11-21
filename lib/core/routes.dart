import 'package:flutter/material.dart';
import '../features/camera/camera_screen.dart';
import '../features/character/character_screen.dart';
import '../features/control/control_screen.dart';
import '../features/home/home_screen.dart';
import '../features/chat/chat_screen.dart';
import '../features/memory/memory_screen.dart';
import '../features/modes/modes_screen.dart';
import '../features/permissions/permissions_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/voice/voice_screen.dart';
import '../features/wake/wake_screen.dart';

/// Naya screen add karna ho to yahan ek route jodo.
class AppRoutes {
  static const home = '/';
  static const chat = '/chat';
  static const camera = '/camera';
  static const character = '/character';
  static const control = '/control';
  static const voice = '/voice';
  static const wake = '/wake';
  static const memory = '/memory';
  static const modes = '/modes';
  static const permissions = '/permissions';
  static const settings = '/settings';

  static final Map<String, WidgetBuilder> routes = {
    home: (_) => const HomeScreen(),
    chat: (_) => const ChatScreen(),
    camera: (_) => const CameraScreen(),
    character: (_) => const CharacterScreen(),
    control: (_) => const ControlScreen(),
    voice: (_) => const VoiceScreen(),
    wake: (_) => const WakeScreen(),
    memory: (_) => const MemoryScreen(),
    modes: (_) => const ModesScreen(),
    permissions: (_) => const PermissionsScreen(),
    settings: (_) => const SettingsScreen(),
  };
}

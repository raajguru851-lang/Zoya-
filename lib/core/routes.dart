import 'package:flutter/material.dart';
import '../features/home/home_screen.dart';
import '../features/chat/chat_screen.dart';
import '../features/modes/modes_screen.dart';
import '../features/settings/settings_screen.dart';

/// Naya screen add karna ho to yahan ek route jodo.
class AppRoutes {
  static const home = '/';
  static const chat = '/chat';
  static const modes = '/modes';
  static const settings = '/settings';

  static final Map<String, WidgetBuilder> routes = {
    home: (_) => const HomeScreen(),
    chat: (_) => const ChatScreen(),
    modes: (_) => const ModesScreen(),
    settings: (_) => const SettingsScreen(),
  };
}

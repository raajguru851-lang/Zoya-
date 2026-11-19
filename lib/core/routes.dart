import 'package:flutter/material.dart';
import '../features/home/home_screen.dart';

/// Naya screen add karna ho to yahan ek route jodo.
class AppRoutes {
  static const home = '/';

  static final Map<String, WidgetBuilder> routes = {
    home: (_) => const HomeScreen(),
  };
}

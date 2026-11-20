import 'package:flutter/material.dart';
import 'core/constants.dart';
import 'core/theme.dart';
import 'widgets/neon.dart';
import 'core/routes.dart';

void main() => runApp(const AssistantApp());

class AssistantApp extends StatelessWidget {
  const AssistantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      builder: (context, child) => Stack(
        fit: StackFit.expand,
        children: [
          child ?? const SizedBox.shrink(),
          const IgnorePointer(child: SideLines()),
        ],
      ),
      initialRoute: AppRoutes.home,
      routes: AppRoutes.routes,
    );
  }
}

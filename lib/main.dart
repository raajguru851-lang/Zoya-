import 'package:flutter/material.dart';
import 'core/constants.dart';
import 'core/theme.dart';
import 'core/routes.dart';
import 'services/wake_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  WakeService.instance.init();
  runApp(const AssistantApp());
}

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
      initialRoute: AppRoutes.home,
      routes: AppRoutes.routes,
    );
  }
}

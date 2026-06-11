import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:recipify/core/theme/app_theme.dart';
import 'package:recipify/core/theme/theme_notifier.dart';
import 'package:recipify/features/splash/screens/splash_screen.dart';

Future<void> main() async {
  FlutterError.onError = (details) {
    debugPrint('FLUTTER ERROR: ${details.exceptionAsString()}');
    debugPrint(details.stack.toString());
  };
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Supabase.initialize(
      url: 'https://mkjbkzvupciocqiymmuf.supabase.co',
      anonKey: 'sb_publishable_sCDqYLvFCqWWHyLNrNa9jQ_-oi2jQ8K',
      debug: true,
    );
    await ThemeNotifier.instance.init();
    runApp(const RecipifyApp());
  }, (error, stack) {
    debugPrint('ZONE ERROR: $error');
    debugPrint(stack.toString());
  });
}

class RecipifyApp extends StatelessWidget {
  const RecipifyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeNotifier.instance,
      builder: (_, mode, __) => MaterialApp(
        title: 'Recipify',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: mode,
        home: const SplashScreen(),
      ),
    );
  }
}
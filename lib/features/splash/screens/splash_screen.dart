import 'package:flutter/material.dart';
import 'package:recipify/features/auth/screens/login_screen.dart';
import 'package:recipify/features/home/screens/main_screen.dart';
import 'package:recipify/services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _redirecionar();
  }

  Future<void> _redirecionar() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Usa AuthService local (SQLite) — não Supabase
    if (AuthService.instance.estaLogado) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Image.asset(
          'assets/images/Logo.png',
          height: 180,
        ),
      ),
    );
  }
}

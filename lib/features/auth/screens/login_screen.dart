import 'package:flutter/material.dart';
import 'package:recipify/core/theme/app_theme.dart';
import 'package:recipify/features/auth/screens/cadastro_screen.dart';
import 'package:recipify/features/home/screens/main_screen.dart';
import 'package:recipify/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();

  bool _carregando   = false;
  bool _mostrarSenha = false;
  String? _erro;

  Future<void> _login() async {
    if (_emailCtrl.text.trim().isEmpty || _senhaCtrl.text.isEmpty) {
      setState(() => _erro = 'Preencha e-mail e senha.');
      return;
    }

    setState(() { _erro = null; _carregando = true; });

    try {
      final result = await AuthService.instance.login(
        email: _emailCtrl.text.trim(),
        senha: _senhaCtrl.text,
      );

      if (!mounted) return;
      setState(() => _carregando = false);

      if (result['sucesso']) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      } else {
        setState(() => _erro = result['erro']);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _carregando = false;
        _erro = 'Erro inesperado. Tente novamente.';
      });
    }
  }

  void _irParaHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),

                // Logo
                Center(
                  child: Image.asset(
                    'assets/images/Logo.png',
                    height: 100,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Bem-vindo!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(height: 32),

                // Card de login com chapéu flutuando no canto inferior direito
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Card principal
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBg,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              hintText: 'E-mail',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _senhaCtrl,
                            obscureText: !_mostrarSenha,
                            decoration: InputDecoration(
                              hintText: 'Senha',
                              prefixIcon: const Icon(Icons.lock_outlined),
                              suffixIcon: IconButton(
                                icon: Icon(_mostrarSenha
                                    ? Icons.visibility_off
                                    : Icons.visibility),
                                onPressed: () => setState(
                                    () => _mostrarSenha = !_mostrarSenha),
                              ),
                            ),
                          ),
                          if (_erro != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              _erro!,
                              style: const TextStyle(
                                  color: Colors.red, fontSize: 13),
                            ),
                          ],
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _carregando ? null : _login,
                            child: _carregando
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Entrar'),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Não possui uma conta? ',
                                style: TextStyle(
                                    color: AppTheme.textGray, fontSize: 13),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const CadastroScreen()),
                                ),
                                child: Text(
                                  'Cadastre-se',
                                  style: TextStyle(
                                    color: AppTheme.primary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          // Espaço para o chapéu não sobrepor o texto
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),

                    // Chapéu flutuando no canto inferior direito do card
                    Positioned(
                      bottom: -60,
                      right: -20, // leve inclinação ~17 graus
                        child: Image.asset(
                          'assets/images/chefhat.png',
                          height: 160,
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 24),

                // Pular
                TextButton(
                  onPressed: _irParaHome,
                  child: Text(
                    'Pular por enquanto',
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontSize: 14,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
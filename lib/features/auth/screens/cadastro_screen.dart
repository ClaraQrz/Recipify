import 'package:flutter/material.dart';
import 'package:recipify/core/theme/app_theme.dart';
import 'package:recipify/features/home/screens/main_screen.dart';
import 'package:recipify/services/auth_service.dart';

class CadastroScreen extends StatefulWidget {
  const CadastroScreen({super.key});

  @override
  State<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  final _apelidoCtrl        = TextEditingController();
  final _emailCtrl          = TextEditingController();
  final _senhaCtrl          = TextEditingController();
  final _confirmarSenhaCtrl = TextEditingController();

  bool _carregando   = false;
  bool _mostrarSenha = false;
  String? _erro;

  Future<void> _cadastrar() async {
    // Validações locais antes de chamar o serviço
    if (_apelidoCtrl.text.trim().isEmpty ||
        _emailCtrl.text.trim().isEmpty ||
        _senhaCtrl.text.isEmpty) {
      setState(() => _erro = 'Preencha todos os campos obrigatórios.');
      return;
    }

    if (_senhaCtrl.text != _confirmarSenhaCtrl.text) {
      setState(() => _erro = 'As senhas não coincidem.');
      return;
    }

    if (_senhaCtrl.text.length < 6) {
      setState(() => _erro = 'A senha deve ter pelo menos 6 caracteres.');
      return;
    }

    setState(() { _erro = null; _carregando = true; });

    try {
      final result = await AuthService.instance.cadastrar(
        apelido: _apelidoCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        senha: _senhaCtrl.text,
      );

      if (!mounted) return;
      setState(() => _carregando = false);

      if (result['sucesso']) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainScreen()),
          (_) => false,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Criar Conta')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _apelidoCtrl,
              decoration: const InputDecoration(
                labelText: 'Apelido',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'E-mail',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _senhaCtrl,
              obscureText: !_mostrarSenha,
              decoration: InputDecoration(
                labelText: 'Senha',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_mostrarSenha
                      ? Icons.visibility_off
                      : Icons.visibility),
                  onPressed: () =>
                      setState(() => _mostrarSenha = !_mostrarSenha),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmarSenhaCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirmar senha',
                prefixIcon: Icon(Icons.lock_reset),
              ),
            ),
            if (_erro != null) ...[
              const SizedBox(height: 10),
              Text(
                _erro!,
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _carregando ? null : _cadastrar,
              child: _carregando
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Criar conta'),
            ),
          ],
        ),
      ),
    );
  }
}
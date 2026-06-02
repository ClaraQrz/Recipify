import 'package:flutter/material.dart';
import 'package:recipify/features/home/screens/main_screen.dart';
import 'package:recipify/services/auth_service.dart';

class CadastroScreen extends StatefulWidget {
  const CadastroScreen({super.key});

  @override
  State<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  final _apelidoCtrl = TextEditingController();
  final _emailCtrl   = TextEditingController();
  final _senhaCtrl   = TextEditingController();
  bool _carregando = false;
  String? _erro;

  Future<void> _cadastrar() async {
    if (_apelidoCtrl.text.isEmpty || _emailCtrl.text.isEmpty || _senhaCtrl.text.isEmpty) {
      setState(() => _erro = 'Preencha todos os campos obrigatórios.');
      return;
    }

    setState(() { _carregando = true; _erro = null; });

    final result = await AuthService.instance.cadastrar(
      apelido: _apelidoCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      senha: _senhaCtrl.text,
    );

    setState(() => _carregando = false);

    if (!mounted) return;

    if (result['sucesso']) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
        (_) => false,
      );
    } else {
      setState(() => _erro = result['erro']);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Criar conta')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _apelidoCtrl,
                decoration: const InputDecoration(
                  labelText: 'Apelido *',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'E-mail *',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _senhaCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Senha *',
                  prefixIcon: Icon(Icons.lock_outlined),
                ),
              ),
              if (_erro != null) ...[
                const SizedBox(height: 8),
                Text(_erro!, style: const TextStyle(color: Colors.red, fontSize: 13)),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _carregando ? null : _cadastrar,
                child: _carregando
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Criar conta'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
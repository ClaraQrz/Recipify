import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:recipify/core/theme/app_theme.dart';
import 'package:recipify/features/auth/screens/login_screen.dart';
import 'package:recipify/repositories/estoque_repository.dart';
import 'package:recipify/repositories/lista_repository.dart';
import 'package:recipify/repositories/receita_repository.dart';
import 'package:recipify/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _totalReceitas = 0;
  int _totalListas = 0;
  int _totalItens = 0;
  bool _carregando = true;

  String? _fotoPath;

  @override
  void initState() {
    super.initState();
    _carregarContagens();
    _carregarFoto();
  }

  Future<void> _carregarFoto() async {
    final prefs = await SharedPreferences.getInstance();

    final usuarioId =
        AuthService.instance.usuarioLogado?['id']?.toString() ?? '';

    final path = prefs.getString('foto_perfil_$usuarioId');

    if (path != null && File(path).existsSync()) {
      setState(() {
        _fotoPath = path;
      });
    }
  }

  Future<void> _trocarFoto() async {
    final picker = ImagePicker();

    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );

    if (picked == null) return;

    final usuarioId =
        AuthService.instance.usuarioLogado?['id']?.toString() ?? '';

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      'foto_perfil_$usuarioId',
      picked.path,
    );

    setState(() {
      _fotoPath = picked.path;
    });
  }

  Future<void> _carregarContagens() async {
    try {
      final usuarioId =
          AuthService.instance.usuarioLogado?['id']?.toString() ?? '';

      final receitas = await ReceitaRepository.instance.minhasReceitas();
      final listas = await ListaRepository.instance.todasAsListas(usuarioId);
      final totalItens =
          await EstoqueRepository.instance.contarItens(usuarioId);

      setState(() {
        _totalReceitas = receitas.length;
        _totalListas = listas.length;
        _totalItens = totalItens;
        _carregando = false;
      });
    } catch (e) {
      debugPrint('>>> ERRO ao carregar contagens: $e');

      setState(() {
        _carregando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final usuario = AuthService.instance.usuarioLogado;

    final String apelido = usuario?['apelido'] ?? 'Usuário';
    final String email = usuario?['email'] ?? '';

    return ScrollConfiguration(
      behavior: const ScrollBehavior().copyWith(
        overscroll: false,
      ),
      child: Scaffold(
        backgroundColor: AppTheme.cardBg,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: AppTheme.primary,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('Meu Perfil'),
          backgroundColor: AppTheme.cardBg,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                color: AppTheme.cardBg,
                padding: const EdgeInsets.only(
                  top: 22,
                  bottom: 22,
                ),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        GestureDetector(
                          onTap: _trocarFoto,
                          child: CircleAvatar(
                            radius: 48,
                            backgroundColor:
                                AppTheme.primary.withOpacity(0.25),
                            backgroundImage: _fotoPath != null
                                ? FileImage(
                                    File(_fotoPath!),
                                  )
                                : null,
                            child: _fotoPath == null
                                ? Text(
                                    apelido.isNotEmpty
                                        ? apelido[0].toUpperCase()
                                        : 'U',
                                    style: const TextStyle(
                                      color: AppTheme.primary,
                                      fontSize: 38,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _trocarFoto,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        Colors.black.withOpacity(0.15),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                size: 16,
                                color: AppTheme.primary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      apelido,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: TextStyle(
                        color: Colors.black.withOpacity(0.85),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _carregando
                        ? const CircularProgressIndicator(
                            color: AppTheme.primary,
                          )
                        : Row(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              _ContadorItem(
                                valor: _totalReceitas,
                                label: 'Receitas',
                              ),
                              _Divisor(),
                              _ContadorItem(
                                valor: _totalListas,
                                label: 'Listas',
                              ),
                              _Divisor(),
                              _ContadorItem(
                                valor: _totalItens,
                                label: 'Itens',
                              ),
                            ],
                          ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color:
                            Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _MenuItem(
                        icon: Icons.notifications_outlined,
                        label: 'Notificações',
                        onTap: () {},
                      ),

                      const Divider(
                        height: 1,
                        indent: 56,
                      ),

                      _MenuItem(
                        icon: Icons.palette_outlined,
                        label: 'Tema',
                        onTap: () {},
                      ),

                      const Divider(
                        height: 1,
                        indent: 56,
                      ),

                      _MenuItem(
                        icon: Icons.share_outlined,
                        label: 'Compartilhar perfil',
                        onTap: () {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Compartilhar perfil — em breve!',
                              ),
                            ),
                          );
                        },
                      ),

                      const Divider(
                        height: 1,
                        indent: 56,
                      ),

                      _MenuItem(
                        icon: Icons.star_outline,
                        label: 'Avaliar app',
                        onTap: () {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Avaliar app — em breve!',
                              ),
                            ),
                          );
                        },
                      ),

                      const Divider(
                        height: 1,
                        indent: 56,
                      ),

                      _MenuItem(
                        icon: Icons.logout,
                        label: 'Sair',
                        onTap: () {
                          AuthService.instance.logout();

                          if (!context.mounted) return;

                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const LoginScreen(),
                            ),
                            (route) => false,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContadorItem extends StatelessWidget {
  final int valor;
  final String label;

  const _ContadorItem({
    required this.valor,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      padding: const EdgeInsets.symmetric(
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            '$valor',
            style: const TextStyle(
              color: AppTheme.primary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: AppTheme.primary.withOpacity(0.9),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divisor extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      margin: const EdgeInsets.symmetric(
        horizontal: 8,
      ),
      color: Colors.grey.withOpacity(0.3),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: AppTheme.textDark,
        size: 22,
      ),
      title: Text(
        label,
        style: const TextStyle(
          color: AppTheme.textDark,
          fontSize: 15,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: AppTheme.textGray,
      ),
      onTap: onTap,
    );
  }
}
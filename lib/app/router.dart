import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '..features/receitas/screens/receitas_screen.dart';
import '..features/estoque/screens/estoque_screen.dart';
import '..features/compras/screens/compras_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/receitas',
  routes: [
    ShellRoute(
      builder: (context, state, child) => ScaffoldWithNav(child: child),
      routes: [
        GoRoute(path: '/receitas', builder: (c, s) => const ReceitasScreen()),
        GoRoute(path: '/estoque', builder: (c, s) => const EstoqueScreen()),
        GoRoute(path: '/compras', builder: (c, s) => const ComprasScreen()),
      ],
    ),
  ],
),
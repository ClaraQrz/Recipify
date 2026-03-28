import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../features/receitas/screens/receitas_screen.dart';
import '../features/compras/screens/compras_screen.dart';
import '../features/estoque/screens/estoque_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/receitas',
  routes: [
    ShellRoute(
      builder: (context, state, child) => ScaffoldWithNav(child: child),
      routes: [
        GoRoute(path: '/receitas', builder: (c, s) => const ReceitasScreen()),
        GoRoute(path: '/compras',  builder: (c, s) => const ComprasScreen()),
        GoRoute(path: '/estoque',  builder: (c, s) => const EstoqueScreen()),
      ],
    ),
  ],
);

class ScaffoldWithNav extends StatelessWidget {
  final Widget child;
  const ScaffoldWithNav({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: ['/receitas', '/compras', '/estoque'].indexOf(location),
        onDestinationSelected: (i) {
          final routes = ['/receitas', '/compras', '/estoque'];
          context.go(routes[i]);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.restaurant_menu), label: 'Receitas'),
          NavigationDestination(icon: Icon(Icons.shopping_cart),   label: 'Compras'),
          NavigationDestination(icon: Icon(Icons.kitchen),         label: 'Estoque'),
        ],
      ),
    );
  }
}
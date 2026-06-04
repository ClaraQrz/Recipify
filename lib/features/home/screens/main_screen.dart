import 'package:flutter/material.dart';
import 'package:recipify/features/perfil/screens/profile_screen.dart';
import 'package:recipify/features/home/screens/home_screen.dart';
import 'package:recipify/features/receitas/screens/receitas_screen.dart';
import 'package:recipify/features/listas/screens/listas_screen.dart';
import 'package:recipify/features/estoque/screens/estoque_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    ReceitasScreen(),
    ListasScreen(),
    EstoqueScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Image.asset('assets/images/Logo.png', height: 36),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined),        label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book_outlined),   label: 'Receitas'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt_outlined),    label: 'Listas'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2_outlined), label: 'Estoque'),
        ],
      ),
    );
  }
}

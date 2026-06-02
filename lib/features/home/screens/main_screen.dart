import 'package:flutter/material.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    Center(child: Text('Home')),
    Center(child: Text('Receitas')),
    Center(child: Text('Listas')),
    Center(child: Text('Estoque')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipify'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {},
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined),      label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book_outlined),  label: 'Receitas'),
          BottomNavigationBarItem(icon: Icon(Icons.list_outlined),       label: 'Listas'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_outlined),  label: 'Estoque'),
        ],
      ),
    );
  }
}
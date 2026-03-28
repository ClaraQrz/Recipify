import 'package:flutter/material.dart';

class EstoqueScreen extends StatelessWidget {
  const EstoqueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Estoque')),
      body: const Center(child: Text('Alimentos em casa')),
    );
  }
}

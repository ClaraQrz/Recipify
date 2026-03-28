import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../receitas_notifier.dart';

class ReceitasScreen extends StatelessWidget {
  const ReceitasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ReceitasNotifier>();
    return Scaffold(
      appBar: AppBar(title: const Text('Receitas')),
      body: notifier.receitas.isEmpty
          ? const Center(child: Text('Nenhuma receita ainda.'))
          : ListView.builder(
              itemCount: notifier.receitas.length,
              itemBuilder: (ctx, i) => ListTile(
                title: Text(notifier.receitas[i].nome),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
  }
}
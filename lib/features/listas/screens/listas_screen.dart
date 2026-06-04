import 'package:flutter/material.dart';

class ListasScreen extends StatelessWidget {
  const ListasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),

      child: Column(
        children: [
          Expanded(
            child: ListView(
              children: const [
                ListaCard(
                  nome: 'Compras da Semana',
                  itens: 12,
                ),

                ListaCard(
                  nome: 'Churrasco',
                  itens: 8,
                ),

                ListaCard(
                  nome: 'Sobremesas',
                  itens: 5,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ListaCard extends StatelessWidget {
  final String nome;
  final int itens;

  const ListaCard({
    super.key,
    required this.nome,
    required this.itens,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading:
            const Icon(Icons.list_alt_outlined),
        title: Text(nome),
        subtitle: Text(
          '$itens itens',
        ),
      ),
    );
  }
}
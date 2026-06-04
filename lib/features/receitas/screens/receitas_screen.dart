import 'package:flutter/material.dart';

class ReceitasScreen extends StatelessWidget {
  const ReceitasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),

      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Pesquisar receita...',
              prefixIcon:
                  const Icon(Icons.search),
            ),
          ),

          const SizedBox(height: 20),

          Expanded(
            child: ListView(
              children: const [
                ReceitaCard(
                  titulo: 'Lasanha',
                  tempo: '45 min',
                ),

                ReceitaCard(
                  titulo: 'Bolo de Cenoura',
                  tempo: '60 min',
                ),

                ReceitaCard(
                  titulo: 'Macarronada',
                  tempo: '30 min',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ReceitaCard extends StatelessWidget {
  final String titulo;
  final String tempo;

  const ReceitaCard({
    super.key,
    required this.titulo,
    required this.tempo,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading:
            const Icon(Icons.menu_book_outlined),
        title: Text(titulo),
        subtitle: Text('Tempo: $tempo'),
      ),
    );
  }
}
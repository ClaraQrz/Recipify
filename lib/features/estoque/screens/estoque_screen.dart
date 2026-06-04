import 'package:flutter/material.dart';
import 'package:recipify/core/theme/app_theme.dart';

class EstoqueScreen extends StatelessWidget {
  const EstoqueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),

      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText:
                  'Pesquisar ingrediente...',
              prefixIcon:
                  const Icon(Icons.search),
            ),
          ),

          const SizedBox(height: 20),

          Expanded(
            child: ListView(
              children: const [
                EstoqueCard(
                  nome: 'Leite',
                  quantidade: '2 litros',
                  vencimento: '2 dias',
                  urgente: true,
                ),

                EstoqueCard(
                  nome: 'Ovos',
                  quantidade: '12 unidades',
                  vencimento: '5 dias',
                  urgente: true,
                ),

                EstoqueCard(
                  nome: 'Farinha',
                  quantidade: '1 kg',
                  vencimento: '30 dias',
                ),

                EstoqueCard(
                  nome: 'Arroz',
                  quantidade: '5 kg',
                  vencimento: '90 dias',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class EstoqueCard extends StatelessWidget {
  final String nome;
  final String quantidade;
  final String vencimento;
  final bool urgente;

  const EstoqueCard({
    super.key,
    required this.nome,
    required this.quantidade,
    required this.vencimento,
    this.urgente = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              urgente
                  ? AppTheme.warning
                  : AppTheme.secondary,

          child: Icon(
            urgente
                ? Icons.warning
                : Icons.inventory_2_outlined,
            color: Colors.white,
          ),
        ),

        title: Text(nome),

        subtitle: Text(
          '$quantidade • vence em $vencimento',
        ),
      ),
    );
  }
}
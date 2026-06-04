import 'package:flutter/material.dart';
import 'package:recipify/core/theme/app_theme.dart';
import 'package:recipify/services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _apelido = '';
  bool _carregando = true;

  // Dados mock enquanto o banco não tem conteúdo real
  final List<Map<String, dynamic>> _topSemanal = [];
  final List<Map<String, dynamic>> _listas = [];
  final List<Map<String, dynamic>> _estoque = [];

  @override
  void initState() {
    super.initState();
    _carregarApelido();
  }

  Future<void> _carregarApelido() async {
    // Usa AuthService SQLite — sem Supabase
    final usuario = AuthService.instance.usuarioLogado;
    setState(() {
      _apelido = usuario?['apelido'] ?? '';
      _carregando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) return const Center(child: CircularProgressIndicator());

    final nome = _apelido.isNotEmpty ? _apelido : 'Usuário';

    return SingleChildScrollView(
      padding: AppTheme.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Saudação
          Text(
            'Olá, $nome 👋',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'O que vamos cozinhar hoje?',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppTheme.textGray),
          ),

          const SizedBox(height: 24),

          // Top Semanal
          _sectionTitle('Top semanal'),
          const SizedBox(height: 10),
          _topSemanal.isEmpty
              ? _emptyState('Nenhuma receita em destaque ainda.')
              : SizedBox(
                  height: 130,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _topSemanal.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, i) {
                      final item = _topSemanal[i];
                      return _topCard(
                          item['posicao'], item['titulo'], item['autor']);
                    },
                  ),
                ),

          const SizedBox(height: 24),

          // Listas
          _sectionTitle('Listas'),
          const SizedBox(height: 10),
          _listas.isEmpty
              ? _emptyState('Nenhuma lista criada ainda.')
              : Column(
                  children: _listas.map((l) => _listaCard(l)).toList()),

          const SizedBox(height: 24),

          // Estoque
          _sectionTitle('Estoque'),
          const SizedBox(height: 10),
          _estoque.isEmpty
              ? _emptyState('Nenhum item no estoque ainda.')
              : Column(
                  children: _estoque.map((i) => _estoqueCard(i)).toList()),
        ],
      ),
    );
  }

  Widget _sectionTitle(String titulo) {
    return Text(
      titulo,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppTheme.primary,
      ),
    );
  }

  Widget _topCard(int posicao, String titulo, String autor) {
    return Container(
      width: 110,
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$posicao°',
              style: TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(titulo,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          Text('Por $autor',
              style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _listaCard(Map<String, dynamic> lista) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.list_alt, color: AppTheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(lista['nome'],
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 6),
            ...(lista['itens'] as List<String>).map((item) => Padding(
                  padding: const EdgeInsets.only(left: 8, top: 2),
                  child: Row(
                    children: [
                      const Icon(Icons.circle,
                          size: 6, color: AppTheme.primary),
                      const SizedBox(width: 6),
                      Text(item, style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _estoqueCard(Map<String, dynamic> item) {
    final vencendo = item['vencimento'] <= 3;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(Icons.inventory_2_outlined,
            color: vencendo ? Colors.red : AppTheme.primary),
        title: Text(item['nome']),
        subtitle: Text(item['quantidade']),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: vencendo ? Colors.red : Colors.green,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            vencendo
                ? 'Vence em ${item['vencimento']}d'
                : '${item['vencimento']}d',
            style: const TextStyle(color: Colors.white, fontSize: 11),
          ),
        ),
      ),
    );
  }

  Widget _emptyState(String mensagem) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(mensagem,
          style: const TextStyle(color: AppTheme.textGray, fontSize: 13)),
    );
  }
}

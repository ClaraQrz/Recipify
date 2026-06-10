import 'package:flutter/material.dart';
import 'package:recipify/core/theme/app_theme.dart';
import 'package:recipify/repositories/estoque_repository.dart';
import 'package:recipify/repositories/lista_repository.dart';
import 'package:recipify/repositories/receita_repository.dart';
import 'package:recipify/services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  bool _carregando = true;

  List<Map<String, dynamic>> _topSemanal = [];
  Map<String, dynamic>?      _listaFav;
  List<Map<String, dynamic>> _vencendo   = [];

  Future<void> recarregar() async {
    await _carregar();
  }

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    final usuario = AuthService.instance.usuarioLogado;
    if (usuario == null) {
      setState(() => _carregando = false);
      return;
    }

    final uid = usuario['id'] as String;

    try {
      final results = await Future.wait([
        ReceitaRepository.instance.topSemanal(),
        ListaRepository.instance.listaFavorita(uid),
        EstoqueRepository.instance.vencendoEmBreve(uid),
      ]);

      if (!mounted) return;
      setState(() {
        _topSemanal = results[0] as List<Map<String, dynamic>>;
        _listaFav   = results[1] as Map<String, dynamic>?;
        _vencendo   = results[2] as List<Map<String, dynamic>>;
        _carregando = false;
      });
    } catch (e) {
      debugPrint('ERRO HOME: $e');
      if (!mounted) return;
      setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const Center(child: CircularProgressIndicator());
    }

    final apelido = AuthService.instance.usuarioLogado?['apelido'] ?? 'Usuário';

    return RefreshIndicator(
      onRefresh: _carregar,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppTheme.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Olá, $apelido 👋',
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

            const SizedBox(height: 28),

            // ── TOP SEMANAL ──────────────────────────────────────────────
            _secaoTitulo('🏆 Top Semanal'),
            const SizedBox(height: 10),
            _topSemanal.isEmpty
                ? _estadoVazio('Nenhuma receita em destaque essa semana.')
                : SizedBox(
                    height: 140,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _topSemanal.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, i) {
                        final item    = _topSemanal[i];
                        final receita = item['receita'] as Map<String, dynamic>;
                        final autor   = receita['usuario'] as Map<String, dynamic>;
                        return _topCard(
                          posicao: item['posicao'] as int,
                          titulo:  receita['titulo'] as String,
                          autor:   autor['apelido'] as String,
                          media:   (receita['media_estrelas'] as num).toDouble(),
                        );
                      },
                    ),
                  ),

            const SizedBox(height: 28),

            // ── LISTA FAVORITA ───────────────────────────────────────────
            _secaoTitulo('📋 Lista favorita'),
            const SizedBox(height: 10),
            _listaFav == null
                ? _estadoVazio('Nenhuma lista marcada como favorita.')
                : _listaCard(_listaFav!),

            const SizedBox(height: 28),

            // ── VENCIMENTO ───────────────────────────────────────────────
            _secaoTitulo('⚠️ Vencendo em breve'),
            const SizedBox(height: 10),
            _vencendo.isEmpty
                ? _estadoVazio('Nenhum item vencendo nos próximos 7 dias.')
                : Column(
                    children: _vencendo.map(_estoqueCard).toList(),
                  ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _secaoTitulo(String texto) => Text(
        texto,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.bold,
          color: AppTheme.primary,
        ),
      );

  Widget _estadoVazio(String mensagem) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(mensagem,
            style: const TextStyle(color: AppTheme.textGray, fontSize: 13)),
      );

  Widget _topCard({
    required int    posicao,
    required String titulo,
    required String autor,
    required double media,
  }) {
    return Container(
      width: 120,
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
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
          const Spacer(),
          Text(titulo,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.star, color: Colors.amber, size: 13),
            const SizedBox(width: 3),
            Text(media.toStringAsFixed(1),
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ]),
          Text('por $autor',
              style: const TextStyle(color: Colors.white60, fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _listaCard(Map<String, dynamic> lista) {
    final itens     = lista['itens'] as List<Map<String, dynamic>>;
    final pendentes = itens.where((i) => i['comprado'] == 0).toList();
    final comprados = itens.where((i) => i['comprado'] == 1).length;
    final total     = itens.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.list_alt, color: AppTheme.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(lista['nome'] as String,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
              ),
              Text('$comprados/$total',
                  style: const TextStyle(
                      color: AppTheme.textGray, fontSize: 12)),
            ]),
            if (pendentes.isNotEmpty) ...[
              const SizedBox(height: 10),
              ...pendentes.take(4).map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(children: [
                      const Icon(Icons.circle,
                          size: 6, color: AppTheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        '${item['nome']} (${item['quantidade']})',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ]),
                  )),
              if (pendentes.length > 4)
                Text('+ ${pendentes.length - 4} itens',
                    style: const TextStyle(
                        color: AppTheme.textGray, fontSize: 12)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _estoqueCard(Map<String, dynamic> item) {
    final dias    = item['dias_restantes'] as int;
    final urgente = dias <= 2;
    final cor     = urgente ? Colors.red : Colors.orange;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(Icons.inventory_2_outlined, color: cor),
        title: Text(item['ingrediente'] as String),
        subtitle: Text('${_fmt(item['quantidade'])} ${item['unidade']}',
            style: const TextStyle(fontSize: 12)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
              color: cor, borderRadius: BorderRadius.circular(8)),
          child: Text(
            dias == 0 ? 'Vence hoje' : dias == 1 ? 'Amanhã' : 'Em ${dias}d',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  String _fmt(dynamic valor) {
    if (valor is num) {
      final n = valor.toDouble();

      return n == n.truncateToDouble()
          ? n.toInt().toString()
          : n.toString();
    }

    return valor.toString();
  }
}

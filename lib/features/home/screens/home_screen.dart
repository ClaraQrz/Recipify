import 'package:flutter/material.dart';
import 'package:recipify/core/theme/app_theme.dart';
import 'package:recipify/features/listas/screens/detalhe_lista_screen.dart';
import 'package:recipify/features/home/screens/main_screen.dart';
import 'package:recipify/repositories/estoque_repository.dart';
import 'package:recipify/repositories/lista_repository.dart';
import 'package:recipify/repositories/receita_repository.dart';
import 'package:recipify/services/auth_service.dart';
import 'package:recipify/features/receitas/screens/receita_detalhe_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _carregando = true;

  List<Map<String, dynamic>> _topSemanal = [];
  Map<String, dynamic>?      _listaFav;
  List<Map<String, dynamic>> _vencendo   = [];

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

  void _abrirListaFavorita() {
    if (_listaFav == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetalheListaScreen(
          listaId:   _listaFav!['id'] as String,
          listaNome: _listaFav!['nome'] as String,
        ),
      ),
    ).then((_) => _carregar());
  }

  void _irParaListas() => MainScreen.of(context)?.irParaAba(2);

  @override
  Widget build(BuildContext context) {
    if (_carregando) return const Center(child: CircularProgressIndicator());

    final apelido = AuthService.instance.usuarioLogado?['apelido'] ?? 'Usuário';

    return RefreshIndicator(
      onRefresh: _carregar,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppTheme.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Olá, $apelido 👋',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('O que vamos cozinhar hoje?',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppTheme.textGray)),

            const SizedBox(height: 28),

            // ── TOP SEMANAL ──────────────────────────────────────────────
            _secaoTitulo('🏆 Top Semanal'),
            const SizedBox(height: 10),
            _topSemanal.isEmpty
                ? _estadoVazio('Nenhuma receita em destaque essa semana.')
                : SizedBox(
                    height: 180,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _topSemanal.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, i) {
                        final item    = _topSemanal[i];
                        final receita = item['receita'] as Map<String, dynamic>? ?? {};
                        final usuarioMap = receita['usuario'];
                        final autor = usuarioMap is Map
                            ? (usuarioMap['apelido'] as String? ?? 'Desconhecido')
                            : 'Desconhecido';

                        return GestureDetector(
                          onTap: () async {
                            final receitaId = receita['id'] as String;
                            final completa = await ReceitaRepository.instance.buscarPorId(receitaId);
                            if (completa == null || !context.mounted) return;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ReceitaDetalheScreen(
                                  receita:    completa,
                                  favoritada: false,
                                ),
                              ),
                            );
                          },
                          child: _topCard(
                            posicao: item['posicao'] as int,
                            titulo:  receita['titulo'] as String? ?? '',
                            autor:   autor,
                            media:   (item['pontuacao'] as num? ?? 0).toDouble(),
                            imgUrl:  receita['imagem_url'] as String?,
                          ),
                        );
                      },
                    ),
                  ),
            // ── LISTA FAVORITA ───────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _secaoTitulo('📋 Lista favorita'),
                GestureDetector(
                  onTap: _irParaListas,
                  child: const Text('Ver todas',
                      style: TextStyle(
                          color: AppTheme.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _listaFav == null
                ? _estadoVazio('Nenhuma lista marcada como favorita.')
                : GestureDetector(
                    onTap: _abrirListaFavorita,
                    child: _listaCard(_listaFav!),
                  ),

            const SizedBox(height: 28),

            // ── VENCIMENTO ───────────────────────────────────────────────
            _secaoTitulo('⚠️ Vencendo em breve'),
            const SizedBox(height: 10),
            _vencendo.isEmpty
                ? _estadoVazio('Nenhum item vencendo nos próximos 7 dias.')
                : Column(children: _vencendo.map(_estoqueCard).toList()),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _secaoTitulo(String texto) => Text(texto,
      style: const TextStyle(
          fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.primary));

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
    String? imgUrl,
  }) {
    final medalhas = ['🥇', '🥈', '🥉'];
    final medalha  = posicao <= 3 ? medalhas[posicao - 1] : '$posicao°';

    return Container(
      width: 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppTheme.cardBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Imagem ou cor sólida de fundo
          Positioned.fill(
            child: imgUrl != null && imgUrl.isNotEmpty
                ? Image.network(imgUrl, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(color: AppTheme.primary))
                : Container(color: AppTheme.primary),
          ),

          // Gradiente escuro na parte inferior
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.75),
                  ],
                  stops: const [0.3, 1.0],
                ),
              ),
            ),
          ),

          // Medalha top esquerdo
          Positioned(
            top: 8, left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(medalha, style: const TextStyle(fontSize: 13)),
            ),
          ),

          // Estrela top direito
          Positioned(
            top: 10, right: 8,
            child: Row(children: [
              const Icon(Icons.star, color: Colors.amber, size: 13),
              const SizedBox(width: 2),
              Text(media.toStringAsFixed(1),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            ]),
          ),

          // Título e autor na parte inferior
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text('por $autor',
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ),
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
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right,
                  color: AppTheme.textGray, size: 18),
            ]),
            if (pendentes.isNotEmpty) ...[
              const SizedBox(height: 10),
              ...pendentes.take(4).map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(children: [
                      const Icon(Icons.circle,
                          size: 6, color: AppTheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${item['quantidade']} de ${item['nome']}',
                          style: const TextStyle(fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ]),
                  )),
              if (pendentes.length > 4)
                Text('+ ${pendentes.length - 4} itens',
                    style: const TextStyle(
                        color: AppTheme.textGray, fontSize: 12)),
            ],
            if (total == 0)
              const Text('Lista vazia.',
                  style: TextStyle(color: AppTheme.textGray, fontSize: 13)),
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
    final n = (valor as num).toDouble();
    return n == n.truncateToDouble() ? n.toInt().toString() : n.toString();
  }
}
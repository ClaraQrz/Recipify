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
  Map<String, Map<String, dynamic>> _sugestoes = {};

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
      final vencendo = results[2] as List<Map<String, dynamic>>;

      final sugestoes = <String, Map<String, dynamic>>{};
      final todasReceitas = await ReceitaRepository.instance.listarReceitas();
      for (final item in vencendo) {
        final nomeIngrediente = (item['ingrediente'] as String).toLowerCase();
        for (final receita in todasReceitas) {
          final titulo = (receita['titulo'] as String? ?? '').toLowerCase();
          final descricao = (receita['descricao'] as String? ?? '').toLowerCase();
          if (titulo.contains(nomeIngrediente) || descricao.contains(nomeIngrediente)) {
            sugestoes[item['id'] as String] = receita;
            break;
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _topSemanal = results[0] as List<Map<String, dynamic>>;
        _listaFav   = results[1] as Map<String, dynamic>?;
        _vencendo   = vencendo;
        _sugestoes  = sugestoes;
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

  void _irParaEstoque() => MainScreen.of(context)?.irParaAba(3);

  @override
  Widget build(BuildContext context) {
    if (_carregando) return const Center(child: CircularProgressIndicator());

    return RefreshIndicator(
      onRefresh: _carregar,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _secaoTitulo('Top semanal'),
            const SizedBox(height: 12),
            _topSemanal.isEmpty
                ? _vazio('Nenhuma receita em destaque essa semana.')
                : _topSemanalWidget(),

            const SizedBox(height: 28),

            _secaoTitulo('Listas'),
            const SizedBox(height: 12),
            _listaFav == null
                ? _vazio('Nenhuma lista marcada como favorita.')
                : GestureDetector(
                    onTap: _abrirListaFavorita,
                    child: _listaCard(_listaFav!),
                  ),

            const SizedBox(height: 28),

            _secaoTitulo('Estoque'),
            const SizedBox(height: 12),
            _vencendo.isEmpty
                ? _vazio('Nenhum item vencendo nos próximos 7 dias.')
                : Column(
                    children: _vencendo.map((item) {
                      final sugestao = _sugestoes[item['id'] as String];
                      return _estoqueCard(item, sugestao);
                    }).toList(),
                  ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _secaoTitulo(String texto) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 22,
          decoration: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          texto,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _vazio(String msg) => Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 4),
        child: Text(msg,
            style: const TextStyle(color: AppTheme.textGray, fontSize: 13)),
      );

  // ── TOP SEMANAL ───────────────────────────────────────────────────

  Widget _topSemanalWidget() {
    final sorted = [..._topSemanal]
      ..sort((a, b) => (a['posicao'] as int).compareTo(b['posicao'] as int));

    final reordenado = <Map<String, dynamic>>[];
    if (sorted.length >= 2) reordenado.add(sorted[1]); // 2°
    if (sorted.isNotEmpty) reordenado.add(sorted[0]);  // 1° (centro)
    if (sorted.length >= 3) reordenado.add(sorted[2]); // 3°

    return SizedBox(
      height: 240,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: reordenado.asMap().entries.map((e) {
          final idx      = e.key;
          final item     = e.value;
          final receita  = item['receita'] as Map<String, dynamic>? ?? {};
          final posicao  = item['posicao'] as int;
          final isCentro = posicao == 1;
          final medalhas = ['🥇', '🥈', '🥉'];
          final medalha  = posicao <= 3 ? medalhas[posicao - 1] : '$posicao°';

          final titulo = receita['titulo'] as String? ?? '';
          final usuarioMap = receita['usuario'];
          final autor = usuarioMap is Map
              ? (usuarioMap['apelido'] as String? ?? '')
              : '';
          final media = (receita['media_estrelas'] as num?)?.toDouble() ?? 0;

          return Expanded(
            child: GestureDetector(
              onTap: () async {
                final id = receita['id'] as String?;
                if (id == null) return;
                final completa = await ReceitaRepository.instance.buscarPorId(id);
                if (completa == null || !context.mounted) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReceitaDetalheScreen(
                      receita: completa,
                      favoritada: false,
                    ),
                  ),
                );
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: EdgeInsets.only(
                  left:  idx == 0 ? 0 : 4,
                  right: idx == reordenado.length - 1 ? 0 : 4,
                  bottom: isCentro ? 0 : 24,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // imagem
                    receita['imagem_url'] != null &&
                            (receita['imagem_url'] as String).isNotEmpty
                        ? Image.network(receita['imagem_url'] as String,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                Container(color: AppTheme.secondary))
                        : Container(color: AppTheme.secondary),
                    // gradiente
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black87],
                          stops: [0.35, 1.0],
                        ),
                      ),
                    ),
                    // info na base
                    Positioned(
                      bottom: 8,
                      left: 6,
                      right: 6,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(medalha,
                              style: TextStyle(fontSize: isCentro ? 22 : 18)),
                          const SizedBox(height: 2),
                          Text(
                            titulo,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isCentro ? 12 : 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (autor.isNotEmpty)
                            Text(
                              autor,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: isCentro ? 10 : 9,
                              ),
                            ),
                          if (media > 0) ...[
                            const SizedBox(height: 2),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.star,
                                    size: 11, color: Colors.amber),
                                const SizedBox(width: 2),
                                Text(
                                  media.toStringAsFixed(1),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: isCentro ? 10 : 9,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── LISTA FAVORITA ────────────────────────────────────────────────

  Widget _listaCard(Map<String, dynamic> lista) {
    final itensRaw  = lista['itens'] as List;
    final itens     = itensRaw.cast<Map<String, dynamic>>();
    final pendentes = itens.where((i) => i['comprado'] == 0).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text(
                lista['nome'] as String,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppTheme.textDark,
                ),
              ),
            ),
            const Icon(Icons.push_pin, size: 18, color: AppTheme.primary),
          ]),
          if (pendentes.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...pendentes.take(4).map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Row(children: [
                    Container(
                      width: 7, height: 7,
                      decoration: const BoxDecoration(
                        color: AppTheme.textDark,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      item['nome'] as String? ?? '',
                      style: const TextStyle(fontSize: 13, color: AppTheme.textDark),
                    ),
                  ]),
                )),
            if (pendentes.length > 4)
              Text('+ ${pendentes.length - 4} itens',
                  style: const TextStyle(
                      color: AppTheme.textGray, fontSize: 12)),
          ],
          if (itens.isEmpty)
            const Text('Lista vazia.',
                style: TextStyle(color: AppTheme.textGray, fontSize: 13)),
        ],
      ),
    );
  }

  // ── ESTOQUE CARD ──────────────────────────────────────────────────

  Widget _estoqueCard(Map<String, dynamic> item, Map<String, dynamic>? sugestao) {
    final dias    = item['dias_restantes'] as int;
    final urgente = dias <= 2;
    final corTag  = urgente ? AppTheme.warning : Colors.orange;
    final labelDias = dias == 0
        ? 'Vence hoje'
        : dias == 1
            ? 'Vence amanhã'
            : 'Vence em ${dias}d';

    return GestureDetector(
      onTap: _irParaEstoque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(
                      item['ingrediente'] as String,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const Text('  •  ',
                        style: TextStyle(color: AppTheme.textGray)),
                    Text(
                      labelDias,
                      style: TextStyle(
                        color: corTag,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ]),
                  if (sugestao != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Sugestão: ${sugestao['titulo']}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textGray,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.kitchen_outlined,
              color: corTag,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(dynamic valor) {
    final n = (valor as num).toDouble();
    return n == n.truncateToDouble() ? n.toInt().toString() : n.toString();
  }
}
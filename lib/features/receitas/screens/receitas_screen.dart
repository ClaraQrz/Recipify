import 'package:flutter/material.dart';
import 'package:recipify/core/theme/app_theme.dart';
import 'package:recipify/repositories/receita_repository.dart';
import 'package:recipify/features/receitas/screens/postar_receita_screen.dart';
import 'package:recipify/features/receitas/screens/minhas_receitas_screen.dart';
import 'package:recipify/features/receitas/screens/receita_detalhe_screen.dart';

class ReceitasScreen extends StatefulWidget {
  const ReceitasScreen({super.key});

  @override
  State<ReceitasScreen> createState() => _ReceitasScreenState();
}

class _ReceitasScreenState extends State<ReceitasScreen> {
  final _searchCtrl = TextEditingController();

  bool _carregando       = true;
  bool _mostrando        = false;
  String _categoriaAtiva = 'Todas';

  List<Map<String, dynamic>> _todasReceitas = [];
  List<Map<String, dynamic>> _receitas      = [];
  Set<String> _favoritas                    = {};

  final List<String> _categorias = [
  'Todas', 'Salgadas', 'Doces', 'Sobremesas', 'Veganas', 'Vegetarianas', 'Rápidas', 'Elaboradas', 'Outras'
];

  @override
  void initState() {
    super.initState();
    _carregar();
    _searchCtrl.addListener(_filtrar);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    try {
      final results = await Future.wait([
        ReceitaRepository.instance.listarReceitas(),
        ReceitaRepository.instance.idsFavoritas(),
      ]);

      if (!mounted) return;
      setState(() {
        _todasReceitas = results[0] as List<Map<String, dynamic>>;
        _favoritas     = results[1] as Set<String>;
        _receitas      = _todasReceitas;
        _carregando    = false;
      });
    } catch (e) {
      debugPrint('ERRO RECEITAS: $e');
      if (!mounted) return;
      setState(() => _carregando = false);
    }
  }

  void _filtrar() {
    final busca = _searchCtrl.text.toLowerCase();
    List<Map<String, dynamic>> base = _mostrando
        ? _todasReceitas.where((r) => _favoritas.contains(r['id'])).toList()
        : _todasReceitas;

    if (_categoriaAtiva != 'Todas') {
      base = base.where((r) => r['categoria'] == _categoriaAtiva).toList();
    }

    if (busca.isNotEmpty) {
      base = base.where((r) {
        final titulo = (r['titulo'] as String).toLowerCase();
        final autor = ((r['usuario'] as Map?)?['apelido'] as String? ?? '').toLowerCase();
        return titulo.contains(busca) || autor.contains(busca);
      }).toList();
    }

    setState(() => _receitas = base);
  }

  void _toggleFavoritas() {
    setState(() => _mostrando = !_mostrando);
    _filtrar();
  }

  void _selecionarCategoria(String categoria) {
    setState(() => _categoriaAtiva = categoria);
    _filtrar();
  }

  Future<void> _toggleFavorito(String receitaId) async {
    final favoritado = _favoritas.contains(receitaId);
    setState(() {
      if (favoritado) {
        _favoritas.remove(receitaId);
      } else {
        _favoritas.add(receitaId);
      }
    });
    await ReceitaRepository.instance.toggleFavorito(receitaId, favoritado);
  }

  void _abrirDetalhe(Map<String, dynamic> receita) {
    final id = receita['id'] as String;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReceitaDetalheScreen(
          receita:    receita,
          favoritada: _favoritas.contains(id),
        ),
      ),
    );
  }

  void _abrirPostarReceita() async {
    final criou = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const PostarReceitaScreen()),
    );
    if (criou == true) _carregar();
  }

  void _abrirMinhasReceitas() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MinhasReceitasScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Search + estrela
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Buscar receita...',
                      prefixIcon: Icon(Icons.search, size: 20),
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _toggleFavoritas,
                  child: Icon(
                    _mostrando ? Icons.star : Icons.star_border,
                    color: AppTheme.primary,
                    size: 28,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categorias.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final cat   = _categorias[i];
                final ativo = cat == _categoriaAtiva;
                return GestureDetector(
                  onTap: () => _selecionarCategoria(cat),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: ativo ? AppTheme.primary : AppTheme.cardBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      cat,
                      style: TextStyle(
                        color: ativo ? Colors.white : AppTheme.textDark,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          Expanded(
            child: _carregando
                ? const Center(child: CircularProgressIndicator())
                : _receitas.isEmpty
                    ? Center(
                        child: Text(
                          _mostrando
                              ? 'Nenhuma receita favoritada.'
                              : 'Nenhuma receita encontrada.',
                          style: const TextStyle(color: AppTheme.textGray),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _carregar,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                          itemCount: _receitas.length,
                          itemBuilder: (context, i) =>
                              _receitaCard(_receitas[i]),
                        ),
                      ),
          ),
        ],
      ),

      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'minhas',
            backgroundColor: AppTheme.cardBg,
            foregroundColor: AppTheme.primary,
            onPressed: _abrirMinhasReceitas,
            child: const Icon(Icons.menu_book),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'postar',
            onPressed: _abrirPostarReceita,
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  Widget _receitaCard(Map<String, dynamic> receita) {
    debugPrint('KEYS DA RECEITA: ${receita.keys.toList()}');
    debugPrint('USUARIO MAP: ${receita['usuario']}');
    final id         = receita['id'] as String;
    final titulo     = receita['titulo'] as String;
    final usuarioMap = receita['usuario'];
    final autor = usuarioMap is Map ? (usuarioMap['apelido'] as String? ?? 'Desconhecido') : 'Desconhecido';
    final tempo      = receita['tempo_minutos'] as int?;
    final categoria  = receita['categoria'] as String?;
    final imgUrl     = receita['imagem_url'] as String?;
    final media      = (receita['media_estrelas'] as num?)?.toDouble() ?? 0;
    final favoritado = _favoritas.contains(id);

    return GestureDetector(
      onTap: () => _abrirDetalhe(receita),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imgUrl != null && imgUrl.isNotEmpty)
              Image.network(
                imgUrl,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _imagemPlaceholder(),
              )
            else
              _imagemPlaceholder(),

            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          titulo,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _toggleFavorito(id),
                        child: Icon(
                          favoritado ? Icons.favorite : Icons.favorite_border,
                          color: AppTheme.primary,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (tempo != null) ...[
                        const Icon(Icons.timer_outlined,
                            size: 14, color: AppTheme.textGray),
                        const SizedBox(width: 3),
                        Text(_formatarTempo(tempo),
                            style: const TextStyle(
                                fontSize: 12, color: AppTheme.textGray)),
                        const SizedBox(width: 10),
                      ],
                      if (categoria != null) ...[
                        const Icon(Icons.label_outline,
                            size: 14, color: AppTheme.textGray),
                        const SizedBox(width: 3),
                        Text(categoria,
                            style: const TextStyle(
                                fontSize: 12, color: AppTheme.textGray)),
                        const SizedBox(width: 10),
                      ],
                      if (media > 0) ...[
                        const Icon(Icons.star, size: 14, color: Colors.amber),
                        const SizedBox(width: 3),
                        Text(media.toStringAsFixed(1),
                            style: const TextStyle(
                                fontSize: 12, color: AppTheme.textGray)),
                      ],
                      const Spacer(),
                      Text(
                        'Por: $autor',
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textGray),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagemPlaceholder() => Container(
        height: 160,
        width: double.infinity,
        color: AppTheme.surface,
        child: const Icon(Icons.restaurant, size: 48, color: AppTheme.textGray),
      );

  String _formatarTempo(int minutos) {
    if (minutos < 60) return '${minutos}min';
    final h = minutos ~/ 60;
    final m = minutos % 60;
    return m == 0 ? '${h}h' : '${h}h${m}min';
  }
}
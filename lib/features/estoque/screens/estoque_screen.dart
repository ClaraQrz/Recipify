import 'package:flutter/material.dart';
import 'package:recipify/core/theme/app_theme.dart';
import 'package:recipify/repositories/estoque_repository.dart';
import 'package:recipify/features/estoque/screens/estoque_form_screen.dart';
import 'package:recipify/services/auth_service.dart';

class EstoqueScreen extends StatefulWidget {
  const EstoqueScreen({super.key});

  @override
  State<EstoqueScreen> createState() => _EstoqueScreenState();
}

class _EstoqueScreenState extends State<EstoqueScreen> {
  List<Map<String, dynamic>> _itens = [];
  bool _carregando = true;
  final _buscaController = TextEditingController();
  String _query = '';

  String get _usuarioId =>
      AuthService.instance.usuarioLogado?['id'] as String? ?? '';

  @override
  void initState() {
    super.initState();
    _carregar();
    _buscaController.addListener(() {
      setState(() => _query = _buscaController.text.trim());
      _carregar();
    });
  }

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    if (_usuarioId.isEmpty) return;
    debugPrint('USUARIO ID: $_usuarioId');
    setState(() => _carregando = true);
    final resultado = _query.isEmpty
        ? await EstoqueRepository.instance.listarTodos(_usuarioId)
        : await EstoqueRepository.instance.buscarPorNome(_usuarioId, _query);
    if (!mounted) return;
    setState(() {
      _itens = resultado;
      _carregando = false;
    });
    debugPrint('ITENS CARREGADOS: $_itens');
  }

  Future<void> _deletar(String id, String nome) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remover item'),
        content: Text('Remover "$nome" do estoque?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Remover', style: TextStyle(color: AppTheme.primary)),
          ),
        ],
      ),
    );
    if (confirmar != true) return;
    await EstoqueRepository.instance.deletar(id);
    _carregar();
  }

  Color _corVencimento(int? dias) {
    if (dias == null) return Colors.transparent;
    if (dias <= 2) return AppTheme.warning;
    if (dias <= 7) return Colors.orange;
    return Colors.transparent;
  }

  String _labelVencimento(int? dias) {
    if (dias == null) return '';
    if (dias < 0) return 'Vencido';
    if (dias == 0) return 'Vence hoje';
    if (dias == 1) return 'Vence amanhã';
    return '$dias dias';
  }

  String _fmtQtd(dynamic valor) {
    final n = (valor as num).toDouble();
    return n == n.truncateToDouble() ? n.toInt().toString() : n.toString();
  }

  bool _venceEmBreve(Map<String, dynamic> item) {
    final dias = item['dias_restantes'] as int?;
    return dias != null && dias <= 7;
  }

  @override
  Widget build(BuildContext context) {
    final vencendo = _itens.where(_venceEmBreve).toList();
    final abastecido = _itens.where((i) => !_venceEmBreve(i)).toList();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Column(
          children: [
            // ── Search bar (sem alteração) ──────────────────────────
            TextField(
              controller: _buscaController,
              decoration: InputDecoration(
                hintText: 'Pesquisar ingrediente...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _buscaController.clear();
                          _carregar();
                        },
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 12),

            // ── Conteúdo ────────────────────────────────────────────
            Expanded(
              child: _carregando
                  ? const Center(child: CircularProgressIndicator())
                  : _itens.isEmpty
                      ? _vazio()
                      : RefreshIndicator(
                          onRefresh: _carregar,
                          child: CustomScrollView(
                            slivers: [
                              if (vencendo.isNotEmpty) ...[
                                _secaoHeader('Vencimento próximo'),
                                _gridSliver(vencendo),
                              ],
                              if (abastecido.isNotEmpty) ...[
                                _secaoHeader('Bem abastecido'),
                                _gridSliver(abastecido),
                              ],
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EstoqueFormScreen()),
          );
          _carregar();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  // ── Título de seção ──────────────────────────────────────────────
  SliverToBoxAdapter _secaoHeader(String titulo) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 8),
        child: Text(
          titulo,
          style: TextStyle(
            color: AppTheme.primary,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  // ── Grid 2 colunas ───────────────────────────────────────────────
  SliverGrid _gridSliver(List<Map<String, dynamic>> itens) {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.1,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, i) => _card(itens[i]),
        childCount: itens.length,
      ),
    );
  }

  // ── Card individual ──────────────────────────────────────────────
  Widget _card(Map<String, dynamic> item) {
    final dias = item['dias_restantes'] as int?;
    final corBadge = _corVencimento(dias);
    final labelBadge = _labelVencimento(dias);
    final temBadge = corBadge != Colors.transparent;

    return GestureDetector(
      onLongPress: () => _deletar(item['id'] as String, item['ingrediente'] as String),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EstoqueFormScreen(item: item),
              ),
            );
            _carregar();
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Badge de vencimento (topo direito)
                Align(
                  alignment: Alignment.centerRight,
                  child: temBadge
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: corBadge,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            labelBadge,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      : const SizedBox(height: 18),
                ),
                // Ícone centralizado
                Expanded(
                  child: Center(
                    child: Icon(
                      temBadge
                          ? Icons.warning_amber_rounded
                          : Icons.inventory_2_outlined,
                      size: 48,
                    ),
                  ),
                ),
                // Nome
                Text(
                  item['ingrediente'] as String,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                // Quantidade + unidade
                Text(
                  '${_fmtQtd(item['quantidade'])} ${item['unidade']}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _vazio() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inventory_2_outlined,
              size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            _query.isNotEmpty
                ? 'Nenhum ingrediente encontrado'
                : 'Seu estoque está vazio',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
          ),
          if (_query.isEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Toque no + para adicionar',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:recipify/core/theme/app_theme.dart';
import 'package:recipify/features/listas/screens/detalhe_lista_screen.dart';
import 'package:recipify/repositories/lista_repository.dart';
import 'package:recipify/services/auth_service.dart';

class ListasScreen extends StatefulWidget {
  const ListasScreen({super.key});

  @override
  State<ListasScreen> createState() => _ListasScreenState();
}

class _ListasScreenState extends State<ListasScreen> {
  final _buscaCtrl = TextEditingController();
  List<Map<String, dynamic>> _listas = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarListas();
  }

  Future<void> _carregarListas() async {
    try {
      final usuarioId = AuthService.instance.usuarioLogado?['id']?.toString();
      if (usuarioId == null) {
        setState(() => _carregando = false);
        return;
      }
      final listas = await ListaRepository.instance.todasAsListas(usuarioId);
      setState(() {
        _listas = listas;
        _carregando = false;
      });
    } catch (e, stack) {
      debugPrint('>>> ERRO: $e');
      debugPrint('>>> STACK: $stack');
      setState(() => _carregando = false);
    }
  }

  void _abrirModalCriarLista() {
    final nomeCtrl = TextEditingController();
    final outerContext = context;

    showModalBottomSheet(
      context: outerContext,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Nova lista',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nomeCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Nome da lista',
                  prefixIcon: Icon(Icons.list_alt_outlined),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final nome = nomeCtrl.text.trim();
                  if (nome.isEmpty) return;

                  final usuarioId =
                      AuthService.instance.usuarioLogado?['id']?.toString();
                  if (usuarioId == null) return;

                  try {
                    final listaId = await ListaRepository.instance.criarLista(
                      usuarioId: usuarioId,
                      nome: nome,
                    );

                    Navigator.pop(outerContext);

                    await Navigator.push(
                      outerContext,
                      MaterialPageRoute(
                        builder: (_) => DetalheListaScreen(
                          listaId: listaId,
                          listaNome: nome,
                        ),
                      ),
                    );

                    _carregarListas();
                  } catch (e) {
                    debugPrint('>>> ERRO ao criar lista: $e');
                  }
                },
                child: const Text('Criar lista'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cardBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _buscaCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Buscar nas listas...',
                    prefixIcon: Icon(Icons.search, color: AppTheme.textGray),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _carregando
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primary,
                        ),
                      )
                    : _listas.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.list_alt_outlined,
                                    size: 64,
                                    color:
                                        AppTheme.textGray.withOpacity(0.4)),
                                const SizedBox(height: 12),
                                Text(
                                  'Nenhuma lista ainda.',
                                  style: TextStyle(
                                    color:
                                        AppTheme.textGray.withOpacity(0.6),
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            itemCount: _listas.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              final lista = _listas[index];
                              final itens = (lista['itens'] as List)
                                  .map((i) => {
                                        'id': i['id'] as String,
                                        'nome': i['nome'] as String,
                                        'qtd': i['quantidade'] as String,
                                        'comprado': i['comprado'] == 1,
                                      })
                                  .toList();
                              return GestureDetector(
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => DetalheListaScreen(
                                        listaId: lista['id'] as String,
                                        listaNome: lista['nome'] as String,
                                      ),
                                    ),
                                  );
                                  _carregarListas();
                                },
                                child: _ListaCard(
                                  nome: lista['nome'] as String,
                                  itens: itens,
                                  onToggleItem: (itemId, comprado) =>
                                      ListaRepository.instance
                                          .toggleItem(itemId, comprado),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _abrirModalCriarLista,
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: AppTheme.textLight),
      ),
    );
  }
}

class _ListaCard extends StatefulWidget {
  final String nome;
  final List<Map<String, dynamic>> itens;
  final Future<void> Function(String itemId, bool comprado) onToggleItem;

  const _ListaCard({
    required this.nome,
    required this.itens,
    required this.onToggleItem,
  });

  @override
  State<_ListaCard> createState() => _ListaCardState();
}

class _ListaCardState extends State<_ListaCard> {
  late List<bool> _marcados;

  @override
  void initState() {
    super.initState();
    _marcados = widget.itens.map((i) => i['comprado'] as bool).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 8),
            child: Row(
              children: [
                const Icon(Icons.shopping_cart_outlined,
                    color: AppTheme.textDark, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.nome,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${widget.itens.length} itens',
                    style: const TextStyle(
                      color: AppTheme.textLight,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Checkbox(
                  value:
                      _marcados.isNotEmpty && _marcados.every((m) => m),
                  onChanged: (v) {
                    setState(() => _marcados =
                        List.filled(widget.itens.length, v!));
                    for (final item in widget.itens) {
                      widget.onToggleItem(item['id'] as String, v!);
                    }
                  },
                  activeColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4)),
                  side: const BorderSide(color: AppTheme.textGray),
                ),
              ],
            ),
          ),
          ...List.generate(widget.itens.length, (i) {
            final item = widget.itens[i];
            final isLast = i == widget.itens.length - 1;
            return Column(
              children: [
                const Divider(height: 1, color: Color(0xFFE0C9A6)),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item['nome'] as String,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textDark,
                            decoration: _marcados[i]
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ),
                      Text(
                        item['qtd'] as String,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Checkbox(
                        value: _marcados[i],
                        onChanged: (v) {
                          setState(() => _marcados[i] = v!);
                          widget.onToggleItem(item['id'] as String, v!);
                        },
                        activeColor: AppTheme.primary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4)),
                        side: const BorderSide(color: AppTheme.textGray),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ),
                if (isLast) ...[
                  const Divider(height: 1, color: Color(0xFFE0C9A6)),
                  _linhaVazia(),
                  const Divider(height: 1, color: Color(0xFFE0C9A6)),
                  _linhaVazia(),
                  const SizedBox(height: 4),
                ],
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _linhaVazia() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.textGray),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}
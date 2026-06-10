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
    return 'Vence em $dias dias';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Column(
          children: [
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
            Expanded(
              child: _carregando
                  ? const Center(child: CircularProgressIndicator())
                  : _itens.isEmpty
                      ? _vazio()
                      : RefreshIndicator(
                          onRefresh: _carregar,
                          child: ListView.separated(
                            itemCount: _itens.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 4),
                            itemBuilder: (context, i) {
                              final item = _itens[i];
                              final dias =
                                  item['dias_restantes'] as int?;
                              final cor = _corVencimento(dias);
                              final label = _labelVencimento(dias);

                              return Dismissible(
                                key: Key(item['id'] as String),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.delete,
                                      color: Colors.white),
                                ),
                                confirmDismiss: (_) async {
                                  await _deletar(
                                    item['id'] as String,
                                    item['ingrediente'] as String,
                                  );
                                  return false; // _deletar já recarrega
                                },
                                child: Card(
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: cor != Colors.transparent
                                          ? cor
                                          : AppTheme.secondary,
                                      child: Icon(
                                        cor != Colors.transparent
                                            ? Icons.warning_amber_rounded
                                            : Icons.inventory_2_outlined,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                    title: Text(
                                      item['ingrediente'] as String,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600),
                                    ),
                                    subtitle: Text(
                                      '${item['quantidade']} ${item['unidade']}'
                                      '${label.isNotEmpty ? ' • $label' : ''}',
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.edit_outlined),
                                      onPressed: () async {
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => EstoqueFormScreen(
                                              item: item,
                                            ),
                                          ),
                                        );
                                        _carregar();
                                      },
                                    ),
                                  ),
                                ),
                              );
                            },
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
            MaterialPageRoute(
              builder: (_) => const EstoqueFormScreen(),
            ),
          );
          _carregar();
        },
        child: const Icon(Icons.add),
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
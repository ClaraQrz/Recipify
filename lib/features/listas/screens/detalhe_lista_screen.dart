import 'package:flutter/material.dart';
import 'package:recipify/core/theme/app_theme.dart';
import 'package:recipify/repositories/lista_repository.dart';

class DetalheListaScreen extends StatefulWidget {
  final String listaId;
  final String listaNome;

  const DetalheListaScreen({
    super.key,
    required this.listaId,
    required this.listaNome,
  });

  @override
  State<DetalheListaScreen> createState() => _DetalheListaScreenState();
}

class _DetalheListaScreenState extends State<DetalheListaScreen> {
  List<Map<String, dynamic>> _itens = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarItens();
  }

  Future<void> _carregarItens() async {
    try {
      final itens =
          await ListaRepository.instance.itensDaLista(widget.listaId);
      setState(() {
        _itens = itens;
        _carregando = false;
      });
    } catch (e) {
      debugPrint('>>> ERRO ao carregar itens: $e');
      setState(() => _carregando = false);
    }
  }

  void _abrirModalAdicionarItem() {
    final nomeCtrl = TextEditingController();
    final qtdCtrl = TextEditingController();
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
                'Adicionar item',
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
                  hintText: 'Nome do item (ex: Tomate)',
                  prefixIcon: Icon(Icons.label_outline),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: qtdCtrl,
                decoration: const InputDecoration(
                  hintText: 'Quantidade (ex: 1 kg)',
                  prefixIcon: Icon(Icons.scale_outlined),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final nome = nomeCtrl.text.trim();
                  final qtd = qtdCtrl.text.trim();
                  if (nome.isEmpty || qtd.isEmpty) return;

                  try {
                    await ListaRepository.instance.adicionarItem(
                      listaId: widget.listaId,
                      nome: nome,
                      quantidade: qtd,
                    );
                    Navigator.pop(outerContext);
                    _carregarItens();
                  } catch (e) {
                    debugPrint('>>> ERRO ao adicionar item: $e');
                  }
                },
                child: const Text('Adicionar'),
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
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.listaNome),
      ),
      body: _carregando
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary))
          : _itens.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_shopping_cart_outlined,
                          size: 64,
                          color: AppTheme.textGray.withOpacity(0.4)),
                      const SizedBox(height: 12),
                      Text(
                        'Nenhum item ainda.',
                        style: TextStyle(
                          color: AppTheme.textGray.withOpacity(0.6),
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _itens.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: Color(0xFFE0C9A6)),
                  itemBuilder: (context, index) {
                    final item = _itens[index];
                    final comprado = item['comprado'] == 1;
                    return ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 8),
                      title: Text(
                        item['nome'] as String,
                        style: TextStyle(
                          decoration: comprado
                              ? TextDecoration.lineThrough
                              : null,
                          color: AppTheme.textDark,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            item['quantidade'] as String,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textDark,
                            ),
                          ),
                          Checkbox(
                            value: comprado,
                            onChanged: (v) async {
                              await ListaRepository.instance.toggleItem(
                                  item['id'] as String, v!);
                              _carregarItens();
                            },
                            activeColor: AppTheme.primary,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4)),
                            side:
                                const BorderSide(color: AppTheme.textGray),
                          ),
                        ],
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _abrirModalAdicionarItem,
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: AppTheme.textLight),
      ),
    );
  }
}
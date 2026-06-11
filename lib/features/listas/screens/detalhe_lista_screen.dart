import 'package:flutter/material.dart';
import 'package:recipify/core/theme/app_theme.dart';
import 'package:recipify/repositories/ingrediente_repository.dart';
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
      final itens = await ListaRepository.instance.itensDaLista(widget.listaId);
      if (!mounted) return;
      setState(() {
        _itens = itens;
        _carregando = false;
      });
    } catch (e) {
      debugPrint('ERRO ao carregar itens: $e');
      if (!mounted) return;
      setState(() => _carregando = false);
    }
  }

  void _abrirModalAdicionarItem() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _ModalAdicionarItem(
        listaId: widget.listaId,
        onAdicionado: _carregarItens,
      ),
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
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
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
              : SingleChildScrollView(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
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
                            decoration: comprado ? TextDecoration.lineThrough : null,
                            color: AppTheme.textDark,
                          ),
                        ),
                        subtitle: (item['quantidade'] as String?)?.isNotEmpty == true
                            ? Text(item['quantidade'] as String,
                                style: const TextStyle(
                                    fontSize: 12, color: AppTheme.textGray))
                            : null,
                        trailing: Checkbox(
                          value: comprado,
                          onChanged: (v) async {
                            await ListaRepository.instance
                                .toggleItem(item['id'] as String, v!);
                            _carregarItens();
                          },
                          activeColor: AppTheme.primary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4)),
                          side: const BorderSide(color: AppTheme.textGray),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _abrirModalAdicionarItem,
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

// ── Modal separado pra manter estado sem fechar ao digitar ──────────────────

class _ModalAdicionarItem extends StatefulWidget {
  final String listaId;
  final VoidCallback onAdicionado;

  const _ModalAdicionarItem({
    required this.listaId,
    required this.onAdicionado,
  });

  @override
  State<_ModalAdicionarItem> createState() => _ModalAdicionarItemState();
}

class _ModalAdicionarItemState extends State<_ModalAdicionarItem> {
  final _nomeCtrl    = TextEditingController();
  final _qtdCtrl     = TextEditingController();
  final _unidadeCtrl = TextEditingController();

  List<Map<String, dynamic>> _sugestoes = [];
  bool _buscando = false;
  bool _salvando = false;
  String? _erro;

  final List<String> _unidadesPadrao = [
    'un', 'kg', 'g', 'l', 'ml', 'cx', 'pct', 'dz', 'fatia', 'xícara', 'colher'
  ];

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _qtdCtrl.dispose();
    _unidadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _buscarIngrediente(String termo) async {
    if (termo.length < 2) {
      setState(() => _sugestoes = []);
      return;
    }
    setState(() => _buscando = true);
    try {
      final resultado = await IngredienteRepository.instance.buscar(termo);
      if (!mounted) return;
      setState(() { _sugestoes = resultado; _buscando = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() => _buscando = false);
    }
  }

  void _selecionarSugestao(Map<String, dynamic> ing) {
    setState(() {
      _nomeCtrl.text    = ing['nome'] as String;
      _unidadeCtrl.text = ing['unidade_padrao'] as String? ?? '';
      _sugestoes        = [];
    });
  }

  Future<void> _adicionar() async {
    final nome    = _nomeCtrl.text.trim();
    final qtd     = _qtdCtrl.text.trim();
    final unidade = _unidadeCtrl.text.trim();

    if (nome.isEmpty) {
      setState(() => _erro = 'Digite o nome do item.');
      return;
    }
    if (qtd.isEmpty) {
      setState(() => _erro = 'Digite a quantidade.');
      return;
    }
    if (unidade.isEmpty) {
      setState(() => _erro = 'Selecione ou digite a unidade.');
      return;
    }

    setState(() { _erro = null; _salvando = true; });

    try {
      await ListaRepository.instance.adicionarItem(
        listaId:    widget.listaId,
        nome:       nome,
        quantidade: '$qtd $unidade',
      );
      if (!mounted) return;
      widget.onAdicionado();
      Navigator.pop(context);
    } catch (e) {
      debugPrint('ERRO adicionar item: $e');
      if (!mounted) return;
      setState(() { _salvando = false; _erro = 'Erro ao adicionar item.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
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
                color: AppTheme.textDark),
          ),
          const SizedBox(height: 16),

          if (_erro != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(_erro!,
                  style: const TextStyle(color: Colors.red, fontSize: 13)),
            ),

          TextField(
            controller: _nomeCtrl,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Nome do item',
              prefixIcon: const Icon(Icons.label_outline),
              suffixIcon: _buscando
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  : null,
            ),
            onChanged: _buscarIngrediente,
          ),

          if (_sugestoes.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 4),
              constraints: const BoxConstraints(maxHeight: 160),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ListView(
                shrinkWrap: true,
                children: _sugestoes
                    .map((ing) => ListTile(
                          dense: true,
                          title: Text(ing['nome'] as String),
                          subtitle: Text(ing['unidade_padrao'] as String? ?? ''),
                          onTap: () => _selecionarSugestao(ing),
                        ))
                    .toList(),
              ),
            ),

          const SizedBox(height: 12),

          Row(children: [
            Expanded(
              flex: 2,
              child: TextField(
                controller: _qtdCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  hintText: 'Qtd',
                  prefixIcon: Icon(Icons.scale_outlined),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 3,
              child: TextField(
                controller: _unidadeCtrl,
                decoration: InputDecoration(
                  hintText: 'Unidade',
                  prefixIcon: const Icon(Icons.straighten_outlined),
                  suffixIcon: PopupMenuButton<String>(
                    icon: const Icon(Icons.arrow_drop_down),
                    onSelected: (v) => setState(() => _unidadeCtrl.text = v),
                    itemBuilder: (_) => _unidadesPadrao
                        .map((u) => PopupMenuItem(value: u, child: Text(u)))
                        .toList(),
                  ),
                ),
              ),
            ),
          ]),

          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: _salvando ? null : _adicionar,
            child: _salvando
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Adicionar'),
          ),
        ],
      ),
    );
  }
}
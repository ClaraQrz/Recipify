import 'package:flutter/material.dart';
import 'package:recipify/core/theme/app_theme.dart';
import 'package:recipify/repositories/ingrediente_repository.dart';
import 'package:recipify/services/auth_service.dart';
import 'package:recipify/services/supabase_service.dart';

// Modelo local de ingrediente adicionado à receita
class _IngredienteItem {
  final String ingredienteId;
  final String nome;
  final double quantidade;
  final String unidade;

  _IngredienteItem({
    required this.ingredienteId,
    required this.nome,
    required this.quantidade,
    required this.unidade,
  });
}

class PostarReceitaScreen extends StatefulWidget {
  const PostarReceitaScreen({super.key});

  @override
  State<PostarReceitaScreen> createState() => _PostarReceitaScreenState();
}

class _PostarReceitaScreenState extends State<PostarReceitaScreen> {
  final _tituloCtrl    = TextEditingController();
  final _descricaoCtrl = TextEditingController();
  final _tempoCtrl     = TextEditingController();
  final _porcoesCtrl   = TextEditingController();
  final _imagemCtrl    = TextEditingController();

  // Ingrediente sendo adicionado
  final _ingredienteCtrl  = TextEditingController();
  final _quantidadeCtrl   = TextEditingController();
  final _unidadeCtrl      = TextEditingController();
  final _tipoCtrl         = TextEditingController();
  final _unidPadraoCtrl   = TextEditingController();

  String _categoria = 'Salgadas';
  bool _publicar    = true;
  bool _salvando    = false;
  String? _erro;

  List<_IngredienteItem> _ingredientes = [];
  List<Map<String, dynamic>> _sugestoes = [];
  bool _buscandoIngrediente = false;
  Map<String, dynamic>? _ingredienteSelecionado;

  final List<String> _categorias = [
    'Salgadas', 'Doces', 'Sobremesas', 'Veganas',
    'Vegetarianas', 'Rápidas', 'Elaboradas', 'Outras',
  ];

  final List<String> _tipos = [
    'grão', 'vegetal', 'fruta', 'laticínio',
    'proteína', 'tempero', 'líquido', 'outro',
  ];

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descricaoCtrl.dispose();
    _tempoCtrl.dispose();
    _porcoesCtrl.dispose();
    _imagemCtrl.dispose();
    _ingredienteCtrl.dispose();
    _quantidadeCtrl.dispose();
    _unidadeCtrl.dispose();
    _tipoCtrl.dispose();
    _unidPadraoCtrl.dispose();
    super.dispose();
  }

  Future<void> _buscarIngrediente(String termo) async {
    if (termo.length < 2) {
      setState(() { _sugestoes = []; _ingredienteSelecionado = null; });
      return;
    }
    setState(() => _buscandoIngrediente = true);
    final resultado = await IngredienteRepository.instance.buscar(termo);
    setState(() {
      _sugestoes = resultado;
      _buscandoIngrediente = false;
      _ingredienteSelecionado = null;
    });
  }

  void _selecionarSugestao(Map<String, dynamic> ing) {
    setState(() {
      _ingredienteSelecionado = ing;
      _ingredienteCtrl.text   = ing['nome'];
      _unidadeCtrl.text       = ing['unidade_padrao'];
      _sugestoes              = [];
    });
  }

  Future<void> _adicionarIngrediente() async {
    final nome       = _ingredienteCtrl.text.trim();
    final qtdStr     = _quantidadeCtrl.text.trim();
    final unidade    = _unidadeCtrl.text.trim();

    if (nome.isEmpty || qtdStr.isEmpty || unidade.isEmpty) {
      setState(() => _erro = 'Preencha nome, quantidade e unidade do ingrediente.');
      return;
    }

    final quantidade = double.tryParse(qtdStr.replaceAll(',', '.'));
    if (quantidade == null || quantidade <= 0) {
      setState(() => _erro = 'Quantidade inválida.');
      return;
    }

    setState(() { _erro = null; _buscandoIngrediente = true; });

    Map<String, dynamic> ing;
    if (_ingredienteSelecionado != null) {
      ing = _ingredienteSelecionado!;
    } else {
      // Cria novo ingrediente
      final tipo       = _tipoCtrl.text.trim().isEmpty ? 'outro' : _tipoCtrl.text.trim();
      final unidPadrao = _unidPadraoCtrl.text.trim().isEmpty ? unidade : _unidPadraoCtrl.text.trim();
      ing = await IngredienteRepository.instance.buscarOuCriar(
        nome: nome,
        unidadePadrao: unidPadrao,
        tipo: tipo,
      );
    }

    setState(() {
      _ingredientes.add(_IngredienteItem(
        ingredienteId: ing['id'],
        nome:          ing['nome'],
        quantidade:    quantidade,
        unidade:       unidade,
      ));
      _ingredienteCtrl.clear();
      _quantidadeCtrl.clear();
      _unidadeCtrl.clear();
      _tipoCtrl.clear();
      _unidPadraoCtrl.clear();
      _ingredienteSelecionado = null;
      _buscandoIngrediente    = false;
    });
  }

  void _removerIngrediente(int index) {
    setState(() => _ingredientes.removeAt(index));
  }

  Future<void> _salvar() async {
    final titulo = _tituloCtrl.text.trim();
    if (titulo.isEmpty) {
      setState(() => _erro = 'O título é obrigatório.');
      return;
    }
    if (_ingredientes.isEmpty) {
      setState(() => _erro = 'Adicione pelo menos um ingrediente.');
      return;
    }

    setState(() { _erro = null; _salvando = true; });

    try {
      final uid    = AuthService.instance.usuarioLogado!['id'];
      final client = SupabaseService.instance.client;

      // 1. Insere receita
      final receita = await client.from('receita').insert({
        'autor_id':      uid,
        'titulo':        titulo,
        'descricao':     _descricaoCtrl.text.trim().isEmpty ? null : _descricaoCtrl.text.trim(),
        'tempo_minutos': int.tryParse(_tempoCtrl.text.trim()),
        'porcoes':       int.tryParse(_porcoesCtrl.text.trim()),
        'categoria':     _categoria,
        'imagem_url':    _imagemCtrl.text.trim().isEmpty ? null : _imagemCtrl.text.trim(),
        'publicada':     _publicar,
      }).select().single();

      // 2. Insere ingredientes da receita
      final receitaId = receita['id'];
      for (final item in _ingredientes) {
        await client.from('receita_ingrediente').insert({
          'receita_id':     receitaId,
          'ingrediente_id': item.ingredienteId,
          'quantidade':     item.quantidade,
          'unidade':        item.unidade,
        });
      }

      if (!mounted) return;
      Navigator.pop(context, true); // retorna true = receita criada
    } catch (e) {
      debugPrint('ERRO POSTAR: $e');
      if (!mounted) return;
      setState(() {
        _salvando = false;
        _erro     = 'Erro ao salvar receita. Tente novamente.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova Receita'),
        actions: [
          TextButton(
            onPressed: _salvando ? null : _salvar,
            child: _salvando
                ? const SizedBox(
                    height: 18, width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
                  )
                : Text(
                    _publicar ? 'Publicar' : 'Salvar',
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_erro != null)
              Container(
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(_erro!,
                    style: const TextStyle(color: Colors.red, fontSize: 13)),
              ),

            // ── Informações básicas ──────────────────────────────────────
            _secao('Informações básicas'),
            const SizedBox(height: 10),

            TextField(
              controller: _tituloCtrl,
              decoration: const InputDecoration(labelText: 'Título *'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descricaoCtrl,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Descrição'),
            ),
            const SizedBox(height: 12),

            // Categoria
            DropdownButtonFormField<String>(
              value: _categoria,
              decoration: const InputDecoration(labelText: 'Categoria'),
              items: _categorias
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _categoria = v!),
            ),
            const SizedBox(height: 12),

            Row(children: [
              Expanded(
                child: TextField(
                  controller: _tempoCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Tempo (min)',
                    prefixIcon: Icon(Icons.timer_outlined, size: 18),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _porcoesCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Porções',
                    prefixIcon: Icon(Icons.people_outline, size: 18),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 12),

            TextField(
              controller: _imagemCtrl,
              decoration: const InputDecoration(
                labelText: 'URL da imagem',
                prefixIcon: Icon(Icons.image_outlined, size: 18),
              ),
            ),
            const SizedBox(height: 12),

            // Publicar ou rascunho
            SwitchListTile(
              value: _publicar,
              onChanged: (v) => setState(() => _publicar = v),
              title: Text(_publicar ? 'Publicar receita' : 'Salvar como rascunho'),
              activeColor: AppTheme.primary,
              contentPadding: EdgeInsets.zero,
            ),

            const Divider(height: 32),

            // ── Ingredientes ─────────────────────────────────────────────
            _secao('Ingredientes'),
            const SizedBox(height: 10),

            // Campo de busca de ingrediente
            TextField(
              controller: _ingredienteCtrl,
              decoration: InputDecoration(
                labelText: 'Buscar ou digitar ingrediente',
                prefixIcon: const Icon(Icons.search, size: 18),
                suffixIcon: _buscandoIngrediente
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          height: 16, width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
              ),
              onChanged: _buscarIngrediente,
            ),

            // Sugestões
            if (_sugestoes.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: AppTheme.cardBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: _sugestoes.map((ing) => ListTile(
                    dense: true,
                    title: Text(ing['nome']),
                    subtitle: Text('${ing['unidade_padrao']} · ${ing['tipo']}'),
                    onTap: () => _selecionarSugestao(ing),
                  )).toList(),
                ),
              ),

            // Se não achou, mostra campos pra criar
            if (_ingredienteCtrl.text.length >= 2 &&
                _sugestoes.isEmpty &&
                !_buscandoIngrediente &&
                _ingredienteSelecionado == null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Ingrediente não encontrado — preencha para criar:',
                        style: TextStyle(fontSize: 12, color: AppTheme.textGray)),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _tipoCtrl.text.isEmpty ? 'outro' : _tipoCtrl.text,
                          decoration: const InputDecoration(labelText: 'Tipo', isDense: true),
                          items: _tipos
                              .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                              .toList(),
                          onChanged: (v) => setState(() => _tipoCtrl.text = v!),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _unidPadraoCtrl,
                          decoration: const InputDecoration(
                              labelText: 'Unidade padrão', isDense: true),
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),

            Row(children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _quantidadeCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Quantidade'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _unidadeCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Unidade (ex: g, ml, xíc)'),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _adicionarIngrediente,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
                child: const Icon(Icons.add, size: 20),
              ),
            ]),

            // Lista de ingredientes adicionados
            if (_ingredientes.isNotEmpty) ...[
              const SizedBox(height: 16),
              ..._ingredientes.asMap().entries.map((e) {
                final i    = e.key;
                final item = e.value;
                return ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  leading: const Icon(Icons.circle,
                      size: 8, color: AppTheme.primary),
                  title: Text(item.nome),
                  subtitle: Text('${_fmt(item.quantidade)} ${item.unidade}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, size: 18, color: Colors.red),
                    onPressed: () => _removerIngrediente(i),
                  ),
                );
              }),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _secao(String titulo) => Text(
        titulo,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppTheme.primary,
        ),
      );

  String _fmt(double valor) =>
      valor == valor.truncateToDouble()
          ? valor.toInt().toString()
          : valor.toString();
}

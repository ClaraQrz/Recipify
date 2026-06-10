import 'package:flutter/material.dart';
import 'package:recipify/core/theme/app_theme.dart';
import 'package:recipify/repositories/estoque_repository.dart';
import 'package:recipify/repositories/ingrediente_repository.dart';
import 'package:recipify/services/auth_service.dart';
import 'package:recipify/services/database_service.dart';

class EstoqueFormScreen extends StatefulWidget {
  final Map<String, dynamic>? item;
  const EstoqueFormScreen({super.key, this.item});

  @override
  State<EstoqueFormScreen> createState() => _EstoqueFormScreenState();
}

class _EstoqueFormScreenState extends State<EstoqueFormScreen> {
  // Ingrediente
  final _buscaController = TextEditingController();
  Map<String, dynamic>? _ingredienteSelecionado;
  List<Map<String, dynamic>> _sugestoes = [];
  bool _buscando = false;
  bool _mostrarCriar = false;

  // Novo ingrediente
  String _tipoSelecionado = 'outro';
  static const _tipos = ['grão', 'proteína', 'laticínio', 'vegetal', 'fruta', 'tempero', 'líquido', 'outro'];

  // Quantidade e unidade
  final _quantController = TextEditingController();
  String? _unidadeSelecionada;
  final _unidadeLivreController = TextEditingController();
  bool _unidadeLivre = false;

  // Unidades por tipo
  static const _unidadesPorTipo = {
    'líquido':   ['ml', 'l', 'xícara', 'colher de sopa', 'colher de chá'],
    'grão':      ['g', 'kg', 'xícara', 'colher de sopa'],
    'proteína':  ['g', 'kg', 'unidade', 'filé'],
    'laticínio': ['ml', 'l', 'g', 'kg', 'unidade', 'fatia'],
    'vegetal':   ['unidade', 'g', 'kg', 'maço', 'xícara'],
    'fruta':     ['unidade', 'g', 'kg', 'xícara'],
    'tempero':   ['g', 'colher de chá', 'colher de sopa', 'pitada', 'unidade'],
    'outro':     ['unidade', 'g', 'kg', 'ml', 'l', 'pacote', 'caixa'],
  };

  // Vencimento
  DateTime? _vencimento;

  bool _salvando = false;
  bool get _editando => widget.item != null;

  @override
  void initState() {
    super.initState();
    if (_editando) {
      _quantController.text = widget.item!['quantidade'].toString();
      final unidade = widget.item!['unidade'] as String? ?? '';
      // verifica se a unidade está nas listas conhecidas
      final todasUnidades = _unidadesPorTipo.values.expand((e) => e).toSet();
      if (todasUnidades.contains(unidade)) {
        _unidadeSelecionada = unidade;
      } else {
        _unidadeLivre = true;
        _unidadeLivreController.text = unidade;
      }
      final v = widget.item!['vencimento'] as String?;
      if (v != null) _vencimento = DateTime.tryParse(v);
      // mostra nome do ingrediente no campo (readonly em edição)
      _buscaController.text = widget.item!['ingrediente'] as String? ?? '';
    }
  }

  @override
  void dispose() {
    _buscaController.dispose();
    _quantController.dispose();
    _unidadeLivreController.dispose();
    super.dispose();
  }

  Future<void> _buscarIngredientes(String termo) async {
    if (termo.trim().length < 2) {
      setState(() { _sugestoes = []; _mostrarCriar = false; });
      return;
    }
    setState(() => _buscando = true);
    final resultado = await IngredienteRepository.instance.buscar(termo);
    if (!mounted) return;
    setState(() {
      _sugestoes = resultado;
      _mostrarCriar = resultado.isEmpty ||
          !resultado.any((i) =>
              (i['nome'] as String).toLowerCase() == termo.trim().toLowerCase());
      _buscando = false;
    });
  }

  void _selecionarIngrediente(Map<String, dynamic> ing) {
    setState(() {
      _ingredienteSelecionado = ing;
      _buscaController.text = ing['nome'] as String;
      _sugestoes = [];
      _mostrarCriar = false;
      _tipoSelecionado = ing['tipo'] as String? ?? 'outro';
      // pré-seleciona unidade padrão
      final padrao = ing['unidade_padrao'] as String?;
      final lista = _unidadesPorTipo[_tipoSelecionado] ?? _unidadesPorTipo['outro']!;
      _unidadeSelecionada = lista.contains(padrao) ? padrao : lista.first;
      _unidadeLivre = false;
    });
  }

  Future<void> _criarESelecionar() async {
    final nome = _buscaController.text.trim();
    if (nome.isEmpty) return;
    setState(() => _buscando = true);
    final unidadePadrao =
        (_unidadesPorTipo[_tipoSelecionado] ?? ['unidade']).first;
    final novo = await IngredienteRepository.instance.buscarOuCriar(
      nome: nome,
      unidadePadrao: unidadePadrao,
      tipo: _tipoSelecionado,
    );
    if (!mounted) return;
    _selecionarIngrediente(novo);
    setState(() => _buscando = false);
  }

  List<String> get _unidadesAtuais =>
      _unidadesPorTipo[_tipoSelecionado] ?? _unidadesPorTipo['outro']!;

  Future<void> _salvar() async {
    final usuarioId =
        AuthService.instance.usuarioLogado?['id'] as String? ?? '';
    if (usuarioId.isEmpty) return;

    if (!_editando && _ingredienteSelecionado == null) {
      _snack('Selecione ou crie um ingrediente');
      return;
    }

    final quant =
        double.tryParse(_quantController.text.replaceAll(',', '.'));
    if (quant == null || quant <= 0) {
      _snack('Informe uma quantidade válida');
      return;
    }

    final unidade = _unidadeLivre
        ? _unidadeLivreController.text.trim()
        : (_unidadeSelecionada ?? '');
    if (unidade.isEmpty) {
      _snack('Informe a unidade');
      return;
    }

    setState(() => _salvando = true);
    try {
      if (_editando) {
        await EstoqueRepository.instance.atualizar(
          id: widget.item!['id'] as String,
          quantidade: quant,
          unidade: unidade,
          vencimento: _vencimento?.toIso8601String(),
        );
      } else {
        debugPrint('SALVANDO: usuarioId=$usuarioId | ingredienteId=${_ingredienteSelecionado!['id']} | quant=$quant | unidade=$unidade');
        await EstoqueRepository.instance.adicionar(
          usuarioId: usuarioId,
          ingredienteId: _ingredienteSelecionado!['id'] as String,
          quantidade: quant,
          unidade: unidade,
          vencimento: _vencimento?.toIso8601String(),
        );
        final db = await DatabaseService.instance.db;
        final check = await db.rawQuery('SELECT * FROM estoque');
        debugPrint('ESTOQUE COMPLETO: $check');
      }
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      debugPrint('ERRO AO SALVAR: $e');
      _snack('Erro ao salvar: $e');
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }
  void _snack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_editando ? 'Editar item' : 'Adicionar ao estoque'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            // ── Ingrediente ──────────────────────────────────
            _label('Ingrediente'),
            const SizedBox(height: 8),
            TextField(
              controller: _buscaController,
              readOnly: _editando,
              decoration: InputDecoration(
                hintText: _editando ? '' : 'Digite para buscar...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _buscando
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : _ingredienteSelecionado != null
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => setState(() {
                              _ingredienteSelecionado = null;
                              _buscaController.clear();
                              _sugestoes = [];
                              _mostrarCriar = false;
                            }),
                          )
                        : null,
                border: const OutlineInputBorder(),
              ),
              onChanged: _editando ? null : _buscarIngredientes,
            ),

            // Sugestões
            if (_sugestoes.isNotEmpty)
              Card(
                margin: const EdgeInsets.only(top: 4),
                child: Column(
                  children: _sugestoes.map((ing) {
                    return ListTile(
                      dense: true,
                      title: Text(ing['nome'] as String),
                      subtitle: Text(ing['tipo'] as String? ?? ''),
                      onTap: () => _selecionarIngrediente(ing),
                    );
                  }).toList(),
                ),
              ),

            // Botão criar novo
            if (_mostrarCriar && !_editando) ...[
              const SizedBox(height: 8),
              _label('Tipo do ingrediente'),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _tipos.map((tipo) {
                  final sel = tipo == _tipoSelecionado;
                  return ChoiceChip(
                    label: Text(tipo),
                    selected: sel,
                    selectedColor: AppTheme.primary,
                    labelStyle: TextStyle(
                      color: sel ? Colors.white : AppTheme.textDark,
                    ),
                    onSelected: (_) => setState(() {
                      _tipoSelecionado = tipo;
                      _unidadeSelecionada = null;
                    }),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _criarESelecionar,
                icon: const Icon(Icons.add),
                label: Text(
                  'Criar "${_buscaController.text.trim()}" como $_tipoSelecionado',
                ),
              ),
            ],

            const SizedBox(height: 20),

            // ── Quantidade ───────────────────────────────────
            _label('Quantidade'),
            const SizedBox(height: 8),
            TextField(
              controller: _quantController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Ex: 2',
              ),
            ),

            const SizedBox(height: 20),

            // ── Unidade ──────────────────────────────────────
            _label('Unidade'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                ..._unidadesAtuais.map((u) {
                  final sel = !_unidadeLivre && u == _unidadeSelecionada;
                  return ChoiceChip(
                    label: Text(u),
                    selected: sel,
                    selectedColor: AppTheme.primary,
                    labelStyle: TextStyle(
                      color: sel ? Colors.white : AppTheme.textDark,
                    ),
                    onSelected: (_) => setState(() {
                      _unidadeSelecionada = u;
                      _unidadeLivre = false;
                    }),
                  );
                }),
                ChoiceChip(
                  label: const Text('outra...'),
                  selected: _unidadeLivre,
                  selectedColor: AppTheme.secondary,
                  labelStyle: TextStyle(
                    color: _unidadeLivre ? Colors.white : AppTheme.textDark,
                  ),
                  onSelected: (_) => setState(() {
                    _unidadeLivre = true;
                    _unidadeSelecionada = null;
                  }),
                ),
              ],
            ),
            if (_unidadeLivre) ...[
              const SizedBox(height: 10),
              TextField(
                controller: _unidadeLivreController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Ex: fatia, porção, lata...',
                ),
              ),
            ],

            const SizedBox(height: 20),

            // ── Vencimento ───────────────────────────────────
            _label('Vencimento (opcional)'),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _vencimento ?? DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                );
                if (picked != null) setState(() => _vencimento = picked);
              },
              icon: const Icon(Icons.calendar_today_outlined),
              label: Text(
                _vencimento == null
                    ? 'Selecionar data'
                    : '${_vencimento!.day.toString().padLeft(2, '0')}/'
                      '${_vencimento!.month.toString().padLeft(2, '0')}/'
                      '${_vencimento!.year}',
              ),
            ),
            if (_vencimento != null) ...[
              const SizedBox(height: 6),
              TextButton(
                onPressed: () => setState(() => _vencimento = null),
                child: const Text('Remover data'),
              ),
            ],

            const SizedBox(height: 32),

            // ── Salvar ───────────────────────────────────────
            FilledButton(
              onPressed: _salvando ? null : _salvar,
              child: _salvando
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(_editando ? 'Salvar alterações' : 'Adicionar ao estoque'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String texto) => Text(
        texto,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      );
}
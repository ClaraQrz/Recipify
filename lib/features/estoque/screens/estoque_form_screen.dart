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
  final _buscaController = TextEditingController();
  Map<String, dynamic>? _ingredienteSelecionado;
  List<Map<String, dynamic>> _sugestoes = [];
  bool _buscando = false;
  bool _mostrarCriar = false;

  String _tipoSelecionado = 'outro';
  static const _tipos = ['grao', 'proteina', 'laticinios', 'vegetal', 'fruta', 'tempero', 'liquido', 'outro'];
  static const _tiposLabel = ['Grão', 'Proteína', 'Laticínios', 'Vegetal', 'Fruta', 'Tempero', 'Líquido', 'Outro'];

  final _quantController = TextEditingController();
  String? _unidadeSelecionada;
  final _unidadeLivreController = TextEditingController();
  bool _unidadeLivre = false;

  static const _unidadesPorTipo = {
    'liquido':    ['ml', 'l', 'xícara', 'colher de sopa', 'colher de chá'],
    'grao':       ['g', 'kg', 'xícara', 'colher de sopa'],
    'proteina':   ['g', 'kg', 'unidade', 'filé'],
    'laticinios': ['ml', 'l', 'g', 'kg', 'unidade', 'fatia'],
    'vegetal':    ['unidade', 'g', 'kg', 'maço', 'xícara'],
    'fruta':      ['unidade', 'g', 'kg', 'xícara'],
    'tempero':    ['g', 'colher de chá', 'colher de sopa', 'pitada', 'unidade'],
    'outro':      ['unidade', 'g', 'kg', 'ml', 'l', 'pacote', 'caixa'],
  };

  DateTime? _vencimento;
  bool _salvando = false;
  bool get _editando => widget.item != null;

  @override
  void initState() {
    super.initState();
    if (_editando) {
      _quantController.text = widget.item!['quantidade'].toString();
      final unidade = widget.item!['unidade'] as String? ?? '';
      final todasUnidades = _unidadesPorTipo.values.expand((e) => e).toSet();
      if (todasUnidades.contains(unidade)) {
        _unidadeSelecionada = unidade;
      } else {
        _unidadeLivre = true;
        _unidadeLivreController.text = unidade;
      }
      final v = widget.item!['vencimento'] as String?;
      if (v != null) _vencimento = DateTime.tryParse(v);
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

    final quant = double.tryParse(_quantController.text.replaceAll(',', '.'));
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
        await EstoqueRepository.instance.adicionar(
          usuarioId: usuarioId,
          ingredienteId: _ingredienteSelecionado!['id'] as String,
          quantidade: quant,
          unidade: unidade,
          vencimento: _vencimento?.toIso8601String(),
        );
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

            // ── Ingrediente ──────────────────────────────────────
            _sectionLabel('Ingrediente'),
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
              ),
              onChanged: _editando ? null : _buscarIngredientes,
            ),

            if (_sugestoes.isNotEmpty) ...[
              const SizedBox(height: 4),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: _sugestoes.map((ing) => ListTile(
                    dense: true,
                    title: Text(ing['nome'] as String),
                    subtitle: Text(ing['tipo'] as String? ?? ''),
                    onTap: () => _selecionarIngrediente(ing),
                  )).toList(),
                ),
              ),
            ],

            if (_mostrarCriar && !_editando) ...[
              const SizedBox(height: 20),
              _sectionLabel('Tipo do ingrediente'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: List.generate(_tipos.length, (i) {
                  final tipo = _tipos[i];
                  final label = _tiposLabel[i];
                  final sel = tipo == _tipoSelecionado;
                  return _chip(
                    label: label,
                    selected: sel,
                    onTap: () => setState(() {
                      _tipoSelecionado = tipo;
                      _unidadeSelecionada = null;
                    }),
                  );
                }),
              ),
              const SizedBox(height: 12),
              // Botão "Criar" sem borda, estilo secundário
              ElevatedButton.icon(
                onPressed: _criarESelecionar,
                icon: const Icon(Icons.add),
                label: Text('Criar "${_buscaController.text.trim()}"'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.surface,
                  foregroundColor: AppTheme.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // ── Quantidade ────────────────────────────────────────
            _sectionLabel('Quantidade'),
            const SizedBox(height: 8),
            TextField(
              controller: _quantController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(hintText: 'Ex: 2'),
            ),

            const SizedBox(height: 20),

            // ── Unidade ───────────────────────────────────────────
            _sectionLabel('Unidade'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                ..._unidadesAtuais.map((u) {
                  final sel = !_unidadeLivre && u == _unidadeSelecionada;
                  return _chip(
                    label: u,
                    selected: sel,
                    onTap: () => setState(() {
                      _unidadeSelecionada = u;
                      _unidadeLivre = false;
                    }),
                  );
                }),
                _chip(
                  label: 'outra...',
                  selected: _unidadeLivre,
                  onTap: () => setState(() {
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
                  hintText: 'Ex: fatia, porção, lata...',
                ),
              ),
            ],

            const SizedBox(height: 20),

            // ── Vencimento ────────────────────────────────────────
            _sectionLabel('Vencimento (opcional)'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _vencimento ?? DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                );
                if (picked != null) setState(() => _vencimento = picked);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 18, color: AppTheme.textGray),
                  const SizedBox(width: 10),
                  Text(
                    _vencimento == null
                        ? 'Selecionar data'
                        : '${_vencimento!.day.toString().padLeft(2, '0')}/'
                          '${_vencimento!.month.toString().padLeft(2, '0')}/'
                          '${_vencimento!.year}',
                    style: TextStyle(
                      color: _vencimento == null
                          ? AppTheme.textGray
                          : AppTheme.textDark,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  if (_vencimento != null)
                    GestureDetector(
                      onTap: () => setState(() => _vencimento = null),
                      child: const Icon(Icons.clear,
                          size: 18, color: AppTheme.textGray),
                    ),
                ]),
              ),
            ),

            const SizedBox(height: 32),

            // ── Salvar ────────────────────────────────────────────
            ElevatedButton(
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

  Widget _sectionLabel(String texto) => Text(
        texto,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
          color: AppTheme.textDark,
        ),
      );

  /// Chip sem contorno, fundo surface quando não selecionado
  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppTheme.textDark,
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:recipify/core/theme/app_theme.dart';
import 'package:recipify/repositories/ingrediente_repository.dart';
import 'package:recipify/services/auth_service.dart';
import 'package:recipify/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  final _ingredienteCtrl = TextEditingController();
  final _quantidadeCtrl  = TextEditingController();
  final _unidadeCtrl     = TextEditingController();

  String _categoria = 'Salgadas';
  bool _publicar    = true;
  bool _salvando    = false;
  String? _erro;

  File? _imagemSelecionada;
  List<_IngredienteItem> _ingredientes = [];
  List<Map<String, dynamic>> _sugestoes = [];
  bool _buscando = false;
  Map<String, dynamic>? _ingredienteSelecionado;

  final List<String> _categorias = [
    'Salgadas', 'Doces', 'Sobremesas', 'Veganas',
    'Vegetarianas', 'Rápidas', 'Elaboradas', 'Outras',
  ];

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descricaoCtrl.dispose();
    _tempoCtrl.dispose();
    _porcoesCtrl.dispose();
    _ingredienteCtrl.dispose();
    _quantidadeCtrl.dispose();
    _unidadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _selecionarImagem() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1200,
    );
    if (picked != null) {
      setState(() => _imagemSelecionada = File(picked.path));
    }
  }

  Future<void> _buscarIngrediente(String termo) async {
    if (termo.length < 2) {
      setState(() { _sugestoes = []; _ingredienteSelecionado = null; });
      return;
    }
    setState(() => _buscando = true);
    final resultado = await IngredienteRepository.instance.buscar(termo);
    setState(() {
      _sugestoes = resultado;
      _buscando  = false;
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

  void _adicionarIngrediente() {
    final nome    = _ingredienteCtrl.text.trim();
    final qtdStr  = _quantidadeCtrl.text.trim();
    final unidade = _unidadeCtrl.text.trim();

    if (_ingredienteSelecionado == null) {
      setState(() => _erro = 'Selecione um ingrediente da lista.');
      return;
    }
    if (qtdStr.isEmpty || unidade.isEmpty) {
      setState(() => _erro = 'Preencha quantidade e unidade.');
      return;
    }
    final quantidade = double.tryParse(qtdStr.replaceAll(',', '.'));
    if (quantidade == null || quantidade <= 0) {
      setState(() => _erro = 'Quantidade inválida.');
      return;
    }

    setState(() {
      _erro = null;
      _ingredientes.add(_IngredienteItem(
        ingredienteId: _ingredienteSelecionado!['id'],
        nome:          _ingredienteSelecionado!['nome'],
        quantidade:    quantidade,
        unidade:       unidade,
      ));
      _ingredienteCtrl.clear();
      _quantidadeCtrl.clear();
      _unidadeCtrl.clear();
      _ingredienteSelecionado = null;
      _sugestoes = [];
    });
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

      // Upload da imagem se selecionada
      String? imagemUrl;
      if (_imagemSelecionada != null) {
        final bytes    = await _imagemSelecionada!.readAsBytes();
        final fileName = '${uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await client.storage
            .from('receitas')
            .uploadBinary(fileName, bytes,
                fileOptions: const FileOptions(contentType: 'image/jpeg'));
        imagemUrl = client.storage.from('receitas').getPublicUrl(fileName);
      }

      // Insere receita
      final receita = await client.from('receita').insert({
        'autor_id':      uid,
        'titulo':        titulo,
        'descricao':     _descricaoCtrl.text.trim().isEmpty ? null : _descricaoCtrl.text.trim(),
        'tempo_minutos': int.tryParse(_tempoCtrl.text.trim()),
        'porcoes':       int.tryParse(_porcoesCtrl.text.trim()),
        'categoria':     _categoria,
        'imagem_url':    imagemUrl,
        'publicada':     _publicar,
      }).select().single();

      // Insere ingredientes
      for (final item in _ingredientes) {
        await client.from('receita_ingrediente').insert({
          'receita_id':     receita['id'],
          'ingrediente_id': item.ingredienteId,
          'quantidade':     item.quantidade,
          'unidade':        item.unidade,
        });
      }

      if (!mounted) return;
      Navigator.pop(context, true);
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
                child: Text(_erro!, style: const TextStyle(color: Colors.red, fontSize: 13)),
              ),

            GestureDetector(
              onTap: _selecionarImagem,
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                clipBehavior: Clip.antiAlias,
                child: _imagemSelecionada != null
                    ? Image.file(_imagemSelecionada!, fit: BoxFit.cover)
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined,
                              size: 40, color: AppTheme.textGray),
                          SizedBox(height: 8),
                          Text('Toque para adicionar foto',
                              style: TextStyle(color: AppTheme.textGray, fontSize: 13)),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 20),

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

            SwitchListTile(
              value: _publicar,
              onChanged: (v) => setState(() => _publicar = v),
              title: Text(_publicar ? 'Publicar receita' : 'Salvar como rascunho'),
              activeColor: AppTheme.primary,
              contentPadding: EdgeInsets.zero,
            ),

            const Divider(height: 32),

            _secao('Ingredientes'),
            const SizedBox(height: 10),

            TextField(
              controller: _ingredienteCtrl,
              decoration: InputDecoration(
                labelText: 'Buscar ingrediente',
                prefixIcon: const Icon(Icons.search, size: 18),
                suffixIcon: _buscando
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
                    subtitle: Text(ing['unidade_padrao']),
                    onTap: () => _selecionarSugestao(ing),
                  )).toList(),
                ),
              ),

            const SizedBox(height: 12),

            Row(children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _quantidadeCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Qtd'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _unidadeCtrl,
                  decoration: const InputDecoration(labelText: 'Unidade'),
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

            if (_ingredientes.isNotEmpty) ...[
              const SizedBox(height: 16),
              ..._ingredientes.asMap().entries.map((e) {
                final i    = e.key;
                final item = e.value;
                return ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  leading: const Icon(Icons.circle, size: 8, color: AppTheme.primary),
                  title: Text(item.nome),
                  subtitle: Text('${_fmt(item.quantidade)} ${item.unidade}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, size: 18, color: Colors.red),
                    onPressed: () => setState(() => _ingredientes.removeAt(i)),
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
import 'package:flutter/material.dart';
import 'package:recipify/core/theme/app_theme.dart';
import 'package:recipify/repositories/receita_repository.dart';
import 'package:recipify/features/receitas/screens/editar_receita_screen.dart';
import 'package:recipify/services/supabase_service.dart';

class MinhasReceitasScreen extends StatefulWidget {
  const MinhasReceitasScreen({super.key});

  @override
  State<MinhasReceitasScreen> createState() => _MinhasReceitasScreenState();
}

class _MinhasReceitasScreenState extends State<MinhasReceitasScreen> {
  bool _carregando = true;
  List<Map<String, dynamic>> _receitas = [];

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    try {
      final resultado = await ReceitaRepository.instance.minhasReceitas();
      if (!mounted) return;
      setState(() {
        _receitas   = resultado;
        _carregando = false;
      });
    } catch (e) {
      debugPrint('ERRO MINHAS RECEITAS: $e');
      if (!mounted) return;
      setState(() => _carregando = false);
    }
  }

  Future<void> _abrirEditar(Map<String, dynamic> receita) async {
    final editou = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditarReceitaScreen(receita: receita),
      ),
    );
    if (editou == true) _carregar();
  }

  Future<void> _confirmarExcluir(String receitaId) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir receita'),
        content: const Text('Tem certeza que deseja excluir esta receita? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmar == true) {
      await SupabaseService.instance.client.from('receita').delete().eq('id', receitaId);     
       _carregar();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Minhas Receitas')),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _receitas.isEmpty
              ? const Center(
                  child: Text(
                    'Você ainda não postou nenhuma receita.',
                    style: TextStyle(color: AppTheme.textGray),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _carregar,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _receitas.length,
                    itemBuilder: (context, i) => _card(_receitas[i]),
                  ),
                ),
    );
  }

  Widget _card(Map<String, dynamic> receita) {
    final titulo    = receita['titulo'] as String;
    final publicada = receita['publicada'] as bool;
    final imgUrl    = receita['imagem_url'] as String?;
    final tempo     = receita['tempo_minutos'] as int?;
    final categoria = receita['categoria'] as String?;
    final media     = (receita['media_estrelas'] as num?)?.toDouble() ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imgUrl != null && imgUrl.isNotEmpty)
            Image.network(imgUrl,
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholder())
          else
            _placeholder(),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: Text(titulo,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold)),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: publicada ? Colors.green : Colors.orange,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      publicada ? 'Publicada' : 'Rascunho',
                      style:
                          const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
                ]),
                const SizedBox(height: 4),
                Row(children: [
                  if (tempo != null) ...[
                    const Icon(Icons.timer_outlined,
                        size: 13, color: AppTheme.textGray),
                    const SizedBox(width: 3),
                    Text(_fmt(tempo),
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textGray)),
                    const SizedBox(width: 10),
                  ],
                  if (categoria != null) ...[
                    const Icon(Icons.label_outline,
                        size: 13, color: AppTheme.textGray),
                    const SizedBox(width: 3),
                    Text(categoria,
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textGray)),
                    const SizedBox(width: 10),
                  ],
                  if (media > 0) ...[
                    const Icon(Icons.star, size: 13, color: Colors.amber),
                    const SizedBox(width: 3),
                    Text(media.toStringAsFixed(1),
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textGray)),
                  ],
                ]),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _abrirEditar(receita),
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('Editar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primary,
                        side: const BorderSide(color: AppTheme.primary),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        textStyle: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
        height: 140,
        width: double.infinity,
        color: AppTheme.surface,
        child:
            const Icon(Icons.restaurant, size: 40, color: AppTheme.textGray),
      );

  String _fmt(int minutos) {
    if (minutos < 60) return '${minutos}min';
    final h = minutos ~/ 60;
    final m = minutos % 60;
    return m == 0 ? '${h}h' : '${h}h${m}min';
  }
}
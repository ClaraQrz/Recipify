import 'package:flutter/material.dart';
import 'package:recipify/core/theme/app_theme.dart';
import 'package:recipify/repositories/receita_repository.dart';
import 'package:recipify/services/auth_service.dart';
import 'package:recipify/services/supabase_service.dart';

class ReceitaDetalheScreen extends StatefulWidget {
  final Map<String, dynamic> receita;
  final bool favoritada;

  const ReceitaDetalheScreen({
    super.key,
    required this.receita,
    required this.favoritada,
  });

  @override
  State<ReceitaDetalheScreen> createState() => _ReceitaDetalheScreenState();
}

class _ReceitaDetalheScreenState extends State<ReceitaDetalheScreen> {
  late bool _favoritada;
  bool _carregandoIngredientes = true;
  List<Map<String, dynamic>> _ingredientes = [];

  // Avaliação
  int? _minhaEstrela;
  bool _salvandoAvaliacao = false;
  double _mediaEstrelas = 0;
  int _totalAvaliacoes  = 0;

  @override
  void initState() {
    super.initState();
    _favoritada    = widget.favoritada;
    _mediaEstrelas = (widget.receita['media_estrelas'] as num?)?.toDouble() ?? 0;
    _totalAvaliacoes = widget.receita['total_avaliacoes'] as int? ?? 0;
    _carregarIngredientes();
    _carregarMinhaAvaliacao();
  }

  Future<void> _carregarIngredientes() async {
    try {
      final receitaId = widget.receita['id'] as String;
      final resultado = await SupabaseService.instance.client
          .from('receita_ingrediente')
          .select('quantidade, unidade, ingrediente ( nome )')
          .eq('receita_id', receitaId);

      if (!mounted) return;
      setState(() {
        _ingredientes = List<Map<String, dynamic>>.from(resultado);
        _carregandoIngredientes = false;
      });
    } catch (e) {
      debugPrint('ERRO INGREDIENTES: $e');
      if (!mounted) return;
      setState(() => _carregandoIngredientes = false);
    }
  }

  Future<void> _carregarMinhaAvaliacao() async {
    final uid = AuthService.instance.usuarioLogado?['id'];
    if (uid == null) return;

    try {
      final resultado = await SupabaseService.instance.client
          .from('avaliacao')
          .select('estrelas')
          .eq('receita_id', widget.receita['id'])
          .eq('usuario_id', uid)
          .maybeSingle();

      if (!mounted) return;
      if (resultado != null) {
        setState(() => _minhaEstrela = resultado['estrelas'] as int);
      }
    } catch (e) {
      debugPrint('ERRO AVALIACAO: $e');
    }
  }

  Future<void> _toggleFavorito() async {
    final id = widget.receita['id'] as String;
    setState(() => _favoritada = !_favoritada);
    await ReceitaRepository.instance.toggleFavorito(id, !_favoritada);
  }

  Future<void> _avaliar(int estrelas) async {
    final uid = AuthService.instance.usuarioLogado?['id'];
    if (uid == null) return;

    setState(() { _salvandoAvaliacao = true; _minhaEstrela = estrelas; });

    try {
      final client    = SupabaseService.instance.client;
      final receitaId = widget.receita['id'] as String;

      // Upsert da avaliação
      await client.from('avaliacao').upsert({
        'receita_id':  receitaId,
        'usuario_id':  uid,
        'estrelas':    estrelas,
      }, onConflict: 'receita_id,usuario_id');

      // Recalcula média direto do banco
      final stats = await client
          .from('avaliacao')
          .select('estrelas')
          .eq('receita_id', receitaId);

      final total = stats.length;
      final soma  = stats.fold<int>(0, (acc, a) => acc + (a['estrelas'] as int));
      final media = total > 0 ? soma / total : 0.0;

      // Atualiza receita
      await client.from('receita').update({
        'media_estrelas':   media,
        'total_avaliacoes': total,
      }).eq('id', receitaId);

      if (!mounted) return;
      setState(() {
        _mediaEstrelas   = media.toDouble();
        _totalAvaliacoes = total;
        _salvandoAvaliacao = false;
      });
    } catch (e) {
      debugPrint('ERRO AVALIAR: $e');
      if (!mounted) return;
      setState(() => _salvandoAvaliacao = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final receita   = widget.receita;
    final titulo    = receita['titulo'] as String;
    final descricao = receita['descricao'] as String?;
    final imgUrl    = receita['imagem_url'] as String?;
    final tempo     = receita['tempo_minutos'] as int?;
    final porcoes   = receita['porcoes'] as int?;
    final categoria = receita['categoria'] as String?;
    final autor     = (receita['usuario'] as Map?)
                        ?['apelido'] as String? ?? 'Desconhecido';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // AppBar com imagem
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: AppTheme.background,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: imgUrl != null && imgUrl.isNotEmpty
                  ? Image.network(imgUrl, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder())
                  : _placeholder(),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _favoritada ? Icons.favorite : Icons.favorite_border,
                  color: _favoritada ? Colors.red : Colors.white,
                ),
                onPressed: _toggleFavorito,
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título + autor
                  Text(titulo,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Por $autor',
                      style: const TextStyle(
                          color: AppTheme.textGray, fontSize: 13)),

                  const SizedBox(height: 16),

                  // Info chips
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      if (tempo != null)
                        _chip(Icons.timer_outlined, _fmtTempo(tempo)),
                      if (porcoes != null)
                        _chip(Icons.people_outline, '$porcoes porções'),
                      if (categoria != null)
                        _chip(Icons.label_outline, categoria),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Avaliação
                  Row(children: [
                    ...List.generate(5, (i) {
                      final estrela = i + 1;
                      return GestureDetector(
                        onTap: _salvandoAvaliacao ? null : () => _avaliar(estrela),
                        child: Icon(
                          estrela <= (_minhaEstrela ?? 0)
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                          size: 28,
                        ),
                      );
                    }),
                    const SizedBox(width: 8),
                    if (_salvandoAvaliacao)
                      const SizedBox(
                        height: 16, width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      Text(
                        _mediaEstrelas > 0
                            ? '${_mediaEstrelas.toStringAsFixed(1)} · $_totalAvaliacoes avaliações'
                            : 'Sem avaliações',
                        style: const TextStyle(
                            color: AppTheme.textGray, fontSize: 12),
                      ),
                  ]),

                  const Divider(height: 32),

                  // Ingredientes
                  const Text('Ingredientes',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary)),
                  const SizedBox(height: 10),

                  _carregandoIngredientes
                      ? const Center(child: CircularProgressIndicator())
                      : _ingredientes.isEmpty
                          ? const Text('Nenhum ingrediente cadastrado.',
                              style: TextStyle(color: AppTheme.textGray))
                          : Column(
                              children: _ingredientes.map((item) {
                                final nome = (item['ingrediente']
                                    as Map)['nome'] as String;
                                final qtd  = (item['quantidade'] as num).toDouble();
                                final und  = item['unidade'] as String;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Row(children: [
                                    const Icon(Icons.circle,
                                        size: 7, color: AppTheme.primary),
                                    const SizedBox(width: 10),
                                    Expanded(child: Text(nome)),
                                    Text(
                                      und == 'a gosto'
                                          ? 'a gosto'
                                          : '${_fmtQtd(qtd)} $und',
                                      style: const TextStyle(
                                          color: AppTheme.textGray,
                                          fontSize: 13),
                                    ),
                                  ]),
                                );
                              }).toList(),
                            ),

                  const Divider(height: 32),

                  // Descrição / modo de preparo
                  if (descricao != null && descricao.isNotEmpty) ...[
                    const Text('Descrição e modo de preparo',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary)),
                    const SizedBox(height: 10),
                    Text(descricao,
                        style: const TextStyle(
                            fontSize: 14, height: 1.6)),
                  ],

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
        color: AppTheme.surface,
        child: const Center(
          child: Icon(Icons.restaurant, size: 60, color: AppTheme.textGray),
        ),
      );

  Widget _chip(IconData icon, String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: AppTheme.textGray),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: AppTheme.textGray)),
        ]),
      );

  String _fmtTempo(int minutos) {
    if (minutos < 60) return '${minutos}min';
    final h = minutos ~/ 60;
    final m = minutos % 60;
    return m == 0 ? '${h}h' : '${h}h${m}min';
  }

  String _fmtQtd(double valor) =>
      valor == valor.truncateToDouble()
          ? valor.toInt().toString()
          : valor.toString();
}
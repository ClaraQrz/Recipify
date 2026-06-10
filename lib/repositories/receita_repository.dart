import 'package:recipify/services/auth_service.dart';
import 'package:recipify/services/supabase_service.dart';

class ReceitaRepository {
  static final ReceitaRepository instance = ReceitaRepository._internal();
  ReceitaRepository._internal();

  final _client = SupabaseService.instance.client;

  /// Top 5 da semana via tabela top_semanal do Supabase
  Future<List<Map<String, dynamic>>> topSemanal({int limite = 5}) async {
    final resultado = await _client
        .from('top_semanal')
        .select('''
          posicao,
          pontuacao,
          receita (
            id,
            titulo,
            imagem_url,
            media_estrelas,
            usuario!receita_autor_id_fkey ( apelido )
          )
        ''')
        .order('posicao', ascending: true)
        .limit(limite);

    return List<Map<String, dynamic>>.from(resultado);
  }

  /// Todas as receitas publicadas com dados completos
  Future<List<Map<String, dynamic>>> listarReceitas({
    String? categoria,
  }) async {
    var query = _client
        .from('receita')
        .select('''
          id,
          titulo,
          descricao,
          tempo_minutos,
          porcoes,
          categoria,
          imagem_url,
          media_estrelas,
          total_avaliacoes,
          criado_em,
          usuario!receita_autor_id_fkey ( id, apelido )
        ''')
        .eq('publicada', true);

    if (categoria != null && categoria != 'Todas') {
      query = query.eq('categoria', categoria);
    }

    final resultado = await query.order('criado_em', ascending: false);
    return List<Map<String, dynamic>>.from(resultado);
  }

  /// Receitas favoritadas pelo usuário logado
  Future<List<Map<String, dynamic>>> listarFavoritas() async {
    final uid = AuthService.instance.usuarioLogado?['id'];
    if (uid == null) return [];

    final resultado = await _client
        .from('favorito')
        .select('''
          receita (
            id,
            titulo,
            descricao,
            tempo_minutos,
            porcoes,
            categoria,
            imagem_url,
            media_estrelas,
            total_avaliacoes,
            criado_em,
            usuario!receita_autor_id_fkey ( id, apelido )
          )
        ''')
        .eq('usuario_id', uid);

    return resultado
        .map((f) => f['receita'] as Map<String, dynamic>)
        .toList();
  }

  /// Receitas postadas pelo usuário logado
  Future<List<Map<String, dynamic>>> minhasReceitas() async {
    final uid = AuthService.instance.usuarioLogado?['id'];
    if (uid == null) return [];

    final resultado = await _client
        .from('receita')
        .select('''
          id,
          titulo,
          descricao,
          tempo_minutos,
          porcoes,
          categoria,
          imagem_url,
          media_estrelas,
          total_avaliacoes,
          publicada,
          criado_em,
          usuario!receita_autor_id_fkey ( id, apelido )
        ''')
        .eq('autor_id', uid)
        .order('criado_em', ascending: false);

    return List<Map<String, dynamic>>.from(resultado);
  }

  /// Favoritar ou desfavoritar uma receita
  Future<void> toggleFavorito(String receitaId, bool favoritado) async {
    final uid = AuthService.instance.usuarioLogado?['id'];
    if (uid == null) return;

    if (favoritado) {
      await _client
          .from('favorito')
          .delete()
          .eq('usuario_id', uid)
          .eq('receita_id', receitaId);
    } else {
      await _client.from('favorito').insert({
        'usuario_id': uid,
        'receita_id': receitaId,
      });
    }
  }

  /// IDs das receitas favoritadas pelo usuário (para marcar coração na lista)
  Future<Set<String>> idsFavoritas() async {
    final uid = AuthService.instance.usuarioLogado?['id'];
    if (uid == null) return {};

    final resultado = await _client
        .from('favorito')
        .select('receita_id')
        .eq('usuario_id', uid);

    return resultado.map((f) => f['receita_id'] as String).toSet();
  }
}
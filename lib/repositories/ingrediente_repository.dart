import 'package:recipify/services/supabase_service.dart';

class IngredienteRepository {
  static final IngredienteRepository instance = IngredienteRepository._internal();
  IngredienteRepository._internal();

  final _client = SupabaseService.instance.client;

  Future<List<Map<String, dynamic>>> buscar(String termo) async {
    if (termo.trim().isEmpty) return [];

    final resultado = await _client
        .from('ingrediente')
        .select('id, nome, unidade_padrao, tipo')
        .ilike('nome', '%$termo%')
        .limit(10);

    return List<Map<String, dynamic>>.from(resultado);
  }

  Future<Map<String, dynamic>> buscarOuCriar({
    required String nome,
    required String unidadePadrao,
    required String tipo,
  }) async {
    final existente = await _client
        .from('ingrediente')
        .select()
        .ilike('nome', nome.trim())
        .maybeSingle();

    if (existente != null) return existente;

    // Cria novo
    final novo = await _client
        .from('ingrediente')
        .insert({
          'nome': nome.trim(),
          'unidade_padrao': unidadePadrao,
          'tipo': tipo,
        })
        .select()
        .single();

    return novo;
  }

    Future<Map<String, dynamic>?> buscarPorId(String id) async {
    final resultado = await _client
        .from('ingrediente')
        .select('id, nome, unidade_padrao, tipo')
        .eq('id', id)
        .maybeSingle();

    return resultado;
  }
}

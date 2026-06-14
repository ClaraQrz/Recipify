import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:recipify/services/supabase_service.dart';

class AuthService {
  static final AuthService instance = AuthService._internal();
  AuthService._internal();

  Map<String, dynamic>? _usuarioLogado;
  Map<String, dynamic>? get usuarioLogado => _usuarioLogado;
  bool get estaLogado => _usuarioLogado != null;

  final _client = SupabaseService.instance.client;

  String _hashSenha(String senha) {
    final bytes = utf8.encode(senha);
    return sha256.convert(bytes).toString();
  }

  Future<Map<String, dynamic>> cadastrar({
    required String apelido,
    required String email,
    required String senha,
    String? dataAniversario,
  }) async {
    final existente = await _client
        .from('usuario')
        .select('id')
        .eq('email', email)
        .maybeSingle();

    if (existente != null) {
      return {'sucesso': false, 'erro': 'E-mail já cadastrado.'};
    }

    final novoUsuario = await _client
        .from('usuario')
        .insert({
          'apelido': apelido,
          'email': email,
          'senha_hash': _hashSenha(senha),
          'eh_oficial': false,
          'tema': 'claro',
          'notif_vencimento': true,
          'notif_feed': true,
          'data_aniversario': dataAniversario,
        })
        .select()
        .single();

    _usuarioLogado = novoUsuario;
    return {'sucesso': true, 'usuario': novoUsuario};
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String senha,
  }) async {
    final resultado = await _client
        .from('usuario')
        .select()
        .eq('email', email)
        .eq('senha_hash', _hashSenha(senha))
        .maybeSingle();

    if (resultado == null) {
      return {'sucesso': false, 'erro': 'E-mail ou senha incorretos.'};
    }

    _usuarioLogado = resultado;
    return {'sucesso': true, 'usuario': resultado};
  }

  void logout() {
    _usuarioLogado = null;
  }
}

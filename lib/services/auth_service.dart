import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:recipify/services/database_service.dart';

class AuthService {
  static final AuthService instance = AuthService._internal();
  AuthService._internal();

  Map<String, dynamic>? _usuarioLogado;
  Map<String, dynamic>? get usuarioLogado => _usuarioLogado;
  bool get estaLogado => _usuarioLogado != null;

  String _hashSenha(String senha) {
    final bytes = utf8.encode(senha);
    return sha256.convert(bytes).toString();
  }

  String _gerarId() =>
      DateTime.now().millisecondsSinceEpoch.toString() +
      (1000 + (999 * (DateTime.now().microsecond / 1000000)).round()).toString();

  Future<Map<String, dynamic>> cadastrar({
    required String apelido,
    required String email,
    required String senha,
    String? dataAniversario,
  }) async {
    final db = await DatabaseService.instance.db;

    final existente = await db.query(
      'usuario',
      where: 'email = ?',
      whereArgs: [email],
    );

    if (existente.isNotEmpty) {
      return {'sucesso': false, 'erro': 'E-mail já cadastrado.'};
    }

    final usuario = {
      'id': _gerarId(),
      'apelido': apelido,
      'email': email,
      'senha_hash': _hashSenha(senha),
      'eh_oficial': 0,
      'tema': 'claro',
      'notif_vencimento': 1,
      'notif_feed': 1,
      'data_aniversario': dataAniversario,
      'criado_em': DateTime.now().toIso8601String(),
    };

    await db.insert('usuario', usuario);
    _usuarioLogado = usuario;
    return {'sucesso': true, 'usuario': usuario};
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String senha,
  }) async {
    final db = await DatabaseService.instance.db;

    final resultado = await db.query(
      'usuario',
      where: 'email = ? AND senha_hash = ?',
      whereArgs: [email, _hashSenha(senha)],
    );

    if (resultado.isEmpty) {
      return {'sucesso': false, 'erro': 'E-mail ou senha incorretos.'};
    }

    _usuarioLogado = resultado.first;
    return {'sucesso': true, 'usuario': resultado.first};
  }

  void logout() {
    _usuarioLogado = null;
  }
}

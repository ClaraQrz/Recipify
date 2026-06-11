import 'package:recipify/repositories/ingrediente_repository.dart';
import 'package:recipify/services/database_service.dart';
import 'package:sqflite/sqflite.dart';

class EstoqueRepository {
  static final EstoqueRepository instance = EstoqueRepository._internal();
  EstoqueRepository._internal();

  String _gerarId() => DateTime.now().microsecondsSinceEpoch.toString();

  Future<List<Map<String, dynamic>>> listarTodos(String usuarioId) async {
    final db = await DatabaseService.instance.db;
    final rows = await db.rawQuery('''
      SELECT id, ingrediente_id, quantidade, unidade, vencimento, alerta_lista, atualizado_em,
        CAST(julianday(vencimento) - julianday('now') AS INTEGER) AS dias_restantes
      FROM estoque
      WHERE usuario_id = ?
      ORDER BY vencimento ASC
    ''', [usuarioId]);

    return _enriquecerComIngrediente(rows);
  }

  Future<List<Map<String, dynamic>>> buscarPorNome(
    String usuarioId,
    String query,
  ) async {
    final todos = await listarTodos(usuarioId);
    final q = query.toLowerCase();
    return todos
        .where((i) =>
            (i['ingrediente'] as String).toLowerCase().contains(q))
        .toList();
  }

  Future<List<Map<String, dynamic>>> _enriquecerComIngrediente(
    List<Map<String, dynamic>> rows,
  ) async {
    if (rows.isEmpty) return [];

    final ids = rows.map((r) => r['ingrediente_id'] as String).toSet().toList();
    final ingredientes = <String, String>{};

    for (final id in ids) {
      final resultado = await IngredienteRepository.instance.buscarPorId(id);
      if (resultado != null) {
        ingredientes[id] = resultado['nome'] as String;
      }
    }

    return rows.map((r) {
      final map = Map<String, dynamic>.from(r);
      map['ingrediente'] =
          ingredientes[r['ingrediente_id'] as String] ?? 'Desconhecido';
      return map;
    }).toList();
  }

  Future<void> adicionar({
    required String usuarioId,
    required String ingredienteId,
    required double quantidade,
    required String unidade,
    String? vencimento,
  }) async {
    final db = await DatabaseService.instance.db;
    await db.insert(
      'estoque',
      {
        'id': _gerarId(),
        'usuario_id': usuarioId,
        'ingrediente_id': ingredienteId,
        'quantidade': quantidade,
        'unidade': unidade,
        'vencimento': vencimento,
        'alerta_lista': 0,
        'atualizado_em': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> atualizar({
    required String id,
    required double quantidade,
    required String unidade,
    String? vencimento,
  }) async {
    final db = await DatabaseService.instance.db;
    await db.update(
      'estoque',
      {
        'quantidade': quantidade,
        'unidade': unidade,
        'vencimento': vencimento,
        'atualizado_em': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deletar(String id) async {
    final db = await DatabaseService.instance.db;
    await db.delete('estoque', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> vencendoEmBreve(
    String usuarioId, {
    int diasAlerta = 7,
  }) async {
    final db = await DatabaseService.instance.db;
    final hoje = DateTime.now().toIso8601String();
    final limite =
        DateTime.now().add(Duration(days: diasAlerta)).toIso8601String();

    final rows = await db.rawQuery('''
      SELECT id, ingrediente_id, quantidade, unidade, vencimento,
        CAST(julianday(vencimento) - julianday('now') AS INTEGER) AS dias_restantes
      FROM estoque
      WHERE usuario_id = ?
        AND vencimento IS NOT NULL
        AND vencimento >= ?
        AND vencimento <= ?
      ORDER BY vencimento ASC
    ''', [usuarioId, hoje, limite]);

    return _enriquecerComIngrediente(rows);
  }

  /// Total de itens no estoque do usuário
  Future<int> contarItens(String usuarioId) async {
    final db = await DatabaseService.instance.db;
    final resultado = await db.rawQuery(
      'SELECT COUNT(*) as total FROM estoque WHERE usuario_id = ?',
      [usuarioId],
    );
    return Sqflite.firstIntValue(resultado) ?? 0;
  }
}

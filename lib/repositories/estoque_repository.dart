import 'package:recipify/services/database_service.dart';

class EstoqueRepository {
  static final EstoqueRepository instance = EstoqueRepository._internal();
  EstoqueRepository._internal();

  /// Itens vencendo nos próximos [diasAlerta] dias (SQLite local)
  Future<List<Map<String, dynamic>>> vencendoEmBreve(
    String usuarioId, {
    int diasAlerta = 7,
  }) async {
    final db = await DatabaseService.instance.db;

    final hoje   = DateTime.now();
    final limite = hoje.add(Duration(days: diasAlerta)).toIso8601String();
    final hojeStr = hoje.toIso8601String();

    final resultado = await db.rawQuery('''
      SELECT
        e.id,
        e.quantidade,
        e.unidade,
        e.vencimento,
        i.nome AS ingrediente,
        CAST(julianday(e.vencimento) - julianday(?) AS INTEGER) AS dias_restantes
      FROM estoque e
      JOIN ingrediente i ON i.id = e.ingrediente_id
      WHERE e.usuario_id = ?
        AND e.vencimento IS NOT NULL
        AND e.vencimento <= ?
        AND e.vencimento >= ?
      ORDER BY e.vencimento ASC
    ''', [hojeStr, usuarioId, limite, hojeStr]);

    return List<Map<String, dynamic>>.from(resultado);
  }
}

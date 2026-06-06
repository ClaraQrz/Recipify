import 'package:recipify/services/database_service.dart';

class ListaRepository {
  static final ListaRepository instance = ListaRepository._internal();
  ListaRepository._internal();

  /// Retorna a lista favorita do usuário com seus itens (SQLite local)
  Future<Map<String, dynamic>?> listaFavorita(String usuarioId) async {
    final db = await DatabaseService.instance.db;

    final listas = await db.query(
      'lista',
      where: 'dono_id = ? AND eh_favorita = 1',
      whereArgs: [usuarioId],
      limit: 1,
    );

    if (listas.isEmpty) return null;

    final lista = Map<String, dynamic>.from(listas.first);

    final itens = await db.rawQuery('''
      SELECT
        li.id,
        li.quantidade,
        li.unidade,
        li.comprado,
        i.nome AS ingrediente
      FROM lista_item li
      JOIN ingrediente i ON i.id = li.ingrediente_id
      WHERE li.lista_id = ?
      ORDER BY li.comprado ASC, li.criado_em ASC
    ''', [lista['id']]);

    lista['itens'] = List<Map<String, dynamic>>.from(itens);
    return lista;
  }
}

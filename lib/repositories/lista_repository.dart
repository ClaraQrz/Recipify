import 'package:recipify/services/database_service.dart';

class ListaRepository {
  static final ListaRepository instance = ListaRepository._internal();
  ListaRepository._internal();

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

    final itens = await db.query(
      'lista_item_livre',
      where: 'lista_id = ?',
      whereArgs: [lista['id']],
      orderBy: 'criado_em ASC',
    );

    lista['itens'] = List<Map<String, dynamic>>.from(itens);
    return lista;
  }

  Future<void> definirFavorita(
    String usuarioId,
    String listaId,
  ) async {
    final db = await DatabaseService.instance.db;

    // remove favorita atual
    await db.update(
      'lista',
      {'eh_favorita': 0},
      where: 'dono_id = ?',
      whereArgs: [usuarioId],
    );

    // marca a nova favorita
    await db.update(
      'lista',
      {'eh_favorita': 1},
      where: 'id = ?',
      whereArgs: [listaId],
    );
  }

  Future<List<Map<String, dynamic>>> todasAsListas(String usuarioId) async {
    final db = await DatabaseService.instance.db;

    final listas = await db.query(
      'lista',
      where: 'dono_id = ?',
      whereArgs: [usuarioId],
      orderBy: 'criado_em DESC',
    );

    final result = <Map<String, dynamic>>[];

    for (final lista in listas) {
      final itens = await db.query(
        'lista_item_livre',
        where: 'lista_id = ?',
        whereArgs: [lista['id']],
        orderBy: 'criado_em ASC',
      );

      result.add({
        ...lista,
        'itens': List<Map<String, dynamic>>.from(itens),
      });
    }

    return result;
  }

  Future<List<Map<String, dynamic>>> itensDaLista(String listaId) async {
    final db = await DatabaseService.instance.db;
    return await db.query(
      'lista_item_livre',
      where: 'lista_id = ?',
      whereArgs: [listaId],
      orderBy: 'criado_em ASC',
    );
  }

  Future<String> criarLista({
    required String usuarioId,
    required String nome,
  }) async {
    final db = await DatabaseService.instance.db;
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    await db.insert('lista', {
      'id': id,
      'dono_id': usuarioId,
      'nome': nome,
      'cor': '#D4572A',
      'eh_favorita': 0,
      'criado_em': DateTime.now().toIso8601String(),
    });
    return id;
  }

  Future<void> adicionarItem({
    required String listaId,
    required String nome,
    required String quantidade,
  }) async {
    final db = await DatabaseService.instance.db;
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    await db.insert('lista_item_livre', {
      'id': id,
      'lista_id': listaId,
      'nome': nome,
      'quantidade': quantidade,
      'comprado': 0,
      'criado_em': DateTime.now().toIso8601String(),
    });
  }

  Future<void> toggleItem(String itemId, bool comprado) async {
    final db = await DatabaseService.instance.db;
    await db.update(
      'lista_item_livre',
      {'comprado': comprado ? 1 : 0},
      where: 'id = ?',
      whereArgs: [itemId],
    );
  }

  // NOVO: deleta um item da lista
  Future<void> deletarItem(String itemId) async {
    final db = await DatabaseService.instance.db;
    await db.delete(
      'lista_item_livre',
      where: 'id = ?',
      whereArgs: [itemId],
    );
  }

  // NOVO: deleta a lista e todos os seus itens
  Future<void> deletarLista(String listaId) async {
    final db = await DatabaseService.instance.db;
    await db.delete(
      'lista_item_livre',
      where: 'lista_id = ?',
      whereArgs: [listaId],
    );
    await db.delete(
      'lista',
      where: 'id = ?',
      whereArgs: [listaId],
    );
  }
}
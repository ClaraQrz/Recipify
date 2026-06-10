import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._internal();
  DatabaseService._internal();

  static Database? _db;

  Future<Database> get db async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), 'recipify.db');
    return openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await _criarTabelas(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Adiciona tabela lista_item_livre se vier de versão antiga
      await db.execute('''
        CREATE TABLE IF NOT EXISTS lista_item_livre (
          id TEXT PRIMARY KEY,
          lista_id TEXT NOT NULL,
          nome TEXT NOT NULL,
          quantidade TEXT NOT NULL,
          comprado INTEGER NOT NULL DEFAULT 0,
          criado_em TEXT NOT NULL,
          FOREIGN KEY (lista_id) REFERENCES lista(id)
        )
      ''');
    }
  }

  Future<void> _criarTabelas(Database db) async {
    await db.execute('''
      CREATE TABLE ingrediente (
        id TEXT PRIMARY KEY,
        nome TEXT NOT NULL UNIQUE,
        unidade_padrao TEXT NOT NULL,
        tipo TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE lista (
        id TEXT PRIMARY KEY,
        dono_id TEXT NOT NULL,
        nome TEXT NOT NULL,
        cor TEXT NOT NULL DEFAULT '#D4572A',
        eh_favorita INTEGER NOT NULL DEFAULT 0,
        criado_em TEXT NOT NULL
      )
    ''');

    // Tabela livre — itens com nome e quantidade como texto
    await db.execute('''
      CREATE TABLE lista_item_livre (
        id TEXT PRIMARY KEY,
        lista_id TEXT NOT NULL,
        nome TEXT NOT NULL,
        quantidade TEXT NOT NULL,
        comprado INTEGER NOT NULL DEFAULT 0,
        criado_em TEXT NOT NULL,
        FOREIGN KEY (lista_id) REFERENCES lista(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE estoque (
        id TEXT PRIMARY KEY,
        usuario_id TEXT NOT NULL,
        ingrediente_id TEXT NOT NULL,
        quantidade REAL NOT NULL,
        unidade TEXT NOT NULL,
        vencimento TEXT,
        alerta_lista INTEGER NOT NULL DEFAULT 0,
        atualizado_em TEXT NOT NULL,
        UNIQUE(usuario_id, ingrediente_id),
        FOREIGN KEY (ingrediente_id) REFERENCES ingrediente(id)
      )
    ''');
  }
}

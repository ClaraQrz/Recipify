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
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE usuario (
        id TEXT PRIMARY KEY,
        apelido TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        senha_hash TEXT NOT NULL,
        foto_url TEXT,
        eh_oficial INTEGER NOT NULL DEFAULT 0,
        tema TEXT NOT NULL DEFAULT 'claro',
        notif_vencimento INTEGER NOT NULL DEFAULT 1,
        notif_feed INTEGER NOT NULL DEFAULT 1,
        data_aniversario TEXT,
        criado_em TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE receita (
        id TEXT PRIMARY KEY,
        autor_id TEXT NOT NULL,
        titulo TEXT NOT NULL,
        descricao TEXT,
        tempo_minutos INTEGER,
        porcoes INTEGER,
        categoria TEXT,
        imagem_url TEXT,
        publicada INTEGER NOT NULL DEFAULT 0,
        media_estrelas REAL NOT NULL DEFAULT 0,
        total_avaliacoes INTEGER NOT NULL DEFAULT 0,
        criado_em TEXT NOT NULL,
        FOREIGN KEY (autor_id) REFERENCES usuario(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE ingrediente (
        id TEXT PRIMARY KEY,
        nome TEXT NOT NULL UNIQUE,
        unidade_padrao TEXT NOT NULL,
        tipo TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE receita_ingrediente (
        receita_id TEXT NOT NULL,
        ingrediente_id TEXT NOT NULL,
        quantidade REAL NOT NULL,
        unidade TEXT NOT NULL,
        PRIMARY KEY (receita_id, ingrediente_id),
        FOREIGN KEY (receita_id) REFERENCES receita(id),
        FOREIGN KEY (ingrediente_id) REFERENCES ingrediente(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE avaliacao (
        id TEXT PRIMARY KEY,
        receita_id TEXT NOT NULL,
        usuario_id TEXT NOT NULL,
        estrelas INTEGER NOT NULL,
        comentario TEXT,
        criado_em TEXT NOT NULL,
        UNIQUE(receita_id, usuario_id),
        FOREIGN KEY (receita_id) REFERENCES receita(id),
        FOREIGN KEY (usuario_id) REFERENCES usuario(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE favorito (
        usuario_id TEXT NOT NULL,
        receita_id TEXT NOT NULL,
        salvo_em TEXT NOT NULL,
        PRIMARY KEY (usuario_id, receita_id),
        FOREIGN KEY (usuario_id) REFERENCES usuario(id),
        FOREIGN KEY (receita_id) REFERENCES receita(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE lista (
        id TEXT PRIMARY KEY,
        dono_id TEXT NOT NULL,
        nome TEXT NOT NULL,
        cor TEXT NOT NULL DEFAULT '#D4572A',
        eh_favorita INTEGER NOT NULL DEFAULT 0,
        criado_em TEXT NOT NULL,
        FOREIGN KEY (dono_id) REFERENCES usuario(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE lista_item (
        id TEXT PRIMARY KEY,
        lista_id TEXT NOT NULL,
        ingrediente_id TEXT NOT NULL,
        quantidade REAL NOT NULL,
        unidade TEXT NOT NULL,
        comprado INTEGER NOT NULL DEFAULT 0,
        criado_em TEXT NOT NULL,
        FOREIGN KEY (lista_id) REFERENCES lista(id),
        FOREIGN KEY (ingrediente_id) REFERENCES ingrediente(id)
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
        FOREIGN KEY (usuario_id) REFERENCES usuario(id),
        FOREIGN KEY (ingrediente_id) REFERENCES ingrediente(id)
      )
    ''');
  }
}

import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import '../models/pesanan.dart';

class DatabaseHelper {
  DatabaseHelper._internal();

  static final DatabaseHelper instance =
      DatabaseHelper._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final lokasiDatabase = path.join(
      await getDatabasesPath(),
      'kantin_kampus.db',
    );

    return await openDatabase(
      lokasiDatabase,
      version: 1,
      onCreate: (db, version) async {
        await _buatTabel(db);
      },
      onOpen: (db) async {
        await _buatTabel(db);
      },
    );
  }

  Future<void> _buatTabel(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS pesanan (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ringkasan_item TEXT NOT NULL,
        total_item INTEGER NOT NULL,
        total_harga INTEGER NOT NULL,
        tanggal TEXT NOT NULL
      )
    ''');
  }

  Future<int> tambahPesanan(Pesanan pesanan) async {
    final db = await database;

    return await db.insert(
      'pesanan',
      pesanan.toMap(),
    );
  }

  Future<List<Pesanan>> ambilSemuaPesanan() async {
    final db = await database;

    final hasil = await db.query(
      'pesanan',
      orderBy: 'id DESC',
    );

    return hasil.map((baris) {
      return Pesanan.fromMap(baris);
    }).toList();
  }

  Future<int> ubahPesanan(Pesanan pesanan) async {
    final db = await database;

    return await db.update(
      'pesanan',
      pesanan.toMap(),
      where: 'id = ?',
      whereArgs: [pesanan.id],
    );
  }

  Future<int> hapusPesanan(int id) async {
    final db = await database;

    return await db.delete(
      'pesanan',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

import 'dart:convert';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/bazar_item.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('bazar_talika.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE items ADD COLUMN originalCreatedAt TEXT',
          );
          // Initialize originalCreatedAt with createdAt for existing items
          await db.execute('UPDATE items SET originalCreatedAt = createdAt');
        }
        if (oldVersion < 3) {
          await db.execute(
            'ALTER TABLE items ADD COLUMN isArchived INTEGER NOT NULL DEFAULT 0',
          );
        }
      },
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
CREATE TABLE items (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  price REAL,
  category TEXT,
  isBought INTEGER NOT NULL,
  isArchived INTEGER NOT NULL DEFAULT 0,
  createdAt TEXT NOT NULL,
  originalCreatedAt TEXT
)
''');
  }

  Future<int> insertItem(BazarItem item) async {
    final db = await instance.database;
    final map = item.toJson();
    if (map['category'] != null) {
      map['category'] = jsonEncode(map['category']);
    }
    return await db.insert('items', map);
  }

  Future<List<BazarItem>> getAllItems() async {
    final db = await instance.database;
    final maps = await db.query('items', orderBy: 'createdAt ASC');

    return maps.map((map) {
      final mutableMap = Map<String, dynamic>.from(map);
      if (mutableMap['category'] != null) {
        mutableMap['category'] = jsonDecode(mutableMap['category'] as String);
      }
      return BazarItem.fromJson(mutableMap);
    }).toList();
  }

  Future<int> updateItem(BazarItem item) async {
    final db = await instance.database;
    final map = item.toJson();
    if (map['category'] != null) {
      map['category'] = jsonEncode(map['category']);
    }
    return db.update('items', map, where: 'id = ?', whereArgs: [item.id]);
  }

  Future<int> deleteItem(int id) async {
    final db = await instance.database;
    return await db.delete('items', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteAllItems() async {
    final db = await instance.database;
    return await db.delete('items', where: 'isArchived = 0');
  }

  Future<int> archiveAllItems() async {
    final db = await instance.database;
    return await db.update('items', {'isArchived': 1}, where: 'isArchived = 0');
  }

  Future<int> deleteArchivedItems() async {
    final db = await instance.database;
    return await db.delete('items', where: 'isArchived = 1');
  }
}

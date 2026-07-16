import 'dart:convert';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/bazar_item.dart';
import '../models/bazar_list.dart';

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
      version: 4,
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
        if (oldVersion < 4) {
          await db.execute('''
          CREATE TABLE lists (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            isArchived INTEGER NOT NULL DEFAULT 0,
            createdAt TEXT NOT NULL
          )
          ''');

          await db.execute('ALTER TABLE items ADD COLUMN listId INTEGER');

          // Create a default list
          final defaultListId = await db.insert('lists', {
            'name': 'আমার তালিকা',
            'isArchived': 0,
            'createdAt': DateTime.now().toIso8601String(),
          });

          // Assign existing items to the default list (unarchived)
          await db.execute('UPDATE items SET listId = ? WHERE isArchived = 0', [
            defaultListId,
          ]);

          // Create an archived list for old archived items
          final archivedListId = await db.insert('lists', {
            'name': 'পুরোনো আর্কাইভ',
            'isArchived': 1,
            'createdAt': DateTime.now().toIso8601String(),
          });

          await db.execute('UPDATE items SET listId = ? WHERE isArchived = 1', [
            archivedListId,
          ]);
        }
      },
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
CREATE TABLE lists (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  isArchived INTEGER NOT NULL DEFAULT 0,
  createdAt TEXT NOT NULL
)
''');

    await db.execute('''
CREATE TABLE items (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  listId INTEGER,
  name TEXT NOT NULL,
  price REAL,
  category TEXT,
  isBought INTEGER NOT NULL,
  isArchived INTEGER NOT NULL DEFAULT 0,
  createdAt TEXT NOT NULL,
  originalCreatedAt TEXT,
  FOREIGN KEY (listId) REFERENCES lists (id) ON DELETE CASCADE
)
''');

    // Create a default list
    await db.insert('lists', {
      'name': 'আমার তালিকা',
      'isArchived': 0,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  // List Operations
  Future<int> insertList(BazarList list) async {
    final db = await instance.database;
    return await db.insert('lists', list.toJson());
  }

  Future<List<BazarList>> getAllLists({bool includeArchived = false}) async {
    final db = await instance.database;
    final where = includeArchived ? null : 'isArchived = 0';
    final maps = await db.query(
      'lists',
      where: where,
      orderBy: 'createdAt DESC',
    );
    return maps.map((map) => BazarList.fromJson(map)).toList();
  }

  Future<BazarList?> getList(int id) async {
    final db = await instance.database;
    final maps = await db.query('lists', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return BazarList.fromJson(maps.first);
    }
    return null;
  }

  Future<int> updateList(BazarList list) async {
    final db = await instance.database;
    return db.update(
      'lists',
      list.toJson(),
      where: 'id = ?',
      whereArgs: [list.id],
    );
  }

  Future<int> deleteList(int id) async {
    final db = await instance.database;
    // Delete items in the list too since we don't have CASCADE enabled if foreign keys are off by default
    await db.delete('items', where: 'listId = ?', whereArgs: [id]);
    return await db.delete('lists', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> archiveList(int id) async {
    final db = await instance.database;
    await db.update(
      'lists',
      {'isArchived': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
    return await db.update(
      'items',
      {'isArchived': 1},
      where: 'listId = ?',
      whereArgs: [id],
    );
  }

  Future<int> assignNullListId(int listId) async {
    final db = await instance.database;
    return db.update('items', {'listId': listId}, where: 'listId IS NULL');
  }

  Future<int> insertItem(BazarItem item) async {
    final db = await instance.database;
    final map = item.toJson();
    if (map['category'] != null) {
      map['category'] = jsonEncode(map['category']);
    }
    return await db.insert('items', map);
  }

  Future<List<BazarItem>> getAllItems({int? listId}) async {
    final db = await instance.database;
    final where = listId != null ? 'listId = ?' : null;
    final whereArgs = listId != null ? [listId] : null;
    final maps = await db.query(
      'items',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'createdAt ASC',
    );

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

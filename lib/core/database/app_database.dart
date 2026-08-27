import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// 앱 전역에서 공유하는 SQLite 연결 (categories, ledgers 테이블 포함).
/// 각 feature의 Service는 이 인스턴스를 통해서만 DB에 접근합니다.
class AppDatabase {
  AppDatabase._internal();

  static final AppDatabase instance = AppDatabase._internal();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'moeda.db');

    return openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE categories (
            id INTEGER PRIMARY KEY,
            name TEXT NOT NULL,
            type TEXT NOT NULL,
            parentId TEXT,
            displayOrder INTEGER NOT NULL,
            colorHex TEXT,
            iconName TEXT,
            isSystem INTEGER NOT NULL,
            isActive INTEGER NOT NULL,
            createdAt TEXT NOT NULL,
            updatedAt TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE ledgers (
            id TEXT PRIMARY KEY,
            amount REAL NOT NULL,
            title TEXT NOT NULL,
            date TEXT NOT NULL,
            categoryId INTEGER NOT NULL
          )
        ''');

        await _createBudgetAndGoalTables(db);
        await _createAssetTable(db);

        final now = DateTime.now().toIso8601String();
        await db.insert('categories', {
          'id': 1,
          'name': '식비',
          'type': 'expense',
          'parentId': null,
          'displayOrder': 0,
          'colorHex': null,
          'iconName': null,
          'isSystem': 0,
          'isActive': 1,
          'createdAt': now,
          'updatedAt': now,
        });
        await db.insert('categories', {
          'id': 2,
          'name': '급여',
          'type': 'income',
          'parentId': null,
          'displayOrder': 1,
          'colorHex': null,
          'iconName': null,
          'isSystem': 0,
          'isActive': 1,
          'createdAt': now,
          'updatedAt': now,
        });
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createBudgetAndGoalTables(db);
        }
        if (oldVersion < 3) {
          await _createAssetTable(db);
        }
      },
    );
  }

  Future<void> _createAssetTable(Database db) async {
    await db.execute('''
      CREATE TABLE assets (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createBudgetAndGoalTables(Database db) async {
    await db.execute('''
      CREATE TABLE budgets (
        id INTEGER PRIMARY KEY,
        yearMonth TEXT NOT NULL UNIQUE,
        amount REAL NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE goals (
        id INTEGER PRIMARY KEY,
        title TEXT NOT NULL,
        targetAmount REAL NOT NULL,
        currentAmount REAL NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');
  }
}

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// 앱 전역에서 공유하는 SQLite 연결 (categories, ledgers 테이블 포함).
/// 각 feature의 Service는 이 인스턴스를 통해서만 DB에 접근합니다.
///
/// 금액 컬럼(amount, targetAmount, currentAmount)은 스키마 v4부터
/// 부동소수점 오차를 피하기 위해 원 단위 INTEGER로 저장합니다.
class AppDatabase {
  AppDatabase._internal();

  static final AppDatabase instance = AppDatabase._internal();

  /// 현재 스키마 버전.
  /// - v2: budgets, goals 추가
  /// - v3: assets 추가
  /// - v4: 금액 컬럼 REAL → INTEGER(원 단위) 전환
  static const int schemaVersion = 4;

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
      version: schemaVersion,
      onCreate: onCreate,
      onUpgrade: onUpgrade,
    );
  }

  @visibleForTesting
  static Future<void> onCreate(Database db, int version) async {
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

    await _createLedgerTable(db);
    await _createBudgetTable(db);
    await _createGoalTable(db);
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
  }

  @visibleForTesting
  static Future<void> onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await _createBudgetTable(db);
      await _createGoalTable(db);
    }
    if (oldVersion < 3) {
      await _createAssetTable(db);
    }
    if (oldVersion < 4) {
      await _migrateMoneyColumnsToInteger(db);
    }
  }

  /// v4: REAL로 저장되던 금액을 원 단위 INTEGER로 변환한다.
  /// SQLite는 컬럼 타입 변경(ALTER COLUMN)을 지원하지 않으므로
  /// 새 테이블 생성 → 반올림 복사 → 기존 테이블 삭제 → 이름 변경 순서로 재구성한다.
  /// onUpgrade는 트랜잭션 안에서 실행되므로 중간에 실패하면 전체가 롤백된다.
  static Future<void> _migrateMoneyColumnsToInteger(Database db) async {
    await _rebuildTable(
      db,
      table: 'ledgers',
      create: _createLedgerTable,
      columns: const ['id', 'amount', 'title', 'date', 'categoryId'],
      moneyColumns: const {'amount'},
    );
    await _rebuildTable(
      db,
      table: 'budgets',
      create: _createBudgetTable,
      columns: const ['id', 'yearMonth', 'amount', 'createdAt', 'updatedAt'],
      moneyColumns: const {'amount'},
    );
    await _rebuildTable(
      db,
      table: 'goals',
      create: _createGoalTable,
      columns: const [
        'id',
        'title',
        'targetAmount',
        'currentAmount',
        'createdAt',
        'updatedAt',
      ],
      moneyColumns: const {'targetAmount', 'currentAmount'},
    );
    await _rebuildTable(
      db,
      table: 'assets',
      create: _createAssetTable,
      columns: const ['id', 'name', 'type', 'amount', 'createdAt', 'updatedAt'],
      moneyColumns: const {'amount'},
    );
  }

  static Future<void> _rebuildTable(
    Database db, {
    required String table,
    required Future<void> Function(Database db, {String? table}) create,
    required List<String> columns,
    required Set<String> moneyColumns,
  }) async {
    final tmp = '${table}_v4';
    await create(db, table: tmp);
    final select = columns
        .map((c) =>
            moneyColumns.contains(c) ? 'CAST(ROUND($c) AS INTEGER)' : c)
        .join(', ');
    await db.execute(
      'INSERT INTO $tmp (${columns.join(', ')}) SELECT $select FROM $table',
    );
    await db.execute('DROP TABLE $table');
    await db.execute('ALTER TABLE $tmp RENAME TO $table');
  }

  static Future<void> _createLedgerTable(Database db, {String? table}) async {
    await db.execute('''
      CREATE TABLE ${table ?? 'ledgers'} (
        id TEXT PRIMARY KEY,
        amount INTEGER NOT NULL,
        title TEXT NOT NULL,
        date TEXT NOT NULL,
        categoryId INTEGER NOT NULL
      )
    ''');
  }

  static Future<void> _createAssetTable(Database db, {String? table}) async {
    await db.execute('''
      CREATE TABLE ${table ?? 'assets'} (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        amount INTEGER NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');
  }

  static Future<void> _createBudgetTable(Database db, {String? table}) async {
    await db.execute('''
      CREATE TABLE ${table ?? 'budgets'} (
        id INTEGER PRIMARY KEY,
        yearMonth TEXT NOT NULL UNIQUE,
        amount INTEGER NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');
  }

  static Future<void> _createGoalTable(Database db, {String? table}) async {
    await db.execute('''
      CREATE TABLE ${table ?? 'goals'} (
        id INTEGER PRIMARY KEY,
        title TEXT NOT NULL,
        targetAmount INTEGER NOT NULL,
        currentAmount INTEGER NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');
  }
}

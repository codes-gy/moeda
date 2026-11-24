// AppDatabase 스키마 생성/마이그레이션 검증.
// 실제 기기 없이 sqflite_common_ffi로 데스크톱 SQLite를 사용한다.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:moeda/core/database/app_database.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// 마이그레이션 이전(v3) 스키마. 금액이 REAL로 저장되던 시절의 정의를 그대로 둔다.
Future<void> _createV3Schema(Database db, int version) async {
  await db.execute('''
    CREATE TABLE categories (
      id INTEGER PRIMARY KEY, name TEXT NOT NULL, type TEXT NOT NULL,
      parentId TEXT, displayOrder INTEGER NOT NULL, colorHex TEXT,
      iconName TEXT, isSystem INTEGER NOT NULL, isActive INTEGER NOT NULL,
      createdAt TEXT NOT NULL, updatedAt TEXT NOT NULL
    )
  ''');
  await db.execute('''
    CREATE TABLE ledgers (
      id TEXT PRIMARY KEY, amount REAL NOT NULL, title TEXT NOT NULL,
      date TEXT NOT NULL, categoryId INTEGER NOT NULL
    )
  ''');
  await db.execute('''
    CREATE TABLE budgets (
      id INTEGER PRIMARY KEY, yearMonth TEXT NOT NULL UNIQUE,
      amount REAL NOT NULL, createdAt TEXT NOT NULL, updatedAt TEXT NOT NULL
    )
  ''');
  await db.execute('''
    CREATE TABLE goals (
      id INTEGER PRIMARY KEY, title TEXT NOT NULL, targetAmount REAL NOT NULL,
      currentAmount REAL NOT NULL, createdAt TEXT NOT NULL,
      updatedAt TEXT NOT NULL
    )
  ''');
  await db.execute('''
    CREATE TABLE assets (
      id INTEGER PRIMARY KEY, name TEXT NOT NULL, type TEXT NOT NULL,
      amount REAL NOT NULL, createdAt TEXT NOT NULL, updatedAt TEXT NOT NULL
    )
  ''');
}

Future<String> _columnType(Database db, String table, String column) async {
  final info = await db.rawQuery('PRAGMA table_info($table)');
  return info.firstWhere((c) => c['name'] == column)['type'] as String;
}

void main() {
  late Directory tempDir;
  late String dbPath;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('moeda_db_test');
    dbPath = p.join(tempDir.path, 'moeda.db');
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  Future<Database> openCurrent() {
    return databaseFactoryFfi.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: AppDatabase.schemaVersion,
        onCreate: AppDatabase.onCreate,
        onUpgrade: AppDatabase.onUpgrade,
      ),
    );
  }

  test('신규 설치 시 금액 컬럼은 INTEGER로 생성되고 기본 카테고리가 들어간다', () async {
    final db = await openCurrent();

    expect(await db.getVersion(), AppDatabase.schemaVersion);
    expect(await _columnType(db, 'ledgers', 'amount'), 'INTEGER');
    expect(await _columnType(db, 'budgets', 'amount'), 'INTEGER');
    expect(await _columnType(db, 'goals', 'targetAmount'), 'INTEGER');
    expect(await _columnType(db, 'goals', 'currentAmount'), 'INTEGER');
    expect(await _columnType(db, 'assets', 'amount'), 'INTEGER');
    expect(await db.query('categories'), hasLength(2));

    await db.close();
  });

  test('v3 → v4 마이그레이션은 REAL 금액을 원 단위 INTEGER로 반올림해 보존한다', () async {
    final legacy = await databaseFactoryFfi.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(version: 3, onCreate: _createV3Schema),
    );
    const now = '2026-08-01T00:00:00.000';
    await legacy.insert('ledgers', {
      'id': 'a',
      'amount': -12000.4,
      'title': '점심',
      'date': now,
      'categoryId': 1,
    });
    await legacy.insert('ledgers', {
      'id': 'b',
      'amount': 3000000.5,
      'title': '월급',
      'date': now,
      'categoryId': 2,
    });
    await legacy.insert('budgets', {
      'id': 1,
      'yearMonth': '2026-08',
      'amount': 1000000.0,
      'createdAt': now,
      'updatedAt': now,
    });
    await legacy.insert('goals', {
      'id': 1,
      'title': '비상금',
      'targetAmount': 5000000.0,
      'currentAmount': 1234.6,
      'createdAt': now,
      'updatedAt': now,
    });
    await legacy.insert('assets', {
      'id': 1,
      'name': '예금',
      'type': 'asset',
      'amount': 0.1 + 0.2,
      'createdAt': now,
      'updatedAt': now,
    });
    await legacy.close();

    final db = await openCurrent();

    expect(await db.getVersion(), AppDatabase.schemaVersion);
    expect(await _columnType(db, 'ledgers', 'amount'), 'INTEGER');

    final ledgers = await db.query('ledgers', orderBy: 'id');
    expect(ledgers.map((r) => r['amount']), [-12000, 3000001]);
    expect(ledgers.every((r) => r['amount'] is int), isTrue);
    expect(ledgers.first['title'], '점심');
    expect(ledgers.first['categoryId'], 1);

    final budget = (await db.query('budgets')).single;
    expect(budget['amount'], 1000000);
    expect(budget['yearMonth'], '2026-08');

    final goal = (await db.query('goals')).single;
    expect(goal['targetAmount'], 5000000);
    expect(goal['currentAmount'], 1235);

    final asset = (await db.query('assets')).single;
    expect(asset['amount'], 0);

    // 저장된 값의 실제 타입도 integer인지 확인 (컬럼 선언만 바뀐 게 아닌지)
    final types = await db.rawQuery(
      'SELECT DISTINCT typeof(amount) AS t FROM ledgers',
    );
    expect(types.single['t'], 'integer');

    // budgets.yearMonth UNIQUE 제약이 재구성 후에도 유지되는지
    await expectLater(
      db.insert('budgets', {
        'id': 2,
        'yearMonth': '2026-08',
        'amount': 1,
        'createdAt': now,
        'updatedAt': now,
      }),
      throwsA(isA<DatabaseException>()),
    );

    await db.close();
  });

  test('v1 → v4 업그레이드도 누락 테이블을 만들고 INTEGER 스키마로 끝난다', () async {
    final legacy = await databaseFactoryFfi.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE categories (
              id INTEGER PRIMARY KEY, name TEXT NOT NULL, type TEXT NOT NULL,
              parentId TEXT, displayOrder INTEGER NOT NULL, colorHex TEXT,
              iconName TEXT, isSystem INTEGER NOT NULL,
              isActive INTEGER NOT NULL, createdAt TEXT NOT NULL,
              updatedAt TEXT NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE ledgers (
              id TEXT PRIMARY KEY, amount REAL NOT NULL, title TEXT NOT NULL,
              date TEXT NOT NULL, categoryId INTEGER NOT NULL
            )
          ''');
        },
      ),
    );
    await legacy.insert('ledgers', {
      'id': 'x',
      'amount': 999.9,
      'title': '커피',
      'date': '2026-08-01T00:00:00.000',
      'categoryId': 1,
    });
    await legacy.close();

    final db = await openCurrent();
    expect(await _columnType(db, 'budgets', 'amount'), 'INTEGER');
    expect(await _columnType(db, 'assets', 'amount'), 'INTEGER');
    expect((await db.query('ledgers')).single['amount'], 1000);
    await db.close();
  });
}

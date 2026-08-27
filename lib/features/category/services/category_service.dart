import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../models/category.dart';

class CategoryService {
  Category _fromMap(Map<String, Object?> map) {
    return Category(
      id: map['id'] as int,
      name: map['name'] as String,
      type: CategoryType.values.firstWhere((t) => t.name == map['type']),
      parentId: map['parentId'] as String?,
      displayOrder: map['displayOrder'] as int,
      colorHex: map['colorHex'] as String?,
      iconName: map['iconName'] as String?,
      isSystem: (map['isSystem'] as int) == 1,
      isActive: (map['isActive'] as int) == 1,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  Map<String, Object?> _toMap(Category category) {
    return {
      'id': category.id,
      'name': category.name,
      'type': category.type.name,
      'parentId': category.parentId,
      'displayOrder': category.displayOrder,
      'colorHex': category.colorHex,
      'iconName': category.iconName,
      'isSystem': category.isSystem ? 1 : 0,
      'isActive': category.isActive ? 1 : 0,
      'createdAt': category.createdAt.toIso8601String(),
      'updatedAt': category.updatedAt.toIso8601String(),
    };
  }

  /// 카테고리 전체 목록 조회 (CategoryController의 loadCategories에서 호출)
  Future<List<Category>> fetchCategories() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('categories', orderBy: 'displayOrder ASC');
    return rows.map(_fromMap).toList();
  }

  /// 카테고리 추가 (CategoryController의 addCategory에서 호출)
  Future<Category> addCategory(
    String name, {
    CategoryType type = CategoryType.expense,
    String? parentId,
    String? colorHex,
    String? iconName,
  }) async {
    final db = await AppDatabase.instance.database;
    final count = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM categories'),
        ) ??
        0;

    final newCategory = Category(
      id: DateTime.now().millisecondsSinceEpoch,
      name: name,
      type: type,
      parentId: parentId,
      displayOrder: count,
      colorHex: colorHex,
      iconName: iconName,
      isSystem: false,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await db.insert('categories', _toMap(newCategory));
    return newCategory;
  }

  /// 카테고리 삭제 (CategoryController의 deleteCategory에서 호출)
  Future<void> deleteCategory(int id) async {
    final db = await AppDatabase.instance.database;
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }
}

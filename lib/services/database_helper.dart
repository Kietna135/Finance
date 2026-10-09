import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/category_model.dart';
import '../models/expense_item.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('expenses.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const textNullable = 'TEXT';
    const realType = 'REAL NOT NULL';

    await db.execute('''
      CREATE TABLE expenses (
        id $idType,
        merchant $textType,
        amount $realType,
        date $textType,
        category $textType,
        receiptImagePath $textNullable,
        rawOcrText $textNullable,
        note $textNullable,
        createdAt $textType
      )
    ''');

    // Khởi tạo một vài dữ liệu mẫu cho sinh viên kiểm thử
    await _insertSampleData(db);
  }

  Future<void> _insertSampleData(Database db) async {
    final now = DateTime.now();
    final sampleExpenses = [
      ExpenseItem(
        id: 'sample_1',
        merchant: 'WinMart Vincom',
        amount: 185000,
        date: now.subtract(const Duration(days: 0)),
        category: ExpenseCategory.food,
        note: 'Mua thực phẩm tuần này',
      ),
      ExpenseItem(
        id: 'sample_2',
        merchant: 'Nhà sách Fahasa',
        amount: 240000,
        date: now.subtract(const Duration(days: 1)),
        category: ExpenseCategory.education,
        note: 'Giáo trình lập trình di động & sổ tay',
      ),
      ExpenseItem(
        id: 'sample_3',
        merchant: 'Grab Bike',
        amount: 45000,
        date: now.subtract(const Duration(days: 2)),
        category: ExpenseCategory.travel,
        note: 'Di chuyển đến trường',
      ),
      ExpenseItem(
        id: 'sample_4',
        merchant: 'Thế Giới Di Động',
        amount: 350000,
        date: now.subtract(const Duration(days: 3)),
        category: ExpenseCategory.devices,
        note: 'Chuột không dây Logitech',
      ),
      ExpenseItem(
        id: 'sample_5',
        merchant: 'CGV Cinemas',
        amount: 130000,
        date: now.subtract(const Duration(days: 4)),
        category: ExpenseCategory.entertainment,
        note: 'Vé xem phim cuối tuần',
      ),
      ExpenseItem(
        id: 'sample_6',
        merchant: 'Highlands Coffee',
        amount: 65000,
        date: now.subtract(const Duration(days: 5)),
        category: ExpenseCategory.food,
        note: 'Học nhóm đồ án',
      ),
    ];

    for (final exp in sampleExpenses) {
      await db.insert('expenses', exp.toMap());
    }
  }

  // --- CRUD OPERATIONS ---

  Future<int> insertExpense(ExpenseItem item) async {
    final db = await database;
    return await db.insert(
      'expenses',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ExpenseItem>> getAllExpenses() async {
    final db = await database;
    final result = await db.query(
      'expenses',
      orderBy: 'date DESC, createdAt DESC',
    );
    return result.map((map) => ExpenseItem.fromMap(map)).toList();
  }

  Future<ExpenseItem?> getExpenseById(String id) async {
    final db = await database;
    final result = await db.query(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (result.isNotEmpty) {
      return ExpenseItem.fromMap(result.first);
    }
    return null;
  }

  Future<int> updateExpense(ExpenseItem item) async {
    final db = await database;
    return await db.update(
      'expenses',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> deleteExpense(String id) async {
    final db = await database;
    return await db.delete(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- THỐNG KÊ PHỤC VỤ CUSTOM PAINTER ---

  /// Tính tổng chi tiêu theo từng danh mục
  Future<Map<ExpenseCategory, double>> getCategoryTotals() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT category, SUM(amount) as total
      FROM expenses
      GROUP BY category
    ''');

    final Map<ExpenseCategory, double> totals = {};
    for (final cat in ExpenseCategory.values) {
      totals[cat] = 0.0;
    }

    for (final row in result) {
      final cat = ExpenseCategory.fromString(row['category'] as String?);
      final total = (row['total'] as num?)?.toDouble() ?? 0.0;
      totals[cat] = total;
    }

    return totals;
  }

  /// Tính chi tiêu 7 ngày gần nhất
  Future<Map<DateTime, double>> getWeeklyDailyTotals() async {
    final db = await database;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sevenDaysAgo = today.subtract(const Duration(days: 6));

    final result = await db.rawQuery('''
      SELECT date, amount
      FROM expenses
      WHERE date >= ?
    ''', [sevenDaysAgo.toIso8601String()]);

    final Map<DateTime, double> dailyTotals = {};
    for (int i = 6; i >= 0; i--) {
      final d = today.subtract(Duration(days: i));
      dailyTotals[DateTime(d.year, d.month, d.day)] = 0.0;
    }

    for (final row in result) {
      final dt = DateTime.parse(row['date'] as String);
      final key = DateTime(dt.year, dt.month, dt.day);
      if (dailyTotals.containsKey(key)) {
        dailyTotals[key] = (dailyTotals[key] ?? 0.0) + (row['amount'] as num).toDouble();
      }
    }

    return dailyTotals;
  }
}

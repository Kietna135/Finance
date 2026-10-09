import 'dart:async';
import 'dart:convert';
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
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
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
        type $textType DEFAULT 'expense',
        receiptImagePath $textNullable,
        rawOcrText $textNullable,
        note $textNullable,
        createdAt $textType
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // Default monthly budget: 5,000,000 VND
    await db.insert('settings', {'key': 'monthly_budget', 'value': '5000000'});

    // Initial sample data
    await _insertSampleData(db);
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute("ALTER TABLE expenses ADD COLUMN type TEXT DEFAULT 'expense'");
      } catch (_) {}
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS settings (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
          )
        ''');
        await db.insert(
          'settings',
          {'key': 'monthly_budget', 'value': '5000000'},
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      } catch (_) {}
    }
  }

  Future<void> _insertSampleData(Database db) async {
    final now = DateTime.now();
    final sampleExpenses = [
      ExpenseItem(
        id: 'sample_income_1',
        merchant: 'Công ty Cổ Phần ABC',
        amount: 12000000,
        date: DateTime(now.year, now.month, 1),
        category: ExpenseCategory.salary,
        type: TransactionType.income,
        note: 'Lương chuyển khoản tháng ${now.month}',
      ),
      ExpenseItem(
        id: 'sample_income_2',
        merchant: 'Thưởng Dự Án',
        amount: 1500000,
        date: DateTime(now.year, now.month, 5),
        category: ExpenseCategory.bonus,
        type: TransactionType.income,
        note: 'Thưởng hoàn thành tiến độ xuất sắc',
      ),
      ExpenseItem(
        id: 'sample_1',
        merchant: 'WinMart Vincom',
        amount: 185000,
        date: now.subtract(const Duration(days: 0)),
        category: ExpenseCategory.food,
        type: TransactionType.expense,
        note: 'Mua thực phẩm tuần này',
      ),
      ExpenseItem(
        id: 'sample_2',
        merchant: 'Nhà sách Fahasa',
        amount: 240000,
        date: now.subtract(const Duration(days: 1)),
        category: ExpenseCategory.education,
        type: TransactionType.expense,
        note: 'Giáo trình lập trình di động & sổ tay',
      ),
      ExpenseItem(
        id: 'sample_3',
        merchant: 'Grab Bike',
        amount: 45000,
        date: now.subtract(const Duration(days: 2)),
        category: ExpenseCategory.travel,
        type: TransactionType.expense,
        note: 'Di chuyển đến trường',
      ),
      ExpenseItem(
        id: 'sample_4',
        merchant: 'Thế Giới Di Động',
        amount: 350000,
        date: now.subtract(const Duration(days: 3)),
        category: ExpenseCategory.devices,
        type: TransactionType.expense,
        note: 'Chuột không dây Logitech',
      ),
      ExpenseItem(
        id: 'sample_5',
        merchant: 'CGV Cinemas',
        amount: 130000,
        date: now.subtract(const Duration(days: 4)),
        category: ExpenseCategory.entertainment,
        type: TransactionType.expense,
        note: 'Vé xem phim cuối tuần',
      ),
      ExpenseItem(
        id: 'sample_6',
        merchant: 'Highlands Coffee',
        amount: 65000,
        date: now.subtract(const Duration(days: 5)),
        category: ExpenseCategory.food,
        type: TransactionType.expense,
        note: 'Học nhóm đồ án',
      ),
    ];

    for (final exp in sampleExpenses) {
      await db.insert('expenses', exp.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
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

  // --- BUDGET SETTINGS ---

  Future<double> getBudgetLimit() async {
    final db = await database;
    final result = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: ['monthly_budget'],
      limit: 1,
    );
    if (result.isNotEmpty) {
      return double.tryParse(result.first['value'] as String) ?? 5000000.0;
    }
    return 5000000.0;
  }

  Future<void> setBudgetLimit(double limit) async {
    final db = await database;
    await db.insert(
      'settings',
      {'key': 'monthly_budget', 'value': limit.toString()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // --- THỐNG KÊ & PHÂN TÍCH ---

  /// Tính tổng chi tiêu theo danh mục (cho loại Expense hoặc Income)
  Future<Map<ExpenseCategory, double>> getCategoryTotals({TransactionType? type}) async {
    final db = await database;
    String query = 'SELECT category, SUM(amount) as total FROM expenses';
    List<dynamic> args = [];
    if (type != null) {
      query += ' WHERE type = ?';
      args.add(type.name);
    }
    query += ' GROUP BY category';

    final result = await db.rawQuery(query, args);

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

  /// Tính tổng chi tiêu 7 ngày gần nhất
  Future<Map<DateTime, double>> getWeeklyDailyTotals({TransactionType? type}) async {
    final db = await database;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sevenDaysAgo = today.subtract(const Duration(days: 6));

    String sql = 'SELECT date, amount FROM expenses WHERE date >= ?';
    List<dynamic> args = [sevenDaysAgo.toIso8601String()];
    if (type != null) {
      sql += ' AND type = ?';
      args.add(type.name);
    }

    final result = await db.rawQuery(sql, args);

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

  // --- SAO LƯU & XUẤT NHẬP DỮ LIỆU ---

  Future<String> exportToJson() async {
    final all = await getAllExpenses();
    final budget = await getBudgetLimit();
    final data = {
      'app': 'FinanceApp',
      'version': '2.0.0',
      'exportDate': DateTime.now().toIso8601String(),
      'budgetLimit': budget,
      'transactions': all.map((e) => e.toMap()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  Future<String> exportToCsv() async {
    final all = await getAllExpenses();
    final buffer = StringBuffer();
    buffer.writeln('ID,Loai,DanhMuc,CuaHang_Nguon,SoTien,Ngay,GhiChu');
    for (final item in all) {
      final cleanMerchant = item.merchant.replaceAll(',', ' ');
      final cleanNote = (item.note ?? '').replaceAll(',', ' ');
      buffer.writeln(
        '${item.id},${item.type.displayName},${item.category.displayName},$cleanMerchant,${item.amount.toStringAsFixed(0)},${item.date.toIso8601String().substring(0, 10)},$cleanNote',
      );
    }
    return buffer.toString();
  }

  Future<int> importFromJson(String jsonString) async {
    try {
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      final list = data['transactions'] as List<dynamic>? ?? [];
      final db = await database;
      int imported = 0;
      for (final raw in list) {
        final item = ExpenseItem.fromMap(raw as Map<String, dynamic>);
        await db.insert('expenses', item.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
        imported++;
      }
      if (data['budgetLimit'] != null) {
        await setBudgetLimit((data['budgetLimit'] as num).toDouble());
      }
      return imported;
    } catch (_) {
      return 0;
    }
  }

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('expenses');
  }
}

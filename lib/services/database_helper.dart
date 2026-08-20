import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:math';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('finance_manager.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2, // Increased version for migration
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Users table
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        created_at TEXT NOT NULL,
        reset_token TEXT,
        reset_token_expiry TEXT
      )
    ''');

    // Transactions table
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        description TEXT,
        date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    // Categories table
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        icon TEXT
      )
    ''');

    // Insert default categories
    await _insertDefaultCategories(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add reset token columns if upgrading from version 1
      await db.execute('ALTER TABLE users ADD COLUMN reset_token TEXT');
      await db.execute('ALTER TABLE users ADD COLUMN reset_token_expiry TEXT');
    }
  }

  Future<void> _insertDefaultCategories(Database db) async {
    final expenseCategories = [
      {'name': 'Food', 'type': 'expense', 'icon': '🍔'},
      {'name': 'Transport', 'type': 'expense', 'icon': '🚗'},
      {'name': 'Shopping', 'type': 'expense', 'icon': '🛒'},
      {'name': 'Bills', 'type': 'expense', 'icon': '📄'},
      {'name': 'Entertainment', 'type': 'expense', 'icon': '🎬'},
      {'name': 'Health', 'type': 'expense', 'icon': '⚕️'},
      {'name': 'Education', 'type': 'expense', 'icon': '📚'},
      {'name': 'Other', 'type': 'expense', 'icon': '📦'},
    ];

    final incomeCategories = [
      {'name': 'Salary', 'type': 'income', 'icon': '💰'},
      {'name': 'Business', 'type': 'income', 'icon': '💼'},
      {'name': 'Investment', 'type': 'income', 'icon': '📈'},
      {'name': 'Gift', 'type': 'income', 'icon': '🎁'},
      {'name': 'Other', 'type': 'income', 'icon': '💵'},
    ];

    for (var category in [...expenseCategories, ...incomeCategories]) {
      await db.insert('categories', category);
    }
  }

  // User operations
  Future<Map<String, dynamic>?> registerUser(
      String username,
      String email,
      String password,
      ) async {
    final db = await database;

    // Check if email exists
    final existing = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );

    if (existing.isNotEmpty) {
      return null; // Email already exists
    }

    // Hash password
    final hashedPassword = sha256.convert(utf8.encode(password)).toString();

    final userId = await db.insert('users', {
      'username': username,
      'email': email,
      'password': hashedPassword,
      'created_at': DateTime.now().toIso8601String(),
    });

    return {
      'id': userId,
      'username': username,
      'email': email,
    };
  }

  Future<Map<String, dynamic>?> loginUser(String email, String password) async {
    final db = await database;
    final hashedPassword = sha256.convert(utf8.encode(password)).toString();

    final result = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, hashedPassword],
    );

    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  Future<Map<String, dynamic>?> getUserById(int userId) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
    );

    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );

    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  // Password Reset Operations
  String _generateResetToken() {
    final random = Random.secure();
    final values = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Url.encode(values);
  }

  Future<String> generatePasswordResetToken(String email) async {
    final db = await database;
    final resetToken = _generateResetToken();
    final expiry = DateTime.now().add(const Duration(hours: 1)); // Token valid for 1 hour

    await db.update(
      'users',
      {
        'reset_token': resetToken,
        'reset_token_expiry': expiry.toIso8601String(),
      },
      where: 'email = ?',
      whereArgs: [email],
    );

    return resetToken;
  }

  Future<bool> verifyResetToken(String email, String token) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'email = ? AND reset_token = ?',
      whereArgs: [email, token],
    );

    if (result.isEmpty) return false;

    final user = result.first;
    final expiryStr = user['reset_token_expiry'] as String?;

    if (expiryStr == null) return false;

    final expiry = DateTime.parse(expiryStr);
    if (DateTime.now().isAfter(expiry)) {
      // Token expired, clear it
      await clearResetToken(email);
      return false;
    }

    return true;
  }

  Future<bool> resetPassword(String email, String newPassword, String token) async {
    final db = await database;

    // Verify token first
    final isValid = await verifyResetToken(email, token);
    if (!isValid) return false;

    // Hash new password
    final hashedPassword = sha256.convert(utf8.encode(newPassword)).toString();

    // Update password and clear reset token
    final updated = await db.update(
      'users',
      {
        'password': hashedPassword,
        'reset_token': null,
        'reset_token_expiry': null,
      },
      where: 'email = ? AND reset_token = ?',
      whereArgs: [email, token],
    );

    return updated > 0;
  }

  Future<void> clearResetToken(String email) async {
    final db = await database;
    await db.update(
      'users',
      {
        'reset_token': null,
        'reset_token_expiry': null,
      },
      where: 'email = ?',
      whereArgs: [email],
    );
  }

  // Transaction operations
  Future<int> addTransaction({
    required int userId,
    required String type,
    required double amount,
    required String category,
    required String description,
    required String date,
  }) async {
    final db = await database;

    return await db.insert('transactions', {
      'user_id': userId,
      'type': type,
      'amount': amount,
      'category': category,
      'description': description,
      'date': date,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getTransactions(int userId) async {
    final db = await database;
    return await db.query(
      'transactions',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'date DESC, created_at DESC',
    );
  }

  Future<int> deleteTransaction(int id) async {
    final db = await database;
    return await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateTransaction({
    required int id,
    required String type,
    required double amount,
    required String category,
    required String description,
    required String date,
  }) async {
    final db = await database;
    return await db.update(
      'transactions',
      {
        'type': type,
        'amount': amount,
        'category': category,
        'description': description,
        'date': date,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Statistics
  Future<Map<String, dynamic>> getDashboardStats(int userId) async {
    final db = await database;

    // Total income
    final incomeResult = await db.rawQuery(
      'SELECT SUM(amount) as total FROM transactions WHERE user_id = ? AND type = "income"',
      [userId],
    );
    final totalIncome = incomeResult.first['total'] ?? 0.0;

    // Total expense
    final expenseResult = await db.rawQuery(
      'SELECT SUM(amount) as total FROM transactions WHERE user_id = ? AND type = "expense"',
      [userId],
    );
    final totalExpense = expenseResult.first['total'] ?? 0.0;

    // Recent transactions
    final recentTransactions = await db.query(
      'transactions',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
      limit: 10,
    );

    // Category breakdown
    final categoryBreakdown = await db.rawQuery('''
      SELECT category, SUM(amount) as total, type 
      FROM transactions 
      WHERE user_id = ? 
      GROUP BY category, type
      ORDER BY total DESC
    ''', [userId]);

    return {
      'total_income': totalIncome,
      'total_expense': totalExpense,
      'balance': (totalIncome as double) - (totalExpense as double),
      'recent_transactions': recentTransactions,
      'category_breakdown': categoryBreakdown,
    };
  }

  Future<List<Map<String, dynamic>>> getCategories(String type) async {
    final db = await database;
    return await db.query(
      'categories',
      where: 'type = ?',
      whereArgs: [type],
    );
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'models/app_models.dart'; // To access our models
import 'dart:math'; // Add this at the top for random numbers

class DatabaseHelper {
  // 1. Setup the Singleton pattern so we only ever have one connection to the DB
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
// --- DATABASE MANAGEMENT OPERATIONS ---

  // 1. Close the database connection safely
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null; // Clear the instance so it re-initializes on next call
    }
  }

  // 2. Delete the database file (Useful for a 'Factory Reset' or before Import)
  Future<void> deleteDatabaseFile() async {
    final dbPath = await getApplicationDocumentsDirectory();
    final path = join(dbPath.path, 'pos_database.db');

    await close(); // Must close it first!

    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
  DatabaseHelper._init();

  // Update your getter to be slightly safer
  Future<Database> get database async {
    // If the database was closed and nulled out, this ensures it re-inits
    if (_database != null && _database!.isOpen) return _database!;
    _database = await _initDB('pos_database.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    // Find the correct local folder for the tablet
    final dbPath = await getApplicationDocumentsDirectory();
    final path = join(dbPath.path, filePath);

    // Open the database and create tables if it's the first time
    return await openDatabase(
      path,
      version: 6, // Bumped to 6 for the Void Order feature
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  // 3. Write the SQL to build our tables
  Future _createDB(Database db, int version) async {
    // Creating the Products table
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        price REAL NOT NULL,
        image TEXT NOT NULL,
        category TEXT NOT NULL,
        tag TEXT,
        tagColor INTEGER
      )
    ''');

    // Creating the Categories table
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE
      )
    ''');

    // Creating the Orders table (updated with isVoid)
    await db.execute('''
      CREATE TABLE orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        subtotal REAL NOT NULL,
        taxAmount REAL NOT NULL,
        finalTotal REAL NOT NULL,
        itemsSummary TEXT NOT NULL,
        cashierName TEXT NOT NULL,
        isVoid INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Creating the Users table
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        role TEXT NOT NULL,
        pin TEXT NOT NULL UNIQUE
      )
    ''');

    // Creating the Settings table
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // Creating the Shifts table
    await db.execute('''
      CREATE TABLE shifts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        employeeName TEXT NOT NULL,
        startingCash REAL NOT NULL,
        totalSales REAL NOT NULL,
        expectedCash REAL NOT NULL,
        actualCash REAL NOT NULL,
        variance REAL NOT NULL
      )
    ''');

    // --- SEED DATA ---

    // 1. Seed default users
    await db.insert('users', {
      'name': 'Alice',
      'role': 'Manager',
      'pin': '1234',
    });
    await db.insert('users', {
      'name': 'Bob',
      'role': 'Barista',
      'pin': '0000',
    });

    // 2. Seed default categories
    await db.insert('categories', {'name': 'Coffee'});
    await db.insert('categories', {'name': 'Pastry'});

    // 3. Seed default products with more reliable URLs
    await db.insert('products', {
      'name': 'Latte',
      'description': 'Smooth espresso with steamed milk',
      'price': 4.50,
      'image': 'https://images.unsplash.com/photo-1541167760496-1628856ab772?auto=format&fit=crop&w=400&q=80',
      'category': 'Coffee',
      'tag': 'Popular',
      'tagColor': 0xFF006E3B,
    });

    await db.insert('products', {
      'name': 'Croissant',
      'description': 'Buttery and flaky french pastry',
      'price': 3.75,
      'image': 'https://images.unsplash.com/photo-1555507036-ab1f4038808a?auto=format&fit=crop&w=400&q=80',
      'category': 'Pastry',
    });

    // 4. Seed default settings
    await db.insert('settings', {'key': 'tax_rate', 'value': '8.0'});
    await db.insert('settings', {'key': 'blind_drop', 'value': 'true'});
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 6) {
      // For development, we drop and recreate to ensure a clean schema.
      await db.execute('DROP TABLE IF EXISTS orders');
      await db.execute('DROP TABLE IF EXISTS settings');
      await db.execute('DROP TABLE IF EXISTS shifts');
      await db.execute('DROP TABLE IF EXISTS users');
      await _createDB(db, newVersion);
    }
  }

  // --- SETTINGS OPERATIONS ---

  Future<void> saveTaxRate(double rate) async {
    final db = await instance.database;
    await db.insert(
      'settings',
      {'key': 'tax_rate', 'value': rate.toString()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<double> getTaxRate() async {
    final db = await instance.database;
    final result = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: ['tax_rate'],
    );

    if (result.isNotEmpty) {
      return double.tryParse(result.first['value'] as String) ?? 0.0;
    }
    return 0.0;
  }

  Future<void> saveBlindDropSetting(bool isEnabled) async {
    final db = await instance.database;
    await db.insert(
      'settings',
      {'key': 'blind_drop', 'value': isEnabled.toString()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<bool> getBlindDropSetting() async {
    final db = await instance.database;
    final result = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: ['blind_drop'],
    );

    if (result.isNotEmpty) {
      return result.first['value'] == 'true';
    }
    return true;
  }

  // --- USER OPERATIONS ---

  Future<PosUser?> getUserByPin(String pin) async {
    final db = await instance.database;
    final result = await db.query(
      'users',
      where: 'pin = ?',
      whereArgs: [pin],
    );

    if (result.isNotEmpty) {
      return PosUser.fromMap(result.first);
    }
    return null;
  }

  Future<List<PosUser>> getAllUsers() async {
    final db = await instance.database;
    final result = await db.query('users');
    return result.map((json) => PosUser.fromMap(json)).toList();
  }

  Future<int> insertUser(PosUser user) async {
    final db = await instance.database;
    return await db.insert('users', user.toMap());
  }

  Future<int> deleteUser(int id) async {
    final db = await instance.database;
    return await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  // --- PRODUCT OPERATIONS ---

  Future<int> insertProduct(Product product) async {
    final db = await instance.database;
    return await db.insert('products', product.toMap());
  }

  Future<List<Product>> getAllProducts() async {
    final db = await instance.database;
    final result = await db.query('products');
    return result.map((json) => Product.fromMap(json)).toList();
  }

  // --- CATEGORY OPERATIONS ---

  Future<int> insertCategory(ProductCategory category) async {
    final db = await instance.database;
    return await db.insert('categories', category.toMap());
  }

  Future<List<ProductCategory>> getAllCategories() async {
    final db = await instance.database;
    final result = await db.query('categories');
    return result.map((json) => ProductCategory.fromMap(json)).toList();
  }

  Future<int> deleteCategory(int id) async {
    final db = await instance.database;
    return await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteProduct(int id) async {
    final db = await instance.database;
    return await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  // --- ORDER OPERATIONS ---

  Future<int> insertOrder(PosOrder order) async {
    final db = await instance.database;
    return await db.insert('orders', order.toMap());
  }

  Future<List<PosOrder>> getAllOrders() async {
    final db = await instance.database;
    final result = await db.query('orders', orderBy: 'id DESC');
    return result.map((json) => PosOrder.fromMap(json)).toList();
  }

  Future<List<PosOrder>> getOrdersByCashier(String cashierName) async {
    final db = await instance.database;
    final result = await db.query(
      'orders',
      where: 'cashierName = ?',
      whereArgs: [cashierName],
      orderBy: 'id DESC',
    );
    return result.map((json) => PosOrder.fromMap(json)).toList();
  }

  // NEW: Query orders by date range (filtering out voided orders)
  Future<List<PosOrder>> getOrdersByRange(DateTime start, DateTime end) async {
    final db = await instance.database;
    final startStr = "${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')} 00:00";
    final endStr = "${end.year}-${end.month.toString().padLeft(2, '0')}-${end.day.toString().padLeft(2, '0')} 23:59";
    
    final result = await db.query(
      'orders',
      where: "date >= ? AND date <= ? AND isVoid = 0",
      whereArgs: [startStr, endStr],
      orderBy: 'date DESC',
    );
    return result.map((json) => PosOrder.fromMap(json)).toList();
  }

  // Void Order logic
  Future<int> voidOrder(int orderId) async {
    final db = await instance.database;
    return await db.update(
      'orders',
      {'isVoid': 1},
      where: 'id = ?',
      whereArgs: [orderId],
    );
  }

  // --- SHIFT OPERATIONS ---

  Future<int> insertShiftReport(ShiftReport report) async {
    final db = await instance.database;
    return await db.insert('shifts', report.toMap());
  }

  Future<List<ShiftReport>> getAllShiftReports() async {
    final db = await instance.database;
    final result = await db.query('shifts', orderBy: 'id DESC');
    return result.map((json) => ShiftReport.fromMap(json)).toList();
  }

// ... inside your DatabaseHelper class ...

  Future<void> seedHistoricalData() async {
    final db = await instance.database;
    final random = Random();
    final now = DateTime.now();

    // Create orders for the last 90 days
    for (int i = 0; i < 90; i++) {
      // Pick a date in the past
      DateTime orderDate = now.subtract(Duration(days: i));

      // Generate 3 to 8 orders for each day
      int ordersToday = random.nextInt(6) + 3;

      for (int j = 0; j < ordersToday; j++) {
        double subtotal = (random.nextDouble() * 20) + 5; // $5 to $25
        double tax = subtotal * 0.08;
        double total = subtotal + tax;

        await db.insert('orders', {
          'date': "${orderDate.year}-${orderDate.month.toString().padLeft(2, '0')}-${orderDate.day.toString().padLeft(2, '0')} ${random.nextInt(12) + 8}:00",
          'subtotal': subtotal,
          'taxAmount': tax,
          'finalTotal': total,
          'itemsSummary': "2x Fake Coffee, 1x Fake Pastry",
          'cashierName': "System Seed",
          'isVoid': 0,
        });
      }
    }
  }
}

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'models/app_models.dart'; // To access our models

class DatabaseHelper {
  // 1. Setup the Singleton pattern so we only ever have one connection to the DB
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  // 2. Open the database (or create it if it doesn't exist)
  Future<Database> get database async {
    if (_database != null) return _database!;
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
      version: 3, // Current version with users and cashierName in orders
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

    // Creating the Orders table (including cashierName)
    await db.execute('''
      CREATE TABLE orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        total REAL NOT NULL,
        itemsSummary TEXT NOT NULL,
        cashierName TEXT NOT NULL
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

    // Seed default users
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
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      // Simple migration for development: recreate tables or add columns
      await db.execute('DROP TABLE IF EXISTS orders');
      await db.execute('DROP TABLE IF EXISTS users');
      await _createDB(db, newVersion);
    }
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

  // Insert a new product
  Future<int> insertProduct(Product product) async {
    final db = await instance.database;
    return await db.insert('products', product.toMap());
  }

  // Read all products to show on the UI
  Future<List<Product>> getAllProducts() async {
    final db = await instance.database;
    // Query the table for all records
    final result = await db.query('products');

    // Convert the List of Maps back into a List of Products
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

  // Delete a product from the menu
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
}

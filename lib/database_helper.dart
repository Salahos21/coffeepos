import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'main.dart'; // To access our Product model

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
    return await openDatabase(path, version: 1, onCreate: _createDB);
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

    // We will add the Receipts/Orders tables here later!
  }

  // --- DATABASE OPERATIONS ---

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
}
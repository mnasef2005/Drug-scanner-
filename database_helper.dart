import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'models.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('pharmacy.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE products (
        barcode TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        price REAL NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        address TEXT,
        hasCredit INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE invoices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customerId INTEGER,
        customerName TEXT NOT NULL,
        totalAmount REAL NOT NULL,
        isPaid INTEGER NOT NULL,
        date TEXT NOT NULL
      )
    ''');
    
    await db.execute('''
      CREATE TABLE invoice_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoiceId INTEGER,
        productBarcode TEXT,
        productName TEXT,
        quantity INTEGER,
        price REAL
      )
    ''');
  }

  // Product Methods
  Future<void> insertOrUpdateProduct(Product product) async {
    final db = await instance.database;
    await db.insert('products', product.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Product?> getProduct(String barcode) async {
    final db = await instance.database;
    final maps = await db.query(
      'products',
      where: 'barcode = ?',
      whereArgs: [barcode],
    );
    if (maps.isNotEmpty) {
      return Product(
        barcode: maps.first['barcode'] as String,
        name: maps.first['name'] as String,
        price: maps.first['price'] as double,
      );
    }
    return null;
  }
  
  // Customer Methods
  Future<int> addCustomer(Customer customer) async {
    final db = await instance.database;
    return await db.insert('customers', customer.toMap());
  }

  Future<List<Customer>> getCustomers() async {
    final db = await instance.database;
    final result = await db.query('customers', orderBy: 'name ASC');
    return result.map((json) => Customer(
      id: json['id'] as int,
      name: json['name'] as String,
      phone: json['phone'] as String,
      address: json['address'] as String,
      hasCredit: (json['hasCredit'] as int) == 1,
    )).toList();
  }

  Future<int> deleteCustomer(int id) async {
    final db = await instance.database;
    return await db.delete('customers', where: 'id = ?', whereArgs: [id]);
  }

  // Invoice Methods
  Future<int> createInvoice(Invoice invoice) async {
    final db = await instance.database;
    final invoiceMap = {
      'customerId': invoice.customerId,
      'customerName': invoice.customerName,
      'totalAmount': invoice.totalAmount,
      'isPaid': invoice.isPaid ? 1 : 0,
      'date': invoice.date.toIso8601String(),
    };
    final id = await db.insert('invoices', invoiceMap);
    
    for (var item in invoice.items) {
      await db.insert('invoice_items', {
        'invoiceId': id,
        'productBarcode': item.barcode,
        'productName': item.name,
        'quantity': item.quantity,
        'price': item.price
      });
    }
    return id;
  }
  
  Future<List<Invoice>> getInvoices() async {
      final db = await instance.database;
      final invoiceMaps = await db.query('invoices', orderBy: 'id DESC');
      List<Invoice> invoices = [];

      for(var invoiceMap in invoiceMaps){
          final itemMaps = await db.query('invoice_items', where: 'invoiceId = ?', whereArgs: [invoiceMap['id']]);
          final items = itemMaps.map((itemMap) => Product(
              barcode: itemMap['productBarcode'] as String,
              name: itemMap['productName'] as String,
              price: itemMap['price'] as double,
              quantity: itemMap['quantity'] as int
          )).toList();

          invoices.add(Invoice(
            id: invoiceMap['id'] as int,
            customerId: invoiceMap['customerId'] as int?,
            customerName: invoiceMap['customerName'] as String,
            totalAmount: invoiceMap['totalAmount'] as double,
            date: DateTime.parse(invoiceMap['date'] as String),
            isPaid: (invoiceMap['isPaid'] as int) == 1,
            items: items,
          ));
      }
      return invoices;
  }

  Future<void> deleteInvoice(int id) async {
    final db = await instance.database;
    await db.delete('invoices', where: 'id = ?', whereArgs: [id]);
    await db.delete('invoice_items', where: 'invoiceId = ?', whereArgs: [id]);
  }
}

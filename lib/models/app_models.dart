import 'package:flutter/material.dart';

class PosUser {
  final dynamic id;
  final String name;
  final String role;
  final String pin;

  const PosUser({this.id, required this.name, required this.role, required this.pin});

  Map<String, dynamic> toMap() => {'name': name, 'role': role, 'pin': pin};

  factory PosUser.fromMap(Map<String, dynamic> map) => PosUser(
    id: map['id'],
    name: map['name'] ?? '',
    role: map['role'] ?? 'Barista',
    pin: map['pin'] ?? '',
  );
}

class ProductCategory {
  final dynamic id;
  final String name;

  const ProductCategory({this.id, required this.name});

  Map<String, dynamic> toMap() => {'name': name};

  factory ProductCategory.fromMap(Map<String, dynamic> map) => ProductCategory(
    id: map['id'],
    name: map['name'] ?? '',
  );
}

class Product {
  final dynamic id;
  final String name;
  final String description;
  final double price;
  final String image;
  final dynamic categoryId;
  final String categoryName;
  final String? tag;
  final Color? tagColor;

  const Product({
    this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.image,
    required this.categoryId,
    this.categoryName = '',
    this.tag,
    this.tagColor,
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'description': description,
    'price': price,
    'image_url': image,
    'category_id': categoryId,
    'tag': tag,
    'tag_color_int': tagColor?.toARGB32(),
  };

  factory Product.fromMap(Map<String, dynamic> map) => Product(
    id: map['id'],
    name: map['name'] ?? '',
    description: map['description'] ?? '',
    price: (map['price'] as num?)?.toDouble() ?? 0.0,
    image: map['image_url'] ?? '',
    categoryId: map['category_id'],
    categoryName: map['categories']?['name'] ?? 'General',
    tag: map['tag'],
    tagColor: map['tag_color_int'] != null ? Color(map['tag_color_int'] as int) : null,
  );
}

class CartItem {
  final Product product;
  int quantity;
  final String modifiers;
  CartItem({required this.product, this.quantity = 1, this.modifiers = 'Regular'});
}

class CartState extends ChangeNotifier {
  final List<CartItem> _items = [];
  double _currentTaxRate = 0.0;
  List<CartItem> get items => _items;
  double get currentTaxRate => _currentTaxRate;
  set currentTaxRate(double value) { _currentTaxRate = value; notifyListeners(); }
  double get subtotal => _items.fold(0, (sum, item) => sum + (item.product.price * item.quantity));
  double get taxAmount => subtotal * (_currentTaxRate / 100);
  double get finalTotal => subtotal + taxAmount;
  void addItem(Product product) {
    final existingIndex = _items.indexWhere((item) => item.product.name == product.name);
    if (existingIndex >= 0) { _items[existingIndex].quantity++; }
    else { _items.add(CartItem(product: product)); }
    notifyListeners();
  }
  void updateQuantity(CartItem item, int delta) {
    item.quantity += delta;
    if (item.quantity <= 0) { _items.remove(item); }
    notifyListeners();
  }
  void clearCart() { _items.clear(); notifyListeners(); }
}

class PosOrder {
  final dynamic id;
  final String date;
  final double subtotal;
  final double taxAmount;
  final double finalTotal;
  final String itemsSummary;
  final String cashierName;
  final bool isVoid;
  PosOrder({this.id, required this.date, required this.subtotal, required this.taxAmount, required this.finalTotal, required this.itemsSummary, required this.cashierName, this.isVoid = false});

  Map<String, dynamic> toMap() => {
    'date': date,
    'subtotal': subtotal,
    'tax_amount': taxAmount,
    'final_total': finalTotal,
    'items_summary': itemsSummary,
    'cashier_name': cashierName,
    'is_void': isVoid,
  };

  factory PosOrder.fromMap(Map<String, dynamic> map) => PosOrder(
    id: map['id'],
    date: map['date'] ?? '',
    subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
    taxAmount: (map['tax_amount'] as num?)?.toDouble() ?? 0.0,
    finalTotal: (map['final_total'] as num?)?.toDouble() ?? 0.0,
    itemsSummary: map['items_summary'] ?? '',
    cashierName: map['cashier_name'] ?? 'Unknown',
    isVoid: map['is_void'] ?? false,
  );
}

class ShiftReport {
  final dynamic id;
  final String date;
  final String employeeName;
  final double totalSales;

  final List<PosOrder> orders;
  final Map<String, int> topSellers;

  ShiftReport({
    this.id,
    required this.date,
    required this.employeeName,
    required this.totalSales,
    this.orders = const [],
    this.topSellers = const {},
  });

  Map<String, dynamic> toMap() => {
    'date': date,
    'employee_name': employeeName,
    'total_sales': totalSales,
    'orders': orders.map((o) => o.toMap()).toList(),
    'top_sellers': topSellers,
  };

  Map<String, dynamic> toDbMap() => {
    'date': date,
    'employee_name': employeeName,
    'total_sales': totalSales,
  };

  factory ShiftReport.fromMap(Map<String, dynamic> map) => ShiftReport(
    id: map['id'],
    date: map['date'] ?? '',
    employeeName: map['employee_name'] ?? 'Unknown',
    totalSales: (map['total_sales'] as num?)?.toDouble() ?? 0.0,
    orders: const [],
    topSellers: const {},
  );
}

final cartState = CartState();
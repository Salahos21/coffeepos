import 'package:flutter/material.dart';

class PosUser {
  final int? id;
  final String name;
  final String role;
  final String pin;

  const PosUser({
    this.id,
    required this.name,
    required this.role,
    required this.pin,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'role': role,
      'pin': pin,
    };
  }

  factory PosUser.fromMap(Map<String, dynamic> map) {
    return PosUser(
      id: map['id'],
      name: map['name'],
      role: map['role'],
      pin: map['pin'],
    );
  }
}

class ProductCategory {
  final int? id;
  final String name;

  const ProductCategory({
    this.id,
    required this.name,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }

  factory ProductCategory.fromMap(Map<String, dynamic> map) {
    return ProductCategory(
      id: map['id'],
      name: map['name'],
    );
  }
}

class Product {
  final int? id;
  final String name;
  final String description;
  final double price;
  final String image;
  final String category;
  final String? tag;
  final Color? tagColor;

  const Product({
    this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.image,
    required this.category,
    this.tag,
    this.tagColor,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'image': image,
      'category': category,
      'tag': tag,
      'tagColor': tagColor?.toARGB32(),
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      price: map['price'],
      image: map['image'],
      category: map['category'],
      tag: map['tag'],
      tagColor: map['tagColor'] != null ? Color(map['tagColor']) : null,
    );
  }
}

class CartItem {
  final Product product;
  int quantity;
  final String modifiers;

  CartItem({
    required this.product,
    this.quantity = 1,
    this.modifiers = 'Regular',
  });
}

class CartState extends ChangeNotifier {
  final List<CartItem> _items = [];
  double currentTaxRate = 0.0;

  List<CartItem> get items => _items;

  double get subtotal => _items.fold(0, (sum, item) => sum + (item.product.price * item.quantity));
  double get taxAmount => subtotal * (currentTaxRate / 100);
  double get finalTotal => subtotal + taxAmount;

  void addItem(Product product) {
    final existingIndex = _items.indexWhere((item) => item.product.name == product.name);

    if (existingIndex >= 0) {
      _items[existingIndex].quantity++;
    } else {
      _items.add(CartItem(product: product));
    }
    // Forces UI listeners to rebuild
    notifyListeners();
  }

  void updateQuantity(CartItem item, int delta) {
    item.quantity += delta;
    if (item.quantity <= 0) {
      _items.remove(item);
    }
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}

class PosOrder {
  final int? id;
  final String date;
  final double subtotal;
  final double taxAmount;
  final double finalTotal;
  final String itemsSummary;
  final String cashierName;
  final bool isVoid;

  PosOrder({
    this.id,
    required this.date,
    required this.subtotal,
    required this.taxAmount,
    required this.finalTotal,
    required this.itemsSummary,
    required this.cashierName,
    this.isVoid = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'subtotal': subtotal,
      'taxAmount': taxAmount,
      'finalTotal': finalTotal,
      'itemsSummary': itemsSummary,
      'cashierName': cashierName,
      'isVoid': isVoid ? 1 : 0,
    };
  }

  factory PosOrder.fromMap(Map<String, dynamic> map) {
    return PosOrder(
      id: map['id'],
      date: map['date'],
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (map['taxAmount'] as num?)?.toDouble() ?? 0.0,
      finalTotal: (map['finalTotal'] as num?)?.toDouble() ?? 0.0,
      itemsSummary: map['itemsSummary'],
      cashierName: map['cashierName'] ?? 'Unknown',
      isVoid: map['isVoid'] == 1,
    );
  }
}

class ShiftReport {
  final int? id;
  final String date;
  final String employeeName;
  final double startingCash;
  final double totalSales;
  final double expectedCash;
  final double actualCash;
  final double variance;

  ShiftReport({
    this.id,
    required this.date,
    required this.employeeName,
    required this.startingCash,
    required this.totalSales,
    required this.expectedCash,
    required this.actualCash,
    required this.variance,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'employeeName': employeeName,
      'startingCash': startingCash,
      'totalSales': totalSales,
      'expectedCash': expectedCash,
      'actualCash': actualCash,
      'variance': variance,
    };
  }

  factory ShiftReport.fromMap(Map<String, dynamic> map) {
    return ShiftReport(
      id: map['id'],
      date: map['date'],
      employeeName: map['employeeName'],
      startingCash: (map['startingCash'] as num).toDouble(),
      totalSales: (map['totalSales'] as num).toDouble(),
      expectedCash: (map['expectedCash'] as num).toDouble(),
      actualCash: (map['actualCash'] as num).toDouble(),
      variance: (map['variance'] as num).toDouble(),
    );
  }
}

// Global instance
final cartState = CartState();
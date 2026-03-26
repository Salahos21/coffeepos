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

  List<CartItem> get items => _items;
  double get subtotal => _items.fold(0, (sum, item) => sum + (item.product.price * item.quantity));
  double get tax => subtotal * 0.08;
  double get total => subtotal + tax;

  void addItem(Product product) {
    final existingIndex = _items.indexWhere((item) => item.product.name == product.name);

    if (existingIndex >= 0) {
      _items[existingIndex].quantity++;
    } else {
      _items.add(CartItem(product: product));
    }
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
  final double total;
  final String itemsSummary;
  final String cashierName; // Added field

  PosOrder({
    this.id,
    required this.date,
    required this.total,
    required this.itemsSummary,
    required this.cashierName, // Added to constructor
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'total': total,
      'itemsSummary': itemsSummary,
      'cashierName': cashierName, // Added to toMap
    };
  }

  factory PosOrder.fromMap(Map<String, dynamic> map) {
    return PosOrder(
      id: map['id'],
      date: map['date'],
      total: map['total'],
      itemsSummary: map['itemsSummary'],
      cashierName: map['cashierName'] ?? 'Unknown', // Added to fromMap
    );
  }
}

// Our global state instances
final cartState = CartState();
PosUser? currentUser;
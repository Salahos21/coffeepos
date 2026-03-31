import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_models.dart';

class SupabaseHelper {
  static final SupabaseHelper instance = SupabaseHelper._init();
  final SupabaseClient _supabase = Supabase.instance.client;

  SupabaseHelper._init();

  // --- STAFF & AUTH ---
  Future<PosUser?> verifyStaffPin(String pin, String cafeId) async {
    final data = await _supabase.from('staff').select().eq('cafe_id', cafeId.trim()).eq('pin', pin.trim()).maybeSingle();
    return data != null ? PosUser.fromMap(data) : null;
  }

  Future<List<PosUser>> getAllStaff(String cafeId) async {
    final response = await _supabase.from('staff').select().eq('cafe_id', cafeId);
    return (response as List).map((json) => PosUser.fromMap(json)).toList();
  }

  Future<void> insertStaff(PosUser user, String cafeId) async {
    await _supabase.from('staff').insert({'cafe_id': cafeId, ...user.toMap()});
  }

  // --- PRODUCTS & CATEGORIES ---
  Future<List<Product>> getProducts(String cafeId) async {
    final response = await _supabase.from('products').select('*, categories(name)').eq('cafe_id', cafeId);
    return (response as List).map((json) => Product.fromMap(json)).toList();
  }

  Future<bool> isCategoryInUse(dynamic categoryId, String cafeId) async {
    try {
      final response = await _supabase
          .from('products')
          .select('id')
          .eq('category_id', categoryId)
          .eq('cafe_id', cafeId)
          .count(CountOption.exact);

      return (response.count) > 0;
    } catch (e) {
      print("Count error: $e");
      return true;
    }
  }

  Future<void> addProduct(Product product, String cafeId) async {
    String finalImageUrl = product.image;
    if (product.image.isNotEmpty && !product.image.startsWith('http')) {
      finalImageUrl = await uploadProductImage(File(product.image), cafeId);
    }
    await _supabase.from('products').insert({
      'cafe_id': cafeId,
      ...product.toMap(),
      'image_url': finalImageUrl,
    });
  }

  Future<String> uploadProductImage(File imageFile, String cafeId) async {
    final fileName = '${cafeId}/${DateTime.now().millisecondsSinceEpoch}.jpg';
    await _supabase.storage.from('product-images').upload(fileName, imageFile);
    return _supabase.storage.from('product-images').getPublicUrl(fileName);
  }

  Future<List<ProductCategory>> getCategories(String cafeId) async {
    final response = await _supabase.from('categories').select().eq('cafe_id', cafeId);
    return (response as List).map((json) => ProductCategory.fromMap(json)).toList();
  }

  Future<void> insertCategory(ProductCategory category, String cafeId) async {
    await _supabase.from('categories').insert({'cafe_id': cafeId, 'name': category.name});
  }

  // --- ORDERS ---
  Future<void> insertOrder(PosOrder order, String cafeId) async {
    await _supabase.from('orders').insert({
      'cafe_id': cafeId,
      ...order.toMap(),
    });
  }

  Future<List<PosOrder>> getOrdersByRange(String cafeId, DateTime start, DateTime end) async {
    try {
      final response = await _supabase
          .from('orders')
          .select()
          .eq('cafe_id', cafeId)
          .gte('date', start.toIso8601String())
          .order('date', ascending: false);
      return (response as List).map((json) => PosOrder.fromMap(json)).toList();
    } catch (e) {
      print("Error fetching orders: $e");
      return [];
    }
  }

  Future<void> voidOrder(int orderId, String cafeId) async {
    await _supabase
        .from('orders')
        .update({'is_void': true})
        .eq('id', orderId)
        .eq('cafe_id', cafeId);
  }

  // --- DELETE METHODS ---
  Future<void> deleteProduct(dynamic productId, String cafeId) async {
    try {
      await _supabase.from('products').delete().eq('id', productId).eq('cafe_id', cafeId);
    } catch (e) {
      print("Delete error: $e");
      rethrow;
    }
  }

  Future<void> deleteCategory(dynamic categoryId, String cafeId) async {
    await _supabase.from('categories').delete().eq('id', categoryId).eq('cafe_id', cafeId);
  }

  // --- UPDATE METHODS ---
  Future<void> updateProduct(Product product, String cafeId) async {
    await _supabase.from('products').update(product.toMap()).eq('id', product.id).eq('cafe_id', cafeId);
  }

  // --- SHIFTS ---
  Future<void> insertShiftReport(ShiftReport report, String cafeId) async {
    // Explicitly mapping cafe_id for SaaS architecture
    await _supabase.from('shifts').insert({
      'cafe_id': cafeId,
      ...report.toMap(),
    });
  }

  // --- SETTINGS ---
  Future<double> getTaxRate(String cafeId) async {
    final data = await _supabase.from('cafe_settings').select('tax_rate').eq('cafe_id', cafeId).maybeSingle();
    return (data?['tax_rate'] as num?)?.toDouble() ?? 0.0;
  }

  Future<void> updateTaxRate(double rate, String cafeId) async {
    await _supabase.from('cafe_settings').upsert({'cafe_id': cafeId, 'tax_rate': rate});
  }
  Future<void> updateCafeSettings({
    required String cafeId,
    required String businessName,
    required String reportingEmail,
  }) async {
    await _supabase.from('cafe_settings').upsert({
      'cafe_id': cafeId,
      'business_name': businessName,
      'reporting_email': reportingEmail,
    });
  }


  // FETCHING CLOUD SETTINGS
  Future<Map<String, dynamic>?> getCafeSettings(String cafeId) async {
    return await _supabase.from('cafe_settings').select().eq('cafe_id', cafeId).maybeSingle();
  }

  // TRIGGER EDGE FUNCTION
  Future<void> sendEmailReportViaEdge({
    required String email,
    required String businessName,
    required ShiftReport report,
  }) async {
    try {
      await _supabase.functions.invoke(
        'send-shift-report',
        body: {
          'email': email,
          'businessName': businessName,
          'reportData': report.toMap(),
        },
      );
    } catch (e) {
      print("Cloud Function Error: $e");
      rethrow;
    }
  }
}
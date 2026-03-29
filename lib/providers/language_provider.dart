import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _currentLocale = const Locale('en');
  Locale get currentLocale => _currentLocale;

  LanguageProvider() {
    _loadLanguage();
  }

  void _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    String code = prefs.getString('language_code') ?? 'en';
    _currentLocale = Locale(code);
    notifyListeners();
  }

  void setLanguage(String code) async {
    _currentLocale = Locale(code);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', code);
    notifyListeners();
  }

  String t(String key) {
    // Normalizing key to lowercase for robust lookup
    String lookupKey = key.toLowerCase().trim();
    return _localizedValues[_currentLocale.languageCode]?[lookupKey] ?? key;
  }

  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      // General & Nav
      'register': 'Register',
      'orders': 'Orders',
      'config': 'Configuration',
      'settings': 'Settings',
      'logout': 'Logout',
      'manager_role': 'Manager',
      'barista_role': 'Barista',

      // Login
      'enter_pin': 'Enter your PIN',
      'invalid_pin': 'Invalid PIN',

      // Register/Center Area
      'all': 'All',
      'coffee': 'Coffee',
      'pastry': 'Pastry',
      'search_hint': 'Search menu...',
      'add_to_cart': 'added to order!',

      // Active Order Sidebar
      'active_order': 'Active Order',
      'cashier': 'Cashier',
      'subtotal': 'Subtotal',
      'tax': 'Tax',
      'total': 'Total',
      'total_due': 'Total Due',
      'checkout': 'Checkout',
      'confirm_order': 'Confirm Order',
      'confirm_payment': 'Confirm Payment',
      'cancel': 'Cancel',

      // Orders Screen
      'order_history': 'Order History',
      'close_shift': 'Close Shift',
      'today_revenue': 'Today Revenue',
      'range_total': 'Range Total',
      'avg_sale': 'Avg Sale',
      'void_order': 'Void Order',

      // Config Screen Tabs
      'categories_tab': 'Categories',
      'products': 'Products',
      'staff_tab': 'Staff',
      'theme_tab': 'Theme',

      // Config Forms
      'new_cat_label': 'New Category Name',
      'prod_name_label': 'Product Name',
      'price': 'Price',
      'pick_image': 'Pick Image',
      'save_product': 'Save Product',
      'add_staff': 'Add Staff Member',
      'name': 'Name',
      'role': 'Role',
      'description': 'Description',
      'add': 'Add',

      // Config Settings & Theme
      'tax_config_title': 'Tax Configuration',
      'tax_config_sub': 'Set your regional sales tax rate.',
      'save_settings': 'Save Settings',
      'security_settings': 'Security Settings',
      'blind_drop_title': 'Require Blind Drop for Baristas',
      'blind_drop_sub': 'Baristas cannot see expected cash amounts.',
      'theme_selection': 'Select App Appearance',
      'theme_green': 'Classic Green',
      'theme_blue': 'Ocean Blue',
      'theme_dark': 'Midnight Dark',
    },
    'fr': {
      'register': 'Caisse',
      'orders': 'Commandes',
      'config': 'Configuration',
      'settings': 'Paramètres',
      'logout': 'Déconnexion',
      'manager_role': 'Gérant',
      'barista_role': 'Serveur',

      'enter_pin': 'Entrez votre code PIN',
      'invalid_pin': 'Code PIN invalide',

      'all': 'Tout',
      'coffee': 'Café',
      'pastry': 'Pâtisserie',
      'search_hint': 'Rechercher...',
      'add_to_cart': 'ajouté !',

      'active_order': 'Commande Active',
      'cashier': 'Caissier',
      'subtotal': 'Sous-total',
      'tax': 'Taxe',
      'total': 'Total',
      'total_due': 'Total à Payer',
      'checkout': 'Encaisser',
      'confirm_order': 'Confirmer Commande',
      'confirm_payment': 'Confirmer Paiement',
      'cancel': 'Annuler',

      'order_history': 'Historique',
      'close_shift': 'Fin de Poste',
      'today_revenue': 'Revenu du Jour',
      'range_total': 'Total Période',
      'avg_sale': 'Vente Moyenne',
      'void_order': 'Annuler Vente',

      'categories_tab': 'Catégories',
      'products': 'Produits',
      'staff_tab': 'Personnel',
      'theme_tab': 'Thème',

      'new_cat_label': 'Nom de la catégorie',
      'prod_name_label': 'Nom du produit',
      'price': 'Prix',
      'pick_image': 'Choisir Image',
      'save_product': 'Enregistrer Produit',
      'add_staff': 'Ajouter Personnel',
      'name': 'Nom',
      'role': 'Rôle',
      'description': 'Description',
      'add': 'Ajouter',

      'tax_config_title': 'Configuration des taxes',
      'tax_config_sub': 'Définissez votre taux de taxe.',
      'save_settings': 'Enregistrer',
      'security_settings': 'Sécurité',
      'blind_drop_title': 'Dépôt à l\'aveugle',
      'blind_drop_sub': 'Les serveurs ne voient pas les montants.',
      'theme_selection': 'Apparence',
      'theme_green': 'Vert Classique',
      'theme_blue': 'Bleu Océan',
      'theme_dark': 'Sombre Minuit',
    },
    'ar': {
      'register': 'صندوق البيع',
      'orders': 'الطلبات',
      'config': 'إعدادات المتجر',
      'settings': 'إعدادات النظام',
      'logout': 'تسجيل الخروج',
      'manager_role': 'مدير',
      'barista_role': 'باريستا',

      'enter_pin': 'أدخل رمز PIN',
      'invalid_pin': 'رمز PIN خاطئ',

      'all': 'الكل',
      'coffee': 'قهوة',
      'pastry': 'حلويات',
      'search_hint': 'بحث عن منتج...',
      'add_to_cart': 'تمت الإضافة!',

      'active_order': 'الطلب الحالي',
      'cashier': 'الكاشير',
      'subtotal': 'المجموع الفرعي',
      'tax': 'الضريبة',
      'total': 'الإجمالي',
      'total_due': 'المبلغ المستحق',
      'checkout': 'دفع وفاتورة',
      'confirm_order': 'تأكيد الطلب',
      'confirm_payment': 'تأكيد الدفع',
      'cancel': 'إلغاء',

      'order_history': 'سجل المبيعات',
      'close_shift': 'إغلاق الوردية',
      'today_revenue': 'دخل اليوم',
      'range_total': 'إجمالي الفترة',
      'avg_sale': 'متوسط البيع',
      'void_order': 'إبطال الفاتورة',

      'categories_tab': 'الفئات',
      'products': 'المنتجات',
      'staff_tab': 'الموظفون',
      'theme_tab': 'المظهر',

      'new_cat_label': 'اسم الفئة الجديدة',
      'prod_name_label': 'اسم المنتج',
      'price': 'السعر',
      'pick_image': 'اختيار صورة',
      'save_product': 'حفظ المنتج',
      'add_staff': 'إضافة موظف',
      'name': 'الاسم',
      'role': 'الدور',
      'description': 'الوصف',
      'add': 'إضافة',

      'tax_config_title': 'تكوين الضرائب',
      'tax_config_sub': 'حدد معدل ضريبة المبيعات الإقليمية.',
      'save_settings': 'حفظ الإعدادات',
      'security_settings': 'إعدادات الأمان',
      'blind_drop_title': 'تفعيل الإيداع الأعمى',
      'blind_drop_sub': 'لا يمكن للباريستا رؤية المبالغ المتوقعة.',
      'theme_selection': 'اختر مظهر التطبيق',
      'theme_green': 'الأخضر الكلاسيكي',
      'theme_blue': 'الأزرق المحيطي',
      'theme_dark': 'منتصف الليل',
    }
  };
}
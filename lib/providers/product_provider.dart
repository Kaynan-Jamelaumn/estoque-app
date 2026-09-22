import 'package:flutter/foundation.dart';
import '../database/db_helper.dart';
import '../models/product.dart';

class ProductProvider extends ChangeNotifier {
  final _db = DBHelper.instance;
  List<Product> _products = [];
  List<Map<String, dynamic>> _categories = [];
  bool loading = false;
  String? error;

  List<Product> get products => _products;
  List<Map<String, dynamic>> get categories => _categories;

  List<Product> get lowStockProducts => _products.where((p) => p.isLowStock).toList();
  List<Product> get outOfStockProducts => _products.where((p) => p.isOutOfStock).toList();
  List<Product> get overStockProducts => _products.where((p) => p.isOverStock).toList();
  List<Product> get nearExpirationProducts => _products.where((p) => p.isNearExpiration).toList();

  double get totalStockValue => _products.fold(0, (sum, p) => sum + p.stockValue);

  Future<void> loadProducts({String? search, int? categoryId}) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      _products = await _db.getProducts(search: search, categoryId: categoryId);
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> loadCategories() async {
    _categories = await _db.getCategories();
    notifyListeners();
  }

  Future<void> addCategory(String name) async {
    await _db.insertCategory(name);
    await loadCategories();
  }

  Future<int> addProduct(Product product) async {
    final id = await _db.insertProduct(product);
    await loadProducts();
    return id;
  }

  Future<void> editProduct(Product product) async {
    await _db.updateProduct(product);
    await loadProducts();
  }

  Future<void> removeProduct(int id) async {
    await _db.deleteProduct(id);
    await loadProducts();
  }

  Future<Product?> findByBarcode(String code) => _db.getProductByBarcode(code);

  Future<List<Map<String, dynamic>>> stockByLocation(int productId) =>
      _db.getStockByLocation(productId);
}

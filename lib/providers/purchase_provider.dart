import 'package:flutter/foundation.dart';
import '../database/db_helper.dart';
import '../models/purchase_order.dart';

class PurchaseProvider extends ChangeNotifier {
  final _db = DBHelper.instance;
  List<PurchaseOrder> _orders = [];
  List<Map<String, dynamic>> _suggestions = [];

  List<PurchaseOrder> get orders => _orders;
  List<Map<String, dynamic>> get suggestions => _suggestions;

  Future<void> loadOrders({PurchaseStatus? status}) async {
    _orders = await _db.getPurchaseOrders(status: status);
    notifyListeners();
  }

  Future<void> loadSuggestions() async {
    _suggestions = await _db.getPurchaseSuggestions();
    notifyListeners();
  }

  Future<void> createOrder(PurchaseOrder order) async {
    await _db.insertPurchaseOrder(order);
    await loadOrders();
  }

  Future<void> receiveOrder(PurchaseOrder order) async {
    await _db.receivePurchaseOrder(order);
    await loadOrders();
  }

  Future<void> cancelOrder(int id) async {
    await _db.cancelPurchaseOrder(id);
    await loadOrders();
  }
}

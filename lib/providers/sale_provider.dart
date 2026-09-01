import 'package:flutter/foundation.dart';
import '../database/db_helper.dart';
import '../models/sale.dart';

class SaleProvider extends ChangeNotifier {
  final _db = DBHelper.instance;
  List<Sale> _sales = [];
  List<Sale> get sales => _sales;

  Future<void> loadSales({DateTime? from, DateTime? to}) async {
    _sales = await _db.getSales(from: from, to: to);
    notifyListeners();
  }

  Future<int> checkout(Sale sale) async {
    final id = await _db.insertSale(sale);
    await loadSales();
    return id;
  }
}

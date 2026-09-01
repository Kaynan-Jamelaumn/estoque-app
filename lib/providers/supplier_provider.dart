import 'package:flutter/foundation.dart';
import '../database/db_helper.dart';
import '../models/supplier.dart';

class SupplierProvider extends ChangeNotifier {
  final _db = DBHelper.instance;
  List<Supplier> _suppliers = [];
  List<Supplier> get suppliers => _suppliers;

  Future<void> loadSuppliers() async {
    final rows = await _db.getSuppliers();
    _suppliers = rows.map((r) => Supplier.fromMap(r)).toList();
    notifyListeners();
  }

  Future<void> addSupplier(Supplier s) async {
    await _db.insertSupplier(s.toMap());
    await loadSuppliers();
  }

  Future<void> editSupplier(Supplier s) async {
    await _db.updateSupplier(s.id!, s.toMap());
    await loadSuppliers();
  }

  Future<void> removeSupplier(int id) async {
    await _db.deleteSupplier(id);
    await loadSuppliers();
  }
}

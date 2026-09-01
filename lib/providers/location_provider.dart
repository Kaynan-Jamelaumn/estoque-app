import 'package:flutter/foundation.dart';
import '../database/db_helper.dart';
import '../models/location.dart';

class LocationProvider extends ChangeNotifier {
  final _db = DBHelper.instance;
  List<StockLocation> _locations = [];
  List<StockLocation> get locations => _locations;

  Future<void> loadLocations() async {
    final rows = await _db.getLocations();
    _locations = rows.map((r) => StockLocation.fromMap(r)).toList();
    notifyListeners();
  }

  Future<void> addLocation(StockLocation loc) async {
    await _db.insertLocation(loc.toMap());
    await loadLocations();
  }
}

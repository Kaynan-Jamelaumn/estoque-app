import 'package:flutter/foundation.dart';
import '../database/db_helper.dart';
import '../models/stock_movement.dart';

class MovementProvider extends ChangeNotifier {
  final _db = DBHelper.instance;
  List<StockMovement> _movements = [];
  List<StockMovement> get movements => _movements;

  Future<void> loadMovements({int? productId, MovementType? type}) async {
    _movements = await _db.getMovements(productId: productId, type: type);
    notifyListeners();
  }

  /// Registra movimentação simples (entrada, saída, devolução, perda).
  Future<void> registerSimple({
    required int productId,
    required MovementType type,
    required double quantity,
    required int locationId,
    String? reason,
    String? document,
  }) async {
    await _db.registerMovement(StockMovement(
      productId: productId,
      type: type,
      quantity: quantity,
      locationId: locationId,
      reason: reason,
      document: document,
    ));
    await loadMovements();
  }

  /// Ajuste manual: define a quantidade final do inventário para o local.
  Future<void> registerAdjustment({
    required int productId,
    required int locationId,
    required double finalQuantity,
    required double currentQuantity,
    String? reason,
  }) async {
    await _db.registerMovement(
      StockMovement(
        productId: productId,
        type: MovementType.ajuste,
        quantity: finalQuantity - currentQuantity,
        locationId: locationId,
        reason: reason ?? 'Ajuste manual de inventário',
      ),
      adjustToValue: finalQuantity,
    );
    await loadMovements();
  }

  Future<void> registerTransfer({
    required int productId,
    required int fromLocationId,
    required int toLocationId,
    required double quantity,
    String? reason,
  }) async {
    await _db.registerMovement(StockMovement(
      productId: productId,
      type: MovementType.transferencia,
      quantity: quantity,
      locationId: fromLocationId,
      destinationLocationId: toLocationId,
      reason: reason ?? 'Transferência entre locais',
    ));
    await loadMovements();
  }
}

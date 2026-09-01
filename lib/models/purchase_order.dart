enum PurchaseStatus { pedido, recebido, cancelado }

extension PurchaseStatusX on PurchaseStatus {
  String get label {
    switch (this) {
      case PurchaseStatus.pedido:
        return 'Pedido';
      case PurchaseStatus.recebido:
        return 'Recebido';
      case PurchaseStatus.cancelado:
        return 'Cancelado';
    }
  }
}

class PurchaseOrderItem {
  final int? id;
  final int? purchaseOrderId;
  final int productId;
  final String? productName; // join
  final double quantity;
  final double unitCost;

  PurchaseOrderItem({
    this.id,
    this.purchaseOrderId,
    required this.productId,
    this.productName,
    required this.quantity,
    required this.unitCost,
  });

  double get total => quantity * unitCost;

  factory PurchaseOrderItem.fromMap(Map<String, dynamic> map) =>
      PurchaseOrderItem(
        id: map['id'] as int?,
        purchaseOrderId: map['purchase_order_id'] as int?,
        productId: map['product_id'] as int,
        productName: map['product_name'] as String?,
        quantity: (map['quantity'] as num).toDouble(),
        unitCost: (map['unit_cost'] as num).toDouble(),
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'purchase_order_id': purchaseOrderId,
        'product_id': productId,
        'quantity': quantity,
        'unit_cost': unitCost,
      };
}

class PurchaseOrder {
  final int? id;
  final int supplierId;
  final String? supplierName; // join
  final int locationId;
  final PurchaseStatus status;
  final DateTime orderDate;
  final DateTime? expectedDate;
  final DateTime? receivedDate;
  final List<PurchaseOrderItem> items;

  PurchaseOrder({
    this.id,
    required this.supplierId,
    this.supplierName,
    required this.locationId,
    this.status = PurchaseStatus.pedido,
    DateTime? orderDate,
    this.expectedDate,
    this.receivedDate,
    this.items = const [],
  }) : orderDate = orderDate ?? DateTime.now();

  double get total => items.fold(0, (sum, i) => sum + i.total);

  factory PurchaseOrder.fromMap(Map<String, dynamic> map,
          {List<PurchaseOrderItem> items = const []}) =>
      PurchaseOrder(
        id: map['id'] as int?,
        supplierId: map['supplier_id'] as int,
        supplierName: map['supplier_name'] as String?,
        locationId: map['location_id'] as int,
        status: PurchaseStatus.values.firstWhere(
            (e) => e.name == map['status'],
            orElse: () => PurchaseStatus.pedido),
        orderDate: DateTime.parse(map['order_date'] as String),
        expectedDate: map['expected_date'] != null
            ? DateTime.parse(map['expected_date'] as String)
            : null,
        receivedDate: map['received_date'] != null
            ? DateTime.parse(map['received_date'] as String)
            : null,
        items: items,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'supplier_id': supplierId,
        'location_id': locationId,
        'status': status.name,
        'order_date': orderDate.toIso8601String(),
        'expected_date': expectedDate?.toIso8601String(),
        'received_date': receivedDate?.toIso8601String(),
      };
}

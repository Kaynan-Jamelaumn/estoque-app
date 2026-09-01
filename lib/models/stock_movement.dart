enum MovementType {
  entrada,
  saida,
  devolucao,
  perda,
  ajuste,
  transferencia,
}

extension MovementTypeX on MovementType {
  String get label {
    switch (this) {
      case MovementType.entrada:
        return 'Entrada';
      case MovementType.saida:
        return 'Saída';
      case MovementType.devolucao:
        return 'Devolução';
      case MovementType.perda:
        return 'Perda/Avaria';
      case MovementType.ajuste:
        return 'Ajuste manual';
      case MovementType.transferencia:
        return 'Transferência';
    }
  }

  // true = soma no estoque, false = subtrai
  bool get isPositive {
    switch (this) {
      case MovementType.entrada:
      case MovementType.devolucao:
        return true;
      case MovementType.saida:
      case MovementType.perda:
        return false;
      case MovementType.ajuste:
      case MovementType.transferencia:
        return true; // tratado com sinal explícito na quantidade/lógica própria
    }
  }
}

class StockMovement {
  final int? id;
  final int productId;
  final String? productName; // join
  final MovementType type;
  final double quantity; // sempre positiva; sinal é definido pelo type
  final int locationId;
  final String? locationName; // join
  final int? destinationLocationId; // usado em transferências
  final String? destinationLocationName; // join
  final DateTime date;
  final String? reason;
  final String? document; // nota fiscal, pedido, etc.

  StockMovement({
    this.id,
    required this.productId,
    this.productName,
    required this.type,
    required this.quantity,
    required this.locationId,
    this.locationName,
    this.destinationLocationId,
    this.destinationLocationName,
    DateTime? date,
    this.reason,
    this.document,
  }) : date = date ?? DateTime.now();

  factory StockMovement.fromMap(Map<String, dynamic> map) => StockMovement(
        id: map['id'] as int?,
        productId: map['product_id'] as int,
        productName: map['product_name'] as String?,
        type: MovementType.values.firstWhere(
            (e) => e.name == map['type'],
            orElse: () => MovementType.ajuste),
        quantity: (map['quantity'] as num).toDouble(),
        locationId: map['location_id'] as int,
        locationName: map['location_name'] as String?,
        destinationLocationId: map['destination_location_id'] as int?,
        destinationLocationName: map['destination_location_name'] as String?,
        date: DateTime.parse(map['date'] as String),
        reason: map['reason'] as String?,
        document: map['document'] as String?,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'product_id': productId,
        'type': type.name,
        'quantity': quantity,
        'location_id': locationId,
        'destination_location_id': destinationLocationId,
        'date': date.toIso8601String(),
        'reason': reason,
        'document': document,
      };
}

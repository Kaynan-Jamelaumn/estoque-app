class SaleItem {
  final int? id;
  final int? saleId;
  final int productId;
  final String? productName; // join
  final double quantity;
  final double unitPrice;

  SaleItem({
    this.id,
    this.saleId,
    required this.productId,
    this.productName,
    required this.quantity,
    required this.unitPrice,
  });

  double get total => quantity * unitPrice;

  factory SaleItem.fromMap(Map<String, dynamic> map) => SaleItem(
        id: map['id'] as int?,
        saleId: map['sale_id'] as int?,
        productId: map['product_id'] as int,
        productName: map['product_name'] as String?,
        quantity: (map['quantity'] as num).toDouble(),
        unitPrice: (map['unit_price'] as num).toDouble(),
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'sale_id': saleId,
        'product_id': productId,
        'quantity': quantity,
        'unit_price': unitPrice,
      };
}

class Sale {
  final int? id;
  final String? customerName;
  final int locationId;
  final DateTime date;
  final double discount;
  final String paymentMethod;
  final List<SaleItem> items;

  Sale({
    this.id,
    this.customerName,
    required this.locationId,
    DateTime? date,
    this.discount = 0,
    this.paymentMethod = 'Dinheiro',
    this.items = const [],
  }) : date = date ?? DateTime.now();

  double get subtotal => items.fold(0, (sum, i) => sum + i.total);
  double get total => (subtotal - discount).clamp(0, double.infinity);

  factory Sale.fromMap(Map<String, dynamic> map,
          {List<SaleItem> items = const []}) =>
      Sale(
        id: map['id'] as int?,
        customerName: map['customer_name'] as String?,
        locationId: map['location_id'] as int,
        date: DateTime.parse(map['date'] as String),
        discount: (map['discount'] as num?)?.toDouble() ?? 0,
        paymentMethod: map['payment_method'] as String? ?? 'Dinheiro',
        items: items,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'customer_name': customerName,
        'location_id': locationId,
        'date': date.toIso8601String(),
        'discount': discount,
        'payment_method': paymentMethod,
      };
}

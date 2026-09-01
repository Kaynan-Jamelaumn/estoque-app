class Product {
  final int? id;
  final String name;
  final String sku;
  final String? barcode;
  final int? categoryId;
  final String? categoryName; // preenchido em joins
  final String? brand;
  final String? description;
  final String? photoPath;
  final String unit; // un, kg, l, cx, etc.
  final double costPrice;
  final double salePrice;
  final double minStock;
  final double maxStock;
  final int? supplierId;
  final String? supplierName; // preenchido em joins
  final DateTime createdAt;
  final DateTime? expirationDate;

  // Preenchido dinamicamente (não persistido diretamente nesta tabela)
  final double currentStock;

  Product({
    this.id,
    required this.name,
    required this.sku,
    this.barcode,
    this.categoryId,
    this.categoryName,
    this.brand,
    this.description,
    this.photoPath,
    this.unit = 'un',
    this.costPrice = 0,
    this.salePrice = 0,
    this.minStock = 0,
    this.maxStock = 0,
    this.supplierId,
    this.supplierName,
    DateTime? createdAt,
    this.expirationDate,
    this.currentStock = 0,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Product.fromMap(Map<String, dynamic> map) => Product(
        id: map['id'] as int?,
        name: map['name'] as String,
        sku: map['sku'] as String,
        barcode: map['barcode'] as String?,
        categoryId: map['category_id'] as int?,
        categoryName: map['category_name'] as String?,
        brand: map['brand'] as String?,
        description: map['description'] as String?,
        photoPath: map['photo_path'] as String?,
        unit: map['unit'] as String? ?? 'un',
        costPrice: (map['cost_price'] as num?)?.toDouble() ?? 0,
        salePrice: (map['sale_price'] as num?)?.toDouble() ?? 0,
        minStock: (map['min_stock'] as num?)?.toDouble() ?? 0,
        maxStock: (map['max_stock'] as num?)?.toDouble() ?? 0,
        supplierId: map['supplier_id'] as int?,
        supplierName: map['supplier_name'] as String?,
        createdAt: map['created_at'] != null
            ? DateTime.parse(map['created_at'] as String)
            : DateTime.now(),
        expirationDate: map['expiration_date'] != null
            ? DateTime.parse(map['expiration_date'] as String)
            : null,
        currentStock: (map['current_stock'] as num?)?.toDouble() ?? 0,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'sku': sku,
        'barcode': barcode,
        'category_id': categoryId,
        'brand': brand,
        'description': description,
        'photo_path': photoPath,
        'unit': unit,
        'cost_price': costPrice,
        'sale_price': salePrice,
        'min_stock': minStock,
        'max_stock': maxStock,
        'supplier_id': supplierId,
        'created_at': createdAt.toIso8601String(),
        'expiration_date': expirationDate?.toIso8601String(),
      };

  Product copyWith({
    int? id,
    String? name,
    String? sku,
    String? barcode,
    int? categoryId,
    String? brand,
    String? description,
    String? photoPath,
    String? unit,
    double? costPrice,
    double? salePrice,
    double? minStock,
    double? maxStock,
    int? supplierId,
    DateTime? expirationDate,
    double? currentStock,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName,
      brand: brand ?? this.brand,
      description: description ?? this.description,
      photoPath: photoPath ?? this.photoPath,
      unit: unit ?? this.unit,
      costPrice: costPrice ?? this.costPrice,
      salePrice: salePrice ?? this.salePrice,
      minStock: minStock ?? this.minStock,
      maxStock: maxStock ?? this.maxStock,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName,
      createdAt: createdAt,
      expirationDate: expirationDate ?? this.expirationDate,
      currentStock: currentStock ?? this.currentStock,
    );
  }

  bool get isLowStock => currentStock <= minStock && currentStock > 0;
  bool get isOutOfStock => currentStock <= 0;
  bool get isOverStock => maxStock > 0 && currentStock > maxStock;
  bool get isNearExpiration =>
      expirationDate != null &&
      expirationDate!.difference(DateTime.now()).inDays <= 30 &&
      expirationDate!.isAfter(DateTime.now());
  bool get isExpired =>
      expirationDate != null && expirationDate!.isBefore(DateTime.now());

  double get stockValue => currentStock * costPrice;
}

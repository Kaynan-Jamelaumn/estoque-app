class StockLocation {
  final int? id;
  final String name;
  final String? description;

  StockLocation({this.id, required this.name, this.description});

  factory StockLocation.fromMap(Map<String, dynamic> map) => StockLocation(
        id: map['id'] as int?,
        name: map['name'] as String,
        description: map['description'] as String?,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'description': description,
      };
}

class Client {
  final int? id;
  final String name;
  final String? phone;
  final String? email;
  final String? notes;
  final DateTime createdAt;

  Client({
    this.id,
    required this.name,
    this.phone,
    this.email,
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Client.fromMap(Map<String, dynamic> map) => Client(
        id: map['id'] as int?,
        name: map['name'] as String,
        phone: map['phone'] as String?,
        email: map['email'] as String?,
        notes: map['notes'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String),
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'phone': phone,
        'email': email,
        'notes': notes,
        'created_at': createdAt.toIso8601String(),
      };
}

class Supplier {
  final int? id;
  final String name;
  final String? contactName;
  final String? phone;
  final String? email;
  final String? address;

  Supplier({
    this.id,
    required this.name,
    this.contactName,
    this.phone,
    this.email,
    this.address,
  });

  factory Supplier.fromMap(Map<String, dynamic> map) => Supplier(
        id: map['id'] as int?,
        name: map['name'] as String,
        contactName: map['contact_name'] as String?,
        phone: map['phone'] as String?,
        email: map['email'] as String?,
        address: map['address'] as String?,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'contact_name': contactName,
        'phone': phone,
        'email': email,
        'address': address,
      };
}

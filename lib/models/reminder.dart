class Reminder {
  final int? id;
  final int? clientId;
  final String? clientName;
  final int? productId;
  final String? productName;
  final int? saleId;
  final DateTime dueDate;
  final String? note;
  final bool done;
  final DateTime createdAt;

  Reminder({
    this.id,
    this.clientId,
    this.clientName,
    this.productId,
    this.productName,
    this.saleId,
    required this.dueDate,
    this.note,
    this.done = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isOverdue => !done && dueDate.isBefore(DateTime.now());

  factory Reminder.fromMap(Map<String, dynamic> map) => Reminder(
        id: map['id'] as int?,
        clientId: map['client_id'] as int?,
        clientName: map['client_name'] as String?,
        productId: map['product_id'] as int?,
        productName: map['product_name'] as String?,
        saleId: map['sale_id'] as int?,
        dueDate: DateTime.parse(map['due_date'] as String),
        note: map['note'] as String?,
        done: (map['done'] as int? ?? 0) != 0,
        createdAt: DateTime.parse(map['created_at'] as String),
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'client_id': clientId,
        'client_name': clientName,
        'product_id': productId,
        'product_name': productName,
        'sale_id': saleId,
        'due_date': dueDate.toIso8601String(),
        'note': note,
        'done': done ? 1 : 0,
        'created_at': createdAt.toIso8601String(),
      };
}

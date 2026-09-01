import 'dart:io';
import 'package:flutter/material.dart';
import '../models/product.dart';
import '../utils/formatters.dart';

class ProductTile extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;

  const ProductTile({super.key, required this.product, this.onTap});

  @override
  Widget build(BuildContext context) {
    Color statusColor = Colors.green;
    String statusText = 'OK';
    if (product.isOutOfStock) {
      statusColor = Colors.red;
      statusText = 'Sem estoque';
    } else if (product.isLowStock) {
      statusColor = Colors.orange;
      statusText = 'Estoque baixo';
    } else if (product.isOverStock) {
      statusColor = Colors.blue;
      statusText = 'Excesso';
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: Colors.grey[200],
          backgroundImage: product.photoPath != null &&
                  File(product.photoPath!).existsSync()
              ? FileImage(File(product.photoPath!))
              : null,
          child: product.photoPath == null
              ? const Icon(Icons.inventory_2_outlined, color: Colors.grey)
              : null,
        ),
        title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('SKU: ${product.sku} • ${product.categoryName ?? "Sem categoria"}'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('${formatQty(product.currentStock)} ${product.unit}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(statusText,
                  style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

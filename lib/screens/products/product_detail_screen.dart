import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:barcode_widget/barcode_widget.dart';
import '../../database/db_helper.dart';
import '../../models/product.dart';
import '../../models/stock_movement.dart';
import '../../providers/product_provider.dart';
import '../../utils/formatters.dart';
import 'product_form_screen.dart';
import '../movements/movement_form_screen.dart';
import '../movements/movement_list_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final int productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final _db = DBHelper.instance;
  Product? _product;
  List<Map<String, dynamic>> _stockByLocation = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final product = await _db.getProductById(widget.productId);
    final stock = await _db.getStockByLocation(widget.productId);
    if (!mounted) return;
    setState(() {
      _product = product;
      _stockByLocation = stock;
      _loading = false;
    });
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir produto'),
        content: const Text('Tem certeza que deseja excluir este produto? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await context.read<ProductProvider>().removeProduct(widget.productId);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _product == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final p = _product!;

    return Scaffold(
      appBar: AppBar(
        title: Text(p.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => ProductFormScreen(product: p)));
              _load();
            },
          ),
          IconButton(icon: const Icon(Icons.delete_outline), onPressed: _delete),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_product_detail',
        onPressed: () async {
          _load();
        },
        icon: const Icon(Icons.swap_vert),
        label: const Text('Movimentar'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: CircleAvatar(
                radius: 44,
                backgroundColor: Colors.grey[200],
                backgroundImage: p.photoPath != null && File(p.photoPath!).existsSync()
                    ? FileImage(File(p.photoPath!))
                    : null,
                child: p.photoPath == null ? const Icon(Icons.inventory_2_outlined, size: 34, color: Colors.grey) : null,
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text('SKU: ${p.sku}', style: TextStyle(color: Colors.grey[700])),
            ),
            if (p.categoryName != null)
              Center(child: Text(p.categoryName!, style: TextStyle(color: Colors.grey[500], fontSize: 12))),
            const SizedBox(height: 16),
            _infoCard('Estoque atual total', '${formatQty(p.currentStock)} ${p.unit}',
                highlight: p.isOutOfStock ? Colors.red : (p.isLowStock ? Colors.orange : Colors.green)),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Estoque por local', style: TextStyle(fontWeight: FontWeight.bold)),
                    const Divider(),
                    ..._stockByLocation.map((s) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(s['location_name'] as String),
                              Text('${formatQty((s['quantity'] as num).toDouble())} ${p.unit}',
                                  style: const TextStyle(fontWeight: FontWeight.w600)),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _infoCard('Custo', currencyFormat.format(p.costPrice))),
                const SizedBox(width: 8),
                Expanded(child: _infoCard('Venda', currencyFormat.format(p.salePrice))),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _infoCard('Mín.', '${formatQty(p.minStock)} ${p.unit}')),
                const SizedBox(width: 8),
                Expanded(child: _infoCard('Máx.', '${formatQty(p.maxStock)} ${p.unit}')),
              ],
            ),
            if (p.brand != null || p.supplierName != null) ...[
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (p.brand != null) Text('Marca: ${p.brand}'),
                      if (p.supplierName != null) Text('Fornecedor: ${p.supplierName}'),
                      if (p.expirationDate != null)
                        Text('Vencimento: ${dateFormat.format(p.expirationDate!)}',
                            style: TextStyle(color: p.isExpired ? Colors.red : (p.isNearExpiration ? Colors.orange : null))),
                    ],
                  ),
                ),
              ),
            ],
            if (p.description != null && p.description!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Descrição', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(p.description!),
                    ],
                  ),
                ),
              ),
            ],
            if (p.barcode != null && p.barcode!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      const Align(alignment: Alignment.centerLeft, child: Text('Código de barras', style: TextStyle(fontWeight: FontWeight.bold))),
                      const SizedBox(height: 8),
                      BarcodeWidget(
                        barcode: Barcode.code128(),
                        data: p.barcode!,
                        height: 70,
                        drawText: true,
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => MovementListScreen(productFilter: p))),
              icon: const Icon(Icons.history),
              label: const Text('Ver histórico de movimentações'),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(String label, String value, {Color? highlight}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: highlight)),
          ],
        ),
      ),
    );
  }
}

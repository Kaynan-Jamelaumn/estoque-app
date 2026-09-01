import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../models/purchase_order.dart';
import '../../providers/product_provider.dart';
import '../../providers/supplier_provider.dart';
import '../../providers/purchase_provider.dart';
import '../../providers/location_provider.dart';
import '../../utils/formatters.dart';

class PurchaseFormScreen extends StatefulWidget {
  const PurchaseFormScreen({super.key});
  @override
  State<PurchaseFormScreen> createState() => _PurchaseFormScreenState();
}

class _PurchaseFormScreenState extends State<PurchaseFormScreen> {
  int? _supplierId;
  int? _locationId;
  DateTime? _expectedDate;
  final List<PurchaseOrderItem> _items = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SupplierProvider>().loadSuppliers();
      context.read<ProductProvider>().loadProducts();
      context.read<LocationProvider>().loadLocations().then((_) {
        final locs = context.read<LocationProvider>().locations;
        if (locs.isNotEmpty) setState(() => _locationId = locs.first.id);
      });
    });
  }

  Future<void> _addItem() async {
    final products = context.read<ProductProvider>().products;
    final result = await showModalBottomSheet<PurchaseOrderItem>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AddItemSheet(products: products),
    );
    if (result != null) setState(() => _items.add(result));
  }

  double get _total => _items.fold(0, (sum, i) => sum + i.total);

  Future<void> _save() async {
    if (_supplierId == null || _locationId == null || _items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecione fornecedor, local e adicione ao menos um item')));
      return;
    }
    final order = PurchaseOrder(
      supplierId: _supplierId!,
      locationId: _locationId!,
      expectedDate: _expectedDate,
      items: _items,
    );
    try {
      await context.read<PurchaseProvider>().createOrder(order);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao criar pedido: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final suppliers = context.watch<SupplierProvider>().suppliers;
    final locations = context.watch<LocationProvider>().locations;

    return Scaffold(
      appBar: AppBar(title: const Text('Novo pedido de compra')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<int>(
            value: _supplierId,
            decoration: const InputDecoration(labelText: 'Fornecedor *', border: OutlineInputBorder()),
            items: suppliers.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
            onChanged: (v) => setState(() => _supplierId = v),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            value: _locationId,
            decoration: const InputDecoration(labelText: 'Local de recebimento *', border: OutlineInputBorder()),
            items: locations.map((l) => DropdownMenuItem(value: l.id, child: Text(l.name))).toList(),
            onChanged: (v) => setState(() => _locationId = v),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(_expectedDate == null
                ? 'Previsão de recebimento (opcional)'
                : 'Previsão: ${dateFormat.format(_expectedDate!)}'),
            trailing: const Icon(Icons.calendar_month),
            onTap: () async {
              final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)));
              if (date != null) setState(() => _expectedDate = date);
            },
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Itens do pedido', style: TextStyle(fontWeight: FontWeight.bold)),
              TextButton.icon(onPressed: _addItem, icon: const Icon(Icons.add), label: const Text('Adicionar')),
            ],
          ),
          ..._items.map((it) => ListTile(
                title: Text(it.productName ?? ''),
                subtitle: Text('${formatQty(it.quantity)} x ${currencyFormat.format(it.unitCost)}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => setState(() => _items.remove(it)),
                ),
              )),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(currencyFormat.format(_total), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(onPressed: _save, icon: const Icon(Icons.save), label: const Text('Criar pedido')),
        ],
      ),
    );
  }
}

class _AddItemSheet extends StatefulWidget {
  final List<Product> products;
  const _AddItemSheet({required this.products});
  @override
  State<_AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<_AddItemSheet> {
  Product? _product;
  final _qty = TextEditingController();
  final _cost = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          left: 16, right: 16, top: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<Product>(
            value: _product,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Produto', border: OutlineInputBorder()),
            items: widget.products
                .map((p) => DropdownMenuItem(value: p, child: Text(p.name, overflow: TextOverflow.ellipsis)))
                .toList(),
            onChanged: (v) {
              setState(() {
                _product = v;
                _cost.text = v?.costPrice.toString() ?? '';
              });
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _qty,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Quantidade', border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _cost,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Custo unitário', border: OutlineInputBorder()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              if (_product == null) return;
              final qty = double.tryParse(_qty.text.replaceAll(',', '.')) ?? 0;
              final cost = double.tryParse(_cost.text.replaceAll(',', '.')) ?? 0;
              if (qty <= 0) return;
              Navigator.pop(
                  context,
                  PurchaseOrderItem(
                      productId: _product!.id!, productName: _product!.name, quantity: qty, unitCost: cost));
            },
            child: const Text('Adicionar item'),
          ),
        ],
      ),
    );
  }
}

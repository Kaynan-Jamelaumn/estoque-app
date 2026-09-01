import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../models/sale.dart';
import '../../providers/product_provider.dart';
import '../../providers/sale_provider.dart';
import '../../providers/location_provider.dart';
import '../../utils/formatters.dart';
import '../barcode/barcode_scanner_screen.dart';

class SaleFormScreen extends StatefulWidget {
  const SaleFormScreen({super.key});
  @override
  State<SaleFormScreen> createState() => _SaleFormScreenState();
}

class _SaleFormScreenState extends State<SaleFormScreen> {
  final _customerController = TextEditingController();
  final _discountController = TextEditingController(text: '0');
  String _paymentMethod = 'Dinheiro';
  int? _locationId;
  final List<SaleItem> _items = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProducts();
      context.read<LocationProvider>().loadLocations().then((_) {
        final locs = context.read<LocationProvider>().locations;
        if (locs.isNotEmpty) setState(() => _locationId = locs.first.id);
      });
    });
  }

  double get _subtotal => _items.fold(0, (sum, i) => sum + i.total);
  double get _discount => double.tryParse(_discountController.text.replaceAll(',', '.')) ?? 0;
  double get _total => (_subtotal - _discount).clamp(0, double.infinity);

  Future<void> _addProduct() async {
    final products = context.read<ProductProvider>().products;
    final selected = await showModalBottomSheet<Product>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ProductPickerSheet(products: products),
    );
    if (selected == null) return;
    if (selected.currentStock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Produto sem estoque disponível')));
      return;
    }
    setState(() {
      _items.add(SaleItem(
          productId: selected.id!, productName: selected.name, quantity: 1, unitPrice: selected.salePrice));
    });
  }

  Future<void> _scanProduct() async {
    final code = await Navigator.push<String>(
        context, MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()));
    if (code == null || !mounted) return;
    final product = await context.read<ProductProvider>().findByBarcode(code);
    if (product == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Produto não encontrado')));
      return;
    }
    setState(() {
      _items.add(
          SaleItem(productId: product.id!, productName: product.name, quantity: 1, unitPrice: product.salePrice));
    });
  }

  Future<void> _checkout() async {
    if (_items.isEmpty || _locationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Adicione ao menos um produto')));
      return;
    }
    final sale = Sale(
      customerName: _customerController.text.trim(),
      locationId: _locationId!,
      discount: _discount,
      paymentMethod: _paymentMethod,
      items: _items,
    );
    try {
      await context.read<SaleProvider>().checkout(sale);
      await context.read<ProductProvider>().loadProducts();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final locations = context.watch<LocationProvider>().locations;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova venda'),
        actions: [IconButton(icon: const Icon(Icons.qr_code_scanner), onPressed: _scanProduct)],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: SafeArea(
          child: FilledButton.icon(
            onPressed: _checkout,
            icon: const Icon(Icons.check_circle_outline),
            label: Text('Finalizar venda • ${currencyFormat.format(_total)}'),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _customerController,
            decoration: const InputDecoration(labelText: 'Cliente (opcional)', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            value: _locationId,
            decoration: const InputDecoration(labelText: 'Local da venda', border: OutlineInputBorder()),
            items: locations.map((l) => DropdownMenuItem(value: l.id, child: Text(l.name))).toList(),
            onChanged: (v) => setState(() => _locationId = v),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _paymentMethod,
            decoration: const InputDecoration(labelText: 'Forma de pagamento', border: OutlineInputBorder()),
            items: ['Dinheiro', 'Cartão de crédito', 'Cartão de débito', 'Pix', 'Boleto']
                .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                .toList(),
            onChanged: (v) => setState(() => _paymentMethod = v ?? 'Dinheiro'),
          ),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Itens', style: TextStyle(fontWeight: FontWeight.bold)),
              TextButton.icon(onPressed: _addProduct, icon: const Icon(Icons.add), label: const Text('Adicionar')),
            ],
          ),
          ..._items.asMap().entries.map((entry) {
            final i = entry.key;
            final it = entry.value;
            return Card(
              child: ListTile(
                title: Text(it.productName ?? ''),
                subtitle: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: () {
                        if (it.quantity > 1) {
                          setState(() => _items[i] =
                              SaleItem(productId: it.productId, productName: it.productName, quantity: it.quantity - 1, unitPrice: it.unitPrice));
                        }
                      },
                    ),
                    Text(formatQty(it.quantity)),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () => setState(() => _items[i] = SaleItem(
                          productId: it.productId, productName: it.productName, quantity: it.quantity + 1, unitPrice: it.unitPrice)),
                    ),
                    Text('x ${currencyFormat.format(it.unitPrice)}'),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => setState(() => _items.removeAt(i)),
                ),
              ),
            );
          }),
          const Divider(),
          TextField(
            controller: _discountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Desconto (R\$)', border: OutlineInputBorder()),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Subtotal'),
              Text(currencyFormat.format(_subtotal)),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(currencyFormat.format(_total), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _ProductPickerSheet extends StatefulWidget {
  final List<Product> products;
  const _ProductPickerSheet({required this.products});
  @override
  State<_ProductPickerSheet> createState() => _ProductPickerSheetState();
}

class _ProductPickerSheetState extends State<_ProductPickerSheet> {
  String _query = '';
  @override
  Widget build(BuildContext context) {
    final filtered = widget.products.where((p) => p.name.toLowerCase().contains(_query.toLowerCase())).toList();
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      expand: false,
      builder: (context, scrollController) => Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              autofocus: true,
              decoration: const InputDecoration(hintText: 'Buscar produto', prefixIcon: Icon(Icons.search)),
              onChanged: (v) => setState(() => _query = v),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: filtered.length,
                itemBuilder: (context, i) {
                  final p = filtered[i];
                  return ListTile(
                    title: Text(p.name),
                    subtitle: Text('Estoque: ${formatQty(p.currentStock)} • ${currencyFormat.format(p.salePrice)}'),
                    onTap: () => Navigator.pop(context, p),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../models/stock_movement.dart';
import '../../providers/product_provider.dart';
import '../../providers/movement_provider.dart';
import '../../providers/location_provider.dart';
import '../../database/db_helper.dart';
import '../barcode/barcode_scanner_screen.dart';

class MovementFormScreen extends StatefulWidget {
  final Product? preselectedProduct;
  const MovementFormScreen({super.key, this.preselectedProduct});

  @override
  State<MovementFormScreen> createState() => _MovementFormScreenState();
}

class _MovementFormScreenState extends State<MovementFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _qtyController = TextEditingController();
  final _reasonController = TextEditingController();
  final _documentController = TextEditingController();

  MovementType _type = MovementType.entrada;
  Product? _product;
  int? _locationId;
  int? _destinationLocationId;
  double _currentQtyAtLocation = 0;

  @override
  void initState() {
    super.initState();
    _product = widget.preselectedProduct;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final locProv = context.read<LocationProvider>();
      await locProv.loadLocations();
      if (locProv.locations.isNotEmpty) {
        setState(() => _locationId = locProv.locations.first.id);
        _refreshCurrentQty();
      }
    });
  }

  Future<void> _refreshCurrentQty() async {
    if (_product == null || _locationId == null) return;
    final stock = await DBHelper.instance.getStockByLocation(_product!.id!);
    final row = stock.firstWhere((s) => s['location_id'] == _locationId, orElse: () => {'quantity': 0});
    setState(() => _currentQtyAtLocation = (row['quantity'] as num).toDouble());
  }

  Future<void> _pickProduct() async {
    final prov = context.read<ProductProvider>();
    if (prov.products.isEmpty) await prov.loadProducts();
    if (!mounted) return;
    final selected = await showModalBottomSheet<Product>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ProductPickerSheet(products: prov.products),
    );
    if (selected != null) {
      setState(() => _product = selected);
      _refreshCurrentQty();
    }
  }

  Future<void> _scanProduct() async {
    final code = await Navigator.push<String>(
        context, MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()));
    if (code == null || !mounted) return;
    final product = await context.read<ProductProvider>().findByBarcode(code);
    if (product != null) {
      setState(() => _product = product);
      _refreshCurrentQty();
    } else if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Nenhum produto encontrado com este código')));
    }
  }

  Future<void> _submit() async {
    if (_product == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecione um produto')));
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    final qty = double.tryParse(_qtyController.text.replaceAll(',', '.')) ?? 0;
    if (qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Informe uma quantidade válida')));
      return;
    }
    if (_locationId == null) return;

    final movementProv = context.read<MovementProvider>();

    try {
      if (_type == MovementType.transferencia) {
        if (_destinationLocationId == null || _destinationLocationId == _locationId) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Selecione um local de destino diferente da origem')));
          return;
        }
        await movementProv.registerTransfer(
          productId: _product!.id!,
          fromLocationId: _locationId!,
          toLocationId: _destinationLocationId!,
          quantity: qty,
          reason: _reasonController.text.trim().isEmpty ? null : _reasonController.text.trim(),
        );
      } else if (_type == MovementType.ajuste) {
        await movementProv.registerAdjustment(
          productId: _product!.id!,
          locationId: _locationId!,
          finalQuantity: qty,
          currentQuantity: _currentQtyAtLocation,
          reason: _reasonController.text.trim().isEmpty ? null : _reasonController.text.trim(),
        );
      } else {
        await movementProv.registerSimple(
          productId: _product!.id!,
          type: _type,
          quantity: qty,
          locationId: _locationId!,
          reason: _reasonController.text.trim().isEmpty ? null : _reasonController.text.trim(),
          document: _documentController.text.trim().isEmpty ? null : _documentController.text.trim(),
        );
      }
      if (mounted) {
        await context.read<ProductProvider>().loadProducts();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final locations = context.watch<LocationProvider>().locations;
    final isAdjustment = _type == MovementType.ajuste;

    return Scaffold(
      appBar: AppBar(title: const Text('Nova movimentação')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Tipo de movimentação', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: MovementType.values.map((t) {
                return ChoiceChip(
                  label: Text(t.label),
                  selected: _type == t,
                  onSelected: (_) => setState(() => _type = t),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Card(
              child: ListTile(
                leading: const Icon(Icons.inventory_2_outlined),
                title: Text(_product?.name ?? 'Selecionar produto'),
                subtitle: _product != null
                    ? Text('SKU: ${_product!.sku} • Estoque atual: ${_currentQtyAtLocation.toStringAsFixed(0)} ${_product!.unit}')
                    : const Text('Toque para escolher'),
                trailing: IconButton(icon: const Icon(Icons.qr_code_scanner), onPressed: _scanProduct),
                onTap: _pickProduct,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: _locationId,
              decoration: InputDecoration(
                  labelText: _type == MovementType.transferencia ? 'Local de origem' : 'Local',
                  border: const OutlineInputBorder()),
              items: locations.map((l) => DropdownMenuItem(value: l.id, child: Text(l.name))).toList(),
              onChanged: (v) {
                setState(() => _locationId = v);
                _refreshCurrentQty();
              },
            ),
            if (_type == MovementType.transferencia) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: _destinationLocationId,
                decoration: const InputDecoration(labelText: 'Local de destino', border: OutlineInputBorder()),
                items: locations
                    .where((l) => l.id != _locationId)
                    .map((l) => DropdownMenuItem(value: l.id, child: Text(l.name)))
                    .toList(),
                onChanged: (v) => setState(() => _destinationLocationId = v),
              ),
            ],
            const SizedBox(height: 12),
            TextFormField(
              controller: _qtyController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: isAdjustment ? 'Quantidade final (inventário)' : 'Quantidade',
                helperText: isAdjustment ? 'Informe a quantidade real contada no local' : null,
                border: const OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.isEmpty) ? 'Informe a quantidade' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _reasonController,
              decoration: const InputDecoration(labelText: 'Motivo', border: OutlineInputBorder()),
            ),
            if (_type != MovementType.transferencia && _type != MovementType.ajuste) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _documentController,
                decoration: const InputDecoration(
                    labelText: 'Documento relacionado (NF, pedido...)', border: OutlineInputBorder()),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(onPressed: _submit, icon: const Icon(Icons.check), label: const Text('Confirmar movimentação')),
          ],
        ),
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
    final filtered = widget.products
        .where((p) => p.name.toLowerCase().contains(_query.toLowerCase()) || p.sku.toLowerCase().contains(_query.toLowerCase()))
        .toList();
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
                    subtitle: Text('SKU: ${p.sku}'),
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

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../providers/product_provider.dart';
import '../../providers/supplier_provider.dart';
import '../barcode/barcode_scanner_screen.dart';

class ProductFormScreen extends StatefulWidget {
  final Product? product;
  final String? initialBarcode;
  const ProductFormScreen({super.key, this.product, this.initialBarcode});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _sku;
  late final TextEditingController _barcode;
  late final TextEditingController _brand;
  late final TextEditingController _description;
  late final TextEditingController _unit;
  late final TextEditingController _cost;
  late final TextEditingController _price;
  late final TextEditingController _minStock;
  late final TextEditingController _maxStock;

  int? _categoryId;
  int? _supplierId;
  String? _photoPath;
  DateTime? _expirationDate;

  bool get _editing => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _name = TextEditingController(text: p?.name ?? '');
    _sku = TextEditingController(text: p?.sku ?? '');
    _barcode = TextEditingController(text: p?.barcode ?? widget.initialBarcode ?? '');
    _brand = TextEditingController(text: p?.brand ?? '');
    _description = TextEditingController(text: p?.description ?? '');
    _unit = TextEditingController(text: p?.unit ?? 'un');
    _cost = TextEditingController(text: p != null ? p.costPrice.toString() : '');
    _price = TextEditingController(text: p != null ? p.salePrice.toString() : '');
    _minStock = TextEditingController(text: p != null ? p.minStock.toString() : '0');
    _maxStock = TextEditingController(text: p != null ? p.maxStock.toString() : '0');
    _categoryId = p?.categoryId;
    _supplierId = p?.supplierId;
    _photoPath = p?.photoPath;
    _expirationDate = p?.expirationDate;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadCategories();
      context.read<SupplierProvider>().loadSuppliers();
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (file == null) return;
    final dir = await getApplicationDocumentsDirectory();
    final newPath = '${dir.path}/product_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await File(file.path).copy(newPath);
    setState(() => _photoPath = newPath);
  }

  Future<void> _scanBarcode() async {
    final code = await Navigator.push<String>(
        context, MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()));
    if (code != null) setState(() => _barcode.text = code);
  }

  Future<void> _addCategoryDialog() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nova categoria'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Salvar')),
        ],
      ),
    );
    if (name != null && name.isNotEmpty && mounted) {
      try {
        await context.read<ProductProvider>().addCategory(name);
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Categoria "$name" criada')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao criar categoria: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<ProductProvider>();
    final product = Product(
      id: widget.product?.id,
      name: _name.text.trim(),
      sku: _sku.text.trim(),
      barcode: _barcode.text.trim().isEmpty ? null : _barcode.text.trim(),
      categoryId: _categoryId,
      brand: _brand.text.trim().isEmpty ? null : _brand.text.trim(),
      description: _description.text.trim().isEmpty ? null : _description.text.trim(),
      photoPath: _photoPath,
      unit: _unit.text.trim().isEmpty ? 'un' : _unit.text.trim(),
      costPrice: double.tryParse(_cost.text.replaceAll(',', '.')) ?? 0,
      salePrice: double.tryParse(_price.text.replaceAll(',', '.')) ?? 0,
      minStock: double.tryParse(_minStock.text.replaceAll(',', '.')) ?? 0,
      maxStock: double.tryParse(_maxStock.text.replaceAll(',', '.')) ?? 0,
      supplierId: _supplierId,
      expirationDate: _expirationDate,
      createdAt: widget.product?.createdAt,
    );

    try {
      if (_editing) {
        await provider.editProduct(product);
      } else {
        await provider.addProduct(product);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar produto: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_editing ? 'Editar produto' : 'Novo produto')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: _photoPath != null ? FileImage(File(_photoPath!)) : null,
                  child: _photoPath == null
                      ? const Icon(Icons.add_a_photo_outlined, size: 30, color: Colors.grey)
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Nome do produto *', border: OutlineInputBorder()),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe o nome' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _sku,
                    decoration: const InputDecoration(labelText: 'SKU / código interno *', border: OutlineInputBorder()),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe o SKU' : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _barcode,
                    decoration: InputDecoration(
                      labelText: 'Código de barras',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(icon: const Icon(Icons.qr_code_scanner), onPressed: _scanBarcode),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Consumer<ProductProvider>(
              builder: (context, prov, _) => Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _categoryId,
                      decoration: const InputDecoration(labelText: 'Categoria', border: OutlineInputBorder()),
                      items: prov.categories
                          .map((c) => DropdownMenuItem<int>(value: c['id'] as int, child: Text(c['name'] as String)))
                          .toList(),
                      onChanged: (v) => setState(() => _categoryId = v),
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: _addCategoryDialog),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _brand,
              decoration: const InputDecoration(labelText: 'Marca', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _description,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Descrição', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _unit,
                    decoration: const InputDecoration(labelText: 'Unidade (un, kg, l...)', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Consumer<SupplierProvider>(
                    builder: (context, sp, _) => DropdownButtonFormField<int>(
                      value: _supplierId,
                      decoration: const InputDecoration(labelText: 'Fornecedor', border: OutlineInputBorder()),
                      items: sp.suppliers
                          .map((s) => DropdownMenuItem<int>(value: s.id, child: Text(s.name)))
                          .toList(),
                      onChanged: (v) => setState(() => _supplierId = v),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _cost,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Custo de compra (R\$)', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _price,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Preço de venda (R\$)', border: OutlineInputBorder()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _minStock,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Estoque mínimo', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _maxStock,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Estoque máximo', border: OutlineInputBorder()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_expirationDate == null
                  ? 'Sem data de vencimento'
                  : 'Vencimento: ${_expirationDate!.day.toString().padLeft(2, '0')}/${_expirationDate!.month.toString().padLeft(2, '0')}/${_expirationDate!.year}'),
              trailing: const Icon(Icons.calendar_month),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _expirationDate ?? DateTime.now(),
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                );
                if (date != null) setState(() => _expirationDate = date);
              },
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: Text(_editing ? 'Salvar alterações' : 'Cadastrar produto'),
            ),
            if (!_editing) ...[
              const SizedBox(height: 8),
              const Text(
                'Após cadastrar, use a tela de Movimentos para registrar a entrada inicial do estoque.',
                style: TextStyle(color: Colors.grey, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

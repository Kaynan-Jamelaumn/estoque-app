import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/product_provider.dart';
import '../../widgets/product_tile.dart';
import 'product_form_screen.dart';
import 'product_detail_screen.dart';
import '../barcode/barcode_scanner_screen.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});
  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final _searchController = TextEditingController();
  int? _categoryFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProducts();
      context.read<ProductProvider>().loadCategories();
    });
  }

  void _search(String value) {
    context.read<ProductProvider>().loadProducts(search: value, categoryId: _categoryFilter);
  }

  Future<void> _scan() async {
    final code = await Navigator.push<String>(
        context, MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()));
    if (code == null || !mounted) return;
    final product = await context.read<ProductProvider>().findByBarcode(code);
    if (!mounted) return;
    if (product != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: product.id!)));
    } else {
      final add = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Produto não encontrado'),
          content: Text('Nenhum produto com o código "$code". Deseja cadastrar um novo produto com este código?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Cadastrar')),
          ],
        ),
      );
      if (add == true && mounted) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => ProductFormScreen(initialBarcode: code)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Produtos'),
        actions: [
          IconButton(icon: const Icon(Icons.qr_code_scanner), onPressed: _scan),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_products',
        onPressed: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const ProductFormScreen())),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por nome, SKU ou código de barras',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
              onChanged: _search,
            ),
          ),
          Consumer<ProductProvider>(
            builder: (context, prov, _) {
              if (prov.categories.isEmpty) return const SizedBox();
              return SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    ChoiceChip(
                      label: const Text('Todas'),
                      selected: _categoryFilter == null,
                      onSelected: (_) {
                        setState(() => _categoryFilter = null);
                        _search(_searchController.text);
                      },
                    ),
                    const SizedBox(width: 6),
                    ...prov.categories.map((c) => Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(c['name'] as String),
                            selected: _categoryFilter == c['id'],
                            onSelected: (_) {
                              setState(() => _categoryFilter = c['id'] as int);
                              _search(_searchController.text);
                            },
                          ),
                        )),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Consumer<ProductProvider>(
              builder: (context, prov, _) {
                if (prov.loading) return const Center(child: CircularProgressIndicator());
                if (prov.error != null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 40),
                          const SizedBox(height: 8),
                          Text('Erro ao carregar produtos: ${prov.error}', textAlign: TextAlign.center),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: () => prov.loadProducts(search: _searchController.text, categoryId: _categoryFilter),
                            child: const Text('Tentar novamente'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                if (prov.products.isEmpty) {
                  return const Center(child: Text('Nenhum produto cadastrado.'));
                }
                return ListView.builder(
                  itemCount: prov.products.length,
                  itemBuilder: (context, i) {
                    final p = prov.products[i];
                    return ProductTile(
                      product: p,
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: p.id!))),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

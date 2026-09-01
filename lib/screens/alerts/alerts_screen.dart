import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/product_provider.dart';
import '../../widgets/product_tile.dart';
import '../products/product_detail_screen.dart';
import '../../utils/formatters.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});
  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<ProductProvider>().loadProducts());
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ProductProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alertas'),
        bottom: TabBar(
          controller: _tab,
          isScrollable: true,
          tabs: [
            Tab(text: 'Baixo (${prov.lowStockProducts.length})'),
            Tab(text: 'Zerado (${prov.outOfStockProducts.length})'),
            Tab(text: 'Vencendo (${prov.nearExpirationProducts.length})'),
            Tab(text: 'Excesso (${prov.overStockProducts.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _list(prov.lowStockProducts, 'Nenhum produto com estoque baixo.'),
          _list(prov.outOfStockProducts, 'Nenhum produto zerado.'),
          _list(prov.nearExpirationProducts, 'Nenhum produto próximo do vencimento.', showExpiration: true),
          _list(prov.overStockProducts, 'Nenhum produto com estoque excessivo.'),
        ],
      ),
    );
  }

  Widget _list(List products, String emptyMessage, {bool showExpiration = false}) {
    if (products.isEmpty) {
      return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(emptyMessage, textAlign: TextAlign.center)));
    }
    return ListView.builder(
      itemCount: products.length,
      itemBuilder: (context, i) {
        final p = products[i];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProductTile(
              product: p,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: p.id))),
            ),
            if (showExpiration && p.expirationDate != null)
              Padding(
                padding: const EdgeInsets.only(left: 72, bottom: 8),
                child: Text('Vence em: ${dateFormat.format(p.expirationDate)}',
                    style: const TextStyle(color: Colors.orange, fontSize: 12)),
              ),
          ],
        );
      },
    );
  }
}

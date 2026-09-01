import 'package:flutter/material.dart';
import '../../database/db_helper.dart';
import '../../providers/product_provider.dart';
import 'package:provider/provider.dart';
import '../../utils/formatters.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _db = DBHelper.instance;
  DateTimeRange? _range;

  @override
  void initState() {
    super.initState();
    _range = DateTimeRange(start: DateTime.now().subtract(const Duration(days: 30)), end: DateTime.now());
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<ProductProvider>().loadProducts());
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ProductProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatórios'),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: () async {
              final range = await showDateRangePicker(
                context: context,
                firstDate: DateTime.now().subtract(const Duration(days: 730)),
                lastDate: DateTime.now(),
                initialDateRange: _range,
              );
              if (range != null) setState(() => _range = range);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          if (_range != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('Período: ${dateFormat.format(_range!.start)} a ${dateFormat.format(_range!.end)}',
                  style: const TextStyle(color: Colors.grey)),
            ),
          _reportTile(
            'Estoque atual',
            Icons.inventory_2_outlined,
            '${prov.products.length} produtos • ${currencyFormat.format(prov.totalStockValue)}',
            () => _showProductsSheet('Estoque atual', prov.products),
          ),
          _reportTile('Valor do estoque', Icons.attach_money, currencyFormat.format(prov.totalStockValue), null),
          FutureBuilder<Map<String, dynamic>>(
            future: _db.getEstimatedProfit(from: _range?.start, to: _range?.end),
            builder: (context, snap) {
              if (!snap.hasData) return _reportTile('Lucro estimado', Icons.trending_up, 'Calculando...', null);
              final data = snap.data!;
              return _reportTile(
                'Lucro estimado (período)',
                Icons.trending_up,
                'Receita: ${currencyFormat.format(data['revenue'])} • Custo: ${currencyFormat.format(data['cost'])} • Lucro: ${currencyFormat.format(data['profit'])}',
                null,
              );
            },
          ),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _db.getTopSellingProducts(limit: 10, days: 30),
            builder: (context, snap) {
              final items = snap.data ?? [];
              return _reportTile('Produtos mais vendidos', Icons.star_outline,
                  '${items.length} produtos no top', () => _showSimpleList('Mais vendidos', items,
                      (r) => '${r['name']}', (r) => '${formatQty((r['total_sold'] as num).toDouble())} un'));
            },
          ),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _db.getStaleProducts(),
            builder: (context, snap) {
              final items = snap.data ?? [];
              return _reportTile('Produtos menos movimentados', Icons.hourglass_bottom,
                  '${items.length} produtos parados', () => _showSimpleList('Parados há muito tempo', items,
                      (r) => '${r['name']}', (r) => r['last_movement'] != null ? dateFormat.format(DateTime.parse(r['last_movement'])) : 'Sem mov.'));
            },
          ),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _db.getPurchasesBySupplier(),
            builder: (context, snap) {
              final items = snap.data ?? [];
              return _reportTile('Compras por fornecedor', Icons.shopping_cart_outlined,
                  '${items.length} fornecedores', () => _showSimpleList('Compras por fornecedor', items,
                      (r) => '${r['supplier_name']} (${r['total_orders']} pedidos)',
                      (r) => currencyFormat.format(r['total_value'])));
            },
          ),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _db.getLossesReport(from: _range?.start, to: _range?.end),
            builder: (context, snap) {
              final items = snap.data ?? [];
              final totalLoss = items.fold<double>(0, (sum, r) => sum + (r['loss_value'] as num).toDouble());
              return _reportTile('Perdas e avarias', Icons.report_gmailerrorred,
                  '${items.length} ocorrências • ${currencyFormat.format(totalLoss)}',
                  () => _showSimpleList('Perdas e avarias', items,
                      (r) => '${r['product_name']}',
                      (r) => '${formatQty((r['quantity'] as num).toDouble())} • ${currencyFormat.format(r['loss_value'])}'));
            },
          ),
          _reportTile('Estoque com baixo', Icons.warning_amber, '${prov.lowStockProducts.length} produtos',
              () => _showProductsSheet('Estoque baixo', prov.lowStockProducts)),
          _reportTile('Produtos sem estoque', Icons.remove_shopping_cart, '${prov.outOfStockProducts.length} produtos',
              () => _showProductsSheet('Sem estoque', prov.outOfStockProducts)),
        ],
      ),
    );
  }

  Widget _reportTile(String title, IconData icon, String subtitle, VoidCallback? onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: onTap != null ? const Icon(Icons.chevron_right) : null,
        onTap: onTap,
      ),
    );
  }

  void _showProductsSheet(String title, List products) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(padding: const EdgeInsets.all(12), child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: products.length,
                itemBuilder: (context, i) {
                  final p = products[i];
                  return ListTile(
                    title: Text(p.name),
                    subtitle: Text('SKU: ${p.sku}'),
                    trailing: Text('${formatQty(p.currentStock)} ${p.unit}'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSimpleList(String title, List<Map<String, dynamic>> items, String Function(Map) titleFn, String Function(Map) trailingFn) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(padding: const EdgeInsets.all(12), child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
            Expanded(
              child: items.isEmpty
                  ? const Center(child: Text('Sem dados para exibir.'))
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: items.length,
                      itemBuilder: (context, i) {
                        final r = items[i];
                        return ListTile(title: Text(titleFn(r)), trailing: Text(trailingFn(r)));
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

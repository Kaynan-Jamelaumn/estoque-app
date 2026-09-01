import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/purchase_order.dart';
import '../../providers/purchase_provider.dart';
import '../../utils/formatters.dart';
import 'purchase_form_screen.dart';

class PurchaseListScreen extends StatefulWidget {
  const PurchaseListScreen({super.key});
  @override
  State<PurchaseListScreen> createState() => _PurchaseListScreenState();
}

class _PurchaseListScreenState extends State<PurchaseListScreen> with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PurchaseProvider>().loadOrders();
      context.read<PurchaseProvider>().loadSuggestions();
    });
  }

  Color _statusColor(PurchaseStatus s) {
    switch (s) {
      case PurchaseStatus.pedido:
        return Colors.orange;
      case PurchaseStatus.recebido:
        return Colors.green;
      case PurchaseStatus.cancelado:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compras'),
        bottom: TabBar(controller: _tab, tabs: const [
          Tab(text: 'Pedidos'),
          Tab(text: 'Sugestão de compra'),
        ]),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_purchases',
        onPressed: () async {
          if (mounted) context.read<PurchaseProvider>().loadOrders();
        },
        child: const Icon(Icons.add),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          Consumer<PurchaseProvider>(
            builder: (context, prov, _) {
              if (prov.orders.isEmpty) return const Center(child: Text('Nenhum pedido de compra.'));
              return ListView.builder(
                itemCount: prov.orders.length,
                itemBuilder: (context, i) {
                  final o = prov.orders[i];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: ExpansionTile(
                      title: Text(o.supplierName ?? 'Fornecedor #${o.supplierId}'),
                      subtitle: Text('${dateFormat.format(o.orderDate)} • ${currencyFormat.format(o.total)}'),
                      trailing: Chip(
                        label: Text(o.status.label, style: const TextStyle(color: Colors.white, fontSize: 11)),
                        backgroundColor: _statusColor(o.status),
                        padding: EdgeInsets.zero,
                      ),
                      children: [
                        ...o.items.map((it) => ListTile(
                              dense: true,
                              title: Text(it.productName ?? 'Produto #${it.productId}'),
                              trailing: Text('${formatQty(it.quantity)} x ${currencyFormat.format(it.unitCost)}'),
                            )),
                        if (o.status == PurchaseStatus.pedido)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () async {
                                      await context.read<PurchaseProvider>().cancelOrder(o.id!);
                                    },
                                    child: const Text('Cancelar'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: FilledButton(
                                    onPressed: () async {
                                      await context.read<PurchaseProvider>().receiveOrder(o);
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Pedido recebido! Estoque atualizado.')));
                                      }
                                    },
                                    child: const Text('Marcar como recebido'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
          Consumer<PurchaseProvider>(
            builder: (context, prov, _) {
              if (prov.suggestions.isEmpty) {
                return const Center(
                    child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Nenhuma sugestão no momento. Produtos abaixo do estoque mínimo aparecerão aqui, '
                      'com base no histórico de vendas dos últimos 30 dias.', textAlign: TextAlign.center),
                ));
              }
              return ListView.builder(
                itemCount: prov.suggestions.length,
                itemBuilder: (context, i) {
                  final s = prov.suggestions[i];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: ListTile(
                      leading: const Icon(Icons.lightbulb_outline, color: Colors.amber),
                      title: Text(s['product_name'] as String),
                      subtitle: Text(
                          'Estoque: ${formatQty((s['current_stock'] as num).toDouble())} • Mín: ${formatQty((s['min_stock'] as num).toDouble())} • Vendido (30d): ${formatQty((s['sold_last_30'] as num).toDouble())}'),
                      trailing: Text('Comprar\n${formatQty((s['suggested_qty'] as num).toDouble())}',
                          textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

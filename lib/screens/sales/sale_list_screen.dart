import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/sale_provider.dart';
import '../../utils/formatters.dart';
import 'sale_form_screen.dart';

class SaleListScreen extends StatefulWidget {
  const SaleListScreen({super.key});
  @override
  State<SaleListScreen> createState() => _SaleListScreenState();
}

class _SaleListScreenState extends State<SaleListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<SaleProvider>().loadSales());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vendas')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_sales',
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const SaleFormScreen()));
          if (mounted) context.read<SaleProvider>().loadSales();
        },
        icon: const Icon(Icons.add_shopping_cart),
        label: const Text('Nova venda'),
      ),
      body: Consumer<SaleProvider>(
        builder: (context, prov, _) {
          if (prov.sales.isEmpty) return const Center(child: Text('Nenhuma venda registrada.'));
          return ListView.builder(
            itemCount: prov.sales.length,
            itemBuilder: (context, i) {
              final s = prov.sales[i];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ExpansionTile(
                  title: Text(s.customerName?.isNotEmpty == true ? s.customerName! : 'Cliente não identificado'),
                  subtitle: Text('${dateTimeFormat.format(s.date)} • ${s.paymentMethod}'),
                  trailing: Text(currencyFormat.format(s.total), style: const TextStyle(fontWeight: FontWeight.bold)),
                  children: s.items
                      .map((it) => ListTile(
                            dense: true,
                            title: Text(it.productName ?? ''),
                            trailing: Text('${formatQty(it.quantity)} x ${currencyFormat.format(it.unitPrice)}'),
                          ))
                      .toList(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

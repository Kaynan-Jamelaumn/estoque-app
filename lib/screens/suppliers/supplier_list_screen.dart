import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/supplier_provider.dart';
import 'supplier_form_screen.dart';

class SupplierListScreen extends StatefulWidget {
  const SupplierListScreen({super.key});
  @override
  State<SupplierListScreen> createState() => _SupplierListScreenState();
}

class _SupplierListScreenState extends State<SupplierListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<SupplierProvider>().loadSuppliers());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fornecedores')),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_suppliers',
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SupplierFormScreen())),
        child: const Icon(Icons.add),
      ),
      body: Consumer<SupplierProvider>(
        builder: (context, prov, _) {
          if (prov.suppliers.isEmpty) {
            return const Center(child: Text('Nenhum fornecedor cadastrado.'));
          }
          return ListView.separated(
            itemCount: prov.suppliers.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final s = prov.suppliers[i];
              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.local_shipping_outlined)),
                title: Text(s.name),
                subtitle: Text([s.contactName, s.phone].where((e) => e != null && e.isNotEmpty).join(' • ')),
                trailing: PopupMenuButton<String>(
                  onSelected: (v) async {
                    if (v == 'edit') {
                      await Navigator.push(context, MaterialPageRoute(builder: (_) => SupplierFormScreen(supplier: s)));
                    } else if (v == 'delete') {
                      await context.read<SupplierProvider>().removeSupplier(s.id!);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Editar')),
                    PopupMenuItem(value: 'delete', child: Text('Excluir')),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

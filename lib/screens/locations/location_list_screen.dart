import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/location_provider.dart';
import '../../models/location.dart';
import '../movements/movement_form_screen.dart';

class LocationListScreen extends StatefulWidget {
  const LocationListScreen({super.key});
  @override
  State<LocationListScreen> createState() => _LocationListScreenState();
}

class _LocationListScreenState extends State<LocationListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<LocationProvider>().loadLocations());
  }

  Future<void> _addLocation() async {
    final controller = TextEditingController();
    final descController = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Novo local de estoque'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: controller, decoration: const InputDecoration(labelText: 'Nome (ex: Loja 2)')),
            TextField(controller: descController, decoration: const InputDecoration(labelText: 'Descrição (opcional)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Salvar')),
        ],
      ),
    );
    if (name != null && name.isNotEmpty && mounted) {
      try {
        await context
            .read<LocationProvider>()
            .addLocation(StockLocation(name: name, description: descController.text.trim()));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Local "$name" criado')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao criar local: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Locais de estoque')),
      floatingActionButton: FloatingActionButton(heroTag: 'fab_locations', onPressed: _addLocation, child: const Icon(Icons.add)),
      body: Consumer<LocationProvider>(
        builder: (context, prov, _) {
          if (prov.locations.isEmpty) return const Center(child: Text('Nenhum local cadastrado.'));
          return ListView.separated(
            itemCount: prov.locations.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final l = prov.locations[i];
              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.store_outlined)),
                title: Text(l.name),
                subtitle: l.description != null ? Text(l.description!) : null,
              );
            },
          );
        },
      ),
      persistentFooterButtons: [
        FilledButton.tonalIcon(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MovementFormScreen())),
          icon: const Icon(Icons.compare_arrows),
          label: const Text('Transferir estoque entre locais'),
        ),
      ],
    );
  }
}

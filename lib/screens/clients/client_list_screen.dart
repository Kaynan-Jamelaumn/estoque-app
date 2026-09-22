import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/client_provider.dart';
import 'client_form_screen.dart';

class ClientListScreen extends StatefulWidget {
  const ClientListScreen({super.key});
  @override
  State<ClientListScreen> createState() => _ClientListScreenState();
}

class _ClientListScreenState extends State<ClientListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<ClientProvider>().loadClients());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clientes')),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_clients',
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ClientFormScreen())),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por nome',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
              onChanged: (v) => context.read<ClientProvider>().loadClients(search: v),
            ),
          ),
          Expanded(
            child: Consumer<ClientProvider>(
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
                          Text('Erro ao carregar clientes: ${prov.error}', textAlign: TextAlign.center),
                          const SizedBox(height: 12),
                          FilledButton(onPressed: () => prov.loadClients(), child: const Text('Tentar novamente')),
                        ],
                      ),
                    ),
                  );
                }
                if (prov.clients.isEmpty) {
                  return const Center(child: Text('Nenhum cliente cadastrado.'));
                }
                return ListView.separated(
                  itemCount: prov.clients.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final c = prov.clients[i];
                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                      title: Text(c.name),
                      subtitle: Text([c.phone, c.email].where((e) => e != null && e.isNotEmpty).join(' • ')),
                      trailing: PopupMenuButton<String>(
                        onSelected: (v) async {
                          if (v == 'edit') {
                            await Navigator.push(context, MaterialPageRoute(builder: (_) => ClientFormScreen(client: c)));
                          } else if (v == 'delete') {
                            await context.read<ClientProvider>().removeClient(c.id!);
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
          ),
        ],
      ),
    );
  }
}

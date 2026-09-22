import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/reminder.dart';
import '../../providers/reminder_provider.dart';
import '../../providers/client_provider.dart';
import '../../providers/product_provider.dart';
import '../../utils/formatters.dart';

class ReminderListScreen extends StatefulWidget {
  const ReminderListScreen({super.key});
  @override
  State<ReminderListScreen> createState() => _ReminderListScreenState();
}

class _ReminderListScreenState extends State<ReminderListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReminderProvider>().loadReminders();
      context.read<ClientProvider>().loadClients();
      context.read<ProductProvider>().loadProducts();
    });
  }

  Future<void> _addManualReminder() async {
    final clients = context.read<ClientProvider>().clients;
    final products = context.read<ProductProvider>().products;
    int? clientId;
    int? productId;
    int days = 30;
    final noteController = TextEditingController();

    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) => Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Novo lembrete', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: clientId,
                  decoration: const InputDecoration(labelText: 'Cliente', border: OutlineInputBorder()),
                  items: clients.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                  onChanged: (v) => setSheetState(() => clientId = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: productId,
                  decoration: const InputDecoration(labelText: 'Produto', border: OutlineInputBorder()),
                  items: products.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
                  onChanged: (v) => setSheetState(() => productId = v),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: '$days',
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Lembrar em quantos dias', border: OutlineInputBorder()),
                  onChanged: (v) => days = int.tryParse(v) ?? days,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: noteController,
                  decoration: const InputDecoration(labelText: 'Observação (opcional)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  icon: const Icon(Icons.check),
                  label: const Text('Criar lembrete'),
                  onPressed: () => Navigator.pop(sheetContext, true),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (created != true || !mounted) return;

    final clientName = clientId != null
        ? clients.firstWhere((c) => c.id == clientId).name
        : null;
    final productName = productId != null
        ? products.firstWhere((p) => p.id == productId).name
        : null;

    await context.read<ReminderProvider>().addReminder(Reminder(
          clientId: clientId,
          clientName: clientName,
          productId: productId,
          productName: productName,
          dueDate: DateTime.now().add(Duration(days: days)),
          note: noteController.text.trim().isEmpty ? null : noteController.text.trim(),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lembretes de recompra')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_reminders',
        onPressed: _addManualReminder,
        icon: const Icon(Icons.add_alert_outlined),
        label: const Text('Novo lembrete'),
      ),
      body: Consumer<ReminderProvider>(
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
                    Text('Erro ao carregar lembretes: ${prov.error}', textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton(onPressed: () => prov.loadReminders(), child: const Text('Tentar novamente')),
                  ],
                ),
              ),
            );
          }
          if (prov.reminders.isEmpty) {
            return const Center(child: Text('Nenhum lembrete pendente.'));
          }
          return ListView.builder(
            itemCount: prov.reminders.length,
            itemBuilder: (context, i) {
              final r = prov.reminders[i];
              final overdue = r.isOverdue;
              return Dismissible(
                key: ValueKey(r.id),
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                direction: DismissDirection.startToEnd,
                onDismissed: (_) => context.read<ReminderProvider>().removeReminder(r.id!),
                child: ListTile(
                  leading: Icon(
                    overdue ? Icons.notification_important : Icons.notifications_active_outlined,
                    color: overdue ? Colors.red : Colors.teal,
                  ),
                  title: Text(r.productName ?? 'Produto não especificado'),
                  subtitle: Text(
                    '${r.clientName ?? 'Cliente não identificado'} • Vence em ${dateFormat.format(r.dueDate)}'
                    '${r.note != null ? ' • ${r.note}' : ''}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.check_circle_outline),
                    tooltip: 'Marcar como concluído',
                    onPressed: () => context.read<ReminderProvider>().markDone(r.id!),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}


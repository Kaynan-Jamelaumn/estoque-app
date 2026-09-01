import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../models/stock_movement.dart';
import '../../providers/movement_provider.dart';
import '../../utils/formatters.dart';
import 'movement_form_screen.dart';

class MovementListScreen extends StatefulWidget {
  final Product? productFilter;
  const MovementListScreen({super.key, this.productFilter});

  @override
  State<MovementListScreen> createState() => _MovementListScreenState();
}

class _MovementListScreenState extends State<MovementListScreen> {
  MovementType? _typeFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    context.read<MovementProvider>().loadMovements(
        productId: widget.productFilter?.id, type: _typeFilter);
  }

  Color _colorFor(MovementType t) {
    switch (t) {
      case MovementType.entrada:
      case MovementType.devolucao:
        return Colors.green;
      case MovementType.saida:
      case MovementType.perda:
        return Colors.red;
      case MovementType.ajuste:
        return Colors.blueGrey;
      case MovementType.transferencia:
        return Colors.blue;
    }
  }

  IconData _iconFor(MovementType t) {
    switch (t) {
      case MovementType.entrada:
        return Icons.call_received;
      case MovementType.saida:
        return Icons.call_made;
      case MovementType.devolucao:
        return Icons.undo;
      case MovementType.perda:
        return Icons.report_gmailerrorred;
      case MovementType.ajuste:
        return Icons.tune;
      case MovementType.transferencia:
        return Icons.compare_arrows;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.productFilter != null
            ? 'Histórico: ${widget.productFilter!.name}'
            : 'Movimentações'),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_movements',
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(
              builder: (_) => MovementFormScreen(preselectedProduct: widget.productFilter)));
          _load();
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              children: [
                ChoiceChip(
                  label: const Text('Todos'),
                  selected: _typeFilter == null,
                  onSelected: (_) {
                    setState(() => _typeFilter = null);
                    _load();
                  },
                ),
                const SizedBox(width: 6),
                ...MovementType.values.map((t) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(t.label),
                        selected: _typeFilter == t,
                        onSelected: (_) {
                          setState(() => _typeFilter = t);
                          _load();
                        },
                      ),
                    )),
              ],
            ),
          ),
          Expanded(
            child: Consumer<MovementProvider>(
              builder: (context, prov, _) {
                if (prov.movements.isEmpty) {
                  return const Center(child: Text('Nenhuma movimentação encontrada.'));
                }
                return ListView.builder(
                  itemCount: prov.movements.length,
                  itemBuilder: (context, i) {
                    final m = prov.movements[i];
                    final color = _colorFor(m.type);
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: color.withOpacity(0.15),
                        child: Icon(_iconFor(m.type), color: color, size: 20),
                      ),
                      title: Text(m.productName ?? 'Produto #${m.productId}'),
                      subtitle: Text(
                        '${m.type.label} • ${m.locationName}'
                        '${m.destinationLocationName != null ? ' → ${m.destinationLocationName}' : ''}\n'
                        '${dateTimeFormat.format(m.date)}'
                        '${m.reason != null ? ' • ${m.reason}' : ''}',
                      ),
                      isThreeLine: true,
                      trailing: Text(
                        '${m.type == MovementType.saida || m.type == MovementType.perda ? '-' : '+'}${formatQty(m.quantity)}',
                        style: TextStyle(fontWeight: FontWeight.bold, color: color),
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

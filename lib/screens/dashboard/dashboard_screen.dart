import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../database/db_helper.dart';
import '../../utils/formatters.dart';
import '../products/product_form_screen.dart';
import '../barcode/barcode_scanner_screen.dart';
import '../movements/movement_form_screen.dart';
import '../alerts/alerts_screen.dart';
import '../../providers/product_provider.dart';
import 'package:provider/provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _db = DBHelper.instance;
  Map<String, dynamic>? _summary;
  List<Map<String, dynamic>> _topSelling = [];
  List<Map<String, dynamic>> _recentEntries = [];
  List<Map<String, dynamic>> _stale = [];
  List<Map<String, dynamic>> _chart = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final summary = await _db.getDashboardSummary();
      final top = await _db.getTopSellingProducts();
      final entries = await _db.getRecentEntries();
      final stale = await _db.getStaleProducts();
      final chart = await _db.getDailyMovementChart(days: 14);
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _topSelling = top;
        _recentEntries = entries;
        _stale = stale.take(5).toList();
        _chart = chart;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Painel de Estoque'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Buscar por código de barras',
            onPressed: () async {
              final code = await Navigator.push<String>(context,
                  MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()));
              if (code != null && mounted) {
                final product = await context.read<ProductProvider>().findByBarcode(code);
                if (!mounted) return;
                if (product != null) {
                  Navigator.push(context, MaterialPageRoute(
                      builder: (_) => ProductFormScreen(product: product)));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Produto não encontrado para este código')));
                }
              }
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_dashboard',
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const MovementFormScreen())),
        icon: const Icon(Icons.add),
        label: const Text('Movimentar'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 40),
                        const SizedBox(height: 8),
                        Text('Erro ao carregar o painel: $_error', textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        FilledButton(onPressed: _load, child: const Text('Tentar novamente')),
                      ],
                    ),
                  ),
                )
              : _summary == null
                  ? const Center(child: Text('Nenhum dado disponível ainda.'))
                  : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 2.4,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    children: [
                      _statCard('Total de produtos', '${_summary!['total_products']}',
                          Icons.inventory_2, Colors.indigo),
                      _statCard('Valor em estoque',
                          currencyFormat.format(_summary!['stock_value']),
                          Icons.attach_money, Colors.green),
                      _statCard('Estoque baixo', '${_summary!['low_stock']}',
                          Icons.warning_amber, Colors.orange, onTap: _goAlerts),
                      _statCard('Sem estoque', '${_summary!['out_of_stock']}',
                          Icons.remove_shopping_cart, Colors.red, onTap: _goAlerts),
                      _statCard('Entradas hoje', '${_summary!['entries_today']}',
                          Icons.call_received, Colors.teal),
                      _statCard('Saídas hoje', '${_summary!['exits_today']}',
                          Icons.call_made, Colors.deepPurple),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Movimentação (14 dias)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  SizedBox(height: 200, child: _buildChart()),
                  const SizedBox(height: 20),
                  _section('Produtos mais vendidos (30 dias)', _topSelling.isEmpty
                      ? [const Text('Nenhuma venda registrada ainda.')]
                      : _topSelling
                          .map((r) => ListTile(
                                dense: true,
                                leading: const Icon(Icons.trending_up, color: Colors.green),
                                title: Text(r['name'] as String),
                                trailing: Text('${formatQty((r['total_sold'] as num).toDouble())} un'),
                              ))
                          .toList()),
                  const SizedBox(height: 12),
                  _section('Entradas recentes', _recentEntries.isEmpty
                      ? [const Text('Nenhuma entrada registrada ainda.')]
                      : _recentEntries
                          .map((r) => ListTile(
                                dense: true,
                                leading: const Icon(Icons.call_received, color: Colors.teal),
                                title: Text(r['product_name'] as String),
                                subtitle: Text(dateTimeFormat.format(DateTime.parse(r['date'] as String))),
                                trailing: Text('+${formatQty((r['quantity'] as num).toDouble())}'),
                              ))
                          .toList()),
                  const SizedBox(height: 12),
                  _section('Produtos parados há muito tempo', _stale.isEmpty
                      ? [const Text('Nenhum produto parado.')]
                      : _stale
                          .map((r) => ListTile(
                                dense: true,
                                leading: const Icon(Icons.hourglass_bottom, color: Colors.grey),
                                title: Text(r['name'] as String),
                                subtitle: Text(r['last_movement'] != null
                                    ? 'Última mov.: ${dateFormat.format(DateTime.parse(r['last_movement'] as String))}'
                                    : 'Sem movimentações'),
                              ))
                          .toList()),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  void _goAlerts() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const AlertsScreen()));
  }

  Widget _statCard(String title, String value, IconData icon, Color color, {VoidCallback? onTap}) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              CircleAvatar(backgroundColor: color.withOpacity(0.15), child: Icon(icon, color: color, size: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        overflow: TextOverflow.ellipsis),
                    Text(title, style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildChart() {
    if (_chart.isEmpty) return const SizedBox();
    double maxY = 1;
    for (final d in _chart) {
      final e = (d['entries'] as num).toDouble();
      final s = (d['exits'] as num).toDouble();
      if (e > maxY) maxY = e;
      if (s > maxY) maxY = s;
    }
    return LineChart(
      LineChartData(
        maxY: maxY * 1.2,
        minY: 0,
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              interval: 2,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= _chart.length) return const SizedBox();
                final date = _chart[idx]['date'] as DateTime;
                return Text(DateFormat('dd/MM').format(date), style: const TextStyle(fontSize: 9));
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 32)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            isCurved: true,
            color: Colors.teal,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            spots: [
              for (int i = 0; i < _chart.length; i++)
                FlSpot(i.toDouble(), (_chart[i]['entries'] as num).toDouble())
            ],
          ),
          LineChartBarData(
            isCurved: true,
            color: Colors.deepPurple,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            spots: [
              for (int i = 0; i < _chart.length; i++)
                FlSpot(i.toDouble(), (_chart[i]['exits'] as num).toDouble())
            ],
          ),
        ],
      ),
    );
  }
}

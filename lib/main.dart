import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'providers/product_provider.dart';
import 'providers/movement_provider.dart';
import 'providers/supplier_provider.dart';
import 'providers/purchase_provider.dart';
import 'providers/sale_provider.dart';
import 'providers/location_provider.dart';

import 'screens/dashboard/dashboard_screen.dart';
import 'screens/products/product_list_screen.dart';
import 'screens/movements/movement_list_screen.dart';
import 'screens/suppliers/supplier_list_screen.dart';
import 'screens/purchases/purchase_list_screen.dart';
import 'screens/sales/sale_list_screen.dart';
import 'screens/locations/location_list_screen.dart';
import 'screens/reports/reports_screen.dart';
import 'screens/alerts/alerts_screen.dart';

Future<void> main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Garante que qualquer erro (inclusive de plugins como o banco de dados)
    // apareça no console em vez de falhar silenciosamente.
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      // ignore: avoid_print
      print('ERRO FLUTTER: ${details.exceptionAsString()}');
    };

    await initializeDateFormatting('pt_BR', null);
    runApp(const EstoqueApp());
  }, (error, stack) {
    // ignore: avoid_print
    print('ERRO NÃO TRATADO: $error');
    // ignore: avoid_print
    print(stack);
  });
}

class EstoqueApp extends StatelessWidget {
  const EstoqueApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => MovementProvider()),
        ChangeNotifierProvider(create: (_) => SupplierProvider()),
        ChangeNotifierProvider(create: (_) => PurchaseProvider()),
        ChangeNotifierProvider(create: (_) => SaleProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
      ],
      child: MaterialApp(
        title: 'Gestão de Estoque',
        debugShowCheckedModeBanner: false,
        locale: const Locale('pt', 'BR'),
        theme: ThemeData(
          colorSchemeSeed: const Color(0xFF2E7D32),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(centerTitle: false),
          cardTheme: CardThemeData(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        home: const RootNav(),
      ),
    );
  }
}

class RootNav extends StatefulWidget {
  const RootNav({super.key});
  @override
  State<RootNav> createState() => _RootNavState();
}

class _RootNavState extends State<RootNav> {
  int _index = 0;

  final _screens = const [
    DashboardScreen(),
    ProductListScreen(),
    MovementListScreen(),
    _MoreMenu(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Painel'),
          NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: 'Produtos'),
          NavigationDestination(icon: Icon(Icons.swap_vert), selectedIcon: Icon(Icons.swap_vert_circle), label: 'Movimentos'),
          NavigationDestination(icon: Icon(Icons.more_horiz), selectedIcon: Icon(Icons.more_horiz), label: 'Mais'),
        ],
      ),
    );
  }
}

class _MoreMenu extends StatelessWidget {
  const _MoreMenu();

  @override
  Widget build(BuildContext context) {
    final items = [
      _MenuItem('Vendas', Icons.point_of_sale, const SaleListScreen()),
      _MenuItem('Compras / Fornecedores', Icons.shopping_cart_outlined, const PurchaseListScreen()),
      _MenuItem('Fornecedores', Icons.local_shipping_outlined, const SupplierListScreen()),
      _MenuItem('Locais de estoque', Icons.store_outlined, const LocationListScreen()),
      _MenuItem('Alertas', Icons.notifications_active_outlined, const AlertsScreen()),
      _MenuItem('Relatórios', Icons.bar_chart_outlined, const ReportsScreen()),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Mais opções')),
      body: ListView.separated(
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final item = items[i];
          return ListTile(
            leading: Icon(item.icon),
            title: Text(item.title),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => item.screen)),
          );
        },
      ),
    );
  }
}

class _MenuItem {
  final String title;
  final IconData icon;
  final Widget screen;
  _MenuItem(this.title, this.icon, this.screen);
}

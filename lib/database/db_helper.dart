import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'db_platform.dart';
import '../models/product.dart';
import '../models/stock_movement.dart';
import '../models/purchase_order.dart';
import '../models/sale.dart';
import '../models/client.dart';
import '../models/reminder.dart';

class DBHelper {
  DBHelper._internal();
  static final DBHelper instance = DBHelper._internal();

  Database? _db;
  Future<Database>? _dbFuture;

  /// Getter seguro contra concorrência: se várias telas pedirem o banco ao
  /// mesmo tempo antes da primeira inicialização terminar, todas esperam a
  /// MESMA inicialização em andamento, em vez de disparar _initDB() várias
  /// vezes (o que causava os avisos repetidos de "changing default factory"
  /// e podia deixar o banco em estado inconsistente).
  Future<Database> get database async {
    if (_db != null) return _db!;
    _dbFuture ??= _initDB();
    _db = await _dbFuture;
    return _db!;
  }

  Future<Database> _initDB() async {
    // Escolhe o databaseFactory certo para a plataforma atual
    // (mobile = plugin nativo, desktop = ffi, web = ffi_web).
    await initDatabaseFactory();

    String path;
    if (kIsWeb) {
      // No navegador não existe sistema de arquivos: o nome já é a "chave"
      // usada para persistir no IndexedDB.
      path = 'estoque.db';
    } else {
      final dir = await getApplicationDocumentsDirectory();
      path = join(dir.path, 'estoque.db');
    }

    return databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 2,
        onCreate: _createDB,
        onUpgrade: _upgradeDB,
      ),
    );
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE sales ADD COLUMN client_id INTEGER');
      await db.execute('''
        CREATE TABLE clients (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          phone TEXT,
          email TEXT,
          notes TEXT,
          created_at TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE reminders (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          client_id INTEGER,
          client_name TEXT,
          product_id INTEGER,
          product_name TEXT,
          sale_id INTEGER,
          due_date TEXT NOT NULL,
          note TEXT,
          done INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL,
          FOREIGN KEY (client_id) REFERENCES clients (id),
          FOREIGN KEY (product_id) REFERENCES products (id),
          FOREIGN KEY (sale_id) REFERENCES sales (id)
        )
      ''');
    }
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE
      )
    ''');

    await db.execute('''
      CREATE TABLE suppliers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        contact_name TEXT,
        phone TEXT,
        email TEXT,
        address TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE locations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        sku TEXT NOT NULL UNIQUE,
        barcode TEXT,
        category_id INTEGER,
        brand TEXT,
        description TEXT,
        photo_path TEXT,
        unit TEXT DEFAULT 'un',
        cost_price REAL DEFAULT 0,
        sale_price REAL DEFAULT 0,
        min_stock REAL DEFAULT 0,
        max_stock REAL DEFAULT 0,
        supplier_id INTEGER,
        created_at TEXT NOT NULL,
        expiration_date TEXT,
        FOREIGN KEY (category_id) REFERENCES categories (id),
        FOREIGN KEY (supplier_id) REFERENCES suppliers (id)
      )
    ''');

    // Estoque por produto/local
    await db.execute('''
      CREATE TABLE stock_by_location (
        product_id INTEGER NOT NULL,
        location_id INTEGER NOT NULL,
        quantity REAL NOT NULL DEFAULT 0,
        PRIMARY KEY (product_id, location_id),
        FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE CASCADE,
        FOREIGN KEY (location_id) REFERENCES locations (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE stock_movements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL,
        type TEXT NOT NULL,
        quantity REAL NOT NULL,
        location_id INTEGER NOT NULL,
        destination_location_id INTEGER,
        date TEXT NOT NULL,
        reason TEXT,
        document TEXT,
        FOREIGN KEY (product_id) REFERENCES products (id),
        FOREIGN KEY (location_id) REFERENCES locations (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE purchase_orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        supplier_id INTEGER NOT NULL,
        location_id INTEGER NOT NULL,
        status TEXT NOT NULL DEFAULT 'pedido',
        order_date TEXT NOT NULL,
        expected_date TEXT,
        received_date TEXT,
        FOREIGN KEY (supplier_id) REFERENCES suppliers (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE purchase_order_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        purchase_order_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        quantity REAL NOT NULL,
        unit_cost REAL NOT NULL,
        FOREIGN KEY (purchase_order_id) REFERENCES purchase_orders (id) ON DELETE CASCADE,
        FOREIGN KEY (product_id) REFERENCES products (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE clients (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        email TEXT,
        notes TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_name TEXT,
        client_id INTEGER,
        location_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        discount REAL DEFAULT 0,
        payment_method TEXT DEFAULT 'Dinheiro',
        FOREIGN KEY (location_id) REFERENCES locations (id),
        FOREIGN KEY (client_id) REFERENCES clients (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE reminders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        client_id INTEGER,
        client_name TEXT,
        product_id INTEGER,
        product_name TEXT,
        sale_id INTEGER,
        due_date TEXT NOT NULL,
        note TEXT,
        done INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (client_id) REFERENCES clients (id),
        FOREIGN KEY (product_id) REFERENCES products (id),
        FOREIGN KEY (sale_id) REFERENCES sales (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE sale_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sale_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        quantity REAL NOT NULL,
        unit_price REAL NOT NULL,
        FOREIGN KEY (sale_id) REFERENCES sales (id) ON DELETE CASCADE,
        FOREIGN KEY (product_id) REFERENCES products (id)
      )
    ''');

    // Locais padrão
    await db.insert('locations', {'name': 'Loja', 'description': 'Local de venda principal'});
    await db.insert('locations', {'name': 'Depósito', 'description': 'Estoque de retaguarda'});
  }

  // ---------------- CATEGORIAS ----------------
  Future<int> insertCategory(String name) async {
    final db = await database;
    return db.insert('categories', {'name': name});
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    final db = await database;
    return db.query('categories', orderBy: 'name');
  }

  Future<int> deleteCategory(int id) async {
    final db = await database;
    return db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  // ---------------- FORNECEDORES ----------------
  Future<int> insertSupplier(Map<String, dynamic> supplier) async {
    final db = await database;
    return db.insert('suppliers', supplier);
  }

  Future<int> updateSupplier(int id, Map<String, dynamic> supplier) async {
    final db = await database;
    return db.update('suppliers', supplier, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteSupplier(int id) async {
    final db = await database;
    return db.delete('suppliers', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getSuppliers() async {
    final db = await database;
    return db.query('suppliers', orderBy: 'name');
  }

  // ---------------- LOCAIS ----------------
  Future<int> insertLocation(Map<String, dynamic> location) async {
    final db = await database;
    return db.insert('locations', location);
  }

  Future<List<Map<String, dynamic>>> getLocations() async {
    final db = await database;
    return db.query('locations', orderBy: 'name');
  }

  // ---------------- PRODUTOS ----------------
  Future<int> insertProduct(Product product) async {
    final db = await database;
    final id = await db.insert('products', product.toMap());
    // Garante linha zerada em cada local existente
    final locations = await getLocations();
    for (final loc in locations) {
      await db.insert('stock_by_location',
          {'product_id': id, 'location_id': loc['id'], 'quantity': 0.0},
          conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    return id;
  }

  Future<int> updateProduct(Product product) async {
    final db = await database;
    return db.update('products', product.toMap(),
        where: 'id = ?', whereArgs: [product.id]);
  }

  Future<int> deleteProduct(int id) async {
    final db = await database;
    return db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  // Lista de produtos com estoque total agregado (soma de todos os locais)
  Future<List<Product>> getProducts({String? search, int? categoryId}) async {
    final db = await database;
    final where = <String>[];
    final args = <dynamic>[];
    if (search != null && search.isNotEmpty) {
      where.add('(p.name LIKE ? OR p.sku LIKE ? OR p.barcode LIKE ?)');
      args.addAll(['%$search%', '%$search%', '%$search%']);
    }
    if (categoryId != null) {
      where.add('p.category_id = ?');
      args.add(categoryId);
    }
    final whereSql = where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}';

    final rows = await db.rawQuery('''
      SELECT p.*, c.name as category_name, s.name as supplier_name,
        COALESCE((SELECT SUM(sbl.quantity) FROM stock_by_location sbl WHERE sbl.product_id = p.id), 0) as current_stock
      FROM products p
      LEFT JOIN categories c ON c.id = p.category_id
      LEFT JOIN suppliers s ON s.id = p.supplier_id
      $whereSql
      ORDER BY p.name
    ''', args);

    return rows.map((r) => Product.fromMap(r)).toList();
  }

  Future<Product?> getProductById(int id) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT p.*, c.name as category_name, s.name as supplier_name,
        COALESCE((SELECT SUM(sbl.quantity) FROM stock_by_location sbl WHERE sbl.product_id = p.id), 0) as current_stock
      FROM products p
      LEFT JOIN categories c ON c.id = p.category_id
      LEFT JOIN suppliers s ON s.id = p.supplier_id
      WHERE p.id = ?
    ''', [id]);
    if (rows.isEmpty) return null;
    return Product.fromMap(rows.first);
  }

  Future<Product?> getProductByBarcode(String barcode) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT p.*, c.name as category_name, s.name as supplier_name,
        COALESCE((SELECT SUM(sbl.quantity) FROM stock_by_location sbl WHERE sbl.product_id = p.id), 0) as current_stock
      FROM products p
      LEFT JOIN categories c ON c.id = p.category_id
      LEFT JOIN suppliers s ON s.id = p.supplier_id
      WHERE p.barcode = ? OR p.sku = ?
      LIMIT 1
    ''', [barcode, barcode]);
    if (rows.isEmpty) return null;
    return Product.fromMap(rows.first);
  }

  // Estoque de um produto por local: [{location_id, location_name, quantity}]
  Future<List<Map<String, dynamic>>> getStockByLocation(int productId) async {
    final db = await database;
    return db.rawQuery('''
      SELECT l.id as location_id, l.name as location_name,
        COALESCE(sbl.quantity, 0) as quantity
      FROM locations l
      LEFT JOIN stock_by_location sbl ON sbl.location_id = l.id AND sbl.product_id = ?
      ORDER BY l.name
    ''', [productId]);
  }

  // ---------------- MOVIMENTAÇÕES (núcleo do controle de estoque) ----------------

  Future<double> _getQty(Transaction txn, int productId, int locationId) async {
    final rows = await txn.query('stock_by_location',
        where: 'product_id = ? AND location_id = ?',
        whereArgs: [productId, locationId]);
    if (rows.isEmpty) return 0;
    return (rows.first['quantity'] as num).toDouble();
  }

  Future<void> _setQty(
      Transaction txn, int productId, int locationId, double qty) async {
    await txn.insert(
      'stock_by_location',
      {'product_id': productId, 'location_id': locationId, 'quantity': qty},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Registra uma movimentação e atualiza o estoque por local de forma atômica.
  /// [quantity] é sempre positiva. Para 'ajuste', use [adjustToValue] para
  /// definir a quantidade final diretamente (ajuste de inventário), ou
  /// [signedAdjustment] (+/-) para ajuste relativo.
  Future<int> registerMovement(
    StockMovement movement, {
    double? adjustToValue,
  }) async {
    final db = await database;
    return db.transaction<int>((txn) async {
      final current = await _getQty(txn, movement.productId, movement.locationId);

      switch (movement.type) {
        case MovementType.entrada:
        case MovementType.devolucao:
          await _setQty(txn, movement.productId, movement.locationId,
              current + movement.quantity);
          break;
        case MovementType.saida:
        case MovementType.perda:
          final newQty = current - movement.quantity;
          await _setQty(txn, movement.productId, movement.locationId,
              newQty < 0 ? 0 : newQty);
          break;
        case MovementType.ajuste:
          final target = adjustToValue ?? (current + movement.quantity);
          await _setQty(txn, movement.productId, movement.locationId,
              target < 0 ? 0 : target);
          break;
        case MovementType.transferencia:
          if (movement.destinationLocationId == null) {
            throw ArgumentError('Transferência requer local de destino');
          }
          final originNew = current - movement.quantity;
          if (originNew < 0) {
            throw StateError('Estoque insuficiente no local de origem');
          }
          await _setQty(txn, movement.productId, movement.locationId, originNew);
          final destCurrent = await _getQty(
              txn, movement.productId, movement.destinationLocationId!);
          await _setQty(txn, movement.productId,
              movement.destinationLocationId!, destCurrent + movement.quantity);
          break;
      }

      return txn.insert('stock_movements', movement.toMap());
    });
  }

  Future<List<StockMovement>> getMovements({
    int? productId,
    MovementType? type,
    DateTime? from,
    DateTime? to,
    int limit = 200,
  }) async {
    final db = await database;
    final where = <String>[];
    final args = <dynamic>[];
    if (productId != null) {
      where.add('m.product_id = ?');
      args.add(productId);
    }
    if (type != null) {
      where.add('m.type = ?');
      args.add(type.name);
    }
    if (from != null) {
      where.add('m.date >= ?');
      args.add(from.toIso8601String());
    }
    if (to != null) {
      where.add('m.date <= ?');
      args.add(to.toIso8601String());
    }
    final whereSql = where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}';

    final rows = await db.rawQuery('''
      SELECT m.*, p.name as product_name,
        l1.name as location_name, l2.name as destination_location_name
      FROM stock_movements m
      JOIN products p ON p.id = m.product_id
      JOIN locations l1 ON l1.id = m.location_id
      LEFT JOIN locations l2 ON l2.id = m.destination_location_id
      $whereSql
      ORDER BY m.date DESC
      LIMIT $limit
    ''', args);

    return rows.map((r) => StockMovement.fromMap(r)).toList();
  }

  // ---------------- PEDIDOS DE COMPRA ----------------
  Future<int> insertPurchaseOrder(PurchaseOrder order) async {
    final db = await database;
    return db.transaction<int>((txn) async {
      final id = await txn.insert('purchase_orders', order.toMap());
      for (final item in order.items) {
        await txn.insert('purchase_order_items', {
          ...item.toMap(),
          'purchase_order_id': id,
        });
      }
      return id;
    });
  }

  Future<List<PurchaseOrder>> getPurchaseOrders({PurchaseStatus? status}) async {
    final db = await database;
    final where = status != null ? 'WHERE po.status = ?' : '';
    final args = status != null ? [status.name] : <dynamic>[];
    final rows = await db.rawQuery('''
      SELECT po.*, s.name as supplier_name
      FROM purchase_orders po
      JOIN suppliers s ON s.id = po.supplier_id
      $where
      ORDER BY po.order_date DESC
    ''', args);

    final orders = <PurchaseOrder>[];
    for (final r in rows) {
      final items = await db.rawQuery('''
        SELECT poi.*, p.name as product_name FROM purchase_order_items poi
        JOIN products p ON p.id = poi.product_id
        WHERE poi.purchase_order_id = ?
      ''', [r['id']]);
      orders.add(PurchaseOrder.fromMap(r,
          items: items.map((i) => PurchaseOrderItem.fromMap(i)).toList()));
    }
    return orders;
  }

  /// Marca pedido como recebido e gera as movimentações de entrada automaticamente.
  Future<void> receivePurchaseOrder(PurchaseOrder order) async {
    final db = await database;
    await db.update(
      'purchase_orders',
      {
        'status': PurchaseStatus.recebido.name,
        'received_date': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [order.id],
    );
    for (final item in order.items) {
      await registerMovement(StockMovement(
        productId: item.productId,
        type: MovementType.entrada,
        quantity: item.quantity,
        locationId: order.locationId,
        reason: 'Recebimento de pedido de compra',
        document: 'PO#${order.id}',
      ));
      // Atualiza custo do produto com o custo mais recente de compra
      final db2 = await database;
      await db2.update('products', {'cost_price': item.unitCost},
          where: 'id = ?', whereArgs: [item.productId]);
    }
  }

  Future<void> cancelPurchaseOrder(int id) async {
    final db = await database;
    await db.update('purchase_orders', {'status': PurchaseStatus.cancelado.name},
        where: 'id = ?', whereArgs: [id]);
  }

  /// Sugestão de compra baseada no histórico de saídas dos últimos 30 dias
  /// e no estoque mínimo/atual.
  Future<List<Map<String, dynamic>>> getPurchaseSuggestions() async {
    final db = await database;
    final since = DateTime.now().subtract(const Duration(days: 30)).toIso8601String();
    final rows = await db.rawQuery('''
      SELECT p.id, p.name, p.sku, p.min_stock, p.max_stock, p.supplier_id, s.name as supplier_name,
        COALESCE((SELECT SUM(sbl.quantity) FROM stock_by_location sbl WHERE sbl.product_id = p.id), 0) as current_stock,
        COALESCE((SELECT SUM(m.quantity) FROM stock_movements m
                  WHERE m.product_id = p.id AND m.type = 'saida' AND m.date >= ?), 0) as sold_last_30
      FROM products p
      LEFT JOIN suppliers s ON s.id = p.supplier_id
    ''', [since]);

    final suggestions = <Map<String, dynamic>>[];
    for (final r in rows) {
      final currentStock = (r['current_stock'] as num).toDouble();
      final minStock = (r['min_stock'] as num).toDouble();
      final soldLast30 = (r['sold_last_30'] as num).toDouble();
      if (currentStock <= minStock) {
        // sugere repor até cobrir 30 dias de venda projetada + margem até o máximo
        final maxStock = (r['max_stock'] as num).toDouble();
        final target = maxStock > 0 ? maxStock : (soldLast30 > 0 ? soldLast30 : minStock * 2);
        final suggestedQty = (target - currentStock).clamp(0, double.infinity);
        if (suggestedQty > 0) {
          suggestions.add({
            'product_id': r['id'],
            'product_name': r['name'],
            'sku': r['sku'],
            'current_stock': currentStock,
            'min_stock': minStock,
            'sold_last_30': soldLast30,
            'suggested_qty': suggestedQty,
            'supplier_id': r['supplier_id'],
            'supplier_name': r['supplier_name'],
          });
        }
      }
    }
    return suggestions;
  }

  // ---------------- VENDAS ----------------
  Future<int> insertSale(Sale sale) async {
    final db = await database;
    return db.transaction<int>((txn) async {
      final id = await txn.insert('sales', sale.toMap());
      for (final item in sale.items) {
        await txn.insert('sale_items', {
          ...item.toMap(),
          'sale_id': id,
        });
      }
      return id;
    }).then((id) async {
      // Baixa automática no estoque via movimentações de saída
      for (final item in sale.items) {
        await registerMovement(StockMovement(
          productId: item.productId,
          type: MovementType.saida,
          quantity: item.quantity,
          locationId: sale.locationId,
          reason: 'Venda',
          document: 'VENDA#$id',
        ));
      }
      return id;
    });
  }

  Future<List<Sale>> getSales({DateTime? from, DateTime? to}) async {
    final db = await database;
    final where = <String>[];
    final args = <dynamic>[];
    if (from != null) {
      where.add('date >= ?');
      args.add(from.toIso8601String());
    }
    if (to != null) {
      where.add('date <= ?');
      args.add(to.toIso8601String());
    }
    final whereSql = where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}';
    final rows = await db.rawQuery(
        'SELECT * FROM sales $whereSql ORDER BY date DESC', args);

    final sales = <Sale>[];
    for (final r in rows) {
      final items = await db.rawQuery('''
        SELECT si.*, p.name as product_name FROM sale_items si
        JOIN products p ON p.id = si.product_id
        WHERE si.sale_id = ?
      ''', [r['id']]);
      sales.add(Sale.fromMap(r, items: items.map((i) => SaleItem.fromMap(i)).toList()));
    }
    return sales;
  }

  // ---------------- DASHBOARD / ALERTAS / RELATÓRIOS ----------------

  Future<Map<String, dynamic>> getDashboardSummary() async {
    final db = await database;

    final totalProducts = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) as c FROM products')) ??
        0;

    final stockValueRow = await db.rawQuery('''
      SELECT COALESCE(SUM(p.cost_price * sbl.quantity), 0) as v
      FROM products p
      JOIN stock_by_location sbl ON sbl.product_id = p.id
    ''');
    final stockValue = (stockValueRow.first['v'] as num).toDouble();

    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day).toIso8601String();

    final entriesToday = Sqflite.firstIntValue(await db.rawQuery('''
      SELECT COUNT(*) as c FROM stock_movements
      WHERE type = 'entrada' AND date >= ?
    ''', [todayStart])) ?? 0;

    final exitsToday = Sqflite.firstIntValue(await db.rawQuery('''
      SELECT COUNT(*) as c FROM stock_movements
      WHERE type = 'saida' AND date >= ?
    ''', [todayStart])) ?? 0;

    final products = await getProducts();
    final lowStock = products.where((p) => p.isLowStock).length;
    final outOfStock = products.where((p) => p.isOutOfStock).length;

    return {
      'total_products': totalProducts,
      'stock_value': stockValue,
      'low_stock': lowStock,
      'out_of_stock': outOfStock,
      'entries_today': entriesToday,
      'exits_today': exitsToday,
    };
  }

  Future<List<Map<String, dynamic>>> getTopSellingProducts({int limit = 5, int days = 30}) async {
    final db = await database;
    final since = DateTime.now().subtract(Duration(days: days)).toIso8601String();
    return db.rawQuery('''
      SELECT p.id, p.name, SUM(m.quantity) as total_sold
      FROM stock_movements m
      JOIN products p ON p.id = m.product_id
      WHERE m.type = 'saida' AND m.date >= ?
      GROUP BY p.id
      ORDER BY total_sold DESC
      LIMIT ?
    ''', [since, limit]);
  }

  Future<List<Map<String, dynamic>>> getStaleProducts({int days = 60}) async {
    final db = await database;
    final since = DateTime.now().subtract(Duration(days: days)).toIso8601String();
    return db.rawQuery('''
      SELECT p.id, p.name, p.sku,
        COALESCE((SELECT SUM(sbl.quantity) FROM stock_by_location sbl WHERE sbl.product_id = p.id), 0) as current_stock,
        (SELECT MAX(m.date) FROM stock_movements m WHERE m.product_id = p.id) as last_movement
      FROM products p
      WHERE (SELECT MAX(m.date) FROM stock_movements m WHERE m.product_id = p.id) < ?
         OR (SELECT MAX(m.date) FROM stock_movements m WHERE m.product_id = p.id) IS NULL
      ORDER BY last_movement ASC NULLS FIRST
    ''', [since]);
  }

  Future<List<Map<String, dynamic>>> getRecentEntries({int limit = 10}) async {
    final db = await database;
    return db.rawQuery('''
      SELECT m.*, p.name as product_name
      FROM stock_movements m
      JOIN products p ON p.id = m.product_id
      WHERE m.type = 'entrada'
      ORDER BY m.date DESC
      LIMIT ?
    ''', [limit]);
  }

  /// Movimentação diária (entradas x saídas) dos últimos [days] dias, para gráfico.
  Future<List<Map<String, dynamic>>> getDailyMovementChart({int days = 14}) async {
    final db = await database;
    final result = <Map<String, dynamic>>[];
    for (int i = days - 1; i >= 0; i--) {
      final day = DateTime.now().subtract(Duration(days: i));
      final dayStart = DateTime(day.year, day.month, day.day);
      final dayEnd = dayStart.add(const Duration(days: 1));
      final entries = Sqflite.firstIntValue(await db.rawQuery('''
        SELECT COALESCE(SUM(quantity),0) as v FROM stock_movements
        WHERE type = 'entrada' AND date >= ? AND date < ?
      ''', [dayStart.toIso8601String(), dayEnd.toIso8601String()])) ?? 0;
      final exits = Sqflite.firstIntValue(await db.rawQuery('''
        SELECT COALESCE(SUM(quantity),0) as v FROM stock_movements
        WHERE type = 'saida' AND date >= ? AND date < ?
      ''', [dayStart.toIso8601String(), dayEnd.toIso8601String()])) ?? 0;
      result.add({'date': dayStart, 'entries': entries, 'exits': exits});
    }
    return result;
  }

  // Relatório de compras por fornecedor
  Future<List<Map<String, dynamic>>> getPurchasesBySupplier() async {
    final db = await database;
    return db.rawQuery('''
      SELECT s.name as supplier_name,
        COUNT(po.id) as total_orders,
        COALESCE(SUM(poi.quantity * poi.unit_cost), 0) as total_value
      FROM purchase_orders po
      JOIN suppliers s ON s.id = po.supplier_id
      LEFT JOIN purchase_order_items poi ON poi.purchase_order_id = po.id
      WHERE po.status = 'recebido'
      GROUP BY s.id
      ORDER BY total_value DESC
    ''');
  }

  // Relatório de perdas e avarias
  Future<List<Map<String, dynamic>>> getLossesReport({DateTime? from, DateTime? to}) async {
    final db = await database;
    final where = <String>["m.type = 'perda'"];
    final args = <dynamic>[];
    if (from != null) {
      where.add('m.date >= ?');
      args.add(from.toIso8601String());
    }
    if (to != null) {
      where.add('m.date <= ?');
      args.add(to.toIso8601String());
    }
    return db.rawQuery('''
      SELECT m.*, p.name as product_name, p.cost_price,
        (m.quantity * p.cost_price) as loss_value
      FROM stock_movements m
      JOIN products p ON p.id = m.product_id
      WHERE ${where.join(' AND ')}
      ORDER BY m.date DESC
    ''', args);
  }

  // Lucro estimado no período (vendas - custo dos produtos vendidos)
  Future<Map<String, dynamic>> getEstimatedProfit({DateTime? from, DateTime? to}) async {
    final db = await database;
    final where = <String>["si.sale_id = s.id"];
    final args = <dynamic>[];
    var dateFilter = '';
    if (from != null) {
      dateFilter += ' AND s.date >= ?';
      args.add(from.toIso8601String());
    }
    if (to != null) {
      dateFilter += ' AND s.date <= ?';
      args.add(to.toIso8601String());
    }
    final rows = await db.rawQuery('''
      SELECT COALESCE(SUM(si.quantity * si.unit_price), 0) as revenue,
        COALESCE(SUM(si.quantity * p.cost_price), 0) as cost
      FROM sale_items si
      JOIN sales s ON ${where.join(' AND ')}
      JOIN products p ON p.id = si.product_id
      WHERE 1=1 $dateFilter
    ''', args);
    final revenue = (rows.first['revenue'] as num).toDouble();
    final cost = (rows.first['cost'] as num).toDouble();
    return {'revenue': revenue, 'cost': cost, 'profit': revenue - cost};
  }

  // ---------------- CLIENTES ----------------
  Future<int> insertClient(Client client) async {
    final db = await database;
    return db.insert('clients', client.toMap());
  }

  Future<int> updateClient(Client client) async {
    final db = await database;
    return db.update('clients', client.toMap(), where: 'id = ?', whereArgs: [client.id]);
  }

  Future<int> deleteClient(int id) async {
    final db = await database;
    return db.delete('clients', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Client>> getClients({String? search}) async {
    final db = await database;
    final where = search != null && search.isNotEmpty ? 'WHERE name LIKE ?' : '';
    final args = search != null && search.isNotEmpty ? ['%$search%'] : <dynamic>[];
    final rows = await db.rawQuery('SELECT * FROM clients $where ORDER BY name', args);
    return rows.map((r) => Client.fromMap(r)).toList();
  }

  Future<Client?> getClientById(int id) async {
    final db = await database;
    final rows = await db.query('clients', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Client.fromMap(rows.first);
  }

  // ---------------- LEMBRETES DE RECOMPRA ----------------
  Future<int> insertReminder(Reminder reminder) async {
    final db = await database;
    return db.insert('reminders', reminder.toMap());
  }

  /// Lista lembretes ordenados por data de vencimento (mais próximos primeiro).
  Future<List<Reminder>> getReminders({bool? done}) async {
    final db = await database;
    final where = done != null ? 'WHERE done = ?' : '';
    final args = done != null ? [done ? 1 : 0] : <dynamic>[];
    final rows = await db.rawQuery('SELECT * FROM reminders $where ORDER BY due_date ASC', args);
    return rows.map((r) => Reminder.fromMap(r)).toList();
  }

  Future<int> markReminderDone(int id, {bool done = true}) async {
    final db = await database;
    return db.update('reminders', {'done': done ? 1 : 0}, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteReminder(int id) async {
    final db = await database;
    return db.delete('reminders', where: 'id = ?', whereArgs: [id]);
  }
}

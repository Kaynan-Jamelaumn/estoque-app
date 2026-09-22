import 'package:flutter/foundation.dart';
import '../database/db_helper.dart';
import '../models/client.dart';

class ClientProvider extends ChangeNotifier {
  final _db = DBHelper.instance;
  List<Client> _clients = [];
  bool loading = false;
  String? error;

  List<Client> get clients => _clients;

  Future<void> loadClients({String? search}) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      _clients = await _db.getClients(search: search);
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<int> addClient(Client client) async {
    final id = await _db.insertClient(client);
    await loadClients();
    return id;
  }

  Future<void> editClient(Client client) async {
    await _db.updateClient(client);
    await loadClients();
  }

  Future<void> removeClient(int id) async {
    await _db.deleteClient(id);
    await loadClients();
  }
}

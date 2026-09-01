import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

/// No navegador não existe sistema de arquivos nem plugin nativo, então
/// usamos `sqflite_common_ffi_web`, que roda o SQLite compilado para
/// WebAssembly (sqlite3.wasm) e persiste os dados no IndexedDB do navegador.
///
/// IMPORTANTE: para isso funcionar, é necessário rodar uma vez, na raiz do
/// projeto, o comando abaixo (ele baixa os arquivos sqlite3.wasm e
/// sqflite_sw.js para dentro da pasta web/):
///
///   dart run sqflite_common_ffi_web:setup
///
bool _initialized = false;

Future<void> initDatabaseFactory() async {
  if (_initialized) return;
  _initialized = true;
  databaseFactory = databaseFactoryFfiWeb;
}

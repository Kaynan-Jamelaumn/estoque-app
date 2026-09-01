import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// No Android e iOS, o `sqflite` já usa o plugin nativo por padrão — não
/// precisamos trocar o `databaseFactory`.
///
/// No Windows, Linux e macOS não existe plugin nativo do sqflite, então
/// usamos `sqflite_common_ffi`, que roda o SQLite via FFI (biblioteca C
/// nativa) diretamente no processo Dart/Flutter.
bool _initialized = false;

Future<void> initDatabaseFactory() async {
  if (_initialized) return;
  _initialized = true;
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  // Android/iOS: mantém o databaseFactory padrão (plugin nativo sqflite).
}

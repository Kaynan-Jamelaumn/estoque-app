/// Ponto único de inicialização do `databaseFactory` do sqflite.
///
/// Este arquivo não contém código real: ele apenas escolhe, em tempo de
/// compilação, qual implementação usar:
/// - `db_platform_web.dart`   -> quando compilado para Web (dart.library.html)
/// - `db_platform_io.dart`    -> quando compilado para mobile/desktop (dart.library.io)
/// - `db_platform_stub.dart`  -> fallback (não deve ser usado na prática)
export 'db_platform_stub.dart'
    if (dart.library.io) 'db_platform_io.dart'
    if (dart.library.html) 'db_platform_web.dart';

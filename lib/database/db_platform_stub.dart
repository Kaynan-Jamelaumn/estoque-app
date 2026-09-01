/// Fallback vazio. Na prática, sempre existirá dart.library.io (mobile/desktop)
/// ou dart.library.html (web) disponível, então este arquivo nunca é usado.
Future<void> initDatabaseFactory() async {}

import 'package:intl/intl.dart';

final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
final dateFormat = DateFormat('dd/MM/yyyy');
final dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');
final qtyFormat = NumberFormat.decimalPattern('pt_BR');

String formatQty(double v) {
  if (v == v.roundToDouble()) return v.toInt().toString();
  return qtyFormat.format(v);
}

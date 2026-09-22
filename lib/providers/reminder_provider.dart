import 'package:flutter/foundation.dart';
import '../database/db_helper.dart';
import '../models/reminder.dart';

class ReminderProvider extends ChangeNotifier {
  final _db = DBHelper.instance;
  List<Reminder> _reminders = [];
  bool loading = false;
  String? error;

  /// Lembretes pendentes (não concluídos), ordenados por vencimento.
  List<Reminder> get reminders => _reminders;

  List<Reminder> get overdue => _reminders.where((r) => r.isOverdue).toList();

  Future<void> loadReminders() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      _reminders = await _db.getReminders(done: false);
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> addReminder(Reminder reminder) async {
    await _db.insertReminder(reminder);
    await loadReminders();
  }

  Future<void> markDone(int id) async {
    await _db.markReminderDone(id, done: true);
    await loadReminders();
  }

  Future<void> removeReminder(int id) async {
    await _db.deleteReminder(id);
    await loadReminders();
  }
}

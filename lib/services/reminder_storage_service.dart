/*
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/budget.dart';

class ReminderStorageService {
  static const String _remindersKey = 'goal_reminders';

  // Save a reminder
  static Future<void> saveReminder(GoalReminder reminder) async {
    final prefs = await SharedPreferences.getInstance();
    final reminders = await getReminders();

    // Remove existing reminder for this goal if exists
    reminders.removeWhere((r) => r.goalId == reminder.goalId);
    reminders.add(reminder);

    final remindersJson = reminders.map((r) => r.toJson()).toList();
    await prefs.setString(_remindersKey, jsonEncode(remindersJson));
  }

  // Get all reminders
  static Future<List<GoalReminder>> getReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final remindersJson = prefs.getString(_remindersKey);

    if (remindersJson != null) {
      final List<dynamic> decoded = jsonDecode(remindersJson);
      return decoded.map((item) => GoalReminder.fromJson(item)).toList();
    }
    return [];
  }

  // Get reminder for a specific goal
  static Future<GoalReminder?> getReminderForGoal(String goalId) async {
    final reminders = await getReminders();
    try {
      return reminders.firstWhere((r) => r.goalId == goalId);
    } catch (e) {
      return null;
    }
  }

  // Delete reminder for a goal
  static Future<void> deleteReminder(String goalId) async {
    final prefs = await SharedPreferences.getInstance();
    final reminders = await getReminders();
    reminders.removeWhere((r) => r.goalId == goalId);

    final remindersJson = reminders.map((r) => r.toJson()).toList();
    await prefs.setString(_remindersKey, jsonEncode(remindersJson));
  }

  // Update reminder
  static Future<void> updateReminder(GoalReminder reminder) async {
    await saveReminder(reminder); // Same as save
  }
}
*/

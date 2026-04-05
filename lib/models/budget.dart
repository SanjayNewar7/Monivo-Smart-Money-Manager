class Budget {
  final String id;
  final String category;
  final double limit;
  final double spent;
  final String color;
  final DateTime startDate;
  final DateTime endDate;
  final BudgetPeriod period;

  Budget({
    required this.id,
    required this.category,
    required this.limit,
    required this.spent,
    required this.color,
    DateTime? startDate,
    DateTime? endDate,
    this.period = BudgetPeriod.monthly,
  })  : startDate = startDate ?? DateTime(DateTime.now().year, DateTime.now().month, 1),
        endDate = endDate ?? DateTime(DateTime.now().year, DateTime.now().month + 1, 0);

  double get progress => (spent / limit) * 100;

  bool get isExceeded => progress > 100;

  bool get isWarning => progress > 80 && progress <= 100;

  bool get isOnTrack => progress <= 80;

  double get remaining => limit - spent;

  double get dailyAverage {
    final daysPassed = DateTime.now().difference(startDate).inDays + 1;
    return spent / daysPassed;
  }

  double get projectedSpending => dailyAverage * (endDate.difference(startDate).inDays + 1);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'limit': limit,
      'spent': spent,
      'color': color,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'period': period.toString().split('.').last,
    };
  }

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'],
      category: json['category'],
      limit: json['limit'].toDouble(),
      spent: json['spent'].toDouble(),
      color: json['color'],
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      period: BudgetPeriod.values.firstWhere(
            (e) => e.toString().split('.').last == json['period'],
        orElse: () => BudgetPeriod.monthly,
      ),
    );
  }
}

enum BudgetPeriod {
  weekly,
  monthly,
  yearly,
}

// ================= OLD CODE COMMENTED OUT =================
// // NEW: Reminder model
// class GoalReminder {
//   final String id;
//   final String goalId;
//   final String frequency; // daily, weekly, monthly
//   final int hour;
//   final int minute;
//   final int? dayOfWeek; // 1-7 for weekly
//   final int? dayOfMonth; // 1-31 for monthly
//   final String? customMessage;
//   final bool isEnabled;
//   final DateTime createdAt;
//
//   GoalReminder({
//     required this.id,
//     required this.goalId,
//     required this.frequency,
//     required this.hour,
//     required this.minute,
//     this.dayOfWeek,
//     this.dayOfMonth,
//     this.customMessage,
//     this.isEnabled = true,
//     DateTime? createdAt,
//   }) : createdAt = createdAt ?? DateTime.now();
//
//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'goalId': goalId,
//       'frequency': frequency,
//       'hour': hour,
//       'minute': minute,
//       'dayOfWeek': dayOfWeek,
//       'dayOfMonth': dayOfMonth,
//       'customMessage': customMessage,
//       'isEnabled': isEnabled,
//       'createdAt': createdAt.toIso8601String(),
//     };
//   }
//
//   factory GoalReminder.fromJson(Map<String, dynamic> json) {
//     return GoalReminder(
//       id: json['id'],
//       goalId: json['goalId'],
//       frequency: json['frequency'],
//       hour: json['hour'],
//       minute: json['minute'],
//       dayOfWeek: json['dayOfWeek'],
//       dayOfMonth: json['dayOfMonth'],
//       customMessage: json['customMessage'],
//       isEnabled: json['isEnabled'] ?? true,
//       createdAt: DateTime.parse(json['createdAt']),
//     );
//   }
// }

class SavingsGoal {
  final String id;
  final String name;
  final double target;
  final double current;
  final String color;
  final DateTime deadline;
  final String? icon;
  final bool isAutoSave;
  // final GoalReminder? reminder; // OLD: Associated reminder (commented out)

  SavingsGoal({
    required this.id,
    required this.name,
    required this.target,
    required this.current,
    required this.color,
    required this.deadline,
    this.icon,
    this.isAutoSave = false,
    // this.reminder,
  });

  double get progress => (current / target) * 100;

  double get remaining => target - current;

  int get daysRemaining => deadline.difference(DateTime.now()).inDays;

  double get requiredDaily {
    if (daysRemaining <= 0) return 0;
    return remaining / daysRemaining;
  }

  bool get isBehind {
    if (deadline.isBefore(DateTime.now())) {
      return current < target;
    }

    final daysRemaining = this.daysRemaining;
    if (daysRemaining <= 0) return current < target;

    final totalDays = deadline.difference(DateTime.now()).inDays + daysRemaining;
    if (totalDays <= 0) return false;

    final expectedProgress = target * (1 - (daysRemaining / totalDays));
    return current < expectedProgress;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'target': target,
      'current': current,
      'color': color,
      'deadline': deadline.toIso8601String(),
      'icon': icon,
      'isAutoSave': isAutoSave,
      // 'reminder': reminder?.toJson(),
    };
  }

  factory SavingsGoal.fromJson(Map<String, dynamic> json) {
    return SavingsGoal(
      id: json['id'],
      name: json['name'],
      target: json['target'].toDouble(),
      current: json['current'].toDouble(),
      color: json['color'],
      deadline: DateTime.parse(json['deadline']),
      icon: json['icon'],
      isAutoSave: json['isAutoSave'] ?? false,
      // reminder: json['reminder'] != null ? GoalReminder.fromJson(json['reminder']) : null,
    );
  }
}
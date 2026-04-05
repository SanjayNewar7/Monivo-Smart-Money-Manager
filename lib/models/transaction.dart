class Transaction {
  final String id;
  final double amount;
  final TransactionType type;
  final String category;
  final String note;
  final DateTime date;
  final String account;
  final String? attachmentPath;
  final bool isRecurring;

  Transaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.category,
    required this.note,
    required this.date,
    required this.account,
    this.attachmentPath,
    this.isRecurring = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'type': type.toString().split('.').last,
      'category': category,
      'note': note,
      'date': date.toIso8601String(),
      'account': account,
      'attachmentPath': attachmentPath,
      'isRecurring': isRecurring,
    };
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      amount: json['amount'].toDouble(),
      type: json['type'] == 'income' ? TransactionType.income : TransactionType.expense,
      category: json['category'],
      note: json['note'],
      date: DateTime.parse(json['date']),
      account: json['account'],
      attachmentPath: json['attachmentPath'],
      isRecurring: json['isRecurring'] ?? false,
    );
  }
}

enum TransactionType {
  income,
  expense,
}

class Category {
  final String id;
  final String name;
  final String icon;
  final String color;
  final TransactionType type;
  final bool isDefault;

  Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
    this.isDefault = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'color': color,
      'type': type.toString().split('.').last,
      'isDefault': isDefault,
    };
  }

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      icon: json['icon'],
      color: json['color'],
      type: json['type'] == 'income' ? TransactionType.income : TransactionType.expense,
      isDefault: json['isDefault'] ?? false,
    );
  }
}

class Account {
  final String id;
  final String name;
  final double balance;
  final String bank;
  final String? accountNumber;
  final String? icon;

  Account({
    required this.id,
    required this.name,
    required this.balance,
    required this.bank,
    this.accountNumber,
    this.icon,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'balance': balance,
      'bank': bank,
      'accountNumber': accountNumber,
      'icon': icon,
    };
  }

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id'],
      name: json['name'],
      balance: json['balance'].toDouble(),
      bank: json['bank'],
      accountNumber: json['accountNumber'],
      icon: json['icon'],
    );
  }
}
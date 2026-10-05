import 'package:uuid/uuid.dart';

enum TransactionType {
  income,
  expense;

  String get displayName {
    switch (this) {
      case TransactionType.income:
        return 'Income';
      case TransactionType.expense:
        return 'Expense';
    }
  }

  static TransactionType fromString(String value) {
    if (value.toLowerCase() == 'income') {
      return TransactionType.income;
    }
    return TransactionType.expense;
  }
}

enum RecurrenceFrequency {
  none,
  daily,
  weekly,
  monthly,
  yearly;

  String get displayName {
    switch (this) {
      case RecurrenceFrequency.none:
        return 'One-time';
      case RecurrenceFrequency.daily:
        return 'Daily';
      case RecurrenceFrequency.weekly:
        return 'Weekly';
      case RecurrenceFrequency.monthly:
        return 'Monthly';
      case RecurrenceFrequency.yearly:
        return 'Yearly';
    }
  }

  static RecurrenceFrequency fromString(String? value) {
    if (value == null) return RecurrenceFrequency.none;
    for (final frequency in RecurrenceFrequency.values) {
      if (frequency.name.toLowerCase() == value.toLowerCase()) {
        return frequency;
      }
    }
    return RecurrenceFrequency.none;
  }
}

class TransactionModel {
  final String id;
  final String title;
  final double amount;
  final TransactionType type;
  final String category;
  final DateTime date;
  final String? note;
  final DateTime createdAt;
  final RecurrenceFrequency recurrence;

  TransactionModel({
    required this.id,
    required this.title,
    double amount = 0.0,
    required this.type,
    required this.category,
    required this.date,
    this.note,
    required this.createdAt,
    this.recurrence = RecurrenceFrequency.none,
  }) : amount = (amount.isNaN || amount.isInfinite || amount < 0) ? 0.0 : amount;

  bool get isExpense => type == TransactionType.expense;
  bool get isIncome => type == TransactionType.income;
  bool get isRecurring => recurrence != RecurrenceFrequency.none;

  TransactionModel copyWith({
    String? id,
    String? title,
    double? amount,
    TransactionType? type,
    String? category,
    DateTime? date,
    String? note,
    DateTime? createdAt,
    RecurrenceFrequency? recurrence,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      date: date ?? this.date,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      recurrence: recurrence ?? this.recurrence,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'type': type.name,
      'category': category,
      'date': date.toIso8601String(),
      'note': note,
      'createdAt': createdAt.toIso8601String(),
      'recurrence': recurrence.name,
    };
  }

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    final dynamic raw = json['amount'];
    double rawAmount = 0.0;
    if (raw is num) {
      rawAmount = raw.toDouble();
    } else if (raw is String) {
      rawAmount = double.tryParse(raw) ?? 0.0;
    }
    final validAmount = (rawAmount.isNaN || rawAmount.isInfinite || rawAmount < 0) ? 0.0 : rawAmount;
    DateTime parsedDate;
    try {
      parsedDate = json['date'] != null ? DateTime.parse(json['date'] as String) : DateTime.now();
    } catch (_) {
      parsedDate = DateTime.now();
    }

    DateTime parsedCreatedAt;
    try {
      parsedCreatedAt = json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now();
    } catch (_) {
      parsedCreatedAt = DateTime.now();
    }

    return TransactionModel(
      id: json['id'] as String? ?? const Uuid().v4(),
      title: json['title'] as String? ?? 'Untitled',
      amount: validAmount,
      type: TransactionType.fromString(json['type'] as String? ?? 'expense'),
      category: json['category'] as String? ?? 'Other',
      date: parsedDate,
      note: json['note'] as String?,
      createdAt: parsedCreatedAt,
      recurrence: RecurrenceFrequency.fromString(json['recurrence'] as String?),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

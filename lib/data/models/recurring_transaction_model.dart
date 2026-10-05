import 'transaction_model.dart';

class RecurringTransactionModel {
  final String id;
  final String title;
  final double amount;
  final TransactionType type;
  final String category;
  final String? note;
  final DateTime startDate;
  final DateTime? endDate;
  final RecurrenceFrequency frequency;
  final bool isActive;
  final DateTime? lastGeneratedDate;
  final DateTime createdAt;

  const RecurringTransactionModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    this.note,
    required this.startDate,
    this.endDate,
    required this.frequency,
    this.isActive = true,
    this.lastGeneratedDate,
    required this.createdAt,
  });

  bool get isIncome => type == TransactionType.income;
  bool get isExpense => type == TransactionType.expense;

  /// Returns the next expected occurrence date on or after [after]
  DateTime? getNextOccurrence([DateTime? after]) {
    final base = after ?? lastGeneratedDate ?? startDate;
    DateTime next;

    if (lastGeneratedDate == null && after == null) {
      next = startDate;
    } else {
      next = _advanceDate(base, frequency);
    }

    if (endDate != null && next.isAfter(endDate!)) {
      return null;
    }
    return next;
  }

  /// Calculates all occurrences due up to [upTo] (defaulting to DateTime.now())
  /// that have not been generated yet.
  List<DateTime> getDueOccurrences(DateTime upTo) {
    if (!isActive) return [];

    final List<DateTime> dueDates = [];
    final targetDate = DateTime(upTo.year, upTo.month, upTo.day, 23, 59, 59);

    DateTime candidate;
    if (lastGeneratedDate == null) {
      candidate = DateTime(startDate.year, startDate.month, startDate.day);
    } else {
      candidate = _advanceDate(lastGeneratedDate!, frequency);
    }

    // Safety limit to prevent infinite loop in case of corrupt dates
    int safetyCounter = 0;
    while (!candidate.isAfter(targetDate) && safetyCounter < 1000) {
      safetyCounter++;
      if (endDate != null && candidate.isAfter(endDate!)) {
        break;
      }
      dueDates.add(candidate);
      candidate = _advanceDate(candidate, frequency);
    }

    return dueDates;
  }

  static DateTime _advanceDate(DateTime date, RecurrenceFrequency freq) {
    switch (freq) {
      case RecurrenceFrequency.daily:
        return date.add(const Duration(days: 1));
      case RecurrenceFrequency.weekly:
        return date.add(const Duration(days: 7));
      case RecurrenceFrequency.monthly:
        int newYear = date.year;
        int newMonth = date.month + 1;
        if (newMonth > 12) {
          newYear += 1;
          newMonth = 1;
        }
        // Handle varying days per month (e.g., Jan 31 -> Feb 28)
        final daysInNextMonth = _daysInMonth(newYear, newMonth);
        final newDay = date.day > daysInNextMonth ? daysInNextMonth : date.day;
        return DateTime(newYear, newMonth, newDay, date.hour, date.minute);
      case RecurrenceFrequency.yearly:
        int newYear = date.year + 1;
        final daysInMonth = _daysInMonth(newYear, date.month);
        final newDay = date.day > daysInMonth ? daysInMonth : date.day;
        return DateTime(newYear, date.month, newDay, date.hour, date.minute);
      case RecurrenceFrequency.none:
        return date;
    }
  }

  static int _daysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  RecurringTransactionModel copyWith({
    String? id,
    String? title,
    double? amount,
    TransactionType? type,
    String? category,
    String? note,
    DateTime? startDate,
    DateTime? endDate,
    RecurrenceFrequency? frequency,
    bool? isActive,
    DateTime? lastGeneratedDate,
    DateTime? createdAt,
  }) {
    return RecurringTransactionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      note: note ?? this.note,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      frequency: frequency ?? this.frequency,
      isActive: isActive ?? this.isActive,
      lastGeneratedDate: lastGeneratedDate ?? this.lastGeneratedDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'type': type.name,
      'category': category,
      'note': note,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'frequency': frequency.name,
      'isActive': isActive,
      'lastGeneratedDate': lastGeneratedDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory RecurringTransactionModel.fromJson(Map<String, dynamic> json) {
    final rawAmount = (json['amount'] as num?)?.toDouble() ?? 0.0;
    final validAmount = (rawAmount.isNaN || rawAmount.isInfinite || rawAmount < 0) ? 0.0 : rawAmount;
    DateTime parsedStartDate;
    try {
      parsedStartDate = json['startDate'] != null
          ? DateTime.parse(json['startDate'] as String)
          : DateTime.now();
    } catch (_) {
      parsedStartDate = DateTime.now();
    }

    DateTime? parsedEndDate;
    if (json['endDate'] != null) {
      try {
        parsedEndDate = DateTime.parse(json['endDate'] as String);
      } catch (_) {
        parsedEndDate = null;
      }
    }

    DateTime? parsedLastGen;
    if (json['lastGeneratedDate'] != null) {
      try {
        parsedLastGen = DateTime.parse(json['lastGeneratedDate'] as String);
      } catch (_) {
        parsedLastGen = null;
      }
    }

    DateTime parsedCreatedAt;
    try {
      parsedCreatedAt = json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now();
    } catch (_) {
      parsedCreatedAt = DateTime.now();
    }

    return RecurringTransactionModel(
      id: json['id'] as String? ?? 'rec_${DateTime.now().millisecondsSinceEpoch}',
      title: json['title'] as String? ?? 'Untitled Rule',
      amount: validAmount,
      type: TransactionType.fromString(json['type'] as String? ?? 'expense'),
      category: json['category'] as String? ?? 'Other',
      note: json['note'] as String?,
      startDate: parsedStartDate,
      endDate: parsedEndDate,
      frequency: RecurrenceFrequency.fromString(json['frequency'] as String?),
      isActive: json['isActive'] as bool? ?? true,
      lastGeneratedDate: parsedLastGen,
      createdAt: parsedCreatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecurringTransactionModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

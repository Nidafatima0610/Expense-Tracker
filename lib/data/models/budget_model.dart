class BudgetModel {
  final String id;
  final String category; // 'Overall' or specific category name like 'Food'
  final double amount;
  final int month; // 1 - 12
  final int year; // e.g. 2026
  final String? note;
  final bool isEnabled;
  final DateTime createdAt;

  const BudgetModel({
    required this.id,
    required this.category,
    required this.amount,
    required this.month,
    required this.year,
    this.note,
    this.isEnabled = true,
    required this.createdAt,
  });

  bool get isOverall => category.toLowerCase() == 'overall';

  BudgetModel copyWith({
    String? id,
    String? category,
    double? amount,
    int? month,
    int? year,
    String? note,
    bool? isEnabled,
    DateTime? createdAt,
  }) {
    return BudgetModel(
      id: id ?? this.id,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      month: month ?? this.month,
      year: year ?? this.year,
      note: note ?? this.note,
      isEnabled: isEnabled ?? this.isEnabled,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'amount': amount,
      'month': month,
      'year': year,
      'note': note,
      'isEnabled': isEnabled,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory BudgetModel.fromJson(Map<String, dynamic> json) {
    return BudgetModel(
      id: json['id'] as String,
      category: json['category'] as String,
      amount: (json['amount'] as num).toDouble(),
      month: json['month'] as int,
      year: json['year'] as int,
      note: json['note'] as String?,
      isEnabled: json['isEnabled'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BudgetModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

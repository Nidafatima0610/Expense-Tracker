import 'package:uuid/uuid.dart';
import 'transaction_model.dart';

class TransactionTemplateModel {
  final String id;
  final String title;
  final TransactionType type;
  final double amount;
  final String category;
  final PaymentMethod paymentMethod;
  final String? note;
  final DateTime createdAt;

  TransactionTemplateModel({
    required this.id,
    required this.title,
    required this.type,
    required this.amount,
    required this.category,
    this.paymentMethod = PaymentMethod.cash,
    this.note,
    required this.createdAt,
  });

  bool get isExpense => type == TransactionType.expense;
  bool get isIncome => type == TransactionType.income;

  TransactionTemplateModel copyWith({
    String? id,
    String? title,
    TransactionType? type,
    double? amount,
    String? category,
    PaymentMethod? paymentMethod,
    String? note,
    DateTime? createdAt,
  }) {
    return TransactionTemplateModel(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'type': type.name,
    'amount': amount,
    'category': category,
    'paymentMethod': paymentMethod.name,
    'note': note,
    'createdAt': createdAt.toIso8601String(),
  };

  factory TransactionTemplateModel.fromJson(Map<String, dynamic> json) {
    final dynamic rawAmount = json['amount'];
    double amount = 0.0;
    if (rawAmount is num) amount = rawAmount.toDouble();
    if (rawAmount is String) amount = double.tryParse(rawAmount) ?? 0.0;

    return TransactionTemplateModel(
      id: json['id'] as String? ?? const Uuid().v4(),
      title: json['title'] as String? ?? 'Untitled Template',
      type: TransactionType.fromString(json['type'] as String? ?? 'expense'),
      amount: amount >= 0 ? amount : 0.0,
      category: json['category'] as String? ?? 'Other',
      paymentMethod: PaymentMethod.fromString(json['paymentMethod'] as String?),
      note: json['note'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }
}

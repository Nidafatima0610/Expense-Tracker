import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'transaction_model.dart';

class GoalContribution {
  final String id;
  final double amount;
  final DateTime date;
  final String? note;
  final PaymentMethod paymentMethod;
  final bool isWithdrawal;

  GoalContribution({
    required this.id,
    required this.amount,
    required this.date,
    this.note,
    this.paymentMethod = PaymentMethod.cash,
    this.isWithdrawal = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'amount': amount,
    'date': date.toIso8601String(),
    'note': note,
    'paymentMethod': paymentMethod.name,
    'isWithdrawal': isWithdrawal,
  };

  factory GoalContribution.fromJson(Map<String, dynamic> json) {
    final dynamic raw = json['amount'];
    double rawAmount = 0.0;
    if (raw is num) rawAmount = raw.toDouble();
    if (raw is String) rawAmount = double.tryParse(raw) ?? 0.0;

    return GoalContribution(
      id: json['id'] as String? ?? const Uuid().v4(),
      amount: rawAmount > 0 ? rawAmount : 0.0,
      date: json['date'] != null ? DateTime.parse(json['date'] as String) : DateTime.now(),
      note: json['note'] as String?,
      paymentMethod: PaymentMethod.fromString(json['paymentMethod'] as String?),
      isWithdrawal: json['isWithdrawal'] as bool? ?? false,
    );
  }
}

class SavingsGoalModel {
  final String id;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final DateTime? deadline;
  final String? note;
  final String category;
  final DateTime createdAt;
  final List<GoalContribution> contributions;

  SavingsGoalModel({
    required this.id,
    required this.name,
    required this.targetAmount,
    this.currentAmount = 0.0,
    this.deadline,
    this.note,
    this.category = 'General',
    required this.createdAt,
    this.contributions = const [],
  });

  double get remainingAmount => (targetAmount - currentAmount).clamp(0.0, targetAmount);
  double get progressPercentage => targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0.0;
  bool get isCompleted => currentAmount >= targetAmount;

  int? get daysRemaining {
    if (deadline == null) return null;
    return deadline!.difference(DateTime.now()).inDays;
  }

  String get statusDisplay {
    if (isCompleted) return 'Completed';
    if (deadline != null) {
      final now = DateTime.now();
      if (now.isAfter(deadline!)) return 'Needs Attention';
      final totalDays = deadline!.difference(createdAt).inDays;
      final remainingDays = deadline!.difference(now).inDays;
      if (totalDays > 0) {
        final expectedProgress = 1.0 - (remainingDays / totalDays);
        if (progressPercentage < expectedProgress - 0.15) {
          return 'Needs Attention';
        }
      }
    }
    return 'On Track';
  }

  Color get statusColor {
    if (isCompleted) return const Color(0xFF10B981); // Emerald green
    if (statusDisplay == 'Needs Attention') return const Color(0xFFEF4444); // Red
    return const Color(0xFF6366F1); // Indigo / accent
  }

  IconData get icon {
    switch (category.toLowerCase()) {
      case 'emergency fund':
      case 'emergency':
        return Icons.health_and_safety_rounded;
      case 'new laptop':
      case 'laptop':
      case 'tech':
        return Icons.laptop_mac_rounded;
      case 'car':
      case 'vehicle':
        return Icons.directions_car_rounded;
      case 'education':
      case 'tuition':
        return Icons.school_rounded;
      case 'vacation':
      case 'travel':
        return Icons.flight_takeoff_rounded;
      case 'home':
      case 'house':
        return Icons.home_rounded;
      case 'personal goal':
      case 'personal':
        return Icons.person_rounded;
      default:
        return Icons.savings_rounded;
    }
  }

  SavingsGoalModel copyWith({
    String? id,
    String? name,
    double? targetAmount,
    double? currentAmount,
    DateTime? deadline,
    String? note,
    String? category,
    DateTime? createdAt,
    List<GoalContribution>? contributions,
  }) {
    return SavingsGoalModel(
      id: id ?? this.id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      deadline: deadline ?? this.deadline,
      note: note ?? this.note,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      contributions: contributions ?? this.contributions,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'targetAmount': targetAmount,
    'currentAmount': currentAmount,
    'deadline': deadline?.toIso8601String(),
    'note': note,
    'category': category,
    'createdAt': createdAt.toIso8601String(),
    'contributions': contributions.map((c) => c.toJson()).toList(),
  };

  factory SavingsGoalModel.fromJson(Map<String, dynamic> json) {
    final dynamic rawTarget = json['targetAmount'];
    final dynamic rawCurrent = json['currentAmount'];
    double target = 0.0;
    double current = 0.0;
    if (rawTarget is num) target = rawTarget.toDouble();
    if (rawTarget is String) target = double.tryParse(rawTarget) ?? 0.0;
    if (rawCurrent is num) current = rawCurrent.toDouble();
    if (rawCurrent is String) current = double.tryParse(rawCurrent) ?? 0.0;

    final rawContribs = json['contributions'] as List<dynamic>? ?? [];
    final contributions = rawContribs
        .map((c) => GoalContribution.fromJson(c as Map<String, dynamic>))
        .toList();

    return SavingsGoalModel(
      id: json['id'] as String? ?? const Uuid().v4(),
      name: json['name'] as String? ?? 'Untitled Goal',
      targetAmount: target > 0 ? target : 1000.0,
      currentAmount: current >= 0 ? current : 0.0,
      deadline: json['deadline'] != null ? DateTime.parse(json['deadline'] as String) : null,
      note: json['note'] as String?,
      category: json['category'] as String? ?? 'General',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : DateTime.now(),
      contributions: contributions,
    );
  }
}

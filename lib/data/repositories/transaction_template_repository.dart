import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction_model.dart';
import '../models/transaction_template_model.dart';

class TransactionTemplateRepository {
  static const String _storageKey = 'expense_tracker_transaction_templates';
  final SharedPreferences _prefs;

  TransactionTemplateRepository(this._prefs);

  List<TransactionTemplateModel> generateSampleTemplates() {
    const uuid = Uuid();
    final now = DateTime.now();

    return [
      TransactionTemplateModel(
        id: uuid.v4(),
        title: 'Monthly Rent',
        type: TransactionType.expense,
        amount: 25000.0,
        category: 'Bills',
        paymentMethod: PaymentMethod.bankAccount,
        note: 'House rent payment',
        createdAt: now,
      ),
      TransactionTemplateModel(
        id: uuid.v4(),
        title: 'Grocery Shopping',
        type: TransactionType.expense,
        amount: 4500.0,
        category: 'Food',
        paymentMethod: PaymentMethod.cash,
        note: 'Supermarket weekly essentials',
        createdAt: now,
      ),
      TransactionTemplateModel(
        id: uuid.v4(),
        title: 'Fuel & Transit',
        type: TransactionType.expense,
        amount: 3000.0,
        category: 'Transport',
        paymentMethod: PaymentMethod.debitCard,
        note: 'Vehicle fuel refill',
        createdAt: now,
      ),
      TransactionTemplateModel(
        id: uuid.v4(),
        title: 'Internet & WiFi',
        type: TransactionType.expense,
        amount: 2500.0,
        category: 'Bills',
        paymentMethod: PaymentMethod.mobileWallet,
        note: 'High-speed broadband bill',
        createdAt: now,
      ),
      TransactionTemplateModel(
        id: uuid.v4(),
        title: 'Monthly Salary',
        type: TransactionType.income,
        amount: 85000.0,
        category: 'Salary',
        paymentMethod: PaymentMethod.bankAccount,
        note: 'Primary employment salary deposit',
        createdAt: now,
      ),
      TransactionTemplateModel(
        id: uuid.v4(),
        title: 'Freelance Payment',
        type: TransactionType.income,
        amount: 35000.0,
        category: 'Freelance',
        paymentMethod: PaymentMethod.bankAccount,
        note: 'Client project milestone delivery',
        createdAt: now,
      ),
    ];
  }

  Future<List<TransactionTemplateModel>> getTemplates() async {
    final rawData = _prefs.getString(_storageKey);
    if (rawData == null || rawData.isEmpty) {
      final sample = generateSampleTemplates();
      await saveTemplates(sample);
      return sample;
    }

    try {
      final List<dynamic> decoded = jsonDecode(rawData) as List<dynamic>;
      return decoded
          .map((item) => TransactionTemplateModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      final sample = generateSampleTemplates();
      await saveTemplates(sample);
      return sample;
    }
  }

  Future<void> saveTemplates(List<TransactionTemplateModel> templates) async {
    final encoded = jsonEncode(templates.map((t) => t.toJson()).toList());
    await _prefs.setString(_storageKey, encoded);
  }

  Future<void> addTemplate(TransactionTemplateModel template) async {
    final current = await getTemplates();
    current.insert(0, template);
    await saveTemplates(current);
  }

  Future<void> updateTemplate(TransactionTemplateModel template) async {
    final current = await getTemplates();
    final index = current.indexWhere((t) => t.id == template.id);
    if (index != -1) {
      current[index] = template;
      await saveTemplates(current);
    }
  }

  Future<void> deleteTemplate(String id) async {
    final current = await getTemplates();
    current.removeWhere((t) => t.id == id);
    await saveTemplates(current);
  }

  Future<void> clearAll() async {
    await _prefs.remove(_storageKey);
  }
}

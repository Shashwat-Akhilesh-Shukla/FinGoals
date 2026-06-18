import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class LocalStorage {
  static List<Map<String, dynamic>>? _transactions;
  static List<Map<String, dynamic>>? _categories;
  static List<Map<String, dynamic>>? _goals;

  static const List<Map<String, dynamic>> _defaultCategories = [
    {"name": "Rent", "bucket": "essentials", "transaction_type": "expense", "is_custom": false},
    {"name": "Groceries", "bucket": "essentials", "transaction_type": "expense", "is_custom": false},
    {"name": "Utilities", "bucket": "essentials", "transaction_type": "expense", "is_custom": false},
    {"name": "Transport", "bucket": "essentials", "transaction_type": "expense", "is_custom": false},
    {"name": "Healthcare", "bucket": "essentials", "transaction_type": "expense", "is_custom": false},
    {"name": "Insurance", "bucket": "essentials", "transaction_type": "expense", "is_custom": false},
    {"name": "EMI / Loan", "bucket": "essentials", "transaction_type": "expense", "is_custom": false},
    {"name": "Dining Out", "bucket": "lifestyle", "transaction_type": "expense", "is_custom": false},
    {"name": "Shopping", "bucket": "lifestyle", "transaction_type": "expense", "is_custom": false},
    {"name": "Entertainment", "bucket": "lifestyle", "transaction_type": "expense", "is_custom": false},
    {"name": "Subscriptions", "bucket": "lifestyle", "transaction_type": "expense", "is_custom": false},
    {"name": "Personal Care", "bucket": "lifestyle", "transaction_type": "expense", "is_custom": false},
    {"name": "Travel", "bucket": "lifestyle", "transaction_type": "expense", "is_custom": false},
    {"name": "Gifts & Donations", "bucket": "lifestyle", "transaction_type": "expense", "is_custom": false},
    {"name": "Stocks", "bucket": "investments", "transaction_type": "investment", "is_custom": false},
    {"name": "SIP / Mutual Funds", "bucket": "investments", "transaction_type": "investment", "is_custom": false},
    {"name": "Crypto", "bucket": "investments", "transaction_type": "investment", "is_custom": false},
    {"name": "Real Estate", "bucket": "investments", "transaction_type": "investment", "is_custom": false},
    {"name": "Gold", "bucket": "investments", "transaction_type": "investment", "is_custom": false},
    {"name": "NPS", "bucket": "investments", "transaction_type": "investment", "is_custom": false},
    {"name": "ELSS", "bucket": "investments", "transaction_type": "investment", "is_custom": false},
    {"name": "Emergency Fund", "bucket": "savings", "transaction_type": "savings", "is_custom": false},
    {"name": "Fixed Deposit", "bucket": "savings", "transaction_type": "savings", "is_custom": false},
    {"name": "PPF", "bucket": "savings", "transaction_type": "savings", "is_custom": false},
    {"name": "Recurring Deposit", "bucket": "savings", "transaction_type": "savings", "is_custom": false},
    {"name": "Other Savings", "bucket": "savings", "transaction_type": "savings", "is_custom": false},
    {"name": "Salary", "bucket": "income", "transaction_type": "income", "is_custom": false},
    {"name": "Freelance", "bucket": "income", "transaction_type": "income", "is_custom": false},
    {"name": "Business", "bucket": "income", "transaction_type": "income", "is_custom": false},
    {"name": "Dividends", "bucket": "income", "transaction_type": "income", "is_custom": false},
    {"name": "Investment Returns", "bucket": "income", "transaction_type": "income", "is_custom": false},
    {"name": "Rental Income", "bucket": "income", "transaction_type": "income", "is_custom": false},
    {"name": "Other Income", "bucket": "income", "transaction_type": "income", "is_custom": false},
  ];

  static Future<File> _getFile(String filename) async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$filename');
  }

  static Future<void> init() async {
    if (_transactions != null && _categories != null && _goals != null) return;

    try {
      final txFile = await _getFile('transactions.json');
      if (await txFile.exists()) {
        final content = await txFile.readAsString();
        _transactions = List<Map<String, dynamic>>.from(jsonDecode(content));
      } else {
        _transactions = [];
      }
    } catch (_) {
      _transactions = [];
    }

    try {
      final catFile = await _getFile('categories.json');
      if (await catFile.exists()) {
        final content = await catFile.readAsString();
        _categories = List<Map<String, dynamic>>.from(jsonDecode(content));
      } else {
        _categories = List<Map<String, dynamic>>.from(_defaultCategories.map((c) => Map<String, dynamic>.from(c)));
        // Seed default IDs
        for (int i = 0; i < _categories!.length; i++) {
          _categories![i]['id'] = i + 1;
        }
        await saveCategories();
      }
    } catch (_) {
      _categories = List<Map<String, dynamic>>.from(_defaultCategories.map((c) => Map<String, dynamic>.from(c)));
      for (int i = 0; i < _categories!.length; i++) {
        _categories![i]['id'] = i + 1;
      }
    }

    try {
      final goalFile = await _getFile('goals.json');
      if (await goalFile.exists()) {
        final content = await goalFile.readAsString();
        _goals = List<Map<String, dynamic>>.from(jsonDecode(content));
      } else {
        _goals = [];
      }
    } catch (_) {
      _goals = [];
    }
  }

  static Future<void> saveTransactions() async {
    final file = await _getFile('transactions.json');
    await file.writeAsString(jsonEncode(_transactions));
  }

  static Future<void> saveCategories() async {
    final file = await _getFile('categories.json');
    await file.writeAsString(jsonEncode(_categories));
  }

  static Future<void> saveGoals() async {
    final file = await _getFile('goals.json');
    await file.writeAsString(jsonEncode(_goals));
  }

  static Future<List<Map<String, dynamic>>> getTransactions() async {
    await init();
    return _transactions!;
  }

  static Future<List<Map<String, dynamic>>> getCategories() async {
    await init();
    return _categories!;
  }

  static Future<List<Map<String, dynamic>>> getGoals() async {
    await init();
    return _goals!;
  }
}

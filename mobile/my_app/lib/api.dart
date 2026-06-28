import 'local_storage.dart';

class Api {
  // ── Transactions ──────────────────────────────
  static Future<Map<String, dynamic>> getTransactions(
      {String? type, String? month, int page = 1, int perPage = 50}) async {
    final all = await LocalStorage.getTransactions();
    
    // Filter
    var filtered = all.where((tx) {
      if (type != null && type.isNotEmpty && tx['type'] != type) return false;
      if (month != null && month.isNotEmpty) {
        final ts = tx['timestamp'] as String? ?? '';
        if (!ts.startsWith(month)) return false;
      }
      return true;
    }).toList();

    // Sort descending by timestamp
    filtered.sort((a, b) {
      final tA = a['timestamp'] as String? ?? '';
      final tB = b['timestamp'] as String? ?? '';
      return tB.compareTo(tA);
    });

    final total = filtered.length;
    final startIndex = (page - 1) * perPage;
    final endIndex = startIndex + perPage;
    
    List<Map<String, dynamic>> items = [];
    if (startIndex < total) {
      final sub = filtered.sublist(startIndex, endIndex > total ? total : endIndex);
      items = List<Map<String, dynamic>>.from(sub);
    }

    return {
      'items': items,
      'total': total,
      'page': page,
      'per_page': perPage,
      'has_more': endIndex < total,
    };
  }

  static Future<dynamic> createTransaction(Map<String, dynamic> data) async {
    final txs = await LocalStorage.getTransactions();
    
    int maxId = 0;
    for (final tx in txs) {
      final id = tx['id'] as int? ?? 0;
      if (id > maxId) maxId = id;
    }

    final newTx = Map<String, dynamic>.from(data);
    newTx['id'] = maxId + 1;
    txs.add(newTx);
    await LocalStorage.saveTransactions();
    await _syncLinkedGoals();
    return newTx;
  }

  static Future<dynamic> updateTransaction(
      int id, Map<String, dynamic> data) async {
    final txs = await LocalStorage.getTransactions();
    final index = txs.indexWhere((tx) => tx['id'] == id);
    if (index == -1) throw Exception('Transaction not found');
    
    final updated = Map<String, dynamic>.from(txs[index]);
    data.forEach((k, v) {
      if (v != null) updated[k] = v;
    });
    txs[index] = updated;
    await LocalStorage.saveTransactions();
    await _syncLinkedGoals();
    return updated;
  }

  static Future<void> deleteTransaction(int id) async {
    final txs = await LocalStorage.getTransactions();
    txs.removeWhere((tx) => tx['id'] == id);
    await LocalStorage.saveTransactions();
    await _syncLinkedGoals();
  }

  // ── Categories ────────────────────────────────
  static Future<List<dynamic>> getCategories() async {
    final cats = await LocalStorage.getCategories();
    // Sort by bucket, then name
    final sorted = List<Map<String, dynamic>>.from(cats);
    sorted.sort((a, b) {
      final bucketA = a['bucket'] as String? ?? '';
      final bucketB = b['bucket'] as String? ?? '';
      final cmp = bucketA.compareTo(bucketB);
      if (cmp != 0) return cmp;
      final nameA = a['name'] as String? ?? '';
      final nameB = b['name'] as String? ?? '';
      return nameA.compareTo(nameB);
    });
    return sorted;
  }

  static Future<dynamic> createCategory(Map<String, dynamic> data) async {
    final cats = await LocalStorage.getCategories();
    
    int maxId = 0;
    for (final cat in cats) {
      final id = cat['id'] as int? ?? 0;
      if (id > maxId) maxId = id;
    }

    final newCat = Map<String, dynamic>.from(data);
    newCat['id'] = maxId + 1;
    newCat['is_custom'] = true;
    cats.add(newCat);
    await LocalStorage.saveCategories();
    return newCat;
  }

  static Future<void> deleteCategory(int id) async {
    final cats = await LocalStorage.getCategories();
    cats.removeWhere((cat) => cat['id'] == id && cat['is_custom'] == true);
    await LocalStorage.saveCategories();
  }

  // ── Analytics Helper ──────────────────────────
  static Future<Map<String, dynamic>> _monthlyData(String month) async {
    final txs = await LocalStorage.getTransactions();
    final cats = await LocalStorage.getCategories();

    double income = 0;
    double expenses = 0;
    double investments = 0;
    double savings = 0;
    double essentials = 0;
    double lifestyle = 0;

    final catBucketMap = {for (var c in cats) c['name'] as String: c['bucket'] as String};

    for (final tx in txs) {
      final ts = tx['timestamp'] as String? ?? '';
      if (!ts.startsWith(month)) continue;

      final type = tx['type'] as String? ?? '';
      final category = tx['category'] as String? ?? '';
      final amount = (tx['amount'] as num? ?? 0).toDouble();

      if (type == 'income') {
        income += amount;
      } else if (type == 'expense') {
        expenses += amount;
        final bucket = catBucketMap[category] ?? 'other';
        if (bucket == 'essentials') {
          essentials += amount;
        } else if (bucket == 'lifestyle') {
          lifestyle += amount;
        }
      } else if (type == 'investment') {
        investments += amount;
      } else if (type == 'savings') {
        savings += amount;
      }
    }

    double sr = income > 0 ? ((income - expenses) / income * 100) : 0;
    double ir = income > 0 ? (investments / income * 100) : 0;
    double er = income > 0 ? (essentials / income * 100) : 0;

    // Round to 2 decimals
    sr = double.parse(sr.toStringAsFixed(2));
    ir = double.parse(ir.toStringAsFixed(2));
    er = double.parse(er.toStringAsFixed(2));

    return {
      "income": income,
      "expenses": expenses,
      "investments": investments,
      "savings": savings,
      "essentials": essentials,
      "lifestyle": lifestyle,
      "net": income - expenses - investments - savings,
      "savings_rate": sr,
      "investment_rate": ir,
      "essential_ratio": er,
    };
  }

  // ── Goal Auto-Sync Helpers ────────────────────
  /// Returns the all-time sum of transactions matching any of the given category names.
  static Future<double> _computeLinkedAmount(List<String> categories) async {
    if (categories.isEmpty) return 0.0;
    final txs = await LocalStorage.getTransactions();
    double total = 0;
    final catSet = categories.toSet();
    for (final tx in txs) {
      if (catSet.contains(tx['category'] as String? ?? '')) {
        total += (tx['amount'] as num? ?? 0).toDouble();
      }
    }
    return double.parse(total.toStringAsFixed(2));
  }

  /// Recalculates and persists current_amount for all goals that have linked_categories.
  /// Also migrates legacy single linked_category string to the list format.
  static Future<void> _syncLinkedGoals() async {
    final goals = await LocalStorage.getGoals();
    bool changed = false;
    for (int i = 0; i < goals.length; i++) {
      // Migrate legacy single linked_category -> linked_categories list
      final legacyCat = goals[i]['linked_category'] as String?;
      List<String> cats = [];
      final rawCats = goals[i]['linked_categories'];
      if (rawCats is List) {
        cats = List<String>.from(rawCats.whereType<String>());
      } else if (legacyCat != null && legacyCat.isNotEmpty) {
        cats = [legacyCat];
        goals[i]['linked_categories'] = cats;
        goals[i].remove('linked_category');
      }

      if (cats.isNotEmpty) {
        final computed = await _computeLinkedAmount(cats);
        goals[i]['current_amount'] = computed;
        changed = true;
      }
    }
    if (changed) await LocalStorage.saveGoals();
  }

  // ── Analytics ─────────────────────────────────
  static Future<Map<String, dynamic>> getSummary({String? month}) async {
    final m = month ?? _currentMonth();
    final data = await _monthlyData(m);
    return {"month": m, ...data};
  }

  static Future<Map<String, dynamic>> getVerdicts({String? month}) async {
    final m = month ?? _currentMonth();
    final data = await _monthlyData(m);

    final double sr = (data["savings_rate"] as num).toDouble();
    final double ir = (data["investment_rate"] as num).toDouble();
    final double er = (data["essential_ratio"] as num).toDouble();

    // 1. Savings Score (/20)
    final int sScore = sr.clamp(0, 20).round();

    // 2. Investment Score (/20)
    final int iScore = ir.clamp(0, 20).round();

    // 3. Expenses Score (/20) - 20 pts if er <= 50%, 0 pts if er >= 80%
    final int expScore = ((80 - er) / 30 * 20).clamp(0, 20).round();

    // 4. Emergency & 5. Goals Scores (/20)
    final goalsList = await getGoals();
    
    final emergencyGoals = goalsList.where((g) => g['type'] == 'emergency').toList();
    int eScore = 0;
    if (emergencyGoals.isNotEmpty) {
      double avgE = emergencyGoals.fold(0.0, (sum, g) => sum + (g['progress_pct'] as num).toDouble()) / emergencyGoals.length;
      eScore = (avgE / 100 * 20).clamp(0, 20).round();
    }

    final activeGoals = goalsList.where((g) => g['type'] != 'emergency').toList();
    int gScore = 0;
    if (activeGoals.isNotEmpty) {
      double avgG = activeGoals.fold(0.0, (sum, g) => sum + (g['progress_pct'] as num).toDouble()) / activeGoals.length;
      gScore = (avgG / 100 * 20).clamp(0, 20).round();
    }

    final int totalScore = sScore + iScore + expScore + eScore + gScore;

    String overallLabel = 'CRITICAL';
    if (totalScore >= 80) overallLabel = 'EXCELLENT';
    else if (totalScore >= 60) overallLabel = 'GOOD';
    else if (totalScore >= 40) overallLabel = 'AVERAGE';
    else if (totalScore >= 20) overallLabel = 'POOR';

    return {
      "total": totalScore,
      "overall_label": overallLabel,
      "breakdown": {
        "Savings": sScore,
        "Investment": iScore,
        "Emergency": eScore,
        "Expenses": expScore,
        "Goals": gScore,
      }
    };
  }

  static Future<List<dynamic>> getTrends({int months = 6}) async {
    final List<dynamic> result = [];
    final today = DateTime.now();
    for (int i = months - 1; i >= 0; i--) {
      final d = DateTime(today.year, today.month - i, 1);
      final m = '${d.year}-${d.month.toString().padLeft(2, '0')}';
      final data = await _monthlyData(m);
      result.append({
        "month": m,
        "income": data["income"],
        "expenses": data["expenses"],
        "investments": data["investments"],
        "savings": data["savings"],
        "savings_rate": data["savings_rate"],
      });
    }
    return result;
  }

  static Future<List<dynamic>> getBreakdown({String? month}) async {
    final m = month ?? _currentMonth();
    final txs = await LocalStorage.getTransactions();
    final cats = await LocalStorage.getCategories();

    final catBucketMap = {for (var c in cats) c['name'] as String: c['bucket'] as String};
    final Map<String, double> categoryAmounts = {};

    for (final tx in txs) {
      final ts = tx['timestamp'] as String? ?? '';
      if (!ts.startsWith(m)) continue;
      if (tx['type'] != 'expense') continue;

      final category = tx['category'] as String? ?? 'Other';
      final amount = (tx['amount'] as num? ?? 0).toDouble();
      categoryAmounts[category] = (categoryAmounts[category] ?? 0) + amount;
    }

    final sortedEntries = categoryAmounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final total = categoryAmounts.values.fold(0.0, (a, b) => a + b);
    final double denom = total > 0 ? total : 1.0;

    return sortedEntries.map((e) {
      final bucket = catBucketMap[e.key] ?? 'other';
      return {
        "category": e.key,
        "bucket": bucket,
        "amount": double.parse(e.value.toStringAsFixed(2)),
        "pct": double.parse((e.value / denom * 100).toStringAsFixed(1)),
      };
    }).toList();
  }

  // ── Goals ─────────────────────────────────────
  static Future<List<dynamic>> getGoals() async {
    final goals = await LocalStorage.getGoals();
    // Sync any linked goals before returning so the UI always has fresh data.
    await _syncLinkedGoals();
    return goals.map((g) {
      final target = (g['target_amount'] as num? ?? 0).toDouble();
      final current = (g['current_amount'] as num? ?? 0).toDouble();
      final pct = target > 0 ? ((current / target * 100).clamp(0.0, 100.0)) : 0.0;

      return {
        'id': g['id'],
        'name': g['name'],
        'type': g['type'],
        // Expose linked_categories as a normalized list
        'linked_categories': _normalizeLinkedCategories(g),
        'target_amount': target,
        'current_amount': current,
        'monthly_target': (g['monthly_target'] as num? ?? 0).toDouble(),
        'description': g['description'],
        'progress_pct': double.parse(pct.toStringAsFixed(1)),
        'created_at': g['created_at'],
      };
    }).toList();
  }

  static Future<dynamic> createGoal(Map<String, dynamic> data) async {
    final goals = await LocalStorage.getGoals();
    
    int maxId = 0;
    for (final g in goals) {
      final id = g['id'] as int? ?? 0;
      if (id > maxId) maxId = id;
    }

    final newGoal = Map<String, dynamic>.from(data);
    newGoal['id'] = maxId + 1;
    newGoal['created_at'] = DateTime.now().toIso8601String();
    goals.add(newGoal);
    await LocalStorage.saveGoals();
    return newGoal;
  }

  static Future<dynamic> updateGoal(int id, Map<String, dynamic> data) async {
    final goals = await LocalStorage.getGoals();
    final index = goals.indexWhere((g) => g['id'] == id);
    if (index == -1) throw Exception('Goal not found');

    final updated = Map<String, dynamic>.from(goals[index]);
    data.forEach((k, v) {
      if (v != null) updated[k] = v;
    });
    goals[index] = updated;
    await LocalStorage.saveGoals();
    return updated;
  }

  static Future<void> deleteGoal(int id) async {
    final goals = await LocalStorage.getGoals();
    goals.removeWhere((g) => g['id'] == id);
    await LocalStorage.saveGoals();
  }

  // ── Helper methods ──────────────────────────────
  static String _currentMonth() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  /// Normalises goal storage — always returns a List<String> of linked categories.
  static List<String> _normalizeLinkedCategories(Map<String, dynamic> g) {
    final rawCats = g['linked_categories'];
    if (rawCats is List) {
      return List<String>.from(rawCats.whereType<String>());
    }
    // Backward compat: migrate legacy linked_category string
    final legacy = g['linked_category'] as String?;
    if (legacy != null && legacy.isNotEmpty) return [legacy];
    return [];
  }
}

extension _ListExt on List<dynamic> {
  void append(dynamic element) => add(element);
}

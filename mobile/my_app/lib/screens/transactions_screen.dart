import 'package:flutter/material.dart';
import '../api.dart';
import '../formatters.dart';
import '../main.dart';

const _typeFilters = [
  ('',           'All'),
  ('income',     'Income'),
  ('expense',    'Expenses'),
  ('investment', 'Invested'),
  ('savings',    'Savings'),
];

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  List<dynamic> _items = [];
  int _total = 0;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = false;
  int _page = 1;
  String _typeFilter = '';
  final _searchCtrl = TextEditingController();
  String _search = '';

  String? _loadedMonth;
  String? _loadedType;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final month = AppState.of(context).selectedMonth;
    if (_loadedMonth != month || _loadedType != _typeFilter) {
      _loadedMonth = month;
      _loadedType = _typeFilter;
      _reload();
    }
  }

  Future<void> _reload() async {
    setState(() { _loading = true; _page = 1; _items = []; });
    await _fetchPage(1);
  }

  Future<void> _fetchPage(int page) async {
    final month = AppState.of(context).selectedMonth;
    try {
      final res = await Api.getTransactions(
        type: _typeFilter, month: month, page: page, perPage: 50,
      );
      final newItems = (res['items'] as List<dynamic>?) ?? [];
      setState(() {
        _loading = false;
        _loadingMore = false;
        _total = (res['total'] as num?)?.toInt() ?? 0;
        _hasMore = res['has_more'] as bool? ?? false;
        if (page == 1) {
          _items = newItems;
        } else {
          _items = [..._items, ...newItems];
        }
        _page = page;
      });
    } catch (e) {
      setState(() { _loading = false; _loadingMore = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: const Color(0xFFef4444)),
        );
      }
    }
  }

  Future<void> _delete(Map<String, dynamic> tx) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a1a),
        title: const Text('Delete transaction?', style: TextStyle(fontSize: 16)),
        content: Text(
          '₹${tx['amount']} · ${tx['category']}',
          style: const TextStyle(color: Color(0xFF888888)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Color(0xFFef4444))),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await Api.deleteTransaction(tx['id'] as int);
      _reload();
    }
  }

  List<dynamic> get _filtered {
    if (_search.isEmpty) return _items;
    final q = _search.toLowerCase();
    return _items.where((tx) =>
      (tx['category'] as String? ?? '').toLowerCase().contains(q) ||
      (tx['note'] as String? ?? '').toLowerCase().contains(q)
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;

    return Scaffold(
      backgroundColor: const Color(0xFF0a0a0a),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => const _TxSheet(),
          );
          _reload();
        },
        backgroundColor: const Color(0xFF10b981),
        foregroundColor: Colors.black,
        child: const Icon(Icons.add, size: 28),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Transactions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                      Text('$_total total records', style: const TextStyle(fontSize: 12, color: Color(0xFF555555))),
                    ],
                  ),
                ],
              ),
            ),

            // Search
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _search = v),
                style: const TextStyle(fontSize: 13),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search_rounded, size: 16, color: Color(0xFF555555)),
                  hintText: 'Search category or note...',
                ),
              ),
            ),

            // Type filter pills
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: _typeFilters.map((f) {
                  final active = _typeFilter == f.$1;
                  return Padding(
                    padding: const EdgeInsets.only(right: 7),
                    child: GestureDetector(
                      onTap: () { setState(() { _typeFilter = f.$1; }); _reload(); },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: active ? const Color(0xFF10b981) : const Color(0xFF1a1a1a),
                          border: Border.all(color: active ? const Color(0xFF10b981) : const Color(0xFF2a2a2a)),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          f.$2,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: active ? Colors.black : const Color(0xFF888888),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 8),

            // List
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF10b981)))
                  : items.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.receipt_long_rounded, size: 36, color: Color(0xFF333333)),
                              const SizedBox(height: 12),
                              const Text('No transactions found', style: TextStyle(fontSize: 14, color: Color(0xFF555555), fontWeight: FontWeight.w500)),
                              const SizedBox(height: 4),
                              const Text('Tap + to add your first one', style: TextStyle(fontSize: 12, color: Color(0xFF444444))),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: items.length + (_hasMore ? 1 : 0),
                          separatorBuilder: (_, __) => const SizedBox(height: 6),
                          itemBuilder: (ctx, i) {
                            if (i == items.length) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() => _loadingMore = true);
                                    _fetchPage(_page + 1);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1a1a1a),
                                      border: Border.all(color: const Color(0xFF2a2a2a)),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: _loadingMore
                                          ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF10b981)))
                                          : const Text('Load more', style: TextStyle(color: Color(0xFF888888), fontSize: 13)),
                                    ),
                                  ),
                                ),
                              );
                            }
                            final tx = items[i] as Map<String, dynamic>;
                            return _TxRow(
                              tx: tx,
                              onEdit: () async {
                                await showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (_) => _TxSheet(transaction: tx),
                                );
                                _reload();
                              },
                              onDelete: () => _delete(tx),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Transaction Row ───────────────────────────────────────────
class _TxRow extends StatelessWidget {
  final Map<String, dynamic> tx;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _TxRow({required this.tx, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final meta  = getTypeMeta(tx['type'] as String? ?? 'expense');
    final sign  = tx['type'] == 'income' ? '+' : '-';
    final bgColor = Color(meta.bg);
    final fgColor = Color(meta.color);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        border: Border.all(color: const Color(0xFF1f1f1f)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
            child: Center(
              child: Text(
                ((tx['type'] as String? ?? 'exp').substring(0, 3)).toUpperCase(),
                style: TextStyle(fontFamily: 'monospace', fontSize: 10, color: fgColor, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx['category'] as String? ?? '',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${tx['account'] ?? ''} · ${formatDate(tx['timestamp'] as String?)}${tx['note'] != null && tx['note'] != '' ? ' · ${tx['note']}' : ''}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF555555)),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$sign${formatINR(tx['amount'])}',
                style: TextStyle(fontFamily: 'monospace', fontSize: 14, fontWeight: FontWeight.w600, color: fgColor),
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: onEdit,
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.edit_outlined, size: 13, color: Color(0xFF555555)),
                    ),
                  ),
                  GestureDetector(
                    onTap: onDelete,
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.delete_outline_rounded, size: 13, color: Color(0xFFef4444)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Transaction Add/Edit Bottom Sheet ─────────────────────────
const _accounts = ['Bank', 'Cash', 'Credit Card', 'UPI / Wallet', 'Other'];

class _TxSheet extends StatefulWidget {
  final Map<String, dynamic>? transaction;
  const _TxSheet({this.transaction});

  @override
  State<_TxSheet> createState() => _TxSheetState();
}

class _TxSheetState extends State<_TxSheet> {
  late String _type;
  late TextEditingController _amountCtrl;
  late TextEditingController _noteCtrl;
  String _category = '';
  String _account  = 'Bank';
  late DateTime _date;
  List<dynamic> _allCats = [];
  bool _saving = false;

  bool get isEdit => widget.transaction != null;

  @override
  void initState() {
    super.initState();
    final tx = widget.transaction;
    _type     = tx?['type']     as String? ?? 'expense';
    _account  = tx?['account']  as String? ?? 'Bank';
    _category = tx?['category'] as String? ?? '';
    _amountCtrl = TextEditingController(text: tx?['amount']?.toString() ?? '');
    _noteCtrl   = TextEditingController(text: tx?['note'] as String? ?? '');
    _date = tx != null
        ? (DateTime.tryParse(tx['timestamp'] as String? ?? '') ?? DateTime.now())
        : DateTime.now();
    _loadCats();
  }

  Future<void> _loadCats() async {
    try {
      final cats = await Api.getCategories();
      if (mounted) setState(() => _allCats = cats);
    } catch (_) {}
  }

  List<dynamic> get _cats =>
      _allCats.where((c) => c['transaction_type'] == _type).toList();

  TypeMeta get _meta => getTypeMeta(_type);

  Future<void> _save() async {
    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || _category.isEmpty) return;
    setState(() => _saving = true);
    try {
      final payload = {
        'amount':    amount,
        'type':      _type,
        'category':  _category,
        'account':   _account,
        'note':      _noteCtrl.text,
        'timestamp': _date.toIso8601String(),
      };
      if (isEdit) {
        await Api.updateTransaction(widget.transaction!['id'] as int, payload);
      } else {
        await Api.createTransaction(payload);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: const Color(0xFFef4444)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final meta  = _meta;
    final color = Color(meta.color);
    final cats  = _cats;
    final canSave = _amountCtrl.text.isNotEmpty && _category.isNotEmpty;

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (ctx, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF111111),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 14),
                width: 36, height: 4,
                decoration: BoxDecoration(color: const Color(0xFF333333), borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(isEdit ? 'Edit Transaction' : 'Add Transaction',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: const Color(0xFF1a1a1a), border: Border.all(color: const Color(0xFF2a2a2a)), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.close, size: 16, color: Color(0xFF888888)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Amount
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1a1a1a),
                border: Border.all(color: color.withOpacity(0.25)),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('AMOUNT (₹)', style: TextStyle(fontSize: 9, color: Color(0xFF555555), letterSpacing: 1.2)),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text('₹', style: TextStyle(fontFamily: 'monospace', fontSize: 26, fontWeight: FontWeight.w700, color: color)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: TextField(
                          controller: _amountCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          autofocus: !isEdit,
                          style: TextStyle(fontFamily: 'monospace', fontSize: 32, fontWeight: FontWeight.w700, color: color),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                            hintText: '0',
                            hintStyle: TextStyle(color: Color(0xFF333333)),
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Type selector
            const Text('TYPE', style: TextStyle(fontSize: 9, color: Color(0xFF555555), letterSpacing: 1.2)),
            const SizedBox(height: 6),
            Row(
              children: typeMeta.entries.map((e) {
                final active = _type == e.key;
                final c = Color(e.value.color);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      onTap: () => setState(() { _type = e.key; _category = ''; }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: active ? Color(e.value.bg) : const Color(0xFF1a1a1a),
                          border: Border.all(color: active ? c : const Color(0xFF2a2a2a)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            e.value.label,
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: active ? c : const Color(0xFF555555)),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),

            // Category chips
            const Text('CATEGORY', style: TextStyle(fontSize: 9, color: Color(0xFF555555), letterSpacing: 1.2)),
            const SizedBox(height: 6),
            if (cats.isEmpty)
              const Text('No categories. Go to Settings to add.', style: TextStyle(fontSize: 12, color: Color(0xFF555555)))
            else
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: cats.map((cat) {
                  final name   = cat['name'] as String? ?? '';
                  final active = _category == name;
                  return GestureDetector(
                    onTap: () => setState(() => _category = name),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: active ? Color(meta.bg) : const Color(0xFF1a1a1a),
                        border: Border.all(color: active ? color : const Color(0xFF2a2a2a)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        name,
                        style: TextStyle(
                          fontSize: 12,
                          color: active ? color : const Color(0xFF888888),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 14),

            // Account + Date row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('ACCOUNT', style: TextStyle(fontSize: 9, color: Color(0xFF555555), letterSpacing: 1.2)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: _account,
                        dropdownColor: const Color(0xFF1a1a1a),
                        style: const TextStyle(fontSize: 13, color: Colors.white),
                        decoration: const InputDecoration(),
                        items: _accounts.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                        onChanged: (v) => setState(() => _account = v ?? _account),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('DATE', style: TextStyle(fontSize: 9, color: Color(0xFF555555), letterSpacing: 1.2)),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () async {
                          final d = await showDatePicker(
                            context: context,
                            initialDate: _date,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                            builder: (ctx, child) => Theme(
                              data: ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: Color(0xFF10b981))),
                              child: child!,
                            ),
                          );
                          if (d != null) setState(() => _date = DateTime(d.year, d.month, d.day, _date.hour, _date.minute));
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1a1a1a),
                            border: Border.all(color: const Color(0xFF2a2a2a)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_outlined, size: 13, color: Color(0xFF555555)),
                              const SizedBox(width: 6),
                              Text(
                                '${_date.day} ${['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][_date.month - 1]}',
                                style: const TextStyle(fontSize: 13, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Note
            const Text('NOTE', style: TextStyle(fontSize: 9, color: Color(0xFF555555), letterSpacing: 1.2)),
            const SizedBox(height: 6),
            TextField(
              controller: _noteCtrl,
              decoration: const InputDecoration(hintText: 'Optional note...'),
            ),
            const SizedBox(height: 20),

            // Save button
            GestureDetector(
              onTap: (canSave && !_saving) ? _save : null,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  color: canSave ? color : const Color(0xFF1a1a1a),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: _saving
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : Text(
                          isEdit ? 'Save Changes' : 'Add ${getTypeMeta(_type).label}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: canSave ? Colors.black : const Color(0xFF555555),
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

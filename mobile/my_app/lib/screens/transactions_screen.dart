import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../api.dart';
import '../formatters.dart';
import '../main.dart';
import '../widgets/app_theme.dart';
import '../widgets/animated_card.dart';

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
      _loadedType  = _typeFilter;
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
      final res = await Api.getTransactions(type: _typeFilter, month: month, page: page, perPage: 50);
      final newItems = (res['items'] as List<dynamic>?) ?? [];
      setState(() {
        _loading    = false;
        _loadingMore= false;
        _total      = (res['total'] as num?)?.toInt() ?? 0;
        _hasMore    = res['has_more'] as bool? ?? false;
        _items      = page == 1 ? newItems : [..._items, ...newItems];
        _page       = page;
      });
    } catch (e) {
      setState(() { _loading = false; _loadingMore = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.negative),
        );
      }
    }
  }

  Future<void> _delete(Map<String, dynamic> tx) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete transaction?', style: TextStyle(fontSize: 16)),
        content: Text('₹${tx['amount']} · ${tx['category']}',
            style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.negative)),
          ),
        ],
      ),
    );
    if (confirmed == true) { await Api.deleteTransaction(tx['id'] as int); _reload(); }
  }

  List<dynamic> get _filtered {
    if (_search.isEmpty) return _items;
    final q = _search.toLowerCase();
    return _items.where((tx) =>
      (tx['category'] as String? ?? '').toLowerCase().contains(q) ||
      (tx['note']     as String? ?? '').toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: Container(
        decoration: BoxDecoration(
          color: AppColors.accent1,
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(color: Color(0x221DB888), blurRadius: 12, offset: Offset(0, 4)),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () async {
            HapticFeedback.mediumImpact();
            await showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const _TxSheet(),
            );
            _reload();
          },
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.black,
          elevation: 0,
          child: const Icon(Icons.add, size: 28),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Transactions',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                      Text('$_total records',
                          style: const TextStyle(fontSize: 11, color: AppColors.textDim)),
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
                style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search_rounded, size: 16, color: AppColors.textDim),
                  hintText: 'Search...',
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.cardBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.cardBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.accent1, width: 1.5),
                  ),
                ),
              ),
            ),

            // Filter pills
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: _typeFilters.map((f) {
                  final active = _typeFilter == f.$1;
                  final col    = f.$1.isEmpty ? AppColors.accent1
                      : AppGradients.colorForType(f.$1);
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _typeFilter = f.$1);
                        _reload();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: active
                            ? BoxDecoration(
                                color: col.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: col.withOpacity(0.4)),
                              )
                            : BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppColors.cardBorder),
                              ),
                        child: Text(
                          f.$2,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: active ? Colors.white : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 10),

            // List
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.accent1, strokeWidth: 2))
                  : items.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.receipt_long_rounded, size: 44, color: AppColors.accent1),
                              const SizedBox(height: 14),
                              const Text('No transactions found',
                                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 4),
                              const Text('Tap + to add one',
                                  style: TextStyle(fontSize: 12, color: AppColors.textDim)),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                          itemCount: items.length + (_hasMore ? 1 : 0),
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (ctx, i) {
                            if (i == items.length) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: GestureDetector(
                                  onTap: () { setState(() => _loadingMore = true); _fetchPage(_page + 1); },
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: AppDecorations.glassCard(radius: 12),
                                    child: Center(
                                      child: _loadingMore
                                          ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent1))
                                          : const Text('Load more', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                                    ),
                                  ),
                                ),
                              );
                            }
                            final tx = items[i] as Map<String, dynamic>;
                            return _TxRow(
                              tx: tx,
                              onEdit: () async {
                                HapticFeedback.selectionClick();
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
    final type    = tx['type'] as String? ?? 'expense';
    final color   = AppGradients.colorForType(type);
    final sign    = type == 'income' ? '+' : '-';

    return Container(
      decoration: AppDecorations.glassCard(radius: 14),
      child: Row(
        children: [
          // Left accent bar
          Container(
            width: 4,
            height: 60,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14), bottomLeft: Radius.circular(14)),
            ),
          ),
          const SizedBox(width: 12),
          // Type icon badge
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withOpacity(0.25)),
            ),
            child: Center(
              child: Text(
                ((tx['type'] as String? ?? 'exp').substring(0, 3)).toUpperCase(),
                style: TextStyle(fontFamily: 'monospace', fontSize: 9, color: color, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx['category'] as String? ?? '',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    overflow: TextOverflow.ellipsis),
                Text(
                  '${tx['account'] ?? ''} · ${formatDate(tx['timestamp'] as String?)}${tx['note'] != null && tx['note'] != '' ? ' · ${tx['note']}' : ''}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textDim),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$sign${formatINR(tx['amount'])}',
                  style: TextStyle(fontFamily: 'monospace', fontSize: 14,
                      fontWeight: FontWeight.w700, color: color)),
              Row(
                children: [
                  GestureDetector(
                    onTap: onEdit,
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(Icons.edit_outlined, size: 14, color: AppColors.textDim),
                    ),
                  ),
                  GestureDetector(
                    onTap: onDelete,
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(Icons.delete_outline_rounded, size: 14, color: AppColors.negative),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

// ── Add/Edit Bottom Sheet ─────────────────────────────────────
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
    final tx  = widget.transaction;
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

  List<dynamic> get _cats => _allCats.where((c) => c['transaction_type'] == _type).toList();
  Color get _typeColor => AppGradients.colorForType(_type);

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
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.negative),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final color  = _typeColor;
    final cats   = _cats;
    final canSave= _amountCtrl.text.isNotEmpty && _category.isNotEmpty;

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.96,
      builder: (ctx, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          children: [
            // Handle bar
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(isEdit ? 'Edit Transaction' : 'Add Transaction',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.card, borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.cardBorder)),
                    child: const Icon(Icons.close, size: 16, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Amount hero
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: color.withOpacity(0.06),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: color.withOpacity(0.18)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('AMOUNT (₹)',
                      style: AppText.label(size: 9, color: color.withOpacity(0.7), spacing: 1.4)),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text('₹', style: TextStyle(fontFamily: 'monospace', fontSize: 28, fontWeight: FontWeight.w800, color: color)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: TextField(
                          controller: _amountCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          autofocus: !isEdit,
                          style: TextStyle(fontFamily: 'monospace', fontSize: 34, fontWeight: FontWeight.w800, color: color),
                          decoration: const InputDecoration(
                            border: InputBorder.none, enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none, filled: false,
                            hintText: '0', hintStyle: TextStyle(color: AppColors.textDim),
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
            const SizedBox(height: 16),

            // Type selector
            _SheetLabel('TYPE'),
            const SizedBox(height: 8),
            Row(
              children: typeMeta.entries.map((e) {
                final active = _type == e.key;
                final c      = AppGradients.colorForType(e.key);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      onTap: () { HapticFeedback.selectionClick(); setState(() { _type = e.key; _category = ''; }); },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: active
                            ? BoxDecoration(
                                color: AppGradients.colorForType(e.key).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppGradients.colorForType(e.key).withOpacity(0.4)),
                              )
                            : BoxDecoration(
                                color: AppColors.card,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.cardBorder),
                              ),
                        child: Center(
                          child: Text(e.value.label,
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                                  color: active ? AppGradients.colorForType(e.key) : AppColors.textSecondary)),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Category chips
            _SheetLabel('CATEGORY'),
            const SizedBox(height: 8),
            if (cats.isEmpty)
              const Text('No categories. Go to Settings.', style: TextStyle(fontSize: 12, color: AppColors.textDim))
            else
              Wrap(
                spacing: 7, runSpacing: 7,
                children: cats.map((cat) {
                  final name   = cat['name'] as String? ?? '';
                  final active = _category == name;
                  return GestureDetector(
                    onTap: () { HapticFeedback.selectionClick(); setState(() => _category = name); },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: active
                          ? BoxDecoration(
                              color: color.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: color.withOpacity(0.4)),
                            )
                          : BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.cardBorder),
                            ),
                      child: Text(name,
                          style: TextStyle(fontSize: 12, fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                              color: active ? color : AppColors.textSecondary)),
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 16),

            // Account + Date
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SheetLabel('ACCOUNT'),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                        decoration: AppDecorations.glassCard(radius: 12),
                        child: DropdownButton<String>(
                          value: _account,
                          isExpanded: true,
                          underline: const SizedBox(),
                          dropdownColor: AppColors.surface,
                          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textDim, size: 18),
                          items: _accounts.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                          onChanged: (v) => setState(() => _account = v ?? _account),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SheetLabel('DATE'),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () async {
                          final d = await showDatePicker(
                            context: context,
                            initialDate: _date,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                            builder: (ctx, child) => Theme(
                              data: ThemeData.dark().copyWith(
                                colorScheme: const ColorScheme.dark(primary: AppColors.accent1),
                              ),
                              child: child!,
                            ),
                          );
                          if (d != null) setState(() => _date = DateTime(d.year, d.month, d.day, _date.hour, _date.minute));
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
                          decoration: AppDecorations.glassCard(radius: 12),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_outlined, size: 13, color: AppColors.textDim),
                              const SizedBox(width: 8),
                              Text(
                                '${_date.day} ${['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][_date.month - 1]}',
                                style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
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
            const SizedBox(height: 16),

            // Note
            _SheetLabel('NOTE'),
            const SizedBox(height: 8),
            TextField(
              controller: _noteCtrl,
              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Optional note...',
                filled: true,
                fillColor: AppColors.card,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.cardBorder)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.cardBorder)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.accent1, width: 1.5)),
              ),
            ),
            const SizedBox(height: 24),

            // Save
            GestureDetector(
              onTap: (canSave && !_saving) ? () { HapticFeedback.mediumImpact(); _save(); } : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: canSave
                    ? BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(color: Color(0x18000000), blurRadius: 8, offset: Offset(0, 3)),
                        ],
                      )
                    : BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                child: Center(
                  child: _saving
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : Text(
                          isEdit ? 'Save Changes' : 'Add ${getTypeMeta(_type).label}',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800,
                              color: canSave ? Colors.black : AppColors.textDim),
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

class _SheetLabel extends StatelessWidget {
  final String text;
  const _SheetLabel(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppText.label(size: 9, color: AppColors.textDim, spacing: 1.6));
  }
}

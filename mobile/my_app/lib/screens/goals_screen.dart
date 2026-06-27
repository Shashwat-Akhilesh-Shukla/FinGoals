import 'package:flutter/material.dart';
import '../api.dart';
import '../formatters.dart';

const _goalTypes = [
  ('emergency', 'Emergency', Color(0xFF3b82f6)),
  ('sip',       'SIP / Invest', Color(0xFF10b981)),
  ('custom',    'Custom', Color(0xFF8b5cf6)),
];

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  List<dynamic> _goals = [];
  bool _loading = true;
  bool _showForm = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final goals = await Api.getGoals();
      if (mounted) setState(() { _goals = goals; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _delete(int id, String name) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a1a),
        title: const Text('Delete goal?', style: TextStyle(fontSize: 16)),
        content: Text(name, style: const TextStyle(color: Color(0xFF888888))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Color(0xFFef4444)))),
        ],
      ),
    );
    if (ok == true) { await Api.deleteGoal(id); _load(); }
  }

  Future<void> _addAmount(Map<String, dynamic> goal, String amt) async {
    final v = double.tryParse(amt);
    if (v == null || v <= 0) return;
    final newAmt = ((goal['current_amount'] as num?)?.toDouble() ?? 0) + v;
    await Api.updateGoal(goal['id'] as int, {'current_amount': newAmt});
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0a0a0a),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Goals', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                      Text('${_goals.length} active goals', style: const TextStyle(fontSize: 12, color: Color(0xFF555555))),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _showForm = !_showForm),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: _showForm ? const Color(0xFF1a1a1a) : const Color(0xFF10b981),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.add, size: 14, color: _showForm ? const Color(0xFF888888) : Colors.black),
                          const SizedBox(width: 4),
                          Text('New Goal', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _showForm ? const Color(0xFF888888) : Colors.black)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _load,
                color: const Color(0xFF10b981),
                backgroundColor: const Color(0xFF1a1a1a),
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF10b981)))
                    : ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          if (_showForm)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _GoalForm(
                                onCancel: () => setState(() => _showForm = false),
                                onCreate: (data) async {
                                  await Api.createGoal(data);
                                  setState(() => _showForm = false);
                                  _load();
                                },
                              ),
                            ),
                          if (_goals.isEmpty && !_showForm)
                            Padding(
                              padding: const EdgeInsets.only(top: 60),
                              child: Column(
                                children: const [
                                  Icon(Icons.flag_rounded, size: 36, color: Color(0xFF333333)),
                                  SizedBox(height: 12),
                                  Text('No goals set', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF555555))),
                                  SizedBox(height: 4),
                                  Text('Define financial targets and track progress', style: TextStyle(fontSize: 12, color: Color(0xFF444444))),
                                ],
                              ),
                            ),
                          ..._goals.map((g) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _GoalCard(
                              goal: g,
                              onAddAmount: (amt) => _addAmount(g, amt),
                              onDelete: () => _delete(g['id'] as int, g['name'] as String? ?? ''),
                            ),
                          )),
                          const SizedBox(height: 16),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalCard extends StatefulWidget {
  final Map<String, dynamic> goal;
  final void Function(String) onAddAmount;
  final VoidCallback onDelete;
  const _GoalCard({required this.goal, required this.onAddAmount, required this.onDelete});

  @override
  State<_GoalCard> createState() => _GoalCardState();
}

class _GoalCardState extends State<_GoalCard> {
  final _ctrl = TextEditingController();

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final g       = widget.goal;
    final pct     = (g['progress_pct'] as num?)?.toDouble() ?? 0;
    final type    = g['type'] as String? ?? 'custom';
    final gType   = _goalTypes.firstWhere((t) => t.$1 == type, orElse: () => _goalTypes.last);
    final color   = pct >= 100 ? const Color(0xFF10b981) : pct >= 60 ? const Color(0xFFf59e0b) : const Color(0xFFef4444);
    final rem     = ((g['target_amount'] as num?)?.toDouble() ?? 0) - ((g['current_amount'] as num?)?.toDouble() ?? 0);
    final hasInput = _ctrl.text.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        border: Border.all(color: const Color(0xFF1f1f1f)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: gType.$3.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_goalIcon(type), size: 18, color: gType.$3),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(g['name'] as String? ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                    Text(gType.$2, style: const TextStyle(fontSize: 11, color: Color(0xFF555555))),
                  ],
                ),
              ),
              GestureDetector(
                onTap: widget.onDelete,
                child: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFF444444)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (pct / 100).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: const Color(0xFF1f1f1f),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(text: formatINR(g['current_amount']), style: const TextStyle(fontFamily: 'monospace', fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                    TextSpan(text: ' / ${formatINR(g['target_amount'])}', style: const TextStyle(fontSize: 12, color: Color(0xFF555555))),
                  ],
                ),
              ),
              Text(
                pct >= 100 ? '✓' : '${pct.toStringAsFixed(1)}%',
                style: TextStyle(fontFamily: 'monospace', fontSize: 20, fontWeight: FontWeight.w800, color: color),
              ),
            ],
          ),

          if (rem > 0) ...[
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${formatINR(rem)} remaining${g['monthly_target'] != null ? ' · ${formatINR(g['monthly_target'])}/mo' : ''}',
                style: const TextStyle(fontSize: 11, color: Color(0xFF555555)),
              ),
            ),
          ],
          const SizedBox(height: 10),

          // Linked auto-update badge OR manual quick-add
          if (g['linked_category'] != null && (g['linked_category'] as String).isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF10b981).withOpacity(0.08),
                border: Border.all(color: const Color(0xFF10b981).withOpacity(0.25)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bolt_rounded, size: 13, color: Color(0xFF10b981)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'AUTO · linked to "${g['linked_category']}"',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF10b981), fontFamily: 'monospace'),
                    ),
                  ),
                ],
              ),
            )
          else
            // Quick add (manual)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(fontSize: 13),
                    decoration: const InputDecoration(hintText: 'Add amount...'),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: hasInput ? () { widget.onAddAmount(_ctrl.text); _ctrl.clear(); setState(() {}); } : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: hasInput ? gType.$3 : const Color(0xFF1a1a1a),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '+ Add',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: hasInput ? Colors.black : const Color(0xFF555555)),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

IconData _goalIcon(String type) {
  return switch (type) {
    'emergency' => Icons.shield_outlined,
    'sip'       => Icons.trending_up_rounded,
    _           => Icons.flag_rounded,
  };
}

class _GoalForm extends StatefulWidget {
  final VoidCallback onCancel;
  final Future<void> Function(Map<String, dynamic>) onCreate;
  const _GoalForm({required this.onCancel, required this.onCreate});

  @override
  State<_GoalForm> createState() => _GoalFormState();
}

class _GoalFormState extends State<_GoalForm> {
  String _type = 'custom';
  String? _linkedCategory;
  List<String> _linkableCategories = [];
  final _nameCtrl    = TextEditingController();
  final _targetCtrl  = TextEditingController();
  final _currentCtrl = TextEditingController();
  final _monthlyCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final cats = await Api.getCategories();
    // Only show savings & investment categories as linkable targets
    final filtered = cats
        .where((c) => (c['bucket'] as String? ?? '') == 'savings' || (c['bucket'] as String? ?? '') == 'investments')
        .map((c) => c['name'] as String)
        .toList();
    if (mounted) setState(() => _linkableCategories = filtered);
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _targetCtrl.dispose();
    _currentCtrl.dispose(); _monthlyCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.isEmpty || _targetCtrl.text.isEmpty) return;
    setState(() => _saving = true);
    await widget.onCreate({
      'name':             _nameCtrl.text,
      'type':             _type,
      'target_amount':    double.tryParse(_targetCtrl.text) ?? 0,
      'current_amount':   double.tryParse(_currentCtrl.text) ?? 0,
      if (_linkedCategory != null && _linkedCategory!.isNotEmpty)
        'linked_category': _linkedCategory,
      if (_type == 'sip' && _monthlyCtrl.text.isNotEmpty)
        'monthly_target': double.tryParse(_monthlyCtrl.text),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        border: Border.all(color: const Color(0xFF1f1f1f)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('New Goal', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              GestureDetector(onTap: widget.onCancel, child: const Icon(Icons.close, size: 16, color: Color(0xFF555555))),
            ],
          ),
          const SizedBox(height: 12),
          TextField(controller: _nameCtrl, decoration: const InputDecoration(hintText: 'Goal name *')),
          const SizedBox(height: 10),
          // Type selector
          Row(
            children: _goalTypes.map((t) {
              final active = _type == t.$1;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () => setState(() => _type = t.$1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: active ? t.$3.withOpacity(0.12) : const Color(0xFF1a1a1a),
                        border: Border.all(color: active ? t.$3 : const Color(0xFF2a2a2a)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(child: Text(t.$2, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: active ? t.$3 : const Color(0xFF555555)))),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: TextField(controller: _targetCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(hintText: 'Target ₹ *'))),
              const SizedBox(width: 8),
              Expanded(child: TextField(controller: _currentCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(hintText: 'Current ₹'))),
            ],
          ),
          if (_type == 'sip') ...[
            const SizedBox(height: 10),
            TextField(controller: _monthlyCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(hintText: 'Monthly target ₹')),
          ],
          const SizedBox(height: 10),
          // Link Category dropdown
          if (_linkableCategories.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1a1a1a),
                border: Border.all(color: const Color(0xFF2a2a2a)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: DropdownButton<String>(
                value: _linkedCategory,
                isExpanded: true,
                underline: const SizedBox(),
                dropdownColor: const Color(0xFF1a1a1a),
                hint: const Text('Link to category (auto-update)', style: TextStyle(fontSize: 12, color: Color(0xFF555555))),
                style: const TextStyle(fontSize: 12, color: Colors.white),
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF555555), size: 18),
                items: [
                  const DropdownMenuItem<String>(value: '', child: Text('No link (manual)', style: TextStyle(fontSize: 12, color: Color(0xFF555555)))),
                  ..._linkableCategories.map((cat) => DropdownMenuItem<String>(
                    value: cat,
                    child: Row(
                      children: [
                        const Icon(Icons.bolt_rounded, size: 12, color: Color(0xFF10b981)),
                        const SizedBox(width: 6),
                        Text(cat, style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  )),
                ],
                onChanged: (val) => setState(() => _linkedCategory = (val == null || val.isEmpty) ? null : val),
              ),
            ),
          ],
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _saving ? null : _submit,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(color: const Color(0xFF10b981), borderRadius: BorderRadius.circular(12)),
              child: Center(
                child: _saving
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                    : const Text('Create Goal', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

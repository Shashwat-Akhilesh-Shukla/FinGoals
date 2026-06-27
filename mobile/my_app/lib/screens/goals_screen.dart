import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../api.dart';
import '../formatters.dart';
import '../widgets/app_theme.dart';
import '../widgets/animated_card.dart';
import '../widgets/section_label.dart';

const _goalTypes = [
  ('emergency', 'Emergency', AppColors.invest),
  ('sip',       'SIP / Invest', AppColors.positive),
  ('custom',    'Custom', Color(0xFFf0a500)),
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
  void initState() { super.initState(); _load(); }

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
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete goal?', style: TextStyle(fontSize: 16)),
        content: Text(name, style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete', style: TextStyle(color: AppColors.negative))),
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
    final totalGoals     = _goals.length;
    final completedGoals = _goals.where((g) => (g['progress_pct'] as num? ?? 0) >= 100).length;

    return Scaffold(
      backgroundColor: Colors.transparent,
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
                      const Text('Goals',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                      RichText(
                        text: TextSpan(children: [
                          TextSpan(text: '$completedGoals/$totalGoals',
                              style: const TextStyle(fontSize: 11, color: AppColors.accent1,
                                  fontWeight: FontWeight.w700, fontFamily: 'monospace')),
                          const TextSpan(text: ' completed',
                              style: TextStyle(fontSize: 11, color: AppColors.textDim)),
                        ]),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () { HapticFeedback.selectionClick(); setState(() => _showForm = !_showForm); },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                      decoration: _showForm
                          ? AppDecorations.glassCard(radius: 12)
                          : BoxDecoration(
                              gradient: AppGradients.primary,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: AppShadows.strongGlow(AppColors.accent1, blur: 12, spread: 3),
                            ),
                      child: Row(
                        children: [
                          Icon(Icons.add, size: 14, color: _showForm ? AppColors.textSecondary : Colors.black),
                          const SizedBox(width: 5),
                          Text('New Goal',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                                  color: _showForm ? AppColors.textSecondary : Colors.black)),
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
                color: AppColors.accent1,
                backgroundColor: AppColors.surface,
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.accent1, strokeWidth: 2))
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                        children: [
                          if (_showForm)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
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
                                children: [
                                  ShaderMask(
                                    blendMode: BlendMode.srcIn,
                                    shaderCallback: (b) => AppGradients.primary.createShader(Rect.fromLTWH(0,0,b.width,b.height)),
                                    child: const Icon(Icons.flag_rounded, size: 44),
                                  ),
                                  const SizedBox(height: 14),
                                  const Text('No goals set',
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                                  const SizedBox(height: 4),
                                  const Text('Define financial targets and track progress',
                                      style: TextStyle(fontSize: 12, color: AppColors.textDim)),
                                ],
                              ),
                            ),
                          ..._goals.asMap().entries.map((entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _GoalCard(
                              goal: entry.value,
                              delayMs: entry.key * 60,
                              onAddAmount: (amt) => _addAmount(entry.value, amt),
                              onDelete: () => _delete(entry.value['id'] as int, entry.value['name'] as String? ?? ''),
                            ),
                          )),
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

// ── Goal Card ─────────────────────────────────────────────────
class _GoalCard extends StatefulWidget {
  final Map<String, dynamic> goal;
  final void Function(String) onAddAmount;
  final VoidCallback onDelete;
  final int delayMs;
  const _GoalCard({required this.goal, required this.onAddAmount, required this.onDelete, this.delayMs = 0});

  @override
  State<_GoalCard> createState() => _GoalCardState();
}

class _GoalCardState extends State<_GoalCard> {
  final _ctrl = TextEditingController();

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final g     = widget.goal;
    final pct   = (g['progress_pct'] as num?)?.toDouble() ?? 0;
    final type  = g['type'] as String? ?? 'custom';
    final gType = _goalTypes.firstWhere((t) => t.$1 == type, orElse: () => _goalTypes.last);
    final color = pct >= 100 ? AppColors.positive : pct >= 60 ? AppColors.savings : AppColors.negative;
    final rem   = ((g['target_amount'] as num?)?.toDouble() ?? 0) - ((g['current_amount'] as num?)?.toDouble() ?? 0);
    final isLinked = g['linked_category'] != null && (g['linked_category'] as String).isNotEmpty;

    return GlassCard(
      delayMs: widget.delayMs,
      padding: EdgeInsets.zero,
      accentColor: gType.$3,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 42, height: 42,
                      decoration: BoxDecoration(
                        color: gType.$3.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(color: gType.$3.withOpacity(0.25)),
                        boxShadow: AppShadows.glow(gType.$3, spread: 1, blur: 5),
                      ),
                      child: Icon(_goalIcon(type), size: 19, color: gType.$3),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(g['name'] as String? ?? '',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                          Text(gType.$2,
                              style: const TextStyle(fontSize: 11, color: AppColors.textDim)),
                        ],
                      ),
                    ),
                    // Progress % badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(color: color.withOpacity(0.3)),
                      ),
                      child: Text(
                        pct >= 100 ? '✓ Done' : '${pct.toStringAsFixed(1)}%',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color, fontFamily: 'monospace'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: widget.onDelete,
                      child: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.textDim),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Progress bar
                AnimatedProgressBar(value: pct / 100, color: color, height: 7, delayMs: widget.delayMs + 100),
                const SizedBox(height: 14),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RichText(
                      text: TextSpan(children: [
                        TextSpan(text: formatINR(g['current_amount']),
                            style: const TextStyle(fontFamily: 'monospace', fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                        TextSpan(text: ' / ${formatINR(g['target_amount'])}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textDim)),
                      ]),
                    ),
                    if (rem > 0)
                      Text(
                        '${formatINR(rem)} left',
                        style: const TextStyle(fontSize: 11, color: AppColors.textDim),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Bottom: AUTO badge or manual add
          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
              border: Border(top: BorderSide(color: AppColors.cardBorder)),
            ),
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: isLinked
                ? Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.accent1.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.accent1.withOpacity(0.25)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.bolt_rounded, size: 12, color: AppColors.accent1),
                            const SizedBox(width: 5),
                            Text(
                              'AUTO · "${g['linked_category']}"',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                                  color: AppColors.accent1, fontFamily: 'monospace'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 38,
                          child: TextField(
                            controller: _ctrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                            decoration: InputDecoration(
                              hintText: 'Add amount...',
                              hintStyle: const TextStyle(color: AppColors.textDim, fontSize: 12),
                              filled: true, fillColor: AppColors.surface,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.cardBorder)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.cardBorder)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.accent1, width: 1.5)),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _ctrl.text.isNotEmpty
                            ? () { HapticFeedback.mediumImpact(); widget.onAddAmount(_ctrl.text); _ctrl.clear(); setState(() {}); }
                            : null,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: _ctrl.text.isNotEmpty
                              ? BoxDecoration(gradient: AppGradients.primary, borderRadius: BorderRadius.circular(10),
                                  boxShadow: AppShadows.glow(AppColors.accent1, spread: 1, blur: 5))
                              : BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.cardBorder)),
                          child: Text('+ Add',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                                  color: _ctrl.text.isNotEmpty ? Colors.black : AppColors.textDim)),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

IconData _goalIcon(String type) => switch (type) {
  'emergency' => Icons.shield_outlined,
  'sip'       => Icons.trending_up_rounded,
  _           => Icons.flag_rounded,
};

// ── Goal Form ─────────────────────────────────────────────────
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
  void initState() { super.initState(); _loadCategories(); }

  Future<void> _loadCategories() async {
    final cats = await Api.getCategories();
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
      'name':           _nameCtrl.text,
      'type':           _type,
      'target_amount':  double.tryParse(_targetCtrl.text) ?? 0,
      'current_amount': double.tryParse(_currentCtrl.text) ?? 0,
      if (_linkedCategory != null && _linkedCategory!.isNotEmpty) 'linked_category': _linkedCategory,
      if (_type == 'sip' && _monthlyCtrl.text.isNotEmpty) 'monthly_target': double.tryParse(_monthlyCtrl.text),
    });
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('New Goal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              GestureDetector(
                onTap: widget.onCancel,
                child: const Icon(Icons.close, size: 18, color: AppColors.textDim),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _nameCtrl,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Goal name *',
              filled: true, fillColor: AppColors.card,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.cardBorder)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.cardBorder)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.accent1, width: 1.5)),
            ),
          ),
          const SizedBox(height: 10),
          // Type selector
          Row(
            children: _goalTypes.map((t) {
              final active = _type == t.$1;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () { HapticFeedback.selectionClick(); setState(() => _type = t.$1); },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: active
                          ? BoxDecoration(
                              color: t.$3.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: t.$3.withOpacity(0.5)),
                              boxShadow: AppShadows.glow(t.$3, spread: 1, blur: 7),
                            )
                          : BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.cardBorder),
                            ),
                      child: Center(child: Text(t.$2,
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                              color: active ? t.$3 : AppColors.textDim))),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _formField(_targetCtrl, 'Target ₹ *')),
              const SizedBox(width: 8),
              Expanded(child: _formField(_currentCtrl, 'Current ₹')),
            ],
          ),
          if (_type == 'sip') ...[
            const SizedBox(height: 10),
            _formField(_monthlyCtrl, 'Monthly target ₹'),
          ],
          if (_linkableCategories.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              decoration: AppDecorations.glassCard(radius: 12),
              child: DropdownButton<String>(
                value: _linkedCategory,
                isExpanded: true,
                underline: const SizedBox(),
                dropdownColor: AppColors.surface,
                hint: const Row(children: [
                  Icon(Icons.bolt_rounded, size: 12, color: AppColors.textDim),
                  SizedBox(width: 6),
                  Text('Link to category (auto-update)', style: TextStyle(fontSize: 12, color: AppColors.textDim)),
                ]),
                style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textDim, size: 18),
                items: [
                  const DropdownMenuItem<String>(value: '', child: Text('No link (manual)', style: TextStyle(fontSize: 12, color: AppColors.textDim))),
                  ..._linkableCategories.map((cat) => DropdownMenuItem<String>(
                    value: cat,
                    child: Row(children: [
                      const Icon(Icons.bolt_rounded, size: 12, color: AppColors.accent1),
                      const SizedBox(width: 6),
                      Text(cat, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
                    ]),
                  )),
                ],
                onChanged: (val) => setState(() => _linkedCategory = (val == null || val.isEmpty) ? null : val),
              ),
            ),
          ],
          const SizedBox(height: 14),
          GestureDetector(
            onTap: _saving ? null : () { HapticFeedback.mediumImpact(); _submit(); },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: AppGradients.primary,
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppShadows.strongGlow(AppColors.accent1, blur: 12, spread: 3),
              ),
              child: Center(
                child: _saving
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                    : const Text('Create Goal', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.black)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _formField(TextEditingController ctrl, String hint) => TextField(
    controller: ctrl,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
    decoration: InputDecoration(
      hintText: hint,
      filled: true, fillColor: AppColors.card,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.cardBorder)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.cardBorder)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.accent1, width: 1.5)),
    ),
  );
}

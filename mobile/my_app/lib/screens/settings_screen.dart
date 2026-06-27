import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../api.dart';
import '../widgets/section_label.dart';
import '../widgets/app_theme.dart';
import '../widgets/animated_card.dart';

const _buckets = [
  ('essentials',  'expense',    'Essentials'),
  ('lifestyle',   'expense',    'Lifestyle'),
  ('investments', 'investment', 'Investments'),
  ('savings',     'savings',    'Savings'),
  ('income',      'income',     'Income'),
];

const _verdictGuide = [
  ('EXCELLENT', AppColors.positive, 'Total Score >= 80'),
  ('GOOD',      AppColors.accent2,  'Total Score 60–79'),
  ('AVERAGE',   AppColors.savings,  'Total Score 40–59'),
  ('POOR',      AppColors.negative, 'Total Score 20–39'),
  ('CRITICAL',  AppColors.negative, 'Total Score < 20'),
  ('SCORING',   AppColors.textDim,  'Max 100: Savings + Invest + Emergency + Expenses + Goals (20 each)'),
];

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  List<dynamic> _cats = [];
  bool _loadingCats = true;
  bool _showCatForm = false;
  final _catNameCtrl = TextEditingController();
  String _catBucket = 'lifestyle';
  bool _savingCat = false;

  @override
  void initState() { super.initState(); _loadCats(); }

  @override
  void dispose() { _catNameCtrl.dispose(); super.dispose(); }

  Future<void> _loadCats() async {
    setState(() => _loadingCats = true);
    try {
      final cats = await Api.getCategories();
      if (mounted) setState(() { _cats = cats; _loadingCats = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingCats = false);
    }
  }

  Future<void> _createCat() async {
    if (_catNameCtrl.text.isEmpty) return;
    setState(() => _savingCat = true);
    final bucket = _catBucket;
    final txType = _buckets.firstWhere((b) => b.$1 == bucket, orElse: () => _buckets[0]).$2;
    try {
      await Api.createCategory({'name': _catNameCtrl.text, 'bucket': bucket, 'transaction_type': txType});
      _catNameCtrl.clear();
      setState(() { _savingCat = false; _showCatForm = false; });
      _loadCats();
    } catch (e) {
      setState(() => _savingCat = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.negative),
        );
      }
    }
  }

  Future<void> _deleteCat(int id, String name) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete category?', style: TextStyle(fontSize: 16)),
        content: Text(name, style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete', style: TextStyle(color: AppColors.negative))),
        ],
      ),
    );
    if (ok == true) { await Api.deleteCategory(id); _loadCats(); }
  }

  @override
  Widget build(BuildContext context) {
    final customCats = _cats.where((c) => c['is_custom'] == true).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            // Header
            const Text('Settings',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            const SizedBox(height: 2),
            const Text('Local-first · Zero cloud · No AI',
                style: TextStyle(fontSize: 12, color: AppColors.textDim)),
            const SizedBox(height: 20),

            // ── Categories ────────────────────────────────
            const SectionLabel('CUSTOM CATEGORIES'),
            const SizedBox(height: 10),
            GlassCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  // Toggle row
                  GestureDetector(
                    onTap: () { HapticFeedback.selectionClick(); setState(() => _showCatForm = !_showCatForm); },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              gradient: AppGradients.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.add, size: 18, color: Colors.black),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Add Custom Category',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                Text('Extend the predefined list',
                                    style: TextStyle(fontSize: 11, color: AppColors.textDim)),
                              ],
                            ),
                          ),
                          Icon(
                            _showCatForm ? Icons.keyboard_arrow_up_rounded : Icons.chevron_right_rounded,
                            size: 18, color: AppColors.textDim,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Form
                  if (_showCatForm)
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      decoration: const BoxDecoration(
                        border: Border(top: BorderSide(color: AppColors.cardBorder)),
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 12),
                          TextField(
                            controller: _catNameCtrl,
                            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                            decoration: InputDecoration(
                              hintText: 'Category name',
                              filled: true, fillColor: AppColors.card,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.cardBorder)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.cardBorder)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.accent1, width: 1.5)),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                            decoration: AppDecorations.glassCard(radius: 12),
                            child: DropdownButton<String>(
                              value: _catBucket,
                              isExpanded: true,
                              underline: const SizedBox(),
                              dropdownColor: AppColors.surface,
                              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textDim, size: 18),
                              items: _buckets.map((b) => DropdownMenuItem(value: b.$1, child: Text(b.$3))).toList(),
                              onChanged: (v) => setState(() => _catBucket = v ?? _catBucket),
                            ),
                          ),
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: (_catNameCtrl.text.isNotEmpty && !_savingCat) ? () { HapticFeedback.mediumImpact(); _createCat(); } : null,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: _catNameCtrl.text.isNotEmpty
                                  ? BoxDecoration(gradient: AppGradients.primary, borderRadius: BorderRadius.circular(12),
                                      boxShadow: AppShadows.glow(AppColors.accent1, blur: 12, spread: 3))
                                  : BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppColors.cardBorder)),
                              child: Center(
                                child: _savingCat
                                    ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                                    : Text('Add Category',
                                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                                            color: _catNameCtrl.text.isNotEmpty ? Colors.black : AppColors.textDim)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Custom category list
                  if (_loadingCats)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator(color: AppColors.accent1, strokeWidth: 2)),
                    )
                  else if (customCats.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: Text('No custom categories yet',
                          style: TextStyle(fontSize: 12, color: AppColors.textDim))),
                    )
                  else
                    ...customCats.map((cat) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: const BoxDecoration(
                        border: Border(top: BorderSide(color: AppColors.cardBorder)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32, height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.accent1.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: const Icon(Icons.label_outline_rounded, size: 15, color: AppColors.accent1),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(cat['name'] as String? ?? '',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                                Text(cat['bucket'] as String? ?? '',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textDim)),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _deleteCat(cat['id'] as int, cat['name'] as String? ?? ''),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.negative.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.delete_outline_rounded, size: 15, color: AppColors.negative),
                            ),
                          ),
                        ],
                      ),
                    )),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Scoring Guide ─────────────────────────────
            const SectionLabel('HEALTH SCORE GUIDE'),
            const SizedBox(height: 10),
            GlassCard(
              delayMs: 80,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: _verdictGuide.map((v) {
                  final isLast = v == _verdictGuide.last;
                  return Padding(
                    padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
                    child: Row(
                      children: [
                        GlowDot(color: v.$2, size: 7),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 76,
                          child: Text(v.$1,
                              style: TextStyle(fontFamily: 'monospace', fontSize: 10,
                                  fontWeight: FontWeight.w800, color: v.$2, letterSpacing: 0.4)),
                        ),
                        Expanded(
                          child: Text(v.$3,
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),

            // ── App info ──────────────────────────────────
            GlassCard(
              delayMs: 120,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      gradient: AppGradients.primary,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(Icons.bolt_rounded, size: 20, color: Colors.black),
                  ),
                  const SizedBox(width: 14),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('FinGoals v2.0 (Mobile)',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      SizedBox(height: 3),
                      Text('Local-first · Zero cloud · Zero AI',
                          style: TextStyle(fontSize: 11, color: AppColors.textDim)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

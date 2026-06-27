import 'package:flutter/material.dart';
import '../api.dart';
import '../widgets/section_label.dart';

const _buckets = [
  ('essentials',  'expense',    'Essentials'),
  ('lifestyle',   'expense',    'Lifestyle'),
  ('investments', 'investment', 'Investments'),
  ('savings',     'savings',    'Savings'),
  ('income',      'income',     'Income'),
];

const _verdictGuide = [
  ('EXCELLENT', Color(0xFF10b981), 'Total Score >= 80'),
  ('GOOD',      Color(0xFF10b981), 'Total Score 60–79'),
  ('AVERAGE',   Color(0xFFf59e0b), 'Total Score 40–59'),
  ('POOR',      Color(0xFFef4444), 'Total Score 20–39'),
  ('CRITICAL',  Color(0xFFef4444), 'Total Score < 20'),
  ('SCORING',   Color(0xFF888888), 'Max 100: Savings (20), Invest (20), Emergency (20), Expenses (20), Goals (20)'),
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
  void initState() {
    super.initState();
    _loadCats();
  }

  @override
  void dispose() {
    _catNameCtrl.dispose();
    super.dispose();
  }

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
    final bucket    = _catBucket;
    final txType    = _buckets.firstWhere((b) => b.$1 == bucket, orElse: () => _buckets[0]).$2;
    try {
      await Api.createCategory({'name': _catNameCtrl.text, 'bucket': bucket, 'transaction_type': txType});
      _catNameCtrl.clear();
      setState(() { _savingCat = false; _showCatForm = false; });
      _loadCats();
    } catch (e) {
      setState(() => _savingCat = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: const Color(0xFFef4444)),
        );
      }
    }
  }

  Future<void> _deleteCat(int id, String name) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a1a),
        title: const Text('Delete category?', style: TextStyle(fontSize: 16)),
        content: Text(name, style: const TextStyle(color: Color(0xFF888888))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Color(0xFFef4444)))),
        ],
      ),
    );
    if (ok == true) { await Api.deleteCategory(id); _loadCats(); }
  }

  @override
  Widget build(BuildContext context) {
    final customCats = _cats.where((c) => c['is_custom'] == true).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0a0a0a),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            const Text('Settings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            const Text('Data control · No cloud · Local only', style: TextStyle(fontSize: 12, color: Color(0xFF555555))),
            const SizedBox(height: 20),

            // ── Categories ───────────────────────────────
            const SectionLabel('CATEGORIES'),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
                border: Border.all(color: const Color(0xFF1f1f1f)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  // Add button
                  GestureDetector(
                    onTap: () => setState(() => _showCatForm = !_showCatForm),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        border: _showCatForm ? Border(bottom: BorderSide(color: const Color(0xFF1f1f1f))) : null,
                        borderRadius: _showCatForm ? null : BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 34, height: 34,
                            decoration: BoxDecoration(
                              color: const Color(0xFF10b981).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.add, size: 16, color: Color(0xFF10b981)),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Add Custom Category', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white)),
                                Text('Extend the predefined list', style: TextStyle(fontSize: 11, color: Color(0xFF555555))),
                              ],
                            ),
                          ),
                          Icon(
                            _showCatForm ? Icons.keyboard_arrow_up_rounded : Icons.chevron_right_rounded,
                            size: 16, color: const Color(0xFF555555),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (_showCatForm)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                      child: Column(
                        children: [
                          const SizedBox(height: 10),
                          TextField(
                            controller: _catNameCtrl,
                            decoration: const InputDecoration(hintText: 'Category name'),
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _catBucket,
                            dropdownColor: const Color(0xFF1a1a1a),
                            style: const TextStyle(fontSize: 13, color: Colors.white),
                            decoration: const InputDecoration(),
                            items: _buckets.map((b) => DropdownMenuItem(value: b.$1, child: Text(b.$3))).toList(),
                            onChanged: (v) => setState(() => _catBucket = v ?? _catBucket),
                          ),
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: (_catNameCtrl.text.isNotEmpty && !_savingCat) ? _createCat : null,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _catNameCtrl.text.isNotEmpty ? const Color(0xFF10b981) : const Color(0xFF1a1a1a),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: _savingCat
                                    ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                                    : Text('Add Category', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _catNameCtrl.text.isNotEmpty ? Colors.black : const Color(0xFF555555))),
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
                      child: Center(child: CircularProgressIndicator(color: Color(0xFF10b981), strokeWidth: 2)),
                    )
                  else if (customCats.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(14),
                      child: Center(child: Text('No custom categories yet', style: TextStyle(fontSize: 12, color: Color(0xFF555555)))),
                    )
                  else
                    ...customCats.map((cat) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                      decoration: const BoxDecoration(
                        border: Border(top: BorderSide(color: Color(0xFF1f1f1f))),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(cat['name'] as String? ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white)),
                                Text(cat['bucket'] as String? ?? '', style: const TextStyle(fontSize: 11, color: Color(0xFF555555))),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _deleteCat(cat['id'] as int, cat['name'] as String? ?? ''),
                            child: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFef4444)),
                          ),
                        ],
                      ),
                    )),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Verdict Guide ────────────────────────────
            const SectionLabel('VERDICT SYSTEM'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
                border: Border.all(color: const Color(0xFF1f1f1f)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: _verdictGuide.map((v) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 148,
                        child: Text(v.$1, style: TextStyle(fontFamily: 'monospace', fontSize: 10, fontWeight: FontWeight.w700, color: v.$2, letterSpacing: 0.4)),
                      ),
                      Expanded(
                        child: Text(v.$3, style: const TextStyle(fontSize: 12, color: Color(0xFF888888))),
                      ),
                    ],
                  ),
                )).toList(),
              ),
            ),
            const SizedBox(height: 20),

            // ── App info ─────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
                border: Border.all(color: const Color(0xFF1f1f1f)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF555555)),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('FinGoals v1.0 (Mobile)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF888888))),
                      SizedBox(height: 2),
                      Text('Local-first · Zero cloud · No AI', style: TextStyle(fontSize: 11, color: Color(0xFF555555))),
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

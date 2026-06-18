import 'package:flutter/material.dart';
import '../api.dart';
import '../formatters.dart';
import '../main.dart';
import '../widgets/section_label.dart';
import '../widgets/stat_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _summary;
  Map<String, dynamic>? _verdicts;
  List<dynamic>? _breakdown;
  List<dynamic>? _trends;
  bool _loading = true;
  String? _error;

  String? _loadedMonth;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final month = AppState.of(context).selectedMonth;
    if (_loadedMonth != month) {
      _loadedMonth = month;
      _load();
    }
  }

  Future<void> _load() async {
    final month = AppState.of(context).selectedMonth;
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        Api.getSummary(month: month),
        Api.getVerdicts(month: month),
        Api.getBreakdown(month: month),
        Api.getTrends(months: 6),
      ]);
      if (mounted) {
        setState(() {
          _summary   = results[0] as Map<String, dynamic>;
          _verdicts  = results[1] as Map<String, dynamic>;
          _breakdown = results[2] as List<dynamic>;
          _trends    = results[3] as List<dynamic>;
          _loading   = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppState.of(context);
    final month    = appState.selectedMonth;

    // Verdict color
    final ol = _verdicts?['overall_label'] as String?;
    final overallColorName = switch (ol) {
      'CRITICAL' || 'POOR' => 'red',
      'AVERAGE' => 'amber',
      'GOOD' || 'EXCELLENT' => 'green',
      _ => 'gray',
    };
    final vc = Color(verdictColorInt(overallColorName));

    final income      = (_summary?['income'] as num?)?.toDouble() ?? 0;
    final expenses    = (_summary?['expenses'] as num?)?.toDouble() ?? 0;
    final investments = (_summary?['investments'] as num?)?.toDouble() ?? 0;
    final savings     = (_summary?['savings'] as num?)?.toDouble() ?? 0;
    final net         = (_summary?['net'] as num?)?.toDouble() ?? 0;
    final retained    = (income - expenses - investments - savings).clamp(0.0, double.infinity);
    final hasData     = income > 0 || expenses > 0;

    return Scaffold(
      backgroundColor: const Color(0xFF0a0a0a),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          color: const Color(0xFF10b981),
          backgroundColor: const Color(0xFF1a1a1a),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _MonthNavBtn(
                        icon: Icons.chevron_left,
                        onTap: () => appState.setMonth(prevMonth(month)),
                      ),
                      Column(
                        children: [
                          Text(
                            getMonthLabel(month),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: Colors.white,
                              fontFamily: 'monospace',
                            ),
                          ),
                          const Text(
                            'FINANCIAL REPORT',
                            style: TextStyle(fontSize: 9, color: Color(0xFF555555), letterSpacing: 1.2),
                          ),
                        ],
                      ),
                      _MonthNavBtn(
                        icon: Icons.chevron_right,
                        onTap: isCurrentMonth(month) ? null : () => appState.setMonth(nextMonth(month)),
                      ),
                    ],
                  ),
                ),
              ),
              if (_loading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: Color(0xFF10b981))),
                )
              else if (_error != null)
                SliverToBoxAdapter(
                  child: _ErrorCard(
                    message: 'Cannot reach server.\nMake sure backend is running and the IP in api.dart is correct.\n\n$_error',
                    onRetry: _load,
                  ),
                )
              else ...[
                // Net balance card
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10b981).withOpacity(0.07),
                        border: Border.all(color: vc.withOpacity(0.2)),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('NET BALANCE', style: TextStyle(fontSize: 9, color: Color(0xFF555555), letterSpacing: 1.2, fontFamily: 'monospace')),
                              if (ol != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: vc.withOpacity(0.15),
                                    border: Border.all(color: vc.withOpacity(0.3)),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(ol, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: vc, fontFamily: 'monospace', letterSpacing: 0.5)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            formatINR(net),
                            style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: 'monospace'),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(Icons.trending_up, size: 13, color: Color(0xFF10b981)),
                              const SizedBox(width: 5),
                              Text(formatINR(income), style: const TextStyle(fontSize: 12, color: Color(0xFF888888), fontFamily: 'monospace')),
                              const SizedBox(width: 16),
                              const Icon(Icons.trending_down, size: 13, color: Color(0xFFef4444)),
                              const SizedBox(width: 5),
                              Text(formatINR(expenses), style: const TextStyle(fontSize: 12, color: Color(0xFF888888), fontFamily: 'monospace')),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Ratio cards
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Row(
                      children: [
                        Expanded(child: StatCard(
                          label: 'SAVINGS',
                          value: formatPct(_summary?['savings_rate']),
                          verdictLabel: (_verdicts?['savings'] as Map?)?.containsKey('label') == true
                              ? _verdicts!['savings']['label'] as String?
                              : null,
                          verdictColor: (_verdicts?['savings'] as Map?)?.containsKey('color') == true
                              ? _verdicts!['savings']['color'] as String?
                              : null,
                        )),
                        const SizedBox(width: 8),
                        Expanded(child: StatCard(
                          label: 'INVEST',
                          value: formatPct(_summary?['investment_rate']),
                          verdictLabel: (_verdicts?['investment'] as Map?)?.containsKey('label') == true
                              ? _verdicts!['investment']['label'] as String?
                              : null,
                          verdictColor: (_verdicts?['investment'] as Map?)?.containsKey('color') == true
                              ? _verdicts!['investment']['color'] as String?
                              : null,
                        )),
                        const SizedBox(width: 8),
                        Expanded(child: StatCard(
                          label: 'ESSENTIALS',
                          value: formatPct(_summary?['essential_ratio']),
                          verdictLabel: (_verdicts?['expense'] as Map?)?.containsKey('label') == true
                              ? _verdicts!['expense']['label'] as String?
                              : null,
                          verdictColor: (_verdicts?['expense'] as Map?)?.containsKey('color') == true
                              ? _verdicts!['expense']['color'] as String?
                              : null,
                        )),
                      ],
                    ),
                  ),
                ),

                // Allocation breakdown
                if (hasData)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: _SurfaceCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SectionLabel('INCOME ALLOCATION'),
                            const SizedBox(height: 10),
                            _AllocRow('Expenses',    expenses,    const Color(0xFFef4444)),
                            const SizedBox(height: 8),
                            _AllocRow('Investments', investments, const Color(0xFF3b82f6)),
                            const SizedBox(height: 8),
                            _AllocRow('Savings',     savings,     const Color(0xFF8b5cf6)),
                            const SizedBox(height: 8),
                            _AllocRow('Retained',    retained,    const Color(0xFF10b981)),
                            if (income > 0) ...[
                              const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: SizedBox(
                                  height: 6,
                                  child: Row(
                                    children: [
                                      for (final seg in [
                                        (expenses,    const Color(0xFFef4444)),
                                        (investments, const Color(0xFF3b82f6)),
                                        (savings,     const Color(0xFF8b5cf6)),
                                        (retained,    const Color(0xFF10b981)),
                                      ])
                                        if (seg.$1 > 0)
                                          Expanded(
                                            flex: (seg.$1 / income * 1000).round(),
                                            child: Container(color: seg.$2),
                                          ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),

                // Expense breakdown (donut-like list)
                if ((_breakdown?.isNotEmpty ?? false))
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: _SurfaceCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SectionLabel('EXPENSE BREAKDOWN'),
                            const SizedBox(height: 10),
                            ...(_breakdown!.take(7).map((b) {
                              final color = Color(bucketColors[b['bucket'] as String? ?? 'other'] ?? 0xFF6b7280);
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 7),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 7, height: 7,
                                      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        b['category'] as String? ?? '',
                                        style: const TextStyle(fontSize: 12, color: Color(0xFF888888)),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      '${(b['pct'] as num?)?.toStringAsFixed(1) ?? '0'}%',
                                      style: const TextStyle(fontSize: 12, color: Colors.white, fontFamily: 'monospace', fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              );
                            })),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Trends
                if ((_trends?.length ?? 0) >= 2)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: _SurfaceCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SectionLabel('6-MONTH TREND'),
                            const SizedBox(height: 14),
                            _MiniTrendChart(trends: _trends!),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Empty state
                if (!hasData)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          const Icon(Icons.show_chart_rounded, size: 36, color: Color(0xFF333333)),
                          const SizedBox(height: 12),
                          Text(
                            'No data for ${getMonthLabel(month)}',
                            style: const TextStyle(fontSize: 14, color: Color(0xFF666666), fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 4),
                          const Text('Go to Transactions and tap + to add one', style: TextStyle(fontSize: 12, color: Color(0xFF444444))),
                        ],
                      ),
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────

class _MonthNavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _MonthNavBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF1a1a1a),
          border: Border.all(color: const Color(0xFF2a2a2a)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: onTap == null ? const Color(0xFF333333) : const Color(0xFF888888)),
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  final Widget child;
  const _SurfaceCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        border: Border.all(color: const Color(0xFF1f1f1f)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}

class _AllocRow extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  const _AllocRow(this.label, this.amount, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF888888)))),
        Text(formatINR(amount), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white, fontFamily: 'monospace')),
      ],
    );
  }
}

class _MiniTrendChart extends StatelessWidget {
  final List<dynamic> trends;
  const _MiniTrendChart({required this.trends});

  @override
  Widget build(BuildContext context) {
    final incomeVals  = trends.map((t) => (t['income'] as num?)?.toDouble() ?? 0).toList();
    final expenseVals = trends.map((t) => (t['expenses'] as num?)?.toDouble() ?? 0).toList();
    final allVals     = [...incomeVals, ...expenseVals];
    final maxVal      = allVals.fold(0.0, (a, b) => b > a ? b : a);
    if (maxVal == 0) return const SizedBox.shrink();

    return SizedBox(
      height: 80,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(trends.length, (i) {
          final iH = (incomeVals[i] / maxVal * 70).clamp(2.0, 70.0);
          final eH = (expenseVals[i] / maxVal * 70).clamp(2.0, 70.0);
          final label = trends[i]['month'] as String? ?? '';
          final parts = label.split('-');
          final shortLabel = parts.length >= 2
              ? ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][int.parse(parts[1]) - 1]
              : label;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        width: 6,
                        height: iH,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10b981),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 2),
                      Container(
                        width: 6,
                        height: eH,
                        decoration: BoxDecoration(
                          color: const Color(0xFFef4444),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(shortLabel, style: const TextStyle(fontSize: 8, color: Color(0xFF555555))),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(Icons.wifi_off_rounded, size: 36, color: Color(0xFFef4444)),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Color(0xFF888888))),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF1a1a1a),
                border: Border.all(color: const Color(0xFF2a2a2a)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('Retry', style: TextStyle(color: Color(0xFF10b981), fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../api.dart';
import '../formatters.dart';
import '../main.dart';
import '../widgets/section_label.dart';
import '../widgets/animated_card.dart';
import '../widgets/app_theme.dart';

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

    final totalScore = (_verdicts?['total'] as num?)?.toInt() ?? 0;
    final ol = _verdicts?['overall_label'] as String? ?? '';
    final vc = _scoreColor(totalScore);

    final income      = (_summary?['income']      as num?)?.toDouble() ?? 0;
    final expenses    = (_summary?['expenses']    as num?)?.toDouble() ?? 0;
    final investments = (_summary?['investments'] as num?)?.toDouble() ?? 0;
    final savings     = (_summary?['savings']     as num?)?.toDouble() ?? 0;
    final net         = (_summary?['net']         as num?)?.toDouble() ?? 0;
    final retained    = (income - expenses - investments - savings).clamp(0.0, double.infinity);
    final hasData     = income > 0 || expenses > 0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _load,
          color: AppColors.accent1,
          backgroundColor: AppColors.surface,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // ── Header ────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _MonthNavBtn(
                        icon: Icons.chevron_left,
                        onTap: () => appState.setMonth(prevMonth(month)),
                      ),
                      Column(
                        children: [
                          GradientText(
                            getMonthLabel(month),
                            gradient: AppGradients.primary,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, fontFamily: 'monospace'),
                          ),
                          const SizedBox(height: 2),
                          const Text('FINANCIAL REPORT',
                              style: TextStyle(fontSize: 8, color: AppColors.textDim, letterSpacing: 2.0)),
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
                  child: Center(child: CircularProgressIndicator(color: AppColors.accent1, strokeWidth: 2)),
                )
              else if (_error != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: GlassCard(
                      accentColor: AppColors.negative,
                      child: Column(children: [
                        const Icon(Icons.wifi_off_rounded, size: 32, color: AppColors.negative),
                        const SizedBox(height: 10),
                        Text(_error!, textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        const SizedBox(height: 14),
                        _GradientButton(label: 'Retry', onTap: _load),
                      ]),
                    ),
                  ),
                )
              else ...[

                // ── Hero Net Balance Card ──────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
                    child: GlassCard(
                      accentColor: vc,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('NET BALANCE',
                                  style: TextStyle(fontSize: 9, color: AppColors.textDim, letterSpacing: 2.0)),
                              if (ol.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: vc.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(100),
                                    border: Border.all(color: vc.withOpacity(0.4)),
                                    boxShadow: AppShadows.strongGlow(vc, spread: 4, blur: 14),
                                  ),
                                  child: Text(ol,
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: vc,
                                          fontFamily: 'monospace', letterSpacing: 0.8)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            formatINR(net),
                            style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary, fontFamily: 'monospace', height: 1.0),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              _MiniStat(label: 'Income', value: formatINR(income), color: AppColors.positive, icon: Icons.arrow_downward_rounded),
                              const SizedBox(width: 20),
                              _MiniStat(label: 'Spent',  value: formatINR(expenses), color: AppColors.negative, icon: Icons.arrow_upward_rounded),
                              const SizedBox(width: 20),
                              _MiniStat(label: 'Invested', value: formatINR(investments), color: AppColors.invest, icon: Icons.trending_up_rounded),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Health Score Card ──────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
                    child: GlassCard(
                      delayMs: 80,
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SectionLabel('FINANCIAL HEALTH SCORE'),
                          const SizedBox(height: 16),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Score ring
                              SizedBox(
                                width: 80, height: 80,
                                child: _ScoreRing(score: totalScore, color: vc),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    RichText(
                                      text: TextSpan(children: [
                                        TextSpan(text: '$totalScore',
                                            style: AppText.number(size: 42, color: vc)),
                                        TextSpan(text: '/100',
                                            style: AppText.number(size: 16, color: AppColors.textDim, weight: FontWeight.w500)),
                                      ]),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(ol, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: vc)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (_verdicts?['breakdown'] != null) ...[
                            const SizedBox(height: 18),
                            ...(_verdicts!['breakdown'] as Map<String, dynamic>).entries.toList().asMap().entries.map((entry) {
                              final idx   = entry.key;
                              final e     = entry.value;
                              final score = (e.value as num).toInt();
                              final barColor = score >= 16 ? AppColors.positive : score >= 10 ? AppColors.savings : AppColors.negative;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 78,
                                      child: Text(e.key,
                                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                                    ),
                                    Expanded(
                                      child: AnimatedProgressBar(
                                        value: score / 20.0,
                                        color: barColor,
                                        height: 5,
                                        delayMs: 100 + idx * 60,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    SizedBox(
                                      width: 40,
                                      child: Text('$score/20',
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                                              color: barColor, fontFamily: 'monospace'),
                                          textAlign: TextAlign.right),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Income Allocation ──────────────────────────
                if (hasData)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
                      child: GlassCard(
                        delayMs: 160,
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SectionLabel('INCOME ALLOCATION'),
                            const SizedBox(height: 14),
                            _AllocRow('Expenses',    expenses,    AppColors.negative, Icons.arrow_upward_rounded),
                            const SizedBox(height: 10),
                            _AllocRow('Investments', investments, AppColors.invest,   Icons.trending_up_rounded),
                            const SizedBox(height: 10),
                            _AllocRow('Savings',     savings,     AppColors.savings,  Icons.savings_outlined),
                            const SizedBox(height: 10),
                            _AllocRow('Retained',    retained,    AppColors.positive, Icons.account_balance_wallet_outlined),
                            if (income > 0) ...[
                              const SizedBox(height: 14),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: SizedBox(
                                  height: 8,
                                  child: Row(
                                    children: [
                                      for (final seg in [
                                        (expenses,    AppColors.negative),
                                        (investments, AppColors.invest),
                                        (savings,     AppColors.savings),
                                        (retained,    AppColors.positive),
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

                // ── Expense Breakdown ──────────────────────────
                if ((_breakdown?.isNotEmpty ?? false))
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
                      child: GlassCard(
                        delayMs: 200,
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SectionLabel('EXPENSE BREAKDOWN'),
                            const SizedBox(height: 12),
                            ...(_breakdown!.take(7).toList().asMap().entries.map((entry) {
                              final b = entry.value as Map<String, dynamic>;
                              final color = Color(bucketColors[b['bucket'] as String? ?? 'other'] ?? 0xFF6b7280);
                              final pct   = (b['pct'] as num?)?.toDouble() ?? 0;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        GlowDot(color: color, size: 7),
                                        const SizedBox(width: 9),
                                        Expanded(
                                          child: Text(b['category'] as String? ?? '',
                                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                              overflow: TextOverflow.ellipsis),
                                        ),
                                        Text('${pct.toStringAsFixed(1)}%',
                                            style: const TextStyle(fontSize: 12, color: AppColors.textPrimary,
                                                fontFamily: 'monospace', fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                    const SizedBox(height: 5),
                                    AnimatedProgressBar(value: pct / 100, color: color, height: 3, delayMs: 200 + entry.key * 50),
                                  ],
                                ),
                              );
                            })),
                          ],
                        ),
                      ),
                    ),
                  ),

                // ── 6-Month Trend ──────────────────────────────
                if ((_trends?.length ?? 0) >= 2)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
                      child: GlassCard(
                        delayMs: 240,
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SectionLabel('6-MONTH TREND'),
                            const SizedBox(height: 16),
                            _MiniTrendChart(trends: _trends!),
                          ],
                        ),
                      ),
                    ),
                  ),

                // ── Empty State ────────────────────────────────
                if (!hasData)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        children: [
                          ShaderMask(
                            blendMode: BlendMode.srcIn,
                            shaderCallback: (b) => AppGradients.primary.createShader(Rect.fromLTWH(0,0,b.width,b.height)),
                            child: const Icon(Icons.show_chart_rounded, size: 44),
                          ),
                          const SizedBox(height: 14),
                          Text('No data for ${getMonthLabel(month)}',
                              style: const TextStyle(fontSize: 15, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 6),
                          const Text('Tap Txns → + to add your first transaction',
                              style: TextStyle(fontSize: 12, color: AppColors.textDim)),
                        ],
                      ),
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Score Ring ────────────────────────────────────────────────
class _ScoreRing extends StatefulWidget {
  final int score;
  final Color color;
  const _ScoreRing({required this.score, required this.color});
  @override State<_ScoreRing> createState() => _ScoreRingState();
}

class _ScoreRingState extends State<_ScoreRing> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _anim = Tween<double>(begin: 0, end: widget.score / 100.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    Future.delayed(const Duration(milliseconds: 120), () { if (mounted) _ctrl.forward(); });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => CustomPaint(
        painter: _RingPainter(progress: _anim.value, color: widget.color),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  const _RingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 6;
    const start  = -math.pi / 2;
    const sweep  = 2 * math.pi;

    // Track
    canvas.drawCircle(center, radius, Paint()
      ..color = AppColors.cardBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6);

    // Progress arc
    if (progress > 0) {
      final rect = Rect.fromCircle(center: center, radius: radius);
      final arcPaint = Paint()
        ..shader = const LinearGradient(colors: [AppColors.accent1, AppColors.accent2]).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, start, sweep * progress, false, arcPaint);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress || old.color != color;
}

Color _scoreColor(int score) {
  if (score >= 80) return AppColors.positive;
  if (score >= 60) return AppColors.accent2;
  if (score >= 40) return AppColors.savings;
  return AppColors.negative;
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
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.cardBorder),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 16,
            color: onTap == null ? AppColors.textDim : AppColors.textSecondary),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const _MiniStat({required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 9, color: AppColors.textDim, letterSpacing: 0.5)),
        ]),
        const SizedBox(height: 3),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
            color: color, fontFamily: 'monospace')),
      ],
    );
  }
}

class _AllocRow extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final IconData icon;
  const _AllocRow(this.label, this.amount, this.color, this.icon);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 8),
        Expanded(child: Text(label,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
        Text(formatINR(amount),
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                color: color, fontFamily: 'monospace')),
      ],
    );
  }
}

class _MiniTrendChart extends StatelessWidget {
  final List<dynamic> trends;
  const _MiniTrendChart({required this.trends});

  @override
  Widget build(BuildContext context) {
    final incomeVals  = trends.map((t) => (t['income']   as num?)?.toDouble() ?? 0).toList();
    final expenseVals = trends.map((t) => (t['expenses'] as num?)?.toDouble() ?? 0).toList();
    final allVals     = [...incomeVals, ...expenseVals];
    final maxVal      = allVals.fold(0.0, (a, b) => b > a ? b : a);
    if (maxVal == 0) return const SizedBox.shrink();
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];

    return SizedBox(
      height: 90,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(trends.length, (i) {
          final iH = (incomeVals[i] / maxVal * 72).clamp(3.0, 72.0);
          final eH = (expenseVals[i] / maxVal * 72).clamp(3.0, 72.0);
          final label = trends[i]['month'] as String? ?? '';
          final parts = label.split('-');
          final month = parts.length >= 2 ? months[int.parse(parts[1]) - 1] : label;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        width: 8, height: iH,
                        decoration: BoxDecoration(
                          gradient: AppGradients.primary,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 2),
                      Container(
                        width: 8, height: eH,
                        decoration: BoxDecoration(
                          color: AppColors.negative,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(month, style: const TextStyle(fontSize: 8, color: AppColors.textDim)),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _GradientButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          gradient: AppGradients.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.black)),
      ),
    );
  }
}

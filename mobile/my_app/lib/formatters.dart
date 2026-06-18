import 'package:intl/intl.dart';

// ── Currency ──────────────────────────────────────────────
String formatINR(dynamic amount) {
  if (amount == null) return '₹—';
  final double v = (amount as num).toDouble();
  final double abs = v.abs();
  String formatted;
  if (abs >= 10000000) {
    formatted = '${(abs / 10000000).toStringAsFixed(2)} Cr';
  } else if (abs >= 100000) {
    formatted = '${(abs / 100000).toStringAsFixed(2)} L';
  } else if (abs >= 1000) {
    formatted = '${(abs / 1000).toStringAsFixed(1)}K';
  } else {
    formatted = NumberFormat('#,##,##0', 'en_IN').format(abs.round());
  }
  return (v < 0 ? '-' : '') + '₹$formatted';
}

String formatPct(dynamic value) {
  if (value == null) return '—%';
  return '${(value as num).toDouble().toStringAsFixed(1)}%';
}

// ── Dates ─────────────────────────────────────────────────
const _months = [
  'Jan','Feb','Mar','Apr','May','Jun',
  'Jul','Aug','Sep','Oct','Nov','Dec'
];

String getMonthLabel(String? monthStr) {
  if (monthStr == null || monthStr.isEmpty) return '';
  final parts = monthStr.split('-');
  if (parts.length < 2) return monthStr;
  final m = int.tryParse(parts[1]);
  if (m == null || m < 1 || m > 12) return monthStr;
  return '${_months[m - 1]} ${parts[0]}';
}

String getCurrentMonth() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}';
}

String prevMonth(String monthStr) {
  final parts = monthStr.split('-').map(int.parse).toList();
  final d = DateTime(parts[0], parts[1] - 1, 1);
  return '${d.year}-${d.month.toString().padLeft(2, '0')}';
}

String nextMonth(String monthStr) {
  final parts = monthStr.split('-').map(int.parse).toList();
  final d = DateTime(parts[0], parts[1] + 1, 1);
  return '${d.year}-${d.month.toString().padLeft(2, '0')}';
}

bool isCurrentMonth(String monthStr) => monthStr == getCurrentMonth();

String formatDate(String? dateStr) {
  if (dateStr == null) return '';
  final d = DateTime.tryParse(dateStr);
  if (d == null) return '';
  return DateFormat('d MMM').format(d);
}

// ── Verdict helpers ───────────────────────────────────────
const verdictColors = {
  'green':   0xFF10b981,
  'emerald': 0xFF10b981,
  'amber':   0xFFf59e0b,
  'red':     0xFFef4444,
  'gray':    0xFF555555,
};

int verdictColorInt(String? c) =>
    verdictColors[c] ?? verdictColors['gray']!;

// ── Transaction type metadata ─────────────────────────────
class TypeMeta {
  final String label;
  final int color;
  final int bg;
  const TypeMeta({required this.label, required this.color, required this.bg});
}

const typeMeta = {
  'income':     TypeMeta(label: 'Income',     color: 0xFF10b981, bg: 0x1A10b981),
  'expense':    TypeMeta(label: 'Expense',    color: 0xFFef4444, bg: 0x1Aef4444),
  'investment': TypeMeta(label: 'Invest',     color: 0xFF3b82f6, bg: 0x1A3b82f6),
  'savings':    TypeMeta(label: 'Savings',    color: 0xFF8b5cf6, bg: 0x1A8b5cf6),
};

TypeMeta getTypeMeta(String type) =>
    typeMeta[type] ??
    const TypeMeta(label: 'Other', color: 0xFF555555, bg: 0x1A555555);

// ── Bucket colors ─────────────────────────────────────────
const bucketColors = {
  'essentials':  0xFF3b82f6,
  'lifestyle':   0xFF8b5cf6,
  'investments': 0xFF10b981,
  'savings':     0xFFf59e0b,
  'income':      0xFF14b8a6,
  'other':       0xFF6b7280,
};

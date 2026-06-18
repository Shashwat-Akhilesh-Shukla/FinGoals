import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/dashboard_screen.dart';
import 'screens/transactions_screen.dart';
import 'screens/goals_screen.dart';
import 'screens/settings_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const FinGoalsApp());
}

// ── App State (shared selected month) ────────────────────────
class AppState extends InheritedWidget {
  final String selectedMonth;
  final ValueChanged<String> setMonth;
  final VoidCallback invalidateAll;

  const AppState({
    super.key,
    required this.selectedMonth,
    required this.setMonth,
    required this.invalidateAll,
    required super.child,
  });

  static AppState of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppState>()!;
  }

  @override
  bool updateShouldNotify(AppState old) =>
      selectedMonth != old.selectedMonth;
}

class AppStateHolder extends StatefulWidget {
  const AppStateHolder({super.key});

  @override
  State<AppStateHolder> createState() => _AppStateHolderState();
}

class _AppStateHolderState extends State<AppStateHolder> {
  String _month = _currentMonth();
  int _invalidateKey = 0;

  static String _currentMonth() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return AppState(
      selectedMonth: _month,
      setMonth: (m) => setState(() => _month = m),
      invalidateAll: () => setState(() => _invalidateKey++),
      child: _NavShell(invalidateKey: _invalidateKey),
    );
  }
}

// ── Navigation Shell ─────────────────────────────────────────
class _NavShell extends StatefulWidget {
  final int invalidateKey;
  const _NavShell({required this.invalidateKey});

  @override
  State<_NavShell> createState() => _NavShellState();
}

class _NavShellState extends State<_NavShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      DashboardScreen(key: ValueKey('dash-${widget.invalidateKey}')),
      TransactionsScreen(key: ValueKey('tx-${widget.invalidateKey}')),
      GoalsScreen(key: ValueKey('goals-${widget.invalidateKey}')),
      SettingsScreen(key: ValueKey('settings-${widget.invalidateKey}')),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0a0a0a),
      body: IndexedStack(index: _tab, children: screens),
      bottomNavigationBar: _BottomNav(
        current: _tab,
        onTap: (i) => setState(() => _tab = i),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int current;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.bar_chart_rounded, 'Dashboard'),
      (Icons.receipt_long_rounded, 'Transactions'),
      (Icons.flag_rounded, 'Goals'),
      (Icons.settings_rounded, 'Settings'),
    ];
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF111111),
        border: Border(top: BorderSide(color: Color(0xFF1f1f1f), width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: List.generate(items.length, (i) {
              final active = i == current;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        items[i].$1,
                        size: 22,
                        color: active
                            ? const Color(0xFF10b981)
                            : const Color(0xFF555555),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        items[i].$2,
                        style: TextStyle(
                          fontSize: 10,
                          color: active
                              ? const Color(0xFF10b981)
                              : const Color(0xFF555555),
                          fontWeight: active
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ── Root App ─────────────────────────────────────────────────
class FinGoalsApp extends StatelessWidget {
  const FinGoalsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FinGoals',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0a0a0a),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF10b981),
          surface: Color(0xFF111111),
        ),
        textTheme: ThemeData.dark().textTheme.apply(
              fontFamily: 'RobotoMono',
            ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1a1a1a),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF2a2a2a)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF2a2a2a)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF10b981)),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          hintStyle: const TextStyle(color: Color(0xFF555555), fontSize: 13),
          labelStyle: const TextStyle(color: Color(0xFF888888), fontSize: 11),
        ),
      ),
      home: const AppStateHolder(),
    );
  }
}

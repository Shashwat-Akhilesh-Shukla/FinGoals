import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/dashboard_screen.dart';
import 'screens/transactions_screen.dart';
import 'screens/goals_screen.dart';
import 'screens/settings_screen.dart';
import 'widgets/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF060810),
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  runApp(const FinGoalsApp());
}

// ── App State ─────────────────────────────────────────────────
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
  bool updateShouldNotify(AppState old) => selectedMonth != old.selectedMonth;
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

// ── Navigation Shell ──────────────────────────────────────────
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
      backgroundColor: AppColors.bg,
      extendBody: true,
      body: IndexedStack(index: _tab, children: screens),
      bottomNavigationBar: _FloatingNav(
        current: _tab,
        onTap: (i) => setState(() => _tab = i),
      ),
    );
  }
}

// ── Floating Pill Nav Bar ─────────────────────────────────────
class _FloatingNav extends StatefulWidget {
  final int current;
  final ValueChanged<int> onTap;
  const _FloatingNav({required this.current, required this.onTap});

  @override
  State<_FloatingNav> createState() => _FloatingNavState();
}

class _FloatingNavState extends State<_FloatingNav> {
  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.bar_chart_rounded,       'Dashboard'),
      (Icons.receipt_long_rounded,    'Txns'),
      (Icons.flag_rounded,            'Goals'),
      (Icons.settings_rounded,        'Settings'),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF060810),
        border: Border(top: BorderSide(color: Color(0x14ffffff), width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Container(
            height: 58,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: AppColors.cardBorder),
              boxShadow: const [
                BoxShadow(color: Color(0x18000000), blurRadius: 12, offset: Offset(0, 4)),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Row(
                children: List.generate(items.length, (i) {
                  final active = i == widget.current;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        widget.onTap(i);
                      },
                      behavior: HitTestBehavior.opaque,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 280),
                        decoration: active
                            ? BoxDecoration(
                                color: AppColors.accent1,
                                borderRadius: BorderRadius.circular(26),
                                boxShadow: const [
                                  BoxShadow(color: Color(0x201DB888), blurRadius: 8, offset: Offset(0, 2)),
                                ],
                              )
                            : null,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              items[i].$1,
                              size: 20,
                              color: active ? Colors.black : AppColors.textDim,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              items[i].$2,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                                color: active ? Colors.black : AppColors.textDim,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Root App ──────────────────────────────────────────────────
class FinGoalsApp extends StatelessWidget {
  const FinGoalsApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);
    return MaterialApp(
      title: 'FinGoals',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: AppColors.bg,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.accent1,
          surface: AppColors.surface,
        ),
        textTheme: base.apply(
          bodyColor: AppColors.textPrimary,
          displayColor: AppColors.textPrimary,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF0d0d22),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.cardBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.cardBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.accent1, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          hintStyle: const TextStyle(color: AppColors.textDim, fontSize: 13),
          labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
      ),
      home: const AppStateHolder(),
    );
  }
}

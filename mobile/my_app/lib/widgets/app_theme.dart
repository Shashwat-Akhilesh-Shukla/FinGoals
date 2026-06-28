import 'package:flutter/material.dart';

// ── Palette ──────────────────────────────────────────────────────────────────
class AppColors {
  // Backgrounds — near-black with a very subtle blue tint
  static const bg        = Color(0xFF060810);
  static const surface   = Color(0xFF0C0F18);
  static const card      = Color(0xFF0F1220);
  static const cardBorder= Color(0xFF1A2035);

  // Primary accent — deep teal-green (desaturated from neon mint)
  static const accent1   = Color(0xFF1DB888); // deep teal-green
  static const accent2   = Color(0xFF0EA5C5); // deep teal-blue

  // Semantic — refined, purpose-driven, not decorative
  static const positive  = Color(0xFF22C486); // reserved green
  static const negative  = Color(0xFFE0465C); // reserved red
  static const invest    = Color(0xFF6366C7); // deep indigo
  static const savings   = Color(0xFFC48B12); // warm amber
  static const neutral   = Color(0xFF3D4560);

  // Text — neutral, less purple-tinted
  static const textPrimary   = Color(0xFFE8EBF0);
  static const textSecondary = Color(0xFF6B7280);
  static const textDim       = Color(0xFF374151);
}

// ── Gradients ────────────────────────────────────────────────────────────────
class AppGradients {
  // Subtle tonal gradient — not a neon flash
  static const primary = LinearGradient(
    colors: [AppColors.accent1, Color(0xFF12A87A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Flat background — no visible radial bloom
  static const bgRadial = RadialGradient(
    center: Alignment(0, -0.5),
    radius: 1.6,
    colors: [Color(0xFF080C14), Color(0xFF060810)],
  );

  // No cardSheen — solid surfaces only
  static const cardSheen = LinearGradient(
    colors: [Colors.transparent, Colors.transparent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Flat solid per-type colors — no gradient flash on transaction rows
  static LinearGradient forType(String type) {
    return switch (type) {
      'income'     => LinearGradient(colors: [AppColors.positive, AppColors.positive], begin: Alignment.topLeft, end: Alignment.bottomRight),
      'expense'    => LinearGradient(colors: [AppColors.negative, AppColors.negative], begin: Alignment.topLeft, end: Alignment.bottomRight),
      'investment' => LinearGradient(colors: [AppColors.invest, AppColors.invest], begin: Alignment.topLeft, end: Alignment.bottomRight),
      'savings'    => LinearGradient(colors: [AppColors.savings, AppColors.savings], begin: Alignment.topLeft, end: Alignment.bottomRight),
      _            => LinearGradient(colors: [AppColors.neutral, AppColors.neutral], begin: Alignment.topLeft, end: Alignment.bottomRight),
    };
  }

  static Color colorForType(String type) {
    return switch (type) {
      'income'     => AppColors.positive,
      'expense'    => AppColors.negative,
      'investment' => AppColors.invest,
      'savings'    => AppColors.savings,
      _            => AppColors.neutral,
    };
  }
}

// ── Shadows — elevation only, no glow ────────────────────────────────────────
class AppShadows {
  // Replaces glow() — clean elevation shadow
  static List<BoxShadow> glow(Color color, {double spread = 8, double blur = 24}) => [
    const BoxShadow(color: Color(0x18000000), blurRadius: 8, offset: Offset(0, 4)),
  ];

  // Replaces strongGlow() — slightly more pronounced elevation
  static List<BoxShadow> strongGlow(Color color, {double spread = 8, double blur = 24}) => [
    const BoxShadow(color: Color(0x22000000), blurRadius: 12, offset: Offset(0, 4)),
  ];

  static const card = [
    BoxShadow(color: Color(0x1A000000), blurRadius: 16, offset: Offset(0, 4)),
  ];
}

// ── Decorations ──────────────────────────────────────────────────────────────
class AppDecorations {
  // Clean solid card — no sheen, no glow border
  static BoxDecoration glassCard({Color? borderColor, double radius = 20}) => BoxDecoration(
    color: AppColors.card,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: borderColor ?? AppColors.cardBorder, width: 1),
    boxShadow: AppShadows.card,
  );

  // Accent card — thin accent-tinted surface, no glow
  static BoxDecoration accentCard(Color accent, {double radius = 20}) => BoxDecoration(
    color: AppColors.card,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: accent.withOpacity(0.22), width: 1),
    boxShadow: AppShadows.card,
  );

  static BoxDecoration pill({required Color color, bool filled = false}) => BoxDecoration(
    color: filled ? color : color.withOpacity(0.10),
    borderRadius: BorderRadius.circular(100),
    border: Border.all(color: color.withOpacity(filled ? 1 : 0.25)),
  );
}

// ── Text styles ──────────────────────────────────────────────────────────────
class AppText {
  static const mono = TextStyle(fontFamily: 'monospace');

  static TextStyle label({double size = 9, Color color = AppColors.textSecondary, double spacing = 1.4}) =>
      TextStyle(fontSize: size, color: color, letterSpacing: spacing, fontWeight: FontWeight.w600);

  static TextStyle number({double size = 28, Color color = AppColors.textPrimary, FontWeight weight = FontWeight.w800}) =>
      TextStyle(fontFamily: 'monospace', fontSize: size, fontWeight: weight, color: color, height: 1.0);
}

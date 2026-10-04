import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Colour tokens from the Figma "Color" collection (Light and Dark modes).
@immutable
class DfColors extends ThemeExtension<DfColors> {
  const DfColors({
    required this.primary,
    required this.primaryStrong,
    required this.primarySoft,
    required this.onPrimary,
    required this.canvas,
    required this.surface,
    required this.surfaceMuted,
    required this.overlay,
    required this.border,
    required this.borderStrong,
    required this.text,
    required this.textSecondary,
    required this.textMuted,
    required this.success,
    required this.successSoft,
    required this.danger,
    required this.dangerSoft,
    required this.flame,
    required this.flameSoft,
    required this.event,
    required this.eventSoft,
    required this.heat,
    required this.tagColors,
    required this.tagSoftColors,
  });

  final Color primary;
  final Color primaryStrong;
  final Color primarySoft;
  final Color onPrimary;
  final Color canvas;
  final Color surface;
  final Color surfaceMuted;
  final Color overlay;
  final Color border;
  final Color borderStrong;
  final Color text;
  final Color textSecondary;
  final Color textMuted;
  final Color success;
  final Color successSoft;
  final Color danger;
  final Color dangerSoft;
  final Color flame;
  final Color flameSoft;
  final Color event;
  final Color eventSoft;

  /// Heatmap ramp, level 0 (none) to 4 (most).
  final List<Color> heat;

  /// Tag palette. A tag stores an index into this list.
  final List<Color> tagColors;
  final List<Color> tagSoftColors;

  static const light = DfColors(
    primary: Color(0xFF234EF3),
    primaryStrong: Color(0xFF1A3CC4),
    primarySoft: Color(0xFFE8EDFF),
    onPrimary: Color(0xFFFFFFFF),
    canvas: Color(0xFFF4F6FB),
    surface: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFEEF1F7),
    overlay: Color(0xFF0F172A),
    border: Color(0xFFE3E7F0),
    borderStrong: Color(0xFFCBD2E0),
    text: Color(0xFF0F172A),
    textSecondary: Color(0xFF475569),
    textMuted: Color(0xFF8A96AB),
    success: Color(0xFF16A34A),
    successSoft: Color(0xFFDCF5E5),
    danger: Color(0xFFE5484D),
    dangerSoft: Color(0xFFFDE7E8),
    flame: Color(0xFFFF7A1A),
    flameSoft: Color(0xFFFFEEDD),
    event: Color(0xFF0EA5A0),
    eventSoft: Color(0xFFDDF6F4),
    heat: [
      Color(0xFFEAEEF6),
      Color(0xFFC7D3FF),
      Color(0xFF8DA4FF),
      Color(0xFF5274F7),
      Color(0xFF234EF3),
    ],
    tagColors: [
      Color(0xFF2F6BEB), // work
      Color(0xFFC97A06), // school
      Color(0xFF139A73), // personal
      Color(0xFFB83FD9), // health
      Color(0xFFE5484D),
      Color(0xFF0EA5A0),
      Color(0xFF475569),
    ],
    tagSoftColors: [
      Color(0xFFE3ECFF),
      Color(0xFFFFF1DB),
      Color(0xFFDDF5EC),
      Color(0xFFF6E6FC),
      Color(0xFFFDE7E8),
      Color(0xFFDDF6F4),
      Color(0xFFEEF1F7),
    ],
  );

  static const dark = DfColors(
    primary: Color(0xFF4C6FFF),
    primaryStrong: Color(0xFF7A93FF),
    primarySoft: Color(0xFF1C2550),
    onPrimary: Color(0xFFFFFFFF),
    canvas: Color(0xFF0A0E18),
    surface: Color(0xFF141A28),
    surfaceMuted: Color(0xFF1C2333),
    overlay: Color(0xFF000000),
    border: Color(0xFF252D3F),
    borderStrong: Color(0xFF36405A),
    text: Color(0xFFF1F5F9),
    textSecondary: Color(0xFFB6C0D0),
    textMuted: Color(0xFF6E7A90),
    success: Color(0xFF22C55E),
    successSoft: Color(0xFF12301F),
    danger: Color(0xFFFF6369),
    dangerSoft: Color(0xFF3A1719),
    flame: Color(0xFFFF8A33),
    flameSoft: Color(0xFF3A2410),
    event: Color(0xFF2DD4BF),
    eventSoft: Color(0xFF0F2E2C),
    heat: [
      Color(0xFF1C2333),
      Color(0xFF1F2E6B),
      Color(0xFF2F48B8),
      Color(0xFF4C6FFF),
      Color(0xFF8FA6FF),
    ],
    tagColors: [
      Color(0xFF4F7FF5),
      Color(0xFFC07F14),
      Color(0xFF22A97F),
      Color(0xFFBD5CE0),
      Color(0xFFFF6369),
      Color(0xFF2DD4BF),
      Color(0xFFB6C0D0),
    ],
    tagSoftColors: [
      Color(0xFF16243F),
      Color(0xFF33260F),
      Color(0xFF0F2D24),
      Color(0xFF2E1A3A),
      Color(0xFF3A1719),
      Color(0xFF0F2E2C),
      Color(0xFF1C2333),
    ],
  );

  Color tag(int index) => tagColors[index % tagColors.length];
  Color tagSoft(int index) => tagSoftColors[index % tagSoftColors.length];

  @override
  DfColors copyWith() => this;

  @override
  DfColors lerp(ThemeExtension<DfColors>? other, double t) =>
      t < 0.5 ? this : (other as DfColors? ?? this);
}

/// Spacing and radius tokens.
class DfSpace {
  static const double s1 = 4, s2 = 8, s3 = 12, s4 = 16, s5 = 20, s6 = 24, s8 = 32;
}

class DfRadius {
  static const double sm = 8, md = 12, lg = 16, xl = 24, full = 999;
}

/// Text styles from the Figma type scale (Plus Jakarta Sans).
class DfText {
  static TextStyle _s(double size, double height, FontWeight w, double ls) =>
      GoogleFonts.plusJakartaSans(
        fontSize: size,
        height: height / size,
        fontWeight: w,
        letterSpacing: ls,
      );

  static TextStyle get display => _s(34, 40, FontWeight.w800, -0.8);
  static TextStyle get h1 => _s(28, 34, FontWeight.w700, -0.6);
  static TextStyle get h2 => _s(22, 28, FontWeight.w700, -0.4);
  static TextStyle get h3 => _s(17, 22, FontWeight.w600, -0.2);
  static TextStyle get bodyStrong => _s(15, 20, FontWeight.w600, 0);
  static TextStyle get body => _s(15, 22, FontWeight.w500, 0);
  static TextStyle get bodyRegular => _s(15, 22, FontWeight.w400, 0);
  static TextStyle get smallStrong => _s(13, 18, FontWeight.w600, 0);
  static TextStyle get small => _s(13, 18, FontWeight.w500, 0);
  static TextStyle get caption => _s(12, 16, FontWeight.w500, 0);
  static TextStyle get overline => _s(11, 14, FontWeight.w700, 0.8);
  static TextStyle get numericLarge => _s(40, 44, FontWeight.w800, -1);
}

class DfShadow {
  static const card = [
    BoxShadow(color: Color(0x0F0F1733), offset: Offset(0, 4), blurRadius: 16),
    BoxShadow(color: Color(0x0A0F1733), offset: Offset(0, 1), blurRadius: 2),
  ];
  static const floating = [
    BoxShadow(color: Color(0x2E142E99), offset: Offset(0, 12), blurRadius: 32),
  ];
  static const sheet = [
    BoxShadow(color: Color(0x1F0F1733), offset: Offset(0, -8), blurRadius: 32),
  ];
}

extension DfContext on BuildContext {
  DfColors get df => Theme.of(this).extension<DfColors>()!;
}

ThemeData buildTheme(Brightness brightness) {
  final c = brightness == Brightness.dark ? DfColors.dark : DfColors.light;
  final base = ThemeData(
    brightness: brightness,
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: c.primary,
      brightness: brightness,
      primary: c.primary,
      onPrimary: c.onPrimary,
      surface: c.surface,
      onSurface: c.text,
      error: c.danger,
    ),
    scaffoldBackgroundColor: c.canvas,
    splashFactory: InkSparkle.splashFactory,
    extensions: [c],
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(
      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
      bodyColor: c.text,
      displayColor: c.text,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: c.canvas,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      foregroundColor: c.text,
    ),
    dividerTheme: DividerThemeData(color: c.border, thickness: 1, space: 1),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(DfRadius.xl)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: c.overlay,
      contentTextStyle: DfText.small.copyWith(color: Colors.white),
      actionTextColor: brightness == Brightness.dark
          ? c.primaryStrong
          : const Color(0xFF8DA4FF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DfRadius.md),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: const WidgetStatePropertyAll(Colors.white),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? c.success : c.borderStrong,
      ),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
  );
}

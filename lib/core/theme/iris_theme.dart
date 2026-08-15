import 'package:flutter/material.dart';

/// Design tokens của IRIS. Mọi quyết định thị giác dùng chung được gom tại
/// đây để toàn bộ ứng dụng đổi đồng bộ khi bảng màu hoặc kích thước thay đổi.
abstract final class IrisColors {
  static const navy900 = Color(0xFF102A6B);
  static const navy800 = Color(0xFF15367D);
  static const blue700 = Color(0xFF145CCB);
  static const blue500 = Color(0xFF2A78F2);
  static const primary = Color(0xFF1769E8);
  static const primaryDark = navy900;
  static const primarySoft = Color(0xFFDDEBFF);
  static const canvas = Color(0xFFF8FBFF);
  static const surface = Color(0xFFFFFFFF);
  static const textPrimary = navy900;
  static const textSecondary = Color(0xFF63738A);
  static const divider = Color(0xFFD9E7F8);
  static const dividerSubtle = Color(0xFFE8F0FA);
  static const success = Color(0xFF22B56B);
  static const successSoft = Color(0xFFE8F8EF);
  static const warning = Color(0xFFF59B23);
  static const warningSoft = Color(0xFFFFF4E3);
  static const neutral = Color(0xFF9AABBF);
  static const neutralSoft = Color(0xFFF1F6FC);
  static const danger = Color(0xFFEF5A78);
  static const dangerSoft = Color(0xFFFFEDF1);
  static const splashGlow = Color(0xFFEAF3FF);
  static const cameraOverlay = Color(0x8A000000);

  // 7 accent cố định theo đúng 7 mã lĩnh vực hiện hành.
  static const cognition = Color(0xFF4C7CF3);
  static const emotion = Color(0xFFF45B69);
  static const sensory = Color(0xFF36B6D9);
  static const social = Color(0xFF8B7CF6);
  static const language = Color(0xFF20C4B0);
  static const biology = Color(0xFFF2994A);
  static const selfCare = Color(0xFF6AAF72);
}

abstract final class IrisSpacing {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 40.0;
  static const xxxl = 48.0;

  static const page = EdgeInsets.all(md);
  static const card = EdgeInsets.all(md);
  static const section = EdgeInsets.symmetric(vertical: lg);
}

abstract final class IrisRadii {
  static const input = 12.0;
  static const button = 12.0;
  static const card = 18.0;
  static const banner = 20.0;
  static const pill = 999.0;

  static const cardBorder = BorderRadius.all(Radius.circular(card));
  static const inputBorder = BorderRadius.all(Radius.circular(input));
  static const buttonBorder = BorderRadius.all(Radius.circular(button));
  static const pillBorder = BorderRadius.all(Radius.circular(pill));
}

abstract final class IrisSizes {
  static const buttonHeight = 52.0;
  static const iconChip = 48.0;
  static const iconSmall = 20.0;
  static const iconMedium = 24.0;
  static const iconLarge = 36.0;
  static const mascotCompact = 64.0;
  static const mascotSmall = 88.0;
  static const mascotMedium = 132.0;
  static const maxBubbleWidthFactor = 0.78;
}

abstract final class IrisShadows {
  static const soft = <BoxShadow>[
    BoxShadow(color: Color(0x0A102A6B), blurRadius: 14, offset: Offset(0, 4)),
  ];

  static const overlay = <BoxShadow>[
    BoxShadow(color: Color(0x14102A6B), blurRadius: 20, offset: Offset(0, 8)),
  ];
}

abstract final class IrisMotion {
  static const press = Duration(milliseconds: 140);
  static const component = Duration(milliseconds: 220);
  static const screen = Duration(milliseconds: 320);
}

/// Một nguồn duy nhất cho màu và icon của lĩnh vực.
abstract final class IrisDomainStyle {
  static const Map<String, Color> colors = {
    'nhan_thuc': IrisColors.cognition,
    'cam_xuc': IrisColors.emotion,
    'giac_quan': IrisColors.sensory,
    'quan_he_xa_hoi': IrisColors.social,
    'ngon_ngu': IrisColors.language,
    'sinh_hoc': IrisColors.biology,
    'sinh_hoat_ca_nhan': IrisColors.selfCare,
  };

  static const Map<String, IconData> icons = {
    'nhan_thuc': Icons.psychology_rounded,
    'cam_xuc': Icons.mood_rounded,
    'giac_quan': Icons.visibility_rounded,
    'quan_he_xa_hoi': Icons.groups_rounded,
    'ngon_ngu': Icons.record_voice_over_rounded,
    'sinh_hoc': Icons.favorite_rounded,
    'sinh_hoat_ca_nhan': Icons.self_improvement_rounded,
  };

  static Color colorOf(String code) => colors[code] ?? IrisColors.primary;
  static IconData iconOf(String code) => icons[code] ?? Icons.circle_rounded;

  static Color softColorOf(String code) => Color.alphaBlend(
    colorOf(code).withValues(alpha: 0.13),
    IrisColors.surface,
  );
}

abstract final class IrisTheme {
  static ThemeData get light {
    const scheme = ColorScheme.light(
      primary: IrisColors.primary,
      onPrimary: Colors.white,
      primaryContainer: IrisColors.primarySoft,
      onPrimaryContainer: IrisColors.primaryDark,
      secondary: IrisColors.social,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFEDEAFF),
      onSecondaryContainer: IrisColors.primaryDark,
      surface: IrisColors.surface,
      onSurface: IrisColors.textPrimary,
      error: IrisColors.danger,
      onError: Colors.white,
      errorContainer: IrisColors.dangerSoft,
      onErrorContainer: Color(0xFF8D2632),
      outline: IrisColors.divider,
      outlineVariant: IrisColors.divider,
      shadow: Color(0x14102A6B),
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: IrisColors.canvas,
      fontFamily: 'Roboto',
      visualDensity: VisualDensity.standard,
    );

    final textTheme = base.textTheme.copyWith(
      headlineLarge: base.textTheme.headlineLarge?.copyWith(
        color: IrisColors.primaryDark,
        fontWeight: FontWeight.w800,
        fontSize: 28,
      ),
      headlineMedium: base.textTheme.headlineMedium?.copyWith(
        color: IrisColors.primaryDark,
        fontWeight: FontWeight.w800,
        fontSize: 24,
      ),
      headlineSmall: base.textTheme.headlineSmall?.copyWith(
        color: IrisColors.primaryDark,
        fontWeight: FontWeight.w800,
        fontSize: 22,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        color: IrisColors.primaryDark,
        fontWeight: FontWeight.w800,
      ),
      titleMedium: base.textTheme.titleMedium?.copyWith(
        color: IrisColors.textPrimary,
        fontWeight: FontWeight.w700,
      ),
      titleSmall: base.textTheme.titleSmall?.copyWith(
        color: IrisColors.textPrimary,
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: base.textTheme.bodyLarge?.copyWith(
        color: IrisColors.textPrimary,
        height: 1.45,
      ),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(
        color: IrisColors.textPrimary,
        height: 1.45,
      ),
      bodySmall: base.textTheme.bodySmall?.copyWith(
        color: IrisColors.textSecondary,
        height: 1.4,
      ),
      labelLarge: base.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      labelMedium: base.textTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      labelSmall: base.textTheme.labelSmall?.copyWith(
        fontWeight: FontWeight.w600,
      ),
    );

    final cardShape = RoundedRectangleBorder(
      borderRadius: IrisRadii.cardBorder,
    );
    final inputBorder = OutlineInputBorder(
      borderRadius: IrisRadii.inputBorder,
      borderSide: const BorderSide(color: IrisColors.divider),
    );
    final buttonShape = RoundedRectangleBorder(
      borderRadius: IrisRadii.buttonBorder,
    );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: IrisColors.canvas,
        foregroundColor: IrisColors.primaryDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: const IconThemeData(color: IrisColors.primaryDark),
      ),
      cardTheme: CardThemeData(
        color: IrisColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: IrisSpacing.xs),
        shape: cardShape.copyWith(
          side: const BorderSide(color: IrisColors.divider),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, IrisSizes.buttonHeight),
          padding: const EdgeInsets.symmetric(
            horizontal: IrisSpacing.lg,
            vertical: IrisSpacing.sm,
          ),
          shape: buttonShape,
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: IrisColors.primary,
          minimumSize: const Size(64, IrisSizes.buttonHeight),
          padding: const EdgeInsets.symmetric(
            horizontal: IrisSpacing.lg,
            vertical: IrisSpacing.sm,
          ),
          side: const BorderSide(color: IrisColors.primary, width: 1.2),
          shape: buttonShape,
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: IrisColors.primary,
          shape: buttonShape,
          textStyle: textTheme.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: IrisColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: IrisSpacing.md,
          vertical: IrisSpacing.md,
        ),
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder.copyWith(
          borderSide: const BorderSide(color: IrisColors.primary, width: 1.8),
        ),
        errorBorder: inputBorder.copyWith(
          borderSide: const BorderSide(color: IrisColors.danger),
        ),
        labelStyle: const TextStyle(color: IrisColors.textSecondary),
        hintStyle: const TextStyle(color: IrisColors.textSecondary),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: IrisColors.surface,
        elevation: 2,
        height: 72,
        indicatorColor: IrisColors.primarySoft,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? IrisColors.primary
                : IrisColors.textSecondary,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => textTheme.labelSmall?.copyWith(
            color: states.contains(WidgetState.selected)
                ? IrisColors.primary
                : IrisColors.textSecondary,
          ),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: IrisColors.neutralSoft,
        selectedColor: IrisColors.primarySoft,
        side: BorderSide.none,
        shape: const StadiumBorder(),
        labelStyle: textTheme.labelMedium,
        padding: const EdgeInsets.symmetric(horizontal: IrisSpacing.xs),
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(
          horizontal: IrisSpacing.md,
          vertical: IrisSpacing.xs,
        ),
        iconColor: IrisColors.primary,
        textColor: IrisColors.textPrimary,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: IrisColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: cardShape,
        titleTextStyle: textTheme.titleLarge,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: IrisColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: CircleBorder(),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: IrisColors.primary,
        linearTrackColor: IrisColors.primarySoft,
        circularTrackColor: IrisColors.primarySoft,
        linearMinHeight: 8,
      ),
      dividerTheme: const DividerThemeData(
        color: IrisColors.divider,
        thickness: 1,
        space: IrisSpacing.md,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: IrisColors.primaryDark,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: IrisRadii.inputBorder),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: IrisColors.primary,
        unselectedLabelColor: IrisColors.textSecondary,
        labelStyle: textTheme.labelLarge,
        indicatorColor: IrisColors.primary,
        dividerColor: IrisColors.divider,
      ),
    );
  }
}

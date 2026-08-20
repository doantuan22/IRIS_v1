import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/services/ai_connectivity_service.dart';
import '../theme/iris_assets.dart';
import '../theme/iris_theme.dart';

class IrisBrandWordmark extends StatelessWidget {
  final double fontSize;
  const IrisBrandWordmark({super.key, this.fontSize = 30});

  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    children: [
      ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (bounds) => const LinearGradient(
          colors: [Color(0xFF4B9BFF), IrisColors.primary, Color(0xFF1552CF)],
        ).createShader(bounds),
        child: Text(
          'IRIS',
          style: GoogleFonts.fredoka(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.6,
            shadows: const [
              Shadow(
                color: Color(0x2B1769E8),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
        ),
      ),
      Positioned(
        top: -fontSize * .12,
        left: fontSize * .06,
        child: IrisSparkle(size: fontSize * .25, color: IrisColors.blue500),
      ),
      Positioned(
        right: -fontSize * .04,
        bottom: fontSize * .08,
        child: IrisSparkle(
          size: fontSize * .13,
          color: const Color(0xFF9BC7FF),
        ),
      ),
    ],
  );
}

class IrisSparkle extends StatelessWidget {
  final double size;
  final Color color;
  const IrisSparkle({
    super.key,
    this.size = 20,
    this.color = IrisColors.primary,
  });
  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: _SparklePainter(color));
}

class _SparklePainter extends CustomPainter {
  final Color color;
  const _SparklePainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final path = Path()
      ..moveTo(c.dx, 0)
      ..lineTo(c.dx + size.width * .18, c.dy - size.height * .18)
      ..lineTo(size.width, c.dy)
      ..lineTo(c.dx + size.width * .18, c.dy + size.height * .18)
      ..lineTo(c.dx, size.height)
      ..lineTo(c.dx - size.width * .18, c.dy + size.height * .18)
      ..lineTo(0, c.dy)
      ..lineTo(c.dx - size.width * .18, c.dy - size.height * .18)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _SparklePainter oldDelegate) =>
      oldDelegate.color != color;
}

class IrisAiStatusLamp extends StatelessWidget {
  const IrisAiStatusLamp({super.key});
  String _label(AiConnectivityState state) {
    if (state.isChecking || (!state.isConnected && !state.hasIssue)) {
      return 'Dang kiem tra ket noi AI';
    }
    return state.isConnected
        ? 'Ket noi AI dang hoat dong tot'
        : 'Ket noi AI dang gap van de';
  }

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<AiConnectivityState>(
        valueListenable: AiConnectivityService.instance.stateNotifier,
        builder: (context, state, _) {
          final color = state.isConnected
              ? IrisColors.success
              : state.hasIssue
              ? IrisColors.danger
              : IrisColors.primary;
          return Semantics(
            button: true,
            label: _label(state),
            child: Tooltip(
              message: _label(state),
              child: Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F8FF),
                  shape: BoxShape.circle,
                  border: Border.all(color: IrisColors.primarySoft, width: 1.4),
                  boxShadow: IrisShadows.soft,
                ),
                child: AnimatedContainer(
                  duration: IrisMotion.component,
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: .42),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
}

class IrisGenderAvatar extends StatelessWidget {
  final String? gender;
  final double size;
  const IrisGenderAvatar({super.key, required this.gender, this.size = 42});
  String get _asset {
    switch (gender?.trim().toLowerCase()) {
      case 'nam':
      case 'male':
        return IrisAssets.avatarBoy;
      case 'nữ':
      case 'nu':
      case 'female':
        return IrisAssets.avatarGirl;
      default:
        return IrisAssets.avatarNeutral;
    }
  }

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    padding: EdgeInsets.all(size * .04),
    decoration: BoxDecoration(
      color: IrisColors.primarySoft,
      shape: BoxShape.circle,
      border: Border.all(color: const Color(0xFF8EC0FF), width: 1.6),
    ),
    child: ClipOval(
      child: Image.asset(
        _asset,
        fit: BoxFit.cover,
        semanticLabel: 'Anh dai dien ho so tre',
      ),
    ),
  );
}

class IrisAssetIcon extends StatelessWidget {
  final String asset;
  final double size;
  final String? semanticLabel;
  const IrisAssetIcon({
    super.key,
    required this.asset,
    this.size = IrisSizes.iconChip,
    this.semanticLabel,
  });
  @override
  Widget build(BuildContext context) => Image.asset(
    asset,
    width: size,
    height: size,
    fit: BoxFit.contain,
    semanticLabel: semanticLabel,
    filterQuality: FilterQuality.medium,
  );
}

class IrisRoundArrow extends StatelessWidget {
  final double size;
  const IrisRoundArrow({super.key, this.size = 44});
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: const BoxDecoration(
      color: Color(0xFFF1F6FD),
      shape: BoxShape.circle,
    ),
    child: Icon(
      Icons.chevron_right_rounded,
      color: IrisColors.primary,
      size: size * .62,
    ),
  );
}

class IrisPageBackdrop extends StatelessWidget {
  const IrisPageBackdrop({super.key});
  @override
  Widget build(BuildContext context) => const IgnorePointer(
    child: Stack(
      children: [
        Positioned(top: -92, right: -72, child: _BackdropOrb(size: 228)),
        Positioned(bottom: -108, left: -94, child: _BackdropOrb(size: 252)),
        Positioned(
          top: 126,
          left: 36,
          child: IrisSparkle(size: 14, color: Color(0xFFB9D8FF)),
        ),
        Positioned(
          bottom: 130,
          right: 36,
          child: IrisSparkle(size: 28, color: Color(0xFFB9D8FF)),
        ),
        Positioned(top: 246, right: 24, child: _DotGrid()),
      ],
    ),
  );
}

class _BackdropOrb extends StatelessWidget {
  final double size;
  const _BackdropOrb({required this.size});
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: const BoxDecoration(
      color: Color(0xFFEAF4FF),
      shape: BoxShape.circle,
    ),
  );
}

class _DotGrid extends StatelessWidget {
  const _DotGrid();
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 52,
    height: 52,
    child: Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(
        25,
        (_) => const SizedBox(
          width: 3,
          height: 3,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Color(0xFFBDD9FF),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    ),
  );
}

class IrisIconChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  const IrisIconChip({
    super.key,
    required this.icon,
    required this.color,
    this.size = IrisSizes.iconChip,
  });
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: Color.alphaBlend(color.withValues(alpha: .14), IrisColors.surface),
      borderRadius: IrisRadii.inputBorder,
    ),
    child: Icon(icon, color: color, size: IrisSizes.iconMedium),
  );
}

class IrisStatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const IrisStatusBadge({super.key, required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: IrisSpacing.sm,
      vertical: IrisSpacing.xxs,
    ),
    decoration: BoxDecoration(
      color: Color.alphaBlend(color.withValues(alpha: .14), IrisColors.surface),
      borderRadius: IrisRadii.pillBorder,
    ),
    child: Text(
      label,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
    ),
  );
}

class IrisInfoBanner extends StatelessWidget {
  final Widget leading;
  final Widget child;
  final Color color;
  const IrisInfoBanner({
    super.key,
    required this.leading,
    required this.child,
    this.color = IrisColors.primary,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: IrisSpacing.card,
    decoration: BoxDecoration(
      color: Color.alphaBlend(color.withValues(alpha: .10), IrisColors.surface),
      borderRadius: const BorderRadius.all(Radius.circular(IrisRadii.banner)),
      boxShadow: IrisShadows.soft,
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        leading,
        const SizedBox(width: IrisSpacing.sm),
        Expanded(child: child),
      ],
    ),
  );
}

class IrisDomainIcon extends StatelessWidget {
  final String domainCode;
  final bool completed;
  final double size;
  const IrisDomainIcon({
    super.key,
    required this.domainCode,
    this.completed = false,
    this.size = 56,
  });
  @override
  Widget build(BuildContext context) {
    final color = IrisDomainStyle.colorOf(domainCode);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: IrisDomainStyle.softColorOf(domainCode),
        borderRadius: IrisRadii.cardBorder,
      ),
      child: Icon(
        completed ? Icons.check_rounded : IrisDomainStyle.iconOf(domainCode),
        color: completed ? IrisColors.success : color,
        size: IrisSizes.iconLarge,
      ),
    );
  }
}

/// Đoạn văn mô tả dài dùng chung toàn app — mặc định canh 2 lề
/// (`TextAlign.justify`) để các đoạn văn nhiều mệnh đề (mô tả, cảnh báo,
/// văn bản do AI sinh...) không bị so le lề phải như `Text` thường. Cho
/// phép override [style]/[textAlign] cho các trường hợp cần khác (VD vẫn
/// muốn `center` ở 1 dòng ngắn).
class IrisParagraph extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign textAlign;

  const IrisParagraph(
    this.text, {
    super.key,
    this.style,
    this.textAlign = TextAlign.justify,
  });

  @override
  Widget build(BuildContext context) =>
      Text(text, style: style, textAlign: textAlign);
}

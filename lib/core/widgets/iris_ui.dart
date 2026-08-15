import 'package:flutter/material.dart';

import '../theme/iris_theme.dart';

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
  Widget build(BuildContext context) {
    return Image.asset(
      asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      semanticLabel: semanticLabel,
      filterQuality: FilterQuality.medium,
    );
  }
}

class IrisMascot extends StatelessWidget {
  final String asset;
  final double height;
  final String? semanticLabel;

  const IrisMascot({
    super.key,
    required this.asset,
    this.height = IrisSizes.mascotMedium,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      asset,
      height: height,
      fit: BoxFit.contain,
      semanticLabel: semanticLabel,
      filterQuality: FilterQuality.medium,
    );
  }
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
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          color.withValues(alpha: 0.14),
          IrisColors.surface,
        ),
        borderRadius: IrisRadii.inputBorder,
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: color, size: IrisSizes.iconMedium),
    );
  }
}

class IrisStatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const IrisStatusBadge({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: IrisSpacing.sm,
        vertical: IrisSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          color.withValues(alpha: 0.14),
          IrisColors.surface,
        ),
        borderRadius: IrisRadii.pillBorder,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
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
  Widget build(BuildContext context) {
    return Container(
      padding: IrisSpacing.card,
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          color.withValues(alpha: 0.10),
          IrisColors.surface,
        ),
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
      decoration: BoxDecoration(
        color: IrisDomainStyle.softColorOf(domainCode),
        borderRadius: IrisRadii.cardBorder,
      ),
      alignment: Alignment.center,
      child: Icon(
        completed ? Icons.check_rounded : IrisDomainStyle.iconOf(domainCode),
        color: completed ? IrisColors.success : color,
        size: IrisSizes.iconLarge,
      ),
    );
  }
}

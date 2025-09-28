import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Curved navigation bar item
class CurvedNavItem {
  final String svgAsset; // SVG asset path
  final String label;
  final Color? activeColor;

  CurvedNavItem({
    required this.svgAsset,
    required this.label,
    this.activeColor,
  });
}

/// Curved navigation bar widget
class CurvedNavBar extends StatelessWidget {
  final List<CurvedNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final double height;
  final double notchRadius;

  const CurvedNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.height = 80,
    this.notchRadius = 36,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final inactive = scheme.onSurfaceVariant.withOpacity(0.65);

    return ClipPath(
      clipper: _ConcaveClipper(radius: notchRadius),
      child: BottomAppBar(
        height: height,
        color: Theme.of(context).bottomAppBarTheme.color ?? Colors.grey.shade200,
        surfaceTintColor: Theme.of(context).bottomAppBarTheme.surfaceTintColor,
        elevation: Theme.of(context).bottomAppBarTheme.elevation ?? 8,
        padding: EdgeInsets.zero,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(items.length, (i) {
            final it = items[i];
            final active = i == currentIndex;
            final color = active ? (it.activeColor ?? scheme.primary) : inactive;

            return _NavButton(
              svgAsset: it.svgAsset,
              label: it.label,
              color: color,
              active: active,
              onTap: () => onTap(i),
            );
          }),
        ),
      ),
    );
  }
}

/// Nav button widget (SVG + label)
class _NavButton extends StatelessWidget {
  final String svgAsset;
  final String label;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  const _NavButton({
    required this.svgAsset,
    required this.label,
    required this.active,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.labelLarge!;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        splashColor: color.withOpacity(0.12),
        child: Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox(
                height: 26,
                width: 26,
                child: SvgPicture.asset(
                  svgAsset,
                  colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                ),
              ),
              const SizedBox(height: 6),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: Theme.of(context).textTheme.labelLarge!.copyWith(
                  color: color,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                ),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );

  }
}

/// Concave shape clipper for curved bottom app bar
class _ConcaveClipper extends CustomClipper<Path> {
  final double radius;
  const _ConcaveClipper({required this.radius});

  @override
  Path getClip(Size size) {
    final r = radius;
    final centerX = size.width / 2;

    final path = Path()
      ..moveTo(0, r)
      ..quadraticBezierTo(0, 0, r, 0)
      ..lineTo(centerX - r * 2, 0)
      ..quadraticBezierTo(centerX - r * 1.2, 0, centerX - r, r * 0.6)
      ..arcToPoint(
        Offset(centerX + r, r * 0.6),
        radius: Radius.circular(r * 1.1),
        clockwise: false,
      )
      ..quadraticBezierTo(centerX + r * 1.2, 0, centerX + r * 2, 0)
      ..lineTo(size.width - r, 0)
      ..quadraticBezierTo(size.width, 0, size.width, r)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

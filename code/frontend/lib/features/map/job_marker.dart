import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/motion.dart';
import '../../core/tokens.dart';
import '../../models/job.dart';

/// A job pin, styled per section 15 of the brand guidelines.
///
/// Default jobs are Trust Burgundy with a white icon; the selected pin is
/// Deep Burgundy with a Copper outline; jobs created on this device are
/// Copper. Selection also enlarges the pin — colour is never the only
/// indicator of state (section 29).
class JobMarker extends StatelessWidget {
  const JobMarker({
    super.key,
    required this.job,
    required this.isSelected,
    required this.onTap,
  });

  final Job job;
  final bool isSelected;
  final VoidCallback onTap;

  // 48, not the 44 minimum: section 29 names 48 as the preferred target and
  // Android's own guideline requires it. A pin is also harder to hit than a
  // rectangle, since its lower half tapers to a point.
  static const double size = BrandSizing.touchTargetPreferred;
  static const double selectedSize = 58;

  @override
  Widget build(BuildContext context) {
    final fill = isSelected
        ? BrandColours.markerSelected
        : (job.isLocal ? BrandColours.markerLocal : BrandColours.markerDefault);

    return Semantics(
      button: true,
      selected: isSelected,
      label: job.displayTitle,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          // Section 28 — the marker gently enlarges when selected.
          duration: Motion.fast(context),
          curve: BrandMotion.curve,
          width: isSelected ? selectedSize : size,
          height: isSelected ? selectedSize : size,
          // The painter needs the full marker size. Given a child, CustomPaint
          // sizes itself to that child — so the pin and the glyph are stacked
          // rather than nested, and the pin fills the marker.
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _PinPainter(
                    fill: fill,
                    outline: isSelected
                        ? BrandColours.markerSelectedOutline
                        : Colors.white,
                    outlineWidth: isSelected ? 3 : 2,
                  ),
                ),
              ),
              Padding(
                // Sit the glyph in the round head of the pin, not the point.
                padding: EdgeInsets.only(bottom: isSelected ? 14 : 11),
                child: Icon(
                  job.icon,
                  size: isSelected ? 20 : 17,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Draws a rounded map pin — a circular head tapering to a point.
class _PinPainter extends CustomPainter {
  const _PinPainter({
    required this.fill,
    required this.outline,
    required this.outlineWidth,
  });

  final Color fill;
  final Color outline;
  final double outlineWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    final radius = width / 2 * 0.78;
    final centre = Offset(width / 2, radius + outlineWidth);
    final tip = Offset(width / 2, height - outlineWidth);

    // One continuous outline: up the tangent from the tip, around the head,
    // and back down. Drawing the head and the point as separate shapes leaves
    // the stroke cutting a visible seam across the join.
    final distanceToTip = tip.dy - centre.dy;
    final tangentAngle = math.acos((radius / distanceToTip).clamp(-1.0, 1.0));

    // Canvas angles run clockwise from the positive x-axis, so π/2 points
    // straight down towards the tip.
    final start = math.pi / 2 + tangentAngle;
    final sweep = 2 * math.pi - 2 * tangentAngle;

    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(
        centre.dx + radius * math.cos(start),
        centre.dy + radius * math.sin(start),
      )
      ..arcTo(
        Rect.fromCircle(center: centre, radius: radius),
        start,
        sweep,
        false,
      )
      ..close();

    // A soft drop shadow so pins stay legible over busy map tiles.
    canvas.drawShadow(path, BrandColours.ink.withValues(alpha: 0.5), 3, false);

    canvas.drawPath(path, Paint()..color = fill);
    canvas.drawPath(
      path,
      Paint()
        ..color = outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = outlineWidth,
    );
  }

  @override
  bool shouldRepaint(_PinPainter oldDelegate) =>
      oldDelegate.fill != fill ||
      oldDelegate.outline != outline ||
      oldDelegate.outlineWidth != outlineWidth;
}

/// The device's own position — Information Blue with a soft ring, never green
/// (section 15).
class UserLocationMarker extends StatelessWidget {
  const UserLocationMarker({super.key});

  static const double size = 28;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Your location',
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: BrandColours.userLocationRing,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: BrandColours.userLocation,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
      ),
    );
  }
}

/// A pin standing for several jobs at once.
///
/// Shows the count, and keeps the kind's glyph when every job in the group is
/// the same kind — a cluster of five plumbing jobs is more useful than a
/// cluster of five anonymous ones.
class ClusterMarker extends StatelessWidget {
  const ClusterMarker({
    super.key,
    required this.count,
    required this.icon,
    required this.onTap,
  });

  final int count;
  final IconData? icon;
  final VoidCallback onTap;

  static const double size = 52;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      label: '$count jobs here. Tap to zoom in.',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: BrandColours.trustBurgundy,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: BrandColours.ink.withValues(alpha: 0.28),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null)
                Icon(icon, size: 14, color: BrandColours.white),
              Text(
                '$count',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: BrandColours.white,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

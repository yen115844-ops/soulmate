import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/theme/theme_context.dart';

/// Glassmorphism Container - Frosted glass effect
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final BorderRadius? borderRadius;
  final EdgeInsets? padding;
  final Border? border;
  final Color? backgroundColor;
  final double? width;
  final double? height;

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 10,
    this.opacity = 0.1,
    this.borderRadius,
    this.padding,
    this.border,
    this.backgroundColor,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          width: width,
          height: height,
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: (backgroundColor ?? Colors.white).withOpacity(opacity),
            borderRadius: borderRadius ?? BorderRadius.circular(16),
            border: border ??
                Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Glassmorphism Card - More styled glass card
class GlassCard extends StatelessWidget {
  final Widget child;
  final double blur;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final VoidCallback? onTap;
  final double borderRadius;
  final Gradient? gradient;

  const GlassCard({
    super.key,
    required this.child,
    this.blur = 10,
    this.padding,
    this.margin,
    this.onTap,
    this.borderRadius = 20,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
              child: Container(
                padding: padding ?? const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: gradient ??
                      LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.15),
                          Colors.white.withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                  borderRadius: BorderRadius.circular(borderRadius),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Neumorphism Container - Soft shadow effect
class NeumorphicContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? backgroundColor;
  final bool isPressed;
  final VoidCallback? onTap;
  final double intensity;

  const NeumorphicContainer({
    super.key,
    required this.child,
    this.borderRadius = 16,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.isPressed = false,
    this.onTap,
    this.intensity = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? context.appColors.background;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: margin,
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: isPressed
              ? [
                  BoxShadow(
                    color: (isDark ? Colors.black : context.appColors.textHint)
                        .withOpacity(0.15 * intensity),
                    offset: const Offset(2, 2),
                    blurRadius: 4,
                  ),
                  BoxShadow(
                    color: (isDark ? Colors.grey.shade800 : Colors.white)
                        .withOpacity(0.7 * intensity),
                    offset: const Offset(-2, -2),
                    blurRadius: 4,
                  ),
                ]
              : [
                  BoxShadow(
                    color: (isDark ? Colors.black : context.appColors.textHint)
                        .withOpacity(0.2 * intensity),
                    offset: const Offset(4, 4),
                    blurRadius: 8,
                  ),
                  BoxShadow(
                    color: (isDark ? Colors.grey.shade800 : Colors.white)
                        .withOpacity(0.9 * intensity),
                    offset: const Offset(-4, -4),
                    blurRadius: 8,
                  ),
                ],
        ),
        child: child,
      ),
    );
  }
}

/// Gradient Border Container
class GradientBorderContainer extends StatelessWidget {
  final Widget child;
  final Gradient gradient;
  final double borderWidth;
  final double borderRadius;
  final EdgeInsets? padding;
  final Color? backgroundColor;

  const GradientBorderContainer({
    super.key,
    required this.child,
    required this.gradient,
    this.borderWidth = 2,
    this.borderRadius = 16,
    this.padding,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Container(
        margin: EdgeInsets.all(borderWidth),
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor ?? context.appColors.surface,
          borderRadius: BorderRadius.circular(borderRadius - borderWidth),
        ),
        child: child,
      ),
    );
  }
}

/// Animated Gradient Container
class AnimatedGradientContainer extends StatefulWidget {
  final Widget child;
  final List<Color> colors;
  final Duration duration;
  final double borderRadius;
  final EdgeInsets? padding;

  const AnimatedGradientContainer({
    super.key,
    required this.child,
    this.colors = const [
      Color(0xFFFF6B6B),
      Color(0xFFFF8E53),
      Color(0xFFEC4899),
      Color(0xFF8B5CF6),
    ],
    this.duration = const Duration(seconds: 3),
    this.borderRadius = 16,
    this.padding,
  });

  @override
  State<AnimatedGradientContainer> createState() =>
      _AnimatedGradientContainerState();
}

class _AnimatedGradientContainerState extends State<AnimatedGradientContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          padding: widget.padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              colors: widget.colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: [
                0.0 + _controller.value,
                0.33 + _controller.value,
                0.66 + _controller.value,
                1.0,
              ].map((s) => s > 1 ? s - 1 : s).toList(),
            ),
          ),
          child: widget.child,
        );
      },
    );
  }
}

/// Shimmer Effect Container
class ShimmerContainer extends StatefulWidget {
  final Widget child;
  final bool isLoading;
  final Color? baseColor;
  final Color? highlightColor;
  final Duration duration;

  ShimmerContainer({
    super.key,
    required this.child,
    this.isLoading = true,
    this.baseColor,
    this.highlightColor,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<ShimmerContainer> createState() => _ShimmerContainerState();
}

class _ShimmerContainerState extends State<ShimmerContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) return widget.child;

    final base = widget.baseColor ?? context.appColors.border;
    final highlight = widget.highlightColor ?? context.appColors.divider;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [
                base,
                highlight,
                base,
              ],
              stops: const [0.0, 0.5, 1.0],
              begin: Alignment(-1.0 + 2 * _controller.value, 0),
              end: Alignment(1.0 + 2 * _controller.value, 0),
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

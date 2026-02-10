import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

 
class AppBackButton extends StatelessWidget {
  const AppBackButton({
    super.key,
    this.onPressed,
    this.color,
    this.size = 24,
  });

   final VoidCallback? onPressed;

  /// Icon color. If null, uses theme's icon color.
  final Color? color;

  /// Icon size. Defaults to 24.
  final double size;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        Icons.arrow_back_ios_new,
        color: color ?? Theme.of(context).appBarTheme.iconTheme?.color,
        size: size,
      ),
      onPressed: onPressed ?? () => context.pop(),
    );
  }
}

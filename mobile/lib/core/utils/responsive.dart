import 'package:flutter/material.dart';

/// Breakpoints (logical pixels).
/// - Mobile: < 600 (phone)
/// - Tablet: 600 - 900 (iPad, small tablet)
/// - Desktop: >= 900 (> iPad, desktop)
class ResponsiveBreakpoints {
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 900;
}

/// Responsive layout helpers: breakpoints và công thức grid theo kích thước màn hình.
class ResponsiveLayout {
  ResponsiveLayout._();

  /// Chiều rộng màn hình (hoặc container).
  static double width(BuildContext context) {
    return MediaQuery.sizeOf(context).width;
  }

  /// Mobile: width < 600.
  static bool isMobile(BuildContext context) {
    return width(context) < ResponsiveBreakpoints.mobile;
  }

  /// Tablet: 600 <= width < 900 (iPad, tablet nhỏ).
  static bool isTablet(BuildContext context) {
    final w = width(context);
    return w >= ResponsiveBreakpoints.mobile && w < ResponsiveBreakpoints.tablet;
  }

  /// Desktop / > iPad: width >= 900.
  static bool isDesktop(BuildContext context) {
    return width(context) >= ResponsiveBreakpoints.tablet;
  }

  /// Số cột grid cho list/card: mobile = 1, còn lại tính theo [minCellWidth].
  /// Công thức: (width - horizontalPadding) / (minCellWidth + spacing) rồi floor, tối thiểu 1.
  /// [horizontalPadding] mặc định 40 (20*2), [spacing] khoảng cách giữa các cột.
  static int gridCrossAxisCount(
    BuildContext context, {
    double minCellWidth = 320,
    double horizontalPadding = 40,
    double spacing = 16,
    int maxColumns = 6,
  }) {
    final w = width(context);
    if (w < ResponsiveBreakpoints.mobile) return 1;
    final available = w - horizontalPadding;
    final cellWithSpacing = minCellWidth + spacing;
    final count = (available / cellWithSpacing).floor();
    return count.clamp(1, maxColumns);
  }

  /// Padding ngang theo breakpoint: mobile 20, tablet 24, desktop 32.
  static double horizontalPadding(BuildContext context) {
    final w = width(context);
    if (w < ResponsiveBreakpoints.mobile) return 20;
    if (w < ResponsiveBreakpoints.tablet) return 24;
    return 32;
  }

  /// Edge padding cho nội dung trang (theo breakpoint).
  static EdgeInsets pagePadding(BuildContext context) {
    final h = horizontalPadding(context);
    return EdgeInsets.symmetric(horizontal: h);
  }

  /// Max width nội dung trên màn hình lớn (để căn giữa, không kéo quá rộng).
  static double? contentMaxWidth(BuildContext context) {
    if (width(context) < ResponsiveBreakpoints.tablet) return null;
    return 1200;
  }
}

/// Wrapper căn nội dung giữa màn hình, dùng cho trang auth / form.
/// Trên tablet/desktop: giới hạn [maxContentWidth] và căn giữa; mobile: full width.
class ResponsiveCenterWrapper extends StatelessWidget {
  final Widget child;
  final double maxContentWidth;

  const ResponsiveCenterWrapper({
    super.key,
    required this.child,
    this.maxContentWidth = 440,
  });

  @override
  Widget build(BuildContext context) {
    if (!ResponsiveLayout.isDesktop(context) && !ResponsiveLayout.isTablet(context)) {
      return child;
    }
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxContentWidth),
        child: child,
      ),
    );
  }
}

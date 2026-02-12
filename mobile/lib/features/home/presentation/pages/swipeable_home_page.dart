import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ionicons/ionicons.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../booking/presentation/pages/bookings_page.dart';
import '../../../chat/presentation/pages/chat_list_page.dart';
import '../../../favorites/presentation/pages/favorites_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import 'home_page.dart';

/// Main page with liquid glass bottom navigation
class SwipeableHomePage extends StatefulWidget {
  final int initialPage;

  const SwipeableHomePage({super.key, this.initialPage = 0});

  @override
  State<SwipeableHomePage> createState() => _SwipeableHomePageState();
}

class _SwipeableHomePageState extends State<SwipeableHomePage>
    with SingleTickerProviderStateMixin {
  late int _currentIndex;
  late AnimationController _slideController;
  double _slideBegin = 0;
  double _slideEnd = 0;

  final List<Widget> _pages = const [
    HomePage(),
    FavoritesPage(),
    BookingsPage(),
    ChatListPage(),
    ProfilePage(),
  ];

  static const _icons = [
    (outline: Ionicons.home_outline, filled: Ionicons.home),
    (outline: Ionicons.heart_outline, filled: Ionicons.heart),
    (outline: Ionicons.calendar_outline, filled: Ionicons.calendar),
    (outline: Ionicons.chatbubble_outline, filled: Ionicons.chatbubble),
    (outline: Ionicons.person_outline, filled: Ionicons.person),
  ];

  @override
  void initState() {
    super.initState();
    switch (widget.initialPage) {
      case 0:
        _currentIndex = 2;
        break;
      case 2:
        _currentIndex = 4;
        break;
      default:
        _currentIndex = 0;
    }

    _slideBegin = _currentIndex.toDouble();
    _slideEnd = _currentIndex.toDouble();

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  double get _animatedPosition {
    final t = Curves.easeOutCubic.transform(_slideController.value);
    return lerpDouble(_slideBegin, _slideEnd, t)!;
  }

  void _onTabTap(int index) {
    if (index == _currentIndex) return;
    HapticFeedback.selectionClick();

    _slideBegin = _animatedPosition;
    _slideEnd = index.toDouble();
    _currentIndex = index;

    _slideController.forward(from: 0.0);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(index: _currentIndex, children: _pages),

          // ── Floating bottom nav ──
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.only(left: 20, right: 20, bottom: 8),
                child: LiquidGlass.withOwnLayer(
                  settings: LiquidGlassSettings(
                    blur: 4,
                    ambientStrength: 0.6,
                    lightAngle: 0.2 * math.pi,
                    glassColor: isDark
                        ? Colors.white10
                        : Colors.black.withAlpha(18),
                  ),
                  shape: LiquidRoundedSuperellipse(borderRadius: 40),
                  glassContainsChild: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 10,
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final tabWidth = constraints.maxWidth / 5;
                        return AnimatedBuilder(
                          animation: _slideController,
                          builder: (context, _) {
                            final pos = _animatedPosition;
                            const pillSize = 48.0;
                            final pillLeft =
                                pos * tabWidth + (tabWidth - pillSize) / 2;

                            return SizedBox(
                              height: pillSize,
                              child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // ── Sliding pill indicator ──
                                Positioned(
                                  left: pillLeft,
                                  top: 0,
                                  bottom: 0,
                                  width: pillSize,
                                  child: Center(
                                    child: _SlidingPill(
                                      size: pillSize,
                                      isDark: isDark,
                                    ),
                                  ),
                                ),
                                // ── Icons row ──
                                Row(
                                  children: List.generate(5, (i) {
                                    final distance = (pos - i).abs();
                                    final activeness =
                                        (1.0 - distance).clamp(0.0, 1.0);
                                    return Expanded(
                                      child: GestureDetector(
                                        onTap: () => _onTabTap(i),
                                        behavior: HitTestBehavior.opaque,
                                        child: _NavIcon(
                                          icon: activeness > 0.5
                                              ? _icons[i].filled
                                              : _icons[i].outline,
                                          activeness: activeness,
                                          isDark: isDark,
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                              ],
                            ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SlidingPill extends StatelessWidget {
  final double size;
  final bool isDark;

  const _SlidingPill({
    required this.size,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(
          color:
              (isDark ? Colors.white : AppColors.primary).withOpacity(0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(isDark ? 0.5 : 0.3),
            blurRadius: 20,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  final IconData icon;
  final double activeness;
  final bool isDark;

  const _NavIcon({
    required this.icon,
    required this.activeness,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = isDark ? Colors.white : AppColors.primary;
    final inactiveColor =
        isDark ? Colors.white60 : AppColors.textSecondary;
    final color = Color.lerp(inactiveColor, activeColor, activeness)!;
    final scale = 1.0 + 0.12 * activeness;
    final size = 24 + 2 * activeness;

    return Center(
      child: Transform.scale(
        scale: scale,
        child: Icon(icon, color: color, size: size),
      ),
    );
  }
}
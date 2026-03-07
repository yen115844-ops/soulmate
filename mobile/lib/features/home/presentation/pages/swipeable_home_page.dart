import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:ionicons/ionicons.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../shared/widgets/auth_guard.dart';
import '../../../booking/presentation/pages/bookings_page.dart';
import '../../../chat/presentation/pages/chat_list_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import 'home_page.dart';

/// Main page with a draggable liquid-glass bottom navigation bar.
///
/// The user can:
///  • Tap a tab icon to switch.
///  • Drag the glass pill horizontally on the nav bar – it stretches and
///    deforms with [RawLiquidStretch] during the gesture, then snaps to the
///    nearest tab with a spring simulation.
///  • Swipe left/right on the page content area via [PageView].
///
/// Both gestures stay in sync through a shared [PageController].
class SwipeableHomePage extends StatefulWidget {
  final int initialPage;

  const SwipeableHomePage({super.key, this.initialPage = 0});

  @override
  State<SwipeableHomePage> createState() => _SwipeableHomePageState();
}

class _SwipeableHomePageState extends State<SwipeableHomePage>
    with TickerProviderStateMixin {
  late int _currentIndex;
  late PageController _pageController;

  /// Continuous 0.0–3.0 position – drives both the pill X offset and icon
  /// activeness. Updated every frame by [_pageController] or by manual drag.
  double _pillPosition = 0.0;

  /// True while the user is dragging on the nav bar itself.
  /// While true we ignore [_pageController] updates to avoid feedback loops.
  bool _isDraggingBar = false;

  /// The horizontal drag offset in pixels accumulated during a bar drag.
  /// Used to compute [RawLiquidStretch] deformation.
  Offset _dragStretch = Offset.zero;

  /// Scale-up factor while the pill is being dragged (press-and-hold feel).
  double _pillScale = 1.0;

  /// Animation controller for snapping the pill after the user lifts the
  /// finger on the bar.
  AnimationController? _snapController;

  /// Animation controller for the stretch spring-back after release.
  late final AnimationController _stretchSpringController;

  // ── Pages ──────────────────────────────────────────────────────────────────

  List<Widget> get _pages {
    final isGuest = !AuthGuard.isAuthenticated;
    return [
      const _KeepAliveWrapper(child: HomePage()),
      _KeepAliveWrapper(
        child:
            isGuest ? const _AuthRequiredPlaceholder() : const BookingsPage(),
      ),
      _KeepAliveWrapper(
        child:
            isGuest ? const _AuthRequiredPlaceholder() : const ChatListPage(),
      ),
      const _KeepAliveWrapper(child: ProfilePage()),
    ];
  }

  // ── Icons ──────────────────────────────────────────────────────────────────

  static const _icons = [
    (outline: Ionicons.home_outline, filled: Ionicons.home),
    (outline: Ionicons.pulse_outline, filled: Ionicons.pulse),
    (outline: Ionicons.chatbubble_outline, filled: Ionicons.chatbubble),
    (outline: Ionicons.person_outline, filled: Ionicons.person),
  ];

  // ── Auth guards ────────────────────────────────────────────────────────────

  static const _authRequiredTabs = {1, 2};

  static const _authTabMessages = {
    1: 'Đăng nhập để xem và quản lý hoạt động.',
    2: 'Đăng nhập để nhắn tin với mọi người.',
  };

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    if (!AuthGuard.isAuthenticated) {
      _currentIndex = 0;
    } else {
      switch (widget.initialPage) {
        case 0:
          _currentIndex = 1;
          break;
        case 2:
          _currentIndex = 3;
          break;
        default:
          _currentIndex = 0;
      }
    }

    _pillPosition = _currentIndex.toDouble();
    _pageController = PageController(initialPage: _currentIndex);
    _pageController.addListener(_onPageScroll);

    _stretchSpringController = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageScroll);
    _pageController.dispose();
    _snapController?.dispose();
    _stretchSpringController.dispose();
    super.dispose();
  }

  // ── Page scroll sync ───────────────────────────────────────────────────────

  void _onPageScroll() {
    // Don't fight with the bar-drag gesture.
    if (_isDraggingBar) return;
    if (_pageController.page != null) {
      setState(() {
        _pillPosition = _pageController.page!;
      });
    }
  }

  void _onPageChanged(int index) {
    if (_isDraggingBar) return;
    // Guest swiped to auth-required tab: bounce back without showing modal.
    // Modal only on explicit tab tap (_onTabTap) to avoid spurious popups on tablet.
    if (_authRequiredTabs.contains(index) && !AuthGuard.isAuthenticated) {
      _pageController.animateToPage(
        _currentIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      HapticFeedback.heavyImpact();
      return;
    }
    HapticFeedback.selectionClick();
    setState(() => _currentIndex = index);
  }

  // ── Tab tap ────────────────────────────────────────────────────────────────

  void _onTabTap(int index) {
    if (index == _currentIndex) return;
    if (_authRequiredTabs.contains(index) && !AuthGuard.isAuthenticated) {
      HapticFeedback.heavyImpact();
      AuthGuard.requireAuth(
        context,
        onAuthenticated: () => _switchToTab(index),
        message: _authTabMessages[index],
      );
      return;
    }
    HapticFeedback.selectionClick();
    _switchToTab(index);
  }

  void _switchToTab(int index) {
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  // ── Bar drag gesture ───────────────────────────────────────────────────────

  /// Called once when the user presses down on the nav bar.
  void _onBarDragStart(double barWidth) {
    _snapController?.stop();
    _isDraggingBar = true;
    _dragStretch = Offset.zero;
    _pillScale = 1.12; // slight press scale-up
    HapticFeedback.selectionClick();
    setState(() {});
  }

  /// Called every pointer-move while dragging on the bar.
  void _onBarDragUpdate(double dx, double barWidth) {
    final tabWidth = barWidth / 4;
    final positionDelta = dx / tabWidth;
    final newPos = (_pillPosition + positionDelta).clamp(0.0, 3.0);

    // Build stretch offset from velocity (dx per frame).
    // Resistance makes it feel natural – large drags are dampened.
    const resistance = 0.06;
    final rawStretch = Offset(dx * 0.6, 0);
    _dragStretch = rawStretch.withResistance(resistance);

    setState(() {
      _pillPosition = newPos;
    });
  }

  /// Called when the finger lifts off the bar.
  void _onBarDragEnd(double velocity, double barWidth) {
    // Keep _isDraggingBar = true so _onPageScroll doesn't fight the snap.
    _pillScale = 1.0;

    // ── Spring-back the stretch to zero ──
    _animateStretchToZero();

    // ── Determine target tab ──
    final tabWidth = barWidth / 4;
    int target = _pillPosition.round().clamp(0, 3);

    // If flicking fast, bias toward the fling direction.
    if (velocity.abs() > 300) {
      if (velocity > 0 && target < 3) target++;
      if (velocity < 0 && target > 0) target--;
    }

    // Auth guard check.
    if (_authRequiredTabs.contains(target) && !AuthGuard.isAuthenticated) {
      target = _currentIndex;
    }

    setState(() => _currentIndex = target);

    // ── Spring animation to target position ──
    // _isDraggingBar stays true until this completes, so PageController
    // listener doesn't reset _pillPosition.
    _animateSnapTo(target.toDouble(), velocity / (tabWidth * 4), () {
      // Snap finished – jump PageView and release the drag lock.
      _isDraggingBar = false;
      _pageController.jumpToPage(target);
    });

    HapticFeedback.selectionClick();
  }

  /// Runs a spring simulation to move [_pillPosition] → [targetPos].
  /// Calls [onComplete] once the spring settles.
  void _animateSnapTo(
      double targetPos, double velocity, VoidCallback onComplete) {
    _snapController?.dispose();
    _snapController = AnimationController.unbounded(
      value: _pillPosition,
      vsync: this,
    );

    const spring = SpringDescription(mass: 1, stiffness: 350, damping: 28);
    final simulation =
        SpringSimulation(spring, _pillPosition, targetPos, velocity);

    _snapController!.addListener(() {
      setState(() {
        _pillPosition = _snapController!.value.clamp(0.0, 3.0);
      });
    });

    _snapController!.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        onComplete();
      }
    });

    _snapController!.animateWith(simulation);
  }

  /// Animates [_dragStretch] back to [Offset.zero] with a spring.
  void _animateStretchToZero() {
    final startStretch = _dragStretch;
    const spring = SpringDescription(mass: 0.8, stiffness: 300, damping: 18);
    final sim = SpringSimulation(spring, 0.0, 1.0, 0.0);

    _stretchSpringController
      ..reset()
      ..animateWith(sim);

    void listener() {
      final t = _stretchSpringController.value.clamp(0.0, 1.0);
      setState(() {
        _dragStretch = Offset.lerp(startStretch, Offset.zero, t)!;
      });
    }

    _stretchSpringController.addListener(listener);

    // Clean up when done.
    late AnimationStatusListener statusListener;
    statusListener = (AnimationStatus status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        _stretchSpringController.removeListener(listener);
        _stretchSpringController.removeStatusListener(statusListener);
      }
    };
    _stretchSpringController.addStatusListener(statusListener);
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Scaffold(
      body: Stack(
        children: [
          // ── Swipeable page content ──
          PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            children: _pages,
          ),

          // ── Floating bottom nav ──
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 8),
              child: _LiquidGlassNavBar(
                position: _pillPosition,
                icons: _icons,
                isDark: isDark,
                onTabTap: _onTabTap,
                onDragStart: _onBarDragStart,
                onDragUpdate: _onBarDragUpdate,
                onDragEnd: _onBarDragEnd,
                dragStretch: _dragStretch,
                pillScale: _pillScale,
                isDragging: _isDraggingBar,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Liquid Glass Bottom Navigation Bar
// ─────────────────────────────────────────────────────────────────────────────

class _LiquidGlassNavBar extends StatelessWidget {
  final double position;
  final List<({IconData outline, IconData filled})> icons;
  final bool isDark;
  final ValueChanged<int> onTabTap;

  // Bar-drag callbacks.
  final void Function(double barWidth) onDragStart;
  final void Function(double dx, double barWidth) onDragUpdate;
  final void Function(double velocity, double barWidth) onDragEnd;

  /// Current stretch deformation offset for the pill.
  final Offset dragStretch;

  /// Current press scale of the pill (1.0 = normal, ~1.12 while pressed).
  final double pillScale;

  /// Whether the user is actively dragging on the bar.
  final bool isDragging;

  const _LiquidGlassNavBar({
    required this.position,
    required this.icons,
    required this.isDark,
    required this.onTabTap,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.dragStretch,
    required this.pillScale,
    required this.isDragging,
  });

  @override
  Widget build(BuildContext context) {
    const pillSize = 48.0;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.card,
        borderRadius: BorderRadius.circular(40),
        border: isDark
            ? Border.all(color: AppColors.borderDark, width: 0.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: isDark ? AppColors.shadowDark : AppColors.shadow,
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final barWidth = constraints.maxWidth;
          final tabWidth = barWidth / 4;
          final pillLeft =
              position * tabWidth + (tabWidth - pillSize) / 2;

          return GestureDetector(
            // ── Horizontal drag on the entire bar ──
            onHorizontalDragStart: (_) => onDragStart(barWidth),
            onHorizontalDragUpdate: (d) =>
                onDragUpdate(d.delta.dx, barWidth),
            onHorizontalDragEnd: (d) =>
                onDragEnd(d.primaryVelocity ?? 0, barWidth),
            behavior: HitTestBehavior.translucent,
            child: SizedBox(
              height: pillSize,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  // ── Liquid-glass pill with stretch ──
                  Positioned(
                    left: pillLeft,
                    top: 0,
                    width: pillSize,
                    height: pillSize,
                    child: _AnimatedGlassPill(
                      pillSize: pillSize,
                      isDark: isDark,
                      stretch: dragStretch,
                      scale: pillScale,
                      isDragging: isDragging,
                    ),
                  ),

                  // ── Icons row ──
                  Row(
                    children: List.generate(4, (i) {
                      final distance = (position - i).abs();
                      final activeness =
                          (1.0 - distance).clamp(0.0, 1.0);
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => onTabTap(i),
                          behavior: HitTestBehavior.opaque,
                          child: _NavIcon(
                            icon: activeness > 0.5
                                ? icons[i].filled
                                : icons[i].outline,
                            activeness: activeness,
                            isDark: isDark,
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Animated Glass Pill with Liquid Stretch
// ─────────────────────────────────────────────────────────────────────────────

/// The active-tab indicator.
///
/// Uses [LiquidGlass] for the frosted-glass look, [RawLiquidStretch] so the
/// pill deforms when dragged, and an animated scale for the press-down feel.
class _AnimatedGlassPill extends StatelessWidget {
  final double pillSize;
  final bool isDark;
  final Offset stretch;
  final double scale;
  final bool isDragging;

  const _AnimatedGlassPill({
    required this.pillSize,
    required this.isDark,
    required this.stretch,
    required this.scale,
    required this.isDragging,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: scale,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      child: RawLiquidStretch(
        stretchPixels: stretch,
        child: LiquidGlass.withOwnLayer(
          settings: LiquidGlassSettings(
            blur: isDragging ? 10 : 8,
            ambientStrength: isDark ? 1.0 : 0.8,
            lightAngle: 0.25 * math.pi,
            lightIntensity: isDark ? 0.4 : 0.55,
            glassColor: isDark
                ? AppColors.primaryDark.withValues(alpha: 0.35)
                : AppColors.primary.withValues(alpha: 0.18),
            thickness: isDragging ? 26 : 22,
            saturation: isDark ? 1.8 : 1.4,
          ),
          shape: LiquidRoundedSuperellipse(
            borderRadius: pillSize / 2,
          ),
          glassContainsChild: false,
          child: Container(
            width: pillSize,
            height: pillSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? AppColors.primaryDark
                          .withValues(alpha: isDragging ? 0.6 : 0.45)
                      : AppColors.primary
                          .withValues(alpha: isDragging ? 0.25 : 0.18),
                  blurRadius: isDragging ? 20 : 14,
                  spreadRadius: isDragging ? 2 : 1,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Nav Icon
// ─────────────────────────────────────────────────────────────────────────────

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
    final activeColor = isDark ? AppColors.primaryLight : AppColors.primary;
    final inactiveColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
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

// ─────────────────────────────────────────────────────────────────────────────
// Helper widgets
// ─────────────────────────────────────────────────────────────────────────────

/// Keeps a child alive inside [PageView] so scroll positions and other
/// state are preserved when swiping away.
class _KeepAliveWrapper extends StatefulWidget {
  final Widget child;
  const _KeepAliveWrapper({required this.child});

  @override
  State<_KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<_KeepAliveWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

/// Lightweight placeholder shown for guest users at auth-required tabs.
/// This prevents auth-required pages from being built and firing API calls.
class _AuthRequiredPlaceholder extends StatelessWidget {
  const _AuthRequiredPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

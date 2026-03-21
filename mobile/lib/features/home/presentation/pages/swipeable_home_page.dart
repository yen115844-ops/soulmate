import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/auth_guard.dart';
import '../../../booking/presentation/pages/bookings_page.dart';
import '../../../chat/presentation/pages/chat_list_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import 'home_page.dart';

/// Main page with swipeable content and a standard bottom navigation bar.
class SwipeableHomePage extends StatefulWidget {
  final int initialPage;

  const SwipeableHomePage({super.key, this.initialPage = 0});

  @override
  State<SwipeableHomePage> createState() => _SwipeableHomePageState();
}

class _SwipeableHomePageState extends State<SwipeableHomePage> {
  late int _currentIndex;
  late PageController _pageController;

  // ── Pages ──────────────────────────────────────────────────────────────────

  List<Widget> get _pages {
    final isGuest = !AuthGuard.isAuthenticated;
    return [
      const _KeepAliveWrapper(child: HomePage()),
      _KeepAliveWrapper(
        child: isGuest
            ? const _AuthRequiredPlaceholder()
            : const BookingsPage(),
      ),
      _KeepAliveWrapper(
        child: isGuest
            ? const _AuthRequiredPlaceholder()
            : const ChatListPage(),
      ),
      const _KeepAliveWrapper(child: ProfilePage()),
    ];
  }

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

    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
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

  @override
  Widget build(BuildContext context) {
    final navTheme = Theme.of(context).copyWith(
      splashFactory: NoSplash.splashFactory,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
    );

    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: _pages,
      ),
      bottomNavigationBar: Theme(
        data: navTheme,
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTap,
          enableFeedback: false,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Ionicons.home_outline),
              activeIcon: Icon(Ionicons.home),
              label: 'Trang chủ',
            ),
            BottomNavigationBarItem(
              icon: Icon(Ionicons.pulse_outline),
              activeIcon: Icon(Ionicons.pulse),
              label: 'Hoạt động',
            ),
            BottomNavigationBarItem(
              icon: Icon(Ionicons.chatbubbles),
              activeIcon: Icon(Ionicons.chatbubble),
              label: 'Tin nhắn',
            ),
            BottomNavigationBarItem(
              icon: Icon(Ionicons.person_outline),
              activeIcon: Icon(Ionicons.person_outline),
              label: 'Hồ sơ',
            ),
          ],
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
        ),
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

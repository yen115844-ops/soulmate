import 'package:flutter/material.dart';

import '../../../booking/presentation/pages/bookings_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import 'home_page.dart';

/// Trang chính có thể swipe giữa Bookings - Home - Settings
/// Note: HomePage tự quản lý BlocProvider nên không cần wrap thêm
class SwipeableHomePage extends StatefulWidget {
  /// Initial page index: 0 = Bookings, 1 = Home, 2 = Profile
  final int initialPage;
  
  const SwipeableHomePage({super.key, this.initialPage = 1});

  @override
  State<SwipeableHomePage> createState() => _SwipeableHomePageState();
}

class _SwipeableHomePageState extends State<SwipeableHomePage> {
  late PageController _pageController;
  int _currentPage = 1; // Bắt đầu từ trang Home (giữa)

  final List<Widget> _pages = const [
    BookingsPage(), // Trang 0 - Kéo từ trái sang phải
    HomePage(), // Trang 1 - Trang chủ (giữa)
    ProfilePage(), // Trang 2 - Kéo từ phải sang trái
  ];

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    _pageController = PageController(initialPage: widget.initialPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // PageView cho swipe navigation
          PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            physics: const BouncingScrollPhysics(),
            children: _pages,
          ),

        
        ],
      ),
    );
  }
 
}

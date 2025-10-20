import 'package:flutter/material.dart';
import 'swipe_screen.dart';
import '../widgets/liquid_nav_bar.dart';
import 'library_screen.dart';
import 'settings_screen.dart';

class MainScreen extends StatefulWidget {
  final AnimationController transitionController;
  final ValueNotifier<int> currentPageNotifier;

  const MainScreen({
    super.key,
    required this.transitionController,
    required this.currentPageNotifier,
  });

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    widget.transitionController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageSwiped(int page) {
    // When the user swipes, we update the central state
    widget.currentPageNotifier.value = page;
  }

  void _onNavItemTapped(int index) {
    if (widget.currentPageNotifier.value == index) return;
    
    // When a nav item is tapped, we also update the central state.
    widget.currentPageNotifier.value = index;

    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: _onPageSwiped,
            children: const [
              SwipeHomePage(),
              LibraryScreen(),
              Center(child: Text("Likes Page", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold))),
              SettingsScreen(),
            ],
          ),
          Align(
            alignment: Alignment.bottomCenter,
        
            child: ValueListenableBuilder<int>(
              valueListenable: widget.currentPageNotifier,
              builder: (context, currentPage, child) {
                return LiquidNavBar(
                  selectedIndex: currentPage,
                  onTabTapped: _onNavItemTapped,
                  animation: widget.transitionController.view,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

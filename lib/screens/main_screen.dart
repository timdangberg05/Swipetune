import 'dart:async';
import 'package:flutter/material.dart';
import 'swipe_screen.dart';
import '../widgets/liquid_nav_bar.dart';
import '../widgets/header_scroll_handler.dart';
import 'library_screen.dart';
import 'settings_screen.dart';

class MainScreen extends StatefulWidget {
  final AnimationController transitionController;
  final ValueNotifier<int> currentPageNotifier;
  final ScrollController? sharedScrollController;

  const MainScreen({
    super.key,
    required this.transitionController,
    required this.currentPageNotifier,
    this.sharedScrollController,
  });

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final PageController _pageController = PageController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;
  bool _isAnimatingToPage = false;
  int? _targetPage;

  @override
  void initState() {
    super.initState();
    widget.transitionController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
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
          PageView.builder(
            controller: _pageController,
            onPageChanged: _onPageSwiped,
            itemCount: 4,
            itemBuilder: (context, index) {
              switch (index) {
                case 0:
                  return const SwipeHomePage();
                case 1:
                  return LibraryScreen(scrollController: widget.sharedScrollController ?? _scrollController);
                case 2:
                  return const Center(child: Text("Likes Page", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)));
                case 3:
                  return SettingsScreen(scrollController: widget.sharedScrollController ?? _scrollController);
                default:
                  return const SizedBox();
              }
            },
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

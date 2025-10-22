import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'swipe_screen.dart';
import '../widgets/liquid_nav_bar.dart';
import '../widgets/header_scroll_handler.dart';
import '../widgets/liquid_background.dart';
import '../widgets/logo_choreographer.dart';
import '../providers/spotify_data_provider.dart';
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

ValueNotifier<double> navBarProgressNotifier = ValueNotifier<double>(0.0);

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;
  late AnimationController _navBarController;
  late Animation<Offset> _navBarAnimation;
  late AnimationController _backgroundTimeController;
  late AnimationController _dummyIntroController;
  late AnimationController _dummySpotifyController;
  late AnimationController _dummyAuthController;
  final ValueNotifier<Offset?> _spotifyLogoCenterNotifier = ValueNotifier(null);
  bool _isAnimatingToPage = false;
  int? _targetPage;
  bool _isNavBarVisible = true;
  double _lastScrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    widget.transitionController.forward();

    // Initialize background animation controller
    _backgroundTimeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 100),
    )..repeat();

    // Initialize dummy controllers for LogoChoreographer (already in home state)
    _dummyIntroController = AnimationController(vsync: this, value: 1.0);
    _dummySpotifyController = AnimationController(vsync: this, value: 0.0);
    _dummyAuthController = AnimationController(vsync: this, value: 0.0);

    // Aufbau Animation Controller für Navbar - More responsive like Dynamic Island
    _navBarController = AnimationController(
      duration: const Duration(milliseconds: 100), // Faster response
      vsync: this,
    );

    _navBarAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0.0, 1.0),
    ).animate(CurvedAnimation(
      parent: _navBarController,
      curve: Curves.fastOutSlowIn, // More dynamic curve like Dynamic Island
    ));


    // Listener for page changes to reset navbar visibility on certain pages
    widget.currentPageNotifier.addListener(_onPageChanges);

    // Sync navbar controller with navBarProgressNotifier from settings screen
    navBarProgressNotifier.addListener(_onNavProgressChanged);
  }



  void _hideNavBar() {
    setState(() {
      _isNavBarVisible = false;
    });
    _navBarController.forward();
  }

  void _showNavBar() {
    setState(() {
      _isNavBarVisible = true;
    });
    _navBarController.reverse();
  }

  void _onPageChanges() {
    int page = widget.currentPageNotifier.value;
    // Bei Page-Wechsel, Navbar immer wieder zeigen (außer evtl. bei Settings wenn scrolled)
    // Für Settings, starten wir als sichtbar
    if (page == 3) {
      _navBarController.animateTo(0.0, duration: Duration(milliseconds: 300));
    } else {
      _navBarController.animateTo(0.0, duration: Duration(milliseconds: 300));
    }
  }

  void _onNavProgressChanged() {
    _navBarController.value = navBarProgressNotifier.value;
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
  void dispose() {
    widget.currentPageNotifier.removeListener(_onPageChanges);
    navBarProgressNotifier.removeListener(_onNavProgressChanged);
    _navBarController.dispose();
    _backgroundTimeController.dispose();
    _dummyIntroController.dispose();
    _dummySpotifyController.dispose();
    _dummyAuthController.dispose();
    _scrollController.dispose();
    _pageController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SpotifyDataProvider>();
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Add LiquidGlassBackground for the swipe screen
          LiquidGlassBackground(
            time: _backgroundTimeController,
            colorTransitionValue: AlwaysStoppedAnimation(0.0),
            spotifyLogoCenterNotifier: _spotifyLogoCenterNotifier,
            swipeActionNotifier: provider.swipeActionNotifier,
            homeTransitionController: widget.transitionController,
          ),
          NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification notification) {
              if (notification is ScrollUpdateNotification &&
                  widget.currentPageNotifier.value == 3 &&
                  notification.metrics.axis == Axis.vertical) {
                final offset = notification.metrics.pixels;
                final delta = offset - _lastScrollOffset;
                if (_navBarController.isAnimating) _navBarController.stop();
                // Up scroll (negative delta) increases hide progress (navBar moves down)
                if (delta < 0) {
                  _navBarController.value = (_navBarController.value + delta.abs() * 0.05).clamp(0.0, 1.0);
                } else if (delta > 0) {
                  // Down scroll decreases hide progress (navBar moves up)
                  _navBarController.value = (_navBarController.value - delta * 0.05).clamp(0.0, 1.0);
                }
                _lastScrollOffset = offset;
                navBarProgressNotifier.value = _navBarController.value;
              }
              return false;
            },
            child: PageView.builder(
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
                    return SettingsScreen(scrollController: widget.sharedScrollController ?? _scrollController, navBarProgress: navBarProgressNotifier);
                  default:
                    return const SizedBox();
                }
              },
            ),
          ),
          // Add back the header
          LogoChoreographer(
            introController: _dummyIntroController,
            spotifyController: _dummySpotifyController,
            authController: _dummyAuthController,
            homeController: widget.transitionController,
            onCancelSpotify: () {},
            currentPageNotifier: widget.currentPageNotifier,
            scrollController: widget.sharedScrollController ?? _scrollController,
          ),
          SlideTransition(
            position: _navBarAnimation,
            child: Align(
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
          ),
        ],
      ),
    );
  }
}

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
    // Wenn eine Tap-Animation läuft, ignorieren wir alle Zwischen-Events
    if (_isAnimatingToPage) {
      // ABER: Wenn der User während der Animation manuell wischt,
      // müssen wir die Animation abbrechen.
      if (_targetPage != null && page != _targetPage) {
        _isAnimatingToPage = false;
        _targetPage = null;
      } else {
        // Ist es die Zielseite? Dann Animation beenden.
        if (_targetPage == page) {
          _isAnimatingToPage = false;
          _targetPage = null;
        }
        return; // Event ignorieren
      }
    }

    // Wenn schon ein Timer läuft, brich ihn ab.
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    // Starte einen neuen, kurzen Timer.
    // Nur wenn 50ms lang *kein neuer* Seitenwechsel reinkommt,
    // wird der Wert tatsächlich gesetzt.
    _debounce = Timer(const Duration(milliseconds: 50), () {
      // Verhindern, dass der ValueNotifier während einer Tap-Animation aktualisiert wird
      // Dies soll Header-Flickering beim NavBar-Tap verhindern
      if (mounted && !_isAnimatingToPage) {
        widget.currentPageNotifier.value = page;
      }
    });
  }

  void _onNavItemTapped(int index) {
    if (widget.currentPageNotifier.value == index) return;
    
    // Beim Tappen wollen wir die Logik beibehalten,
    // aber den Debounce-Timer abbrechen.
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    // Setze das Flag und die Zielseite
    _isAnimatingToPage = true;
    _targetPage = index;
    
    // Sofort den Header aktualisieren
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

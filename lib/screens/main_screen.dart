import 'dart:async';
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

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'swipe_screen.dart';
import '../widgets/liquid_nav_bar.dart';
// import '../widgets/header_scroll_handler.dart'; // HeaderScrollHandler wird jetzt vom LogoChoreographer übernommen
import '../widgets/liquid_background.dart';
import '../widgets/logo_choreographer.dart';
import '../widgets/library/library_header_choreographer.dart';
import '../providers/spotify_data_provider.dart';
import 'library_screen.dart';
import 'settings_screen.dart';

// Stelle sicher, dass SwipeAction definiert ist (z.B. in spotify_data_provider.dart)
// enum SwipeAction { like, dislike }

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

// ValueNotifier für den Navbar-Fortschritt (kann global oder hier sein)
ValueNotifier<double> navBarProgressNotifier = ValueNotifier<double>(0.0);

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  // Verwende sharedScrollController, wenn vorhanden, sonst einen lokalen
  late ScrollController _scrollController;
  Timer? _debounce;
  late AnimationController _navBarController;
  late Animation<Offset> _navBarAnimation;
  late AnimationController _backgroundTimeController;

  // Dummy-Controller für LogoChoreographer im Home-Zustand
  late AnimationController _dummyIntroController;
  late AnimationController _dummySpotifyController;
  late AnimationController _dummyAuthController;
  late AnimationController _dummySpotifySuccessController; // *** HIER KORRIGIERT ***

  // Library Morph Controller
  late AnimationController _libraryMorphController;
  final ValueNotifier<bool> isLibraryDetailVisible = ValueNotifier(false);

  final ValueNotifier<Offset?> _spotifyLogoCenterNotifier = ValueNotifier(null);
  bool _isAnimatingToPage = false;
  int? _targetPage;
  // bool _isNavBarVisible = true; // Wird jetzt durch _navBarController.value gesteuert
  double _lastScrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    // Verwende sharedScrollController oder erstelle einen neuen
    _scrollController = widget.sharedScrollController ?? ScrollController();

    // widget.transitionController.forward(); // Wird bereits im LandingScreen gestartet

    _backgroundTimeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 100),
    )..repeat();

    // Dummy-Controller initialisieren
    _dummyIntroController = AnimationController(vsync: this, value: 1.0); // Intro ist fertig
    _dummySpotifyController = AnimationController(vsync: this, value: 0.0); // Spotify nicht aktiv
    _dummyAuthController = AnimationController(vsync: this, value: 0.0); // Auth nicht aktiv
    _dummySpotifySuccessController = AnimationController(vsync: this, value: 0.0); // Success nicht aktiv *** HIER KORRIGIERT ***

    // Library Morph Controller initialisieren
    _libraryMorphController = AnimationController(
      duration: const Duration(milliseconds: 600), // Dauer für das Aufsteigen
      vsync: this,
    );

    _navBarController = AnimationController(
      duration: const Duration(milliseconds: 100), // Schnellere Reaktion
      vsync: this,
    );

    _navBarAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0.0, 1.0), // Nach unten ausblenden
    ).animate(CurvedAnimation(
      parent: _navBarController,
      curve: Curves.fastOutSlowIn,
    ));

    widget.currentPageNotifier.addListener(_onPageChanges);
    navBarProgressNotifier.addListener(_onNavProgressChanged);
  }

  void _onPageChanges() {
    int page = widget.currentPageNotifier.value;
    // Wenn die Seite wechselt UND der PageController nicht bereits auf dieser Seite ist
    if (_pageController.hasClients && (_pageController.page?.round() ?? 0) != page) {
      _pageController.animateToPage(
        page,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    }
     // Navbar beim Seitenwechsel immer anzeigen (außer evtl. bei Settings)
     // Wenn die Seite NICHT Settings ist, zeige die Navbar sofort an
     if (page != 3) {
        _showNavBar();
     } else {
       // Wenn es Settings ist, setze den Fortschritt basierend auf dem aktuellen Scroll-Offset zurück
       _navBarController.value = navBarProgressNotifier.value;
     }
  }

  void _onNavProgressChanged() {
    // Nur aktualisieren, wenn die aktuelle Seite Settings ist
    if (widget.currentPageNotifier.value == 3) {
      _navBarController.value = navBarProgressNotifier.value;
    }
  }

  void _showNavBar() {
    if (_navBarController.status != AnimationStatus.dismissed) {
      _navBarController.reverse();
    }
  }

  void _hideNavBar() {
     if (_navBarController.status != AnimationStatus.completed) {
      _navBarController.forward();
    }
  }


  // Wird vom PageView aufgerufen, wenn der Benutzer wischt
  void _onPageSwiped(int page) {
    // Aktualisiere den zentralen Notifier, wenn der Benutzer wischt
    if (widget.currentPageNotifier.value != page) {
        widget.currentPageNotifier.value = page;
         // _onPageChanges wird dadurch ausgelöst und kümmert sich um die Navbar
    }
  }

  // Wird aufgerufen, wenn auf ein Navigationsleisten-Item getippt wird
  void _onNavItemTapped(int index) {
    if (widget.currentPageNotifier.value == index) return;
    // Aktualisiere den zentralen Notifier, dies löst _onPageChanges aus
    widget.currentPageNotifier.value = index;
     // _onPageChanges kümmert sich um das Blättern im PageView und die Navbar
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
    _dummySpotifySuccessController.dispose(); // *** HIER KORRIGIERT ***
    _libraryMorphController.dispose();
    // Nur den lokalen ScrollController entsorgen, wenn er erstellt wurde
    if (widget.sharedScrollController == null) {
      _scrollController.dispose();
    }
    _pageController.dispose();
    _debounce?.cancel();
    _spotifyLogoCenterNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Den Provider sicher abrufen
    SpotifyDataProvider? provider;
    try {
      provider = context.watch<SpotifyDataProvider>();
    } catch(e) {
      provider = null; // Falls Provider noch nicht bereit
    }


    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // LiquidGlassBackground für den Home-Zustand
          LiquidGlassBackground(
            time: _backgroundTimeController,
            colorTransitionValue: const AlwaysStoppedAnimation(0.0), // Keine Farbtransition hier
            spotifyLogoCenterNotifier: _spotifyLogoCenterNotifier,
            // SwipeNotifier nur übergeben, wenn Provider existiert
            swipeActionNotifier: provider?.swipeActionNotifier,
            homeTransitionController: widget.transitionController.view, // .view für Animation<double>
             // backgroundMorphController nicht benötigt hier, kann null sein
            libraryMorphAnimation: _libraryMorphController.view,
          ),

          // Scroll-Listener für Navbar in Settings
          NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification notification) {
              // Nur auf ScrollUpdates auf der Settings-Seite (Index 3) reagieren
              if (notification is ScrollUpdateNotification &&
                  widget.currentPageNotifier.value == 3 &&
                  notification.metrics.axis == Axis.vertical) {

                final offset = notification.metrics.pixels;
                final delta = offset - _lastScrollOffset;
                // Verhindere Sprünge während der Animation
                 if (_navBarController.isAnimating) _navBarController.stop();

                // Scrollen nach unten (delta > 0) -> Navbar verstecken (value -> 1.0)
                if (delta > 0 && offset > 10) { // Kleine Toleranz am Anfang
                   _navBarController.value = (_navBarController.value + delta * 0.005).clamp(0.0, 1.0);
                }
                // Scrollen nach oben (delta < 0) -> Navbar zeigen (value -> 0.0)
                else if (delta < 0) {
                   _navBarController.value = (_navBarController.value + delta * 0.005).clamp(0.0, 1.0);
                }

                _lastScrollOffset = offset;
                // Synchronisiere den externen Notifier
                navBarProgressNotifier.value = _navBarController.value;
              }
               // Falls der User ganz nach oben scrollt in Settings
               else if (notification is ScrollEndNotification && widget.currentPageNotifier.value == 3 && notification.metrics.pixels <= 10) {
                 _showNavBar();
                 navBarProgressNotifier.value = 0.0;
               }
              return false; // Weiterleiten der Notification
            },
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageSwiped,
              itemCount: 4, // Anzahl der Seiten
              itemBuilder: (context, index) {
                switch (index) {
                  case 0:
                    return const SwipeHomePage();
                  case 1:
                    // LibraryScreen erhält den ScrollController
                    return LibraryScreen(
                      scrollController: _scrollController, 
                      libraryMorphController: _libraryMorphController,
                      isDetailViewNotifier: isLibraryDetailVisible, // <-- NEU
                    );
                  case 2:
                    // TODO: Likes Page implementieren
                    return const Center(child: Text("Likes Page", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)));
                  case 3:
                    // SettingsScreen erhält den ScrollController und den Navbar-Notifier
                    return SettingsScreen(scrollController: _scrollController, navBarProgress: navBarProgressNotifier);
                  default:
                    return const SizedBox.shrink(); // Fallback
                }
              },
            ),
          ),

          // Logo/Header Choreographer
          ValueListenableBuilder<bool>(
            valueListenable: isLibraryDetailVisible,
            builder: (context, isDetailVisible, child) {
              return IgnorePointer(
                ignoring: isDetailVisible,
                child: AnimatedOpacity(
                  opacity: isDetailVisible ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  child: child,
                ),
              );
            },
            child: LogoChoreographer(
              introController: _dummyIntroController,
              spotifyController: _dummySpotifyController,
              spotifySuccessController: _dummySpotifySuccessController,
              authController: _dummyAuthController,
              homeController: widget.transitionController,
              onCancelSpotify: () {},
              currentPageNotifier: widget.currentPageNotifier,
              scrollController: _scrollController,
            ),
          ),

          // Animierte Navigationsleiste
          SlideTransition(
            position: _navBarAnimation,
            child: Align(
              alignment: Alignment.bottomCenter,
              // Höre auf den zentralen currentPageNotifier, um die Auswahl zu aktualisieren
              child: ValueListenableBuilder<int>(
                valueListenable: widget.currentPageNotifier,
                builder: (context, currentPage, child) {
                  return LiquidNavBar(
                    selectedIndex: currentPage,
                    onTabTapped: _onNavItemTapped,
                    animation: widget.transitionController.view,
                    // Die Animation der Navbar selbst wird nicht mehr benötigt hier
                    // animation: widget.transitionController.view, // Entfernt
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

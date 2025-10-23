import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui'; // Für lerpDouble
import 'package:flutter/physics.dart'; // Für SpringSimulation
import 'package:just_audio/just_audio.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:swipetune/screens/songdetails.dart';
import '../providers/spotify_data_provider.dart';
import '../widgets/song_card.dart';
import '../widgets/stacked_card.dart';
import '../widgets/empty_state.dart'; // Add EmptyState import
import '../models/firebasemodels/firebase_track_model.dart';
import '../services/discovery_service.dart';
import '../utils/local_preferences_storage.dart';
import '../API/firebase_client.dart';
import '../API/SpotifyApiClient.dart';

class SwipeHomePage extends StatefulWidget {
  const SwipeHomePage({super.key});

  @override
  _SwipeHomePageState createState() => _SwipeHomePageState();
}

class _SwipeHomePageState extends State<SwipeHomePage> with TickerProviderStateMixin {

  late AnimationController _cardAnimationController;
  double _screenWidth = 0;
  final List<FirebaseTrack> _trackQueue = [];
  bool _isQueueInitialized = false;

  // --- NEUER ZENTRALER PLAYER ---
  late final AudioPlayer _audioPlayer;
  late DiscoveryService _discoveryService;
  StreamSubscription<PlayerState>? _playerStateSubscription;
  bool _currentPlayerIsPlaying = false;
  // --- ENDE NEU ---

  @override
  void initState() {
    super.initState();

    _cardAnimationController = AnimationController(
      vsync: this,
      lowerBound: -1.0,
      upperBound: 1.0,
      value: 0.0,
      duration: const Duration(milliseconds: 300),
    );

    _cardAnimationController.addListener(_onAnimationUpdate);

    // --- PLAYER INITIALISIEREN ---
    _audioPlayer = AudioPlayer(
      audioLoadConfiguration: AudioLoadConfiguration(
        androidLoadControl: AndroidLoadControl(
          minBufferDuration: const Duration(seconds: 5),
          maxBufferDuration: const Duration(seconds: 10),
          bufferForPlaybackDuration: const Duration(seconds: 2),
          prioritizeTimeOverSizeThresholds: true,
        ),
        darwinLoadControl: DarwinLoadControl(
          automaticallyWaitsToMinimizeStalling: true,
          preferredForwardBufferDuration: const Duration(seconds: 5),
        ),
      ),
    );
    // _discoveryService wird später in didChangeDependencies oder bei Bedarf geholt
    _listenToPlayerState(); // Listener für Play/Pause-Status starten
    // --- ENDE PLAYER ---

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _screenWidth = MediaQuery.of(context).size.width;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // --- ANGEPASSTE INITIALISIERUNG ---
    // Läuft nur EINMAL, wenn die Queue noch nicht initialisiert ist.
    if (!_isQueueInitialized) {
      final provider = context.watch<SpotifyDataProvider>();

      // Hol den DiscoveryService hier, da context jetzt sicher ist
      // Stelle sicher, dass DiscoveryService im Provider-Setup in main.dart verfügbar ist
      try {
        _discoveryService = context.read<DiscoveryService>();
      } catch (e) {
        print("🚨 FEHLER: DiscoveryService konnte nicht aus context gelesen werden! Ist er in main.dart registriert? $e");
        // Handle den Fehler, z.B. durch Anzeigen einer Fehlermeldung
        return; // Verhindert weiteren Code-Ausführung
      }


      // Prüfe, ob der Ladevorgang des Providers abgeschlossen ist.
      if (!provider.isLoading) {
        print("🚀 Provider finished loading. Initializing UI State..."); // Debug Print
        // Verwende addPostFrameCallback, um setState außerhalb des Builds sicher aufzurufen
        WidgetsBinding.instance.addPostFrameCallback((_) {
            // Erneuter Check, ob Widget noch da ist, bevor setState gerufen wird
            if(mounted && !_isQueueInitialized) {
                setState(() {
                  _isQueueInitialized = true;
                  _trackQueue.clear(); // Sicherstellen, dass sie leer ist

                  // Fülle die Queue nur, wenn Tracks vorhanden sind.
                  if (provider.tracks.isNotEmpty) {
                    _trackQueue.addAll(provider.tracks.skip(provider.currentIndex));
                    print("✅ Queue Initialized with ${_trackQueue.length} tracks."); // Debug Print
                    // Lade den ersten Track *nur*, wenn die Queue gefüllt wurde.
                    _loadTrackForPlayer(_trackQueue.firstOrNull);
                  } else {
                     print("🤷 Queue Initialized, but no tracks found from provider."); // Debug Print
                  }
                });
            }
        });
      }
      // Wenn der Provider *noch lädt* und wir noch nicht initialisiert haben,
      // und der Provider auch keine Tracks hat (z.B. beim allerersten Start),
      // dann triggern wir das Laden im Provider.
      else if (provider.tracks.isEmpty && !_isQueueInitialized) {
         print("⏳ Provider is still loading or has no tracks, triggering loadDiscoveryTracks..."); // Debug Print
         // Verzögert aufrufen, um Build-Konflikte zu vermeiden
         WidgetsBinding.instance.addPostFrameCallback((_) {
             if (mounted) {
                 // Verwende read, um nicht auf Änderungen hier zu lauschen
                 context.read<SpotifyDataProvider>().loadDiscoveryTracks();
             }
         });
      }
    }
    // --- ENDE ANGEPASSTE INITIALISIERUNG ---
  }

  @override
  void dispose() {
    _cardAnimationController.removeListener(_onAnimationUpdate);
    _cardAnimationController.dispose();
    _playerStateSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  // Diese Methode wird JEDEN Frame aufgerufen, während die Karte animiert wird
  void _onAnimationUpdate() {
    // Aktualisiere den Provider-Notifier für das Hintergrund-Feedback
    final provider = context.read<SpotifyDataProvider>();
    provider.swipeProgressNotifier.value = _cardAnimationController.value;

    // setState() ist hier nicht nötig, da wir einen AnimatedBuilder verwenden
  }

  // --- NEUE PLAYER METHODEN ---
  void _listenToPlayerState() {
    _playerStateSubscription = _audioPlayer.playerStateStream.listen((state) {
      if (!mounted) return; // Wichtig: Prüfen, ob Widget noch existiert

      final isPlaying = state.playing;
      final processingState = state.processingState;

      // Aktualisiere den lokalen Play/Pause-Status für die UI
      if (_currentPlayerIsPlaying != isPlaying) {
         setState(() {
             _currentPlayerIsPlaying = isPlaying;
         });
      }

      // Wenn Song fertig -> Pause & Reset (wie vorher, nur zentral)
      if (processingState == ProcessingState.completed) {
        _audioPlayer.seek(Duration.zero);
        _audioPlayer.pause(); // Stoppt die Wiedergabe und setzt _currentPlayerIsPlaying auf false
      }
    });
  }

  Future<void> _loadTrackForPlayer(FirebaseTrack? track) async {
    // Stoppe Player nur, wenn er spielt oder lädt
    if (_audioPlayer.playing || _audioPlayer.processingState != ProcessingState.idle) {
      await _audioPlayer.stop();
    }
    if (!mounted) return; // Wichtig: Prüfen, ob Widget noch existiert

    setState(() {
       _currentPlayerIsPlaying = false; // Reset Play-Button
    });

    if (track == null) {
      print("ℹ️ Kein nächster Track zum Laden.");
      return; // Kein Track vorhanden, nichts laden
    }

    try {
      // DiscoveryService sollte jetzt initialisiert sein
      String? previewUrl = await _discoveryService.getDeezerPreviewUrl(track);
      if (!mounted) return; // Erneuter Check nach async call

      if (previewUrl != null) {
        await _audioPlayer.setUrl(previewUrl);
        print("🎧 Track ${track.name} geladen.");
        // Optional: Automatisch abspielen?
        // await _audioPlayer.play();
      } else {
         print('⚠️ Kein Preview URL für ${track.name}');
         // UI für keinen Preview (z.B. Button deaktivieren) wird indirekt durch Player State gesteuert
      }
    } catch (e) {
       print('❌ Fehler beim Laden des Tracks (${track.name}): $e');
       // UI für Fehler (z.B. Snackbar)
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Fehler beim Laden von: ${track.name}'))
         );
       }
    }
  }

  void _togglePlayPause() {
     if (_audioPlayer.playing) {
       _audioPlayer.pause();
     } else {
       // Nur starten, wenn eine URL geladen ist
       if (_audioPlayer.processingState != ProcessingState.idle) {
         _audioPlayer.play();
       }
     }
     // Der _listenToPlayerState kümmert sich um das setState für den Button
  }
  // --- ENDE NEUE PLAYER METHODEN ---

  /// Wird aufgerufen, NACHDEM die Fling/Animate-Animation beendet ist
  void _handleSwipeComplete(SwipeAction action) async {
    final provider = context.read<SpotifyDataProvider>();
    if (_trackQueue.isEmpty) return;
    final swipedTrack = _trackQueue.first;

    await _audioPlayer.stop();

    if (action == SwipeAction.like) {
      provider.likeTrack(swipedTrack);
    } else {
      provider.dislikeTrack(swipedTrack);
    }
    provider.nextTrack(); // Wichtig: provider.nextTrack() löst KEIN notifyListeners() mehr aus!

    FirebaseTrack? nextTrack;
    bool needsPrefetch = false;
    setState(() {
      _trackQueue.removeAt(0);
      _currentPlayerIsPlaying = false;
      nextTrack = _trackQueue.firstOrNull;
      // --- Prefetching Check ---
      if (_trackQueue.length <= 10 && !provider.isPrefetching && !provider.isLoading) {
         needsPrefetch = true;
      }
      // --- Ende Prefetching Check ---
    });

    _cardAnimationController.value = 0.0;
    await _loadTrackForPlayer(nextTrack);

    // --- Prefetching Auslösen (außerhalb von setState) ---
    if (needsPrefetch) {
       print("🔥 Triggering Prefetch..."); // Debug Print
       provider.prefetchMoreTracks().then((newTracks) {
          // Füge die neuen Tracks zur lokalen Queue hinzu
          if (mounted && newTracks.isNotEmpty) {
             setState(() {
                // Füge nur Tracks hinzu, die noch nicht in der Queue sind
                // (um Duplikate bei schnellem Swipen zu vermeiden)
                final currentIds = _trackQueue.map((t) => t.id).toSet();
                _trackQueue.addAll(newTracks.where((t) => !currentIds.contains(t.id)));
                print("➡️ Prefetched tracks added. Queue size: ${_trackQueue.length}"); // Debug Print
             });
          }
       }).catchError((e) {
          print("❌ Prefetch failed: $e");
       });
    }
    // --- Ende Prefetching Auslösen ---
  }

  @override
  Widget build(BuildContext context) {
    // Nur noch 'select' verwenden, um gezielt auf isLoading zu hören,
    // *bevor* die Queue initialisiert ist.
    final isLoadingBeforeInit = context.select((SpotifyDataProvider p) => p.isLoading && !_isQueueInitialized);

    // --- VEREINFACHTE BUILD-LOGIK ---

    // 1. Zeige Ladeindikator NUR, wenn wir noch nicht initialisiert sind UND der Provider lädt.
    if (isLoadingBeforeInit) {
       print("⏳ Showing Loading Indicator (Provider loading, UI not initialized yet)"); // Debug Print
       return const Scaffold(
         backgroundColor: Colors.transparent,
         body: Center(child: CircularProgressIndicator(color: Colors.white)),
       );
    }
    // 2. Sobald _isQueueInitialized true ist (egal ob Tracks da sind oder nicht),
    //    bauen wir die Haupt-UI.
    else if (_isQueueInitialized) {
       // Prüfe hier, ob die _trackQueue leer ist.
       if (_trackQueue.isEmpty) {
          print("🤷 UI Initialized, but Track Queue is empty. Showing Empty State."); // Debug Print
          // Lese den Provider, um reload auszulösen
          final provider = context.read<SpotifyDataProvider>();
          return Scaffold(
             backgroundColor: Colors.transparent,
             // Verwende dein EmptyState Widget
             body: Center(child: EmptyState(onReload: () async {
                 print("🔄 Reload triggered from EmptyState.");
                 // Setze UI zurück in Ladezustand und lade neu
                 setState(() {
                   _isQueueInitialized = false;
                 });
                 await provider.reload(); // reload sollte isLoading wieder auf true setzen
                 // didChangeDependencies wird dann die Initialisierung erneut versuchen
             })),
          );
       }
       // Wenn die Queue initialisiert UND NICHT leer ist -> Baue die Karten.
       else {
         final track = _trackQueue.first;
         print("✅ Building Card UI. Queue size: ${_trackQueue.length}"); // Debug Print
         return Scaffold(
            backgroundColor: Colors.transparent,
            body: SafeArea(
              child: AnimatedBuilder(
                      animation: _cardAnimationController,
                      builder: (context, _) {
                        // ... (Animationslogik für Karten bleibt gleich) ...
                         final progress = _cardAnimationController.value;
                         final cardOffset = Offset(progress * _screenWidth * 1.1, 0);
                         final cardRotation = progress * (math.pi / 20);

                        return Center(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Stacked Cards (bleibt gleich)
                              for (int i = 3; i >= 1; i--)
                                if (i < _trackQueue.length)
                                  GlassStackedCard(
                                    track: _trackQueue[i],
                                    position: i.toDouble(),
                                    swipeProgress: progress,
                                    player: _audioPlayer, // Player übergeben
                                  ),

                              // Oberste Karte (bleibt gleich)
                              GestureDetector(
                                onTap: () { /* Navigation zu Details */
                                   Navigator.push(context, MaterialPageRoute(builder: (context) => SongDetailPage(track: track),));
                                },
                                onHorizontalDragStart: (details) { _cardAnimationController.stop();},
                                onHorizontalDragUpdate: (details) { /* Update Controller Value */
                                  double friction = (_screenWidth == 0) ? 300.0 : _screenWidth * 0.8;
                                  _cardAnimationController.value += details.delta.dx / friction;
                                },
                                onHorizontalDragEnd: (details) { /* Handle Fling/Animate/Snap */
                                    final velocity = details.velocity.pixelsPerSecond.dx;
                                    final progress = _cardAnimationController.value;
                                    // ... (Fling/Animate/Snap Logik bleibt exakt gleich) ...
                                     if (velocity.abs() > 800.0) {
                                      final target = velocity > 0 ? 1.0 : -1.0;
                                      _cardAnimationController.fling(velocity: velocity / _screenWidth).then((_) {
                                        _handleSwipeComplete(target > 0 ? SwipeAction.like : SwipeAction.dislike);
                                      });
                                    }
                                    else if (progress.abs() > 0.4) {
                                      final target = progress > 0 ? 1.0 : -1.0;
                                      _cardAnimationController.animateTo(target, curve: Curves.easeOut).then((_) {
                                        _handleSwipeComplete(target > 0 ? SwipeAction.like : SwipeAction.dislike);
                                      });
                                    }
                                    else {
                                      // Definiere die Feder-Eigenschaften (Hier kannst du experimentieren!)
                                      // mass:   Trägheit (höher = langsamer)
                                      // stiffness: Federstärke (höher = schneller, "härter")
                                      // damping: Dämpfung (höher = weniger/kein Überschwingen)
                                      final SpringDescription spring = SpringDescription(
                                        mass: 1.0,      // Standard
                                        stiffness: 150.0, // Mittlere Stärke (nicht zu hart)
                                        damping: 20.0,   // Gute Dämpfung für "weiches" Anhalten
                                      );

                                      // Wo soll die Feder hin? (Ziel = Mitte = 0.0)
                                      final double endPosition = 0.0;
                                      // Wo ist die Karte gerade? (Aktueller Controller-Wert)
                                      final double currentPosition = _cardAnimationController.value;
                                      // Wie schnell war sie beim Loslassen? (Skaliert auf den Controller-Bereich -1 bis 1)
                                      final double currentVelocity = details.velocity.pixelsPerSecond.dx / (_screenWidth > 0 ? _screenWidth : 300.0); // Verhindere Division durch Null

                                      // Erstelle die Simulation
                                      final simulation = SpringSimulation(
                                          spring,
                                          currentPosition, // Startpunkt
                                          endPosition,     // Endpunkt
                                          currentVelocity  // Startgeschwindigkeit
                                      );

                                      // Starte die Animation mit der Simulation
                                      _cardAnimationController.animateWith(simulation);
                                    }
                                },
                                child: Transform.translate(
                                  offset: cardOffset,
                                  child: Transform.rotate(
                                    angle: cardRotation,
                                    child: GlassSongCard(
                                      key: ValueKey(track.id), // Key verwenden
                                      track: track,
                                      isPlaying: _currentPlayerIsPlaying,
                                      onPlayPause: _togglePlayPause,
                                      player: _audioPlayer, // Player übergeben
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                    )
            ),
          );
       }
    }
    // 3. Fallback: Sollte nicht mehr oft erreicht werden.
    //    Wird angezeigt, wenn Provider *nicht* lädt, aber die UI *noch nicht* initialisiert ist.
    //    Kann passieren, wenn didChangeDependencies noch nicht lief oder fehlgeschlagen ist.
    else {
      print("🤔 Fallback: Provider not loading, but UI not initialized? Triggering load..."); // Debug Print
      // Lade erneut auslösen, falls etwas schiefgelaufen ist.
      WidgetsBinding.instance.addPostFrameCallback((_) {
         if (mounted && !_isQueueInitialized) {
             context.read<SpotifyDataProvider>().loadDiscoveryTracks();
         }
      });
      return Scaffold(
         backgroundColor: Colors.transparent,
         body: Center(child: CircularProgressIndicator(color: Colors.grey)), // anderer Indikator zur Unterscheidung
       );
    }
    // --- ENDE VEREINFACHTE BUILD-LOGIK ---
  }
}

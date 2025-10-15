import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../services/auth_services.dart';

// Der bestehende ActionButton
class ActionButton extends StatefulWidget {
  final Color accentColor;
  final Color? textColor;
  final String text;
  final VoidCallback onTap;

  const ActionButton({super.key, required this.accentColor, required this.onTap, required this.text, this.textColor});

  @override
  _ActionButtonState createState() => _ActionButtonState();
}

class _ActionButtonState extends State<ActionButton> {
  bool _isPressed = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: Container(
          height: 56,
          width: double.infinity,
          decoration: BoxDecoration(
            color: widget.accentColor,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: widget.accentColor.withOpacity(0.5),
                blurRadius: 25,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: Center(
            child: Text(
              widget.text,
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: widget.textColor ?? Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}


// NEU: Der Spotify-Button mit Liquid-Glass-Effekt
class SpotifyButton extends StatefulWidget {
  final VoidCallback onTap;
  const SpotifyButton({super.key, required this.onTap});

  @override
  State<SpotifyButton> createState() => _SpotifyButtonState();
}

class _SpotifyButtonState extends State<SpotifyButton> {


  // Keine finale Implementation (Testzweck), wird u.U. noch angepasst
  // ==============================================
  // final auth = AuthServices(
  //   clientId: 'deb60e6c420e48b789b7a205a25df95e',  
  //   redirectUri: 'http://127.0.0.1:8080/callback',
  //   scopes: [
  //     'user-read-email',
  //     'playlist-modify-public',
  //     'playlist-modify-private',
  //     'user-top-read',
  //   ],
  // );
  //==============================================
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    const spotifyColor = Color(0xFF1DB954);

    return GestureDetector(
      onTapDown: (_){
        setState(() => _isPressed = true);
        // auth.openAuthorizeUrl();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              height: 56,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: spotifyColor.withOpacity(0.5), width: 1.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const FaIcon(FontAwesomeIcons.spotify, color: spotifyColor, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    "Continue with Spotify",
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

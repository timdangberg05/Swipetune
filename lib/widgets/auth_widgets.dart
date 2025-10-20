import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SpotifyLoginPanel extends StatelessWidget {
  final VoidCallback onCancel;
  const SpotifyLoginPanel({super.key, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "Connecting to Spotify...",
          style: GoogleFonts.manrope(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 24),
        const CircularProgressIndicator(color: Color(0xFF1DB954)),
        const SizedBox(height: 24),
        TextButton(
          onPressed: onCancel,
          child: const Text("Cancel", style: TextStyle(color: Colors.white70)),
        )
      ],
    );
  }
}

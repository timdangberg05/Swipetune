import 'package:flutter/material.dart';
import '/homepage_songs/song.dart';

class SongCard extends StatelessWidget {
  final Song song;

  const SongCard({super.key, required this.song});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      elevation: 8,
      color: Colors.grey.shade900,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            song.coverUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _coverFallback(),
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                color: Colors.black,
                child: const Center(child: CircularProgressIndicator()),
              );
            },
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 40,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  song.title,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [Shadow(blurRadius: 8, color: Colors.black)],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  song.artist,
                  style: const TextStyle(fontSize: 16, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _coverFallback() => Container(
        color: Colors.grey.shade800,
        child: const Center(
          child: Icon(Icons.music_note, size: 56, color: Colors.white70),
        ),
      );
}

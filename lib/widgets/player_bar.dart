import 'package:flutter/material.dart';
import '/homepage_songs/song.dart';

class PlayerBar extends StatelessWidget {
  final Song song;
  final bool isPlaying;
  final VoidCallback onPlayPause;

  const PlayerBar({
    super.key,
    required this.song,
    required this.isPlaying,
    required this.onPlayPause,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade900.withOpacity(0.9),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LinearProgressIndicator(
              value: isPlaying ? 0.3 : 0.0,
              backgroundColor: Colors.grey.shade800,
              valueColor:
                  AlwaysStoppedAnimation<Color>(Colors.green.shade400),
              minHeight: 3,
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      song.coverUrl,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      // Fallback, wenn das Bild nicht geladen werden kann
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 50,
                          height: 50,
                          color: Colors.white12,
                          child: const Icon(
                            Icons.music_note,
                            color: Colors.white54,
                            size: 28,
                          ),
                        );
                      },
                      // Optional: Lade-Indikator, während das Bild geladen wird
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          width: 50,
                          height: 50,
                          color: Colors.white12,
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white54,
                              strokeWidth: 2,
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          song.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          song.artist,
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon:
                        const Icon(Icons.skip_previous, color: Colors.white),
                    onPressed: () {},
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.black,
                        size: 28,
                      ),
                      onPressed: onPlayPause,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_next, color: Colors.white),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

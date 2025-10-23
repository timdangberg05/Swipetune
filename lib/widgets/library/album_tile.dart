import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:swipetune/models/personal_album.dart';

class AlbumTile extends StatelessWidget {
  final PersonalAlbum? album;
  final VoidCallback onTap;
  final bool isCreate;

  const AlbumTile({
    super.key,
    this.album,
    required this.onTap,
    this.isCreate = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isCreate) {
      return GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.0),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF9B51E0).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16.0),
                ),
                child: const Center(
                  child: Icon(
                    Icons.add,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (album == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: onTap,
      child: Hero(
        tag: 'hero-album-${album!.key}',
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.0),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16.0),
                image: album!.coverImageUrl != null
                    ? DecorationImage(
                        image: CachedNetworkImageProvider(album!.coverImageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.0),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.6),
                      Colors.black.withOpacity(0.2),
                    ],
                  ),
                ),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      album!.name,
                      style: GoogleFonts.manrope(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

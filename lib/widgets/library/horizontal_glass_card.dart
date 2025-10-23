import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

enum CardType { liked, create, album }

class HorizontalGlassCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final CardType type;
  final VoidCallback onTap;
  final String heroTag;

  const HorizontalGlassCard({
    super.key,
    required this.title,
    this.subtitle,
    this.imageUrl,
    required this.type,
    required this.onTap,
    required this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.0,
      child: Padding(
        padding: const EdgeInsets.only(right: 16.0),
        child: Hero(
          tag: heroTag,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.15),
                      Colors.white.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.35),
                    width: 2.5,
                  ),
                  image: (type == CardType.album && imageUrl != null)
                      ? DecorationImage(
                          image: CachedNetworkImageProvider(imageUrl!),
                          fit: BoxFit.cover,
                          opacity: 0.6,
                        )
                      : null,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onTap();
                    },
                    borderRadius: BorderRadius.circular(24),
                    child: Stack(
                      children: [
                        _buildIconOverlay(),
                        _buildTextOverlay(),
                      ],
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
  
  Widget _buildIconOverlay() {
    Widget icon;
    Color color;

    switch (type) {
      case CardType.liked:
        icon = Icon(Icons.favorite, size: 48);
        color = Color(0xFF9B51E0);
        break;
      case CardType.create:
        icon = Icon(Icons.add_circle_outline, size: 48);
        color = Colors.white.withOpacity(0.9);
        break;
      case CardType.album:
        // No icon if image exists
        if (imageUrl != null) return SizedBox.shrink(); 
        icon = Icon(Icons.library_music, size: 48);
        color = Colors.white.withOpacity(0.9);
        break;
    }

    return Center(
      child: Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(0.15),
        ),
        child: IconTheme(
          data: IconThemeData(color: color, size: 48),
          child: icon,
        ),
      ),
    );
  }

  Widget _buildTextOverlay() {
    return Align(
      alignment: Alignment.bottomLeft,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color.fromARGB(255, 255, 255, 255),
                shadows: [
                  Shadow(
                    offset: Offset(0, 2),
                    blurRadius: 8,
                    color: Colors.black.withOpacity(0.4),
                  ),
                  Shadow(
                    offset: Offset(0, 1),
                    blurRadius: 4,
                    color: Colors.black.withOpacity(0.3),
                  ),
                ],
              ),
              maxLines: 2,
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color.fromARGB(255, 255, 255, 255),
                  shadows: [
                    Shadow(
                      offset: Offset(0, 1),
                      blurRadius: 6,
                      color: Colors.black.withOpacity(0.4),
                    ),
                  ],
                ),
                maxLines: 1,
              ),
          ],
        ),
      ),
    );
  }
}

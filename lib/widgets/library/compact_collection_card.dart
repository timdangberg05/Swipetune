import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

enum CompactCardType { liked, create, album }

class CompactCollectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final CompactCardType type;
  final VoidCallback onTap;
  final String heroTag;

  const CompactCollectionCard({
    super.key,
    required this.title,
    this.subtitle,
    this.imageUrl,
    required this.type,
    required this.onTap,
    required this.heroTag,
  });

  LinearGradient _getCardGradient() {
    switch (type) {
      case CompactCardType.liked:
        // Subtle pink/purple - reduced from 0.35/0.25 to 0.15/0.12
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFC73666).withOpacity(0.15),
            Color(0xFF9B51E0).withOpacity(0.12),
            Colors.white.withOpacity(0.08),
          ],
        );
      case CompactCardType.create:
        // Subtle blue/cyan - reduced from 0.25/0.15 to 0.12/0.1
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2D9CDB).withOpacity(0.12),
            Color(0xFF1DB954).withOpacity(0.1),
            Colors.white.withOpacity(0.08),
          ],
        );
      case CompactCardType.album:
        // Neutral white gradient
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.15),
            Colors.white.withOpacity(0.06),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 160,
        margin: EdgeInsets.only(right: 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                gradient: _getCardGradient(),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.35),
                  width: 2.0,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon/Image section
                  Hero(
                    tag: heroTag,
                    child: Container(
                      height: 94,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
                        image: (type == CompactCardType.album && imageUrl != null)
                            ? DecorationImage(
                                image: CachedNetworkImageProvider(imageUrl!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: (type != CompactCardType.album || imageUrl == null)
                          ? Center(child: _buildIcon())
                          : null,
                    ),
                  ),
                  
                  // Text section
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Color.fromARGB(255, 255, 255, 255),
                            shadows: [
                              Shadow(
                                offset: Offset(0, 2),
                                blurRadius: 6,
                                color: Colors.black.withOpacity(0.4),
                              ),
                              Shadow(
                                offset: Offset(0, 1),
                                blurRadius: 3,
                                color: Colors.black.withOpacity(0.3),
                              ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (subtitle != null) ...[
                          SizedBox(height: 4),
                          Text(
                            subtitle!,
                            style: GoogleFonts.manrope(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color.fromARGB(255, 255, 255, 255),
                              shadows: [
                                Shadow(
                                  offset: Offset(0, 1),
                                  blurRadius: 4,
                                  color: Colors.black.withOpacity(0.3),
                                ),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
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

  Widget _buildIcon() {
    IconData iconData;
    Color color;
    Color bgColor1;
    Color bgColor2;

    switch (type) {
      case CompactCardType.liked:
        // Softer pink - reduced intensity
        iconData = Icons.favorite_rounded;
        color = Color(0xFFFF6B9D).withOpacity(0.9);
        bgColor1 = Color(0xFFC73666).withOpacity(0.2);
        bgColor2 = Color(0xFF9B51E0).withOpacity(0.1);
        break;
      case CompactCardType.create:
        // Softer blue - reduced intensity
        iconData = Icons.add_circle_rounded;
        color = Color(0xFF2D9CDB).withOpacity(0.9);
        bgColor1 = Color(0xFF2D9CDB).withOpacity(0.2);
        bgColor2 = Color(0xFF1DB954).withOpacity(0.1);
        break;
      case CompactCardType.album:
        iconData = Icons.album_rounded;
        color = Colors.white.withOpacity(0.9);
        bgColor1 = Colors.white.withOpacity(0.2);
        bgColor2 = Colors.white.withOpacity(0.08);
        break;
    }

    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [bgColor1, bgColor2],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Icon(
        iconData,
        color: color,
        size: 30,
        shadows: [
          Shadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
    );
  }
}

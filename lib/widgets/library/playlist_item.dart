import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:swipetune/models/playlist_model.dart';

class PlaylistItem extends StatelessWidget {
  final PlaylistModel playlist;
  final VoidCallback onTap;

  const PlaylistItem({
    super.key,
    required this.playlist,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bottomPadding = size.height * 0.012;
    final horizontalPadding = size.width * 0.04;
    final verticalPadding = size.height * 0.015;
    final iconSpacing = size.width * 0.04;
    
    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: RepaintBoundary(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0x14FFFFFF),
                    Color(0x05FFFFFF),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0x1AFFFFFF),
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: verticalPadding,
                    ),
                    child: Row(
                      children: [
                        _buildPlaylistIcon(),
                        SizedBox(width: iconSpacing),
                        Expanded(
                          child: _buildPlaylistInfo(),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Color(0x4DFFFFFF),
                          size: 16,
                        ),
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

  Widget _buildPlaylistIcon() {
    return RepaintBoundary(
      child: Hero(
        tag: 'playlist_${playlist.id}',
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: playlist.imageUrl != null && playlist.imageUrl!.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: playlist.imageUrl!,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  memCacheWidth: 96,
                  memCacheHeight: 96,
                  errorWidget: (_, __, ___) => _buildFallbackIcon(),
                  placeholder: (_, __) => _buildFallbackIcon(),
                )
              : _buildFallbackIcon(),
        ),
      ),
    );
  }

  Widget _buildPlaylistInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          playlist.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.manrope(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${playlist.trackCount} Tracks',
          style: GoogleFonts.manrope(
            fontSize: 12,
            color: const Color(0x80FFFFFF),
          ),
        ),
      ],
    );
  }

  Widget _buildFallbackIcon() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0x26FFFFFF),
            Color(0x0DFFFFFF),
          ],
        ),
      ),
      child: const Icon(
        Icons.library_music,
        color: Color(0xE6FFFFFF),
        size: 24,
      ),
    );
  }
}

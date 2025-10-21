import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:swipetune/models/Track.dart';

class SongItem extends StatelessWidget {
  final Track track;
  final int index;
  final VoidCallback onTap;

  const SongItem({
    super.key,
    required this.track,
    required this.index,
    required this.onTap,
  });

  String _formatDuration(int ms) {
    final duration = Duration(milliseconds: ms);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bottomPadding = size.height * 0.01;
    final horizontalPadding = size.width * 0.04;
    final verticalPadding = size.height * 0.012;
    final imageSpacing = size.width * 0.03;
    
    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: RepaintBoundary(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0x0DFFFFFF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0x14FFFFFF),
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: verticalPadding,
                    ),
                    child: Row(
                      children: [
                        _buildTrackImage(),
                        SizedBox(width: imageSpacing),
                        Expanded(
                          child: _buildTrackInfo(),
                        ),
                        _buildDuration(),
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

  Widget _buildTrackImage() {
    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: track.albumImageUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: track.albumImageUrl,
                width: 42,
                height: 42,
                fit: BoxFit.cover,
                memCacheWidth: 84,
                memCacheHeight: 84,
                placeholder: (_, __) => _buildPlaceholder(),
                errorWidget: (_, __, ___) => _buildMusicNotePlaceholder(),
              )
            : _buildIndexBox(),
      ),
    );
  }

  Widget _buildTrackInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          track.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          track.artist,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.manrope(
            fontSize: 12,
            color: const Color(0x80FFFFFF),
          ),
        ),
      ],
    );
  }

  Widget _buildDuration() {
    return Text(
      _formatDuration(track.durationMs),
      style: GoogleFonts.manrope(
        fontSize: 12,
        color: const Color(0x66FFFFFF),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 42,
      height: 42,
      color: const Color(0x1AFFFFFF),
    );
  }

  Widget _buildMusicNotePlaceholder() {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0x1FFFFFFF),
            Color(0x0AFFFFFF),
          ],
        ),
      ),
      child: const Icon(
        Icons.music_note,
        color: Color(0xB3FFFFFF),
        size: 20,
      ),
    );
  }

  Widget _buildIndexBox() {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0x1FFFFFFF),
            Color(0x0AFFFFFF),
          ],
        ),
      ),
      child: Center(
        child: Text(
          '${index + 1}',
          style: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: const Color(0xB3FFFFFF),
          ),
        ),
      ),
    );
  }
}

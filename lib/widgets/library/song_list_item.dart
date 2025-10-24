import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:swipetune/models/firebasemodels/firebase_track_model.dart';

class SongListItem extends StatelessWidget {
  final FirebaseTrack track;
  final int index;
  final VoidCallback onTap;
  final VoidCallback? onShowOptions;

  const SongListItem({
    super.key,
    required this.track,
    required this.index,
    required this.onTap,
    this.onShowOptions,
  });

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
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.12),
                    Colors.white.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 2.0,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onTap();
                  },
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
                        if (onShowOptions != null)
                          IconButton(
                            icon: Icon(
                              Icons.more_vert,
                              color: Color.fromARGB(255, 255, 255, 255),
                              size: 20,
                            ),
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              onShowOptions!();
                            },
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(),
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

  Widget _buildTrackImage() {
    return track.albumImageUrl.isNotEmpty
        ? ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: track.albumImageUrl,
              width: 42,
              height: 42,
              fit: BoxFit.cover,
              memCacheWidth: 84,
              memCacheHeight: 84,
              placeholder: (_, __) => _buildPlaceholder(),
              errorWidget: (_, __, ___) => _buildIndexBox(),
            ),
          )
        : _buildIndexBox();
  }

  Widget _buildIndexBox() {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.2),
            Colors.white.withOpacity(0.08),
          ],
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.25),
          width: 1.5,
        ),
      ),
      child: Center(
        child: Text(
          '${index + 1}',
          style: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 255, 255, 255),
            shadows: [
              Shadow(
                offset: Offset(0, 1),
                blurRadius: 4,
                color: Colors.black.withOpacity(0.3),
              ),
            ],
          ),
        ),
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
            fontWeight: FontWeight.w700,
            color: Color.fromARGB(255, 255, 255, 255),
            shadows: [
              Shadow(
                offset: Offset(0, 1),
                blurRadius: 4,
                color: Colors.black.withOpacity(0.3),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          track.artist,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.manrope(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color.fromARGB(255, 255, 255, 255),
            shadows: [
              Shadow(
                offset: Offset(0, 1),
                blurRadius: 3,
                color: Colors.black.withOpacity(0.25),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

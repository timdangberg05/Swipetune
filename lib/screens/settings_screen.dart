import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:swipetune/models/user_model.dart';
import 'package:swipetune/providers/spotify_data_provider.dart';
import 'package:swipetune/screens/landing_screen.dart';
import 'package:swipetune/services/auth_services.dart';
import '../providers/user_provider.dart';
import '../models/Track.dart';
import 'songdetails.dart';


class SettingsScreen extends StatefulWidget {
  final ScrollController? scrollController;
  final ValueNotifier<double>? navBarProgress;

  const SettingsScreen({super.key, this.scrollController, this.navBarProgress});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class StatItem {
  final String label;
  final String value;
  final Color color;

  StatItem({required this.label, required this.value, required this.color});
}

class _SettingsScreenState extends State<SettingsScreen> with TickerProviderStateMixin {
  int _selectedTabIndex = 0;
  late PageController _pageController;

  Future<void> _handleLogout() async {
  try {
    // Clear User Provider
    context.read<UserProvider>().clearUser();

    // Call Auth Service Logout
    await AuthServices.logout();  // Deine static Methode

    // Navigate to Landing Screen
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LandingScreen()),
      (route) => false,
    );
  } catch (e) {
    // Error Handling (optional)
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Logout failed: $e')),
    );
  }
}
  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pageController.addListener(() {
      setState(() {
        _selectedTabIndex = _pageController.page?.round() ?? 0;
      });
    });
    if (widget.navBarProgress != null) {
      _pageController.addListener(() {
        // Reset navbar on tab change to show it
        widget.navBarProgress!.value = 0.0;
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().loadUserProfile();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabSelected(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutQuart,
    );
    // Reset navbar when switching tabs
    if (widget.navBarProgress != null) {
      widget.navBarProgress!.value = 0.0;
    }
  }

    int get totalSwipes {
    final dataProvider = context.read<SpotifyDataProvider>();
    return dataProvider.likedCount + dataProvider.dislikedCount;
  }

  int get likeRate {
    final dataProvider = context.read<SpotifyDataProvider>();
    final total = totalSwipes;
    if (total == 0) return 0;
    return ((dataProvider.likedCount / total) * 100).round();
  }

//Wichtig 
//-------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final topPadding = MediaQuery.of(context).padding.top + 60; // Account for global header
    final horizontalPadding = screenSize.width * 0.04; // Responsive horizontal padding, even tighter
    final bottomPadding = MediaQuery.of(context).padding.bottom + screenSize.height * 0.01; // Responsive bottom, even tighter
    final contentTopPadding = screenSize.height * 0.00; // Maximally tight spacing to header content
    final headerHorizontalPadding = horizontalPadding; // Ensure consistency with scrollable area
//------------------------------------------------------------------------
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final user = userProvider.user;

        return Column(
          children: [
            // Padded Container for Global Header
            SizedBox(height: topPadding),

            // Fixed Header
            _buildProfileHeaderWidget(user, screenSize, headerHorizontalPadding),

            // Scrollable Content Below
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  left: horizontalPadding,
                  right: horizontalPadding,
                  top: contentTopPadding,
                  bottom: bottomPadding,
                ),
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    SingleChildScrollView(controller: widget.scrollController, physics: const BouncingScrollPhysics(), child: _buildRecentTab(screenSize)),
                    SingleChildScrollView(physics: const BouncingScrollPhysics(), child: _buildFollowingTab(screenSize)),
                    SingleChildScrollView(physics: const BouncingScrollPhysics(), child: _buildPlaylistsTab(screenSize)),
                    SingleChildScrollView(physics: const BouncingScrollPhysics(), child: _buildSettingsTab(screenSize)),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProfileHeaderWidget(SpotifyUser? user, Size screenSize, double headerHorizontalPadding) {
    final spacingMedium = screenSize.height * 0.015;
    final spacingLarge = screenSize.height * 0.025;
    final verticalPadding = screenSize.height * 0.01;
    final avatarSize = screenSize.width * 0.2; // Responsive avatar size
    final statGap = screenSize.width * 0.03;

    return Container(
      color: Colors.transparent,
      padding: EdgeInsets.symmetric(horizontal: headerHorizontalPadding, vertical: verticalPadding),
      child: Column(
        children: [
          // Avatar and Name Row
          Row(
            children: [
              Container(
                width: avatarSize,
                height: avatarSize,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.3),
                      const Color(0xFF1DB954).withOpacity(0.3),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: ClipOval(
                  child: user?.imageUrl != null
                      ? Image.network(
                          user!.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildAvatarFallback();
                          },
                        )
                      : _buildAvatarFallback(),
                ),
              ),
              SizedBox(width: screenSize.width * 0.04),
              if (user != null)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user!.displayName,
                        style: GoogleFonts.manrope(
                          fontSize: screenSize.width * 0.07, // Responsive font size
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                      SizedBox(height: screenSize.height * 0.01),
                      Text(
                        '@${user!.id}',
                        style: GoogleFonts.manrope(
                          fontSize: screenSize.width * 0.04,
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          SizedBox(height: spacingMedium),

          // Stats Cards
          Consumer<SpotifyDataProvider>(
            builder: (context, dataProvider, child) {
              final totalSwipes = dataProvider.likedCount + dataProvider.dislikedCount;
              final likeRate = totalSwipes == 0 ? 0 : ((dataProvider.likedCount / totalSwipes) * 100).round();

              return Row(
                children: [
                  Expanded(child: _buildStatCard('$totalSwipes', 'Swipes', screenSize)),
                  SizedBox(width: statGap),
                  Expanded(child: _buildStatCard('${dataProvider.likedCount}', 'Likes', screenSize)),
                  SizedBox(width: statGap),
                  Expanded(child: _buildStatCard('$likeRate%', 'Like Rate', screenSize)),
                ],
              );
            },
          ),

          SizedBox(height: spacingLarge),

          // Tabs
          _buildModernTabBar(_onTabSelected, screenSize),
        ],
      ),
    );
  }


  Widget _buildAvatarFallback() {
    return Container(
      color: Colors.white12,
      child: const Icon(Icons.person, size: 40.0, color: Colors.white54),
    );
  }




  Widget _buildStatCard(String value, String label, Size screenSize) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: screenSize.height * 0.02, horizontal: screenSize.width * 0.03),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            children: [
              Text(
                value,
                style: GoogleFonts.manrope(
                  fontSize: screenSize.width * 0.06,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.manrope(
                  fontSize: screenSize.width * 0.03,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernTabBar(Function(int) onTabSelected, Size screenSize) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: EdgeInsets.all(screenSize.width * 0.01),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              _buildTabButton('Recent', 0, onTabSelected, screenSize),
              _buildTabButton('Following', 1, onTabSelected, screenSize),
              _buildTabButton('Playlists', 2, onTabSelected, screenSize),
              _buildTabButton('Settings', 3, onTabSelected, screenSize),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton(String label, int index, Function(int) onTabSelected, Size screenSize) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTabSelected(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: EdgeInsets.symmetric(vertical: screenSize.height * 0.015),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.white.withOpacity(0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: screenSize.width * 0.035,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.white : Colors.white.withOpacity(0.6),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentTab(Size screenSize) {
    return Consumer<SpotifyDataProvider>(
      builder: (context, dataProvider, child) {
        // Combine liked and disliked tracks, take last 6 for recent
        final List<Map<String, dynamic>> recentSwipes = [];
        final liked = dataProvider.likedTracks.reversed.take(3).map((t) => {'track': t, 'isLike': true});
        final disliked = dataProvider.dislikedTracks.reversed.take(3).map((t) => {'track': t, 'isLike': false});
        recentSwipes.addAll(liked);
        recentSwipes.addAll(disliked);
        recentSwipes.shuffle(); // Randomize order for variety

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recent Swipes Section
            _buildSectionHeader('Recent Activity', onViewAll: recentSwipes.isNotEmpty ? () {} : null),
            SizedBox(height: screenSize.height * 0.015),
            if (recentSwipes.isNotEmpty)
              SizedBox(
                height: screenSize.height * 0.25,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: recentSwipes.length,
                  itemBuilder: (context, index) {
                    final swipe = recentSwipes[index];
                    final track = swipe['track'] as Track;
                    final isLike = swipe['isLike'] as bool;
                    return Padding(
                      padding: EdgeInsets.only(right: screenSize.width * 0.03),
                      child: _buildUltraModernSwipeCard(
                        isLike: isLike,
                        track: track,
                        screenSize: screenSize,
                      ),
                    );
                  },
                ),
              )
            else
              Container(
                height: screenSize.height * 0.15,
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.swipe_outlined,
                      color: Colors.white.withOpacity(0.4),
                      size: screenSize.width * 0.12,
                    ),
                    SizedBox(height: screenSize.height * 0.01),
                    Text(
                      'No recent swipes yet',
                      style: GoogleFonts.manrope(
                        fontSize: screenSize.width * 0.04,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                    Text(
                      'Start swiping to see activity',
                      style: GoogleFonts.manrope(
                        fontSize: screenSize.width * 0.03,
                        color: Colors.white.withOpacity(0.4),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildFollowingTab(Size screenSize) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Following Artists', subtitle: '🎵 47 Artists', onViewAll: () {}),
        SizedBox(height: screenSize.height * 0.02),
        SizedBox(
          height: screenSize.height * 0.23,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 6,
            itemBuilder: (context, index) {
              return _buildArtistCard('Artist ${index + 1}');
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPlaylistsTab(Size screenSize) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('SwipeTune Playlists'),
        SizedBox(height: screenSize.height * 0.015),
        _buildPlaylistItem(
          title: '💚 Liked Songs',
          subtitle: '234 tracks · Created from your swipes',
        ),
        SizedBox(height: screenSize.height * 0.03),
        _buildSectionHeader('Your Spotify Playlists', onViewAll: () {}),
        SizedBox(height: screenSize.height * 0.02),
        SizedBox(
          height: screenSize.height * 0.25,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 5,
            itemBuilder: (context, index) {
              return _buildPlaylistCard(
                'Playlist ${index + 1}',
                '${45 + index * 10} songs',
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsTab(Size screenSize) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Profile',
          style: GoogleFonts.manrope(
            fontSize: screenSize.width * 0.035,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.6),
          ),
        ),
        SizedBox(height: screenSize.height * 0.015),
        _buildSettingItem(
          icon: Icons.edit_outlined,
          title: 'Edit Display Name',
          subtitle: 'Alex',
        ),
        _buildSettingItem(
          icon: Icons.image_outlined,
          title: 'Change Avatar',
          subtitle: 'Update your picture',
        ),
        SizedBox(height: screenSize.height * 0.03),
        Text(
          'Notifications',
          style: GoogleFonts.manrope(
            fontSize: screenSize.width * 0.035,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.6),
          ),
        ),
        SizedBox(height: screenSize.height * 0.015),
        _buildSettingItem(
          icon: Icons.music_note_outlined,
          title: 'New Song Suggestions',
          subtitle: 'Daily recommendations',
          hasToggle: true,
        ),
        _buildSettingItem(
          icon: Icons.playlist_add_check_rounded,
          title: 'Playlist Updates',
          subtitle: 'When your playlists are ready',
          hasToggle: true,
          toggleValue: true,
        ),
        SizedBox(height: screenSize.height * 0.03),
        Text(
          'Account',
          style: GoogleFonts.manrope(
            fontSize: screenSize.width * 0.035,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.6),
          ),
        ),
        SizedBox(height: screenSize.height * 0.015),
        _buildSettingItem(
          icon: Icons.logout_rounded,
          title: 'Log Out',
          subtitle: 'You will be returned to login',
          isDestructive: true,
          onTap: _handleLogout, 
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, {String? subtitle, VoidCallback? onViewAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
            ],
          ],
        ),
        if (onViewAll != null)
          GestureDetector(
            onTap: onViewAll,
            child: Row(
              children: [
                Text(
                  'View All',
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1DB954),
                  ),
                ),
                const SizedBox(width: 4),
              const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14.0,
                  color: Color(0xFF1DB954),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSwipeCard({
    required bool isLike,
    required String songName,
    required String artistName,
    required String timeAgo,
  }) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Badge
                Container(
                  padding: const EdgeInsets.all(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (isLike ? const Color(0xFF1DB954) : const Color(0xFFFF5A5A))
                          .withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isLike ? '🟢 LIKE' : '🔴 DISLIKE',
                      style: GoogleFonts.manrope(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isLike ? const Color(0xFF1DB954) : const Color(0xFFFF5A5A),
                      ),
                    ),
                  ),
                ),
                // Album Art Placeholder
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Icon(Icons.music_note, color: Colors.white24, size: 32.0),
                    ),
                  ),
                ),
                // Song Info
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        songName,
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        artistName,
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          color: Colors.white.withOpacity(0.6),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        timeAgo,
                        style: GoogleFonts.manrope(
                          fontSize: 10,
                          color: Colors.white.withOpacity(0.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildArtistCard(String artistName) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person, color: Colors.white24, size: 40.0),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    artistName,
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildArtistMorphCard(String artistName, Size screenSize) {
    return Transform.scale(
      scale: 0.85, // Slightly smaller for morph effect
      child: Container(
        width: 110,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.1),
                    Colors.white.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 65,
                    height: 65,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.2),
                          Colors.white.withOpacity(0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: const Icon(Icons.music_note, color: Colors.white38, size: 30.0),
                  ),
                  SizedBox(height: screenSize.height * 0.01),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      artistName,
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

  Widget _buildPlaylistCard(String name, String trackCount) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Icon(Icons.library_music, color: Colors.white24, size: 32.0),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        trackCount,
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaylistItem({required String title, required String subtitle}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.manrope(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16.0,
                color: Colors.white38,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    bool isDestructive = false,
    bool hasToggle = false,
    bool toggleValue = false,
    VoidCallback? onTap,
  }) {
    final color = isDestructive ? const Color(0xFFFF5A5A) : Colors.white;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child:GestureDetector(
        onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                  Icon(icon, color: color.withOpacity(0.8), size: 22.0),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.manrope(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          color: color.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasToggle)
                  Switch(
                    value: toggleValue,
                    onChanged: (value) {},
                    activeTrackColor: const Color(0xFF1DB954).withOpacity(0.5),
                    activeColor: const Color(0xFF1DB954),
                  )
                else if (!isDestructive)
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white38,
                    size: 16.0,
                  ),
              ],
            ),
          ),
        ),
      ),
    )
    );
  }

  Widget _buildGlassStatsCard({
    required String title,
    required String subtitle,
    required List<StatItem> stats,
    required Size screenSize,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.all(screenSize.width * 0.05),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.manrope(
                  fontSize: screenSize.width * 0.045,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: screenSize.height * 0.005),
              Text(
                subtitle,
                style: GoogleFonts.manrope(
                  fontSize: screenSize.width * 0.035,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              SizedBox(height: screenSize.height * 0.02),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: stats.map((stat) => _buildStatCircle(stat, screenSize)).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCircle(StatItem stat, Size screenSize) {
    return Container(
      width: screenSize.width * 0.15,
      height: screenSize.width * 0.15,
      decoration: BoxDecoration(
        color: stat.color.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(
          color: stat.color.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            stat.value,
            style: GoogleFonts.manrope(
              fontSize: screenSize.width * 0.035,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            stat.label,
            style: GoogleFonts.manrope(
              fontSize: screenSize.width * 0.025,
              color: Colors.white.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildModernSwipeCard({
    required bool? isLike,
    required String songName,
    required String artistName,
    required String timeAgo,
    required Size screenSize,
  }) {
    Color statusColor;
    String statusEmoji;
    String statusText;

    if (isLike == true) {
      statusColor = const Color(0xFF1DB954);
      statusEmoji = '💚';
      statusText = 'LIKE';
    } else if (isLike == false) {
      statusColor = const Color(0xFFFF5A5A);
      statusEmoji = '💔';
      statusText = 'DISLIKE';
    } else {
      statusColor = Colors.blue;
      statusEmoji = '🎵';
      statusText = 'PLAYED';
    }

    return Container(
      width: screenSize.width * 0.35,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.07),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: statusColor.withOpacity(0.2),
                width: 2,
              ),
            ),
            child: Column(
              children: [
                // Status Header
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenSize.width * 0.03,
                    vertical: screenSize.height * 0.008,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                  ),
                  child: Row(
                    children: [
                      Text(
                        '$statusEmoji $statusText',
                        style: GoogleFonts.manrope(
                          fontSize: screenSize.width * 0.03,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
                // Album Art
                Expanded(
                  child: Container(
                    margin: EdgeInsets.all(screenSize.width * 0.025),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Icon(
                        isLike == true ? Icons.thumb_up :
                        isLike == false ? Icons.thumb_down :
                        Icons.play_circle_filled,
                        color: Colors.white.withOpacity(0.6),
                        size: screenSize.width * 0.08,
                      ),
                    ),
                  ),
                ),
                // Song Info
                Padding(
                  padding: EdgeInsets.all(screenSize.width * 0.025),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        songName,
                        style: GoogleFonts.manrope(
                          fontSize: screenSize.width * 0.035,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: screenSize.height * 0.003),
                      Text(
                        artistName,
                        style: GoogleFonts.manrope(
                          fontSize: screenSize.width * 0.03,
                          color: Colors.white.withOpacity(0.7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: screenSize.height * 0.008),
                      Text(
                        timeAgo,
                        style: GoogleFonts.manrope(
                          fontSize: screenSize.width * 0.025,
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUltraModernSwipeCard({
    required bool isLike,
    required Track track,
    required Size screenSize,
  }) {
    // Simulate a timestamp - in real app, you'd have actual timestamps
    final timeAgo = track.name.length % 2 == 0 ? 'Just now' : '2h ago';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => SongDetailPage(track: track)),
      ),
      child: Container(
        width: screenSize.width * 0.38,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              spreadRadius: 3,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isLike ? const Color(0xFF1DB954).withOpacity(0.3) :
                         Colors.white.withOpacity(0.15),
                  width: 2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Badge with haptic feedback simulation
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenSize.width * 0.035,
                      vertical: screenSize.height * 0.01,
                    ),
                    decoration: BoxDecoration(
                      color: isLike ?
                        const Color(0xFF1DB954).withOpacity(0.15) :
                        const Color(0xFFFF5A5A).withOpacity(0.15),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(22),
                        topRight: Radius.circular(22),
                      ),
                    ),
                    child: Text(
                      isLike ? '💚 LIKED' : '💔 DISLIKED',
                      style: GoogleFonts.manrope(
                        fontSize: screenSize.width * 0.032,
                        fontWeight: FontWeight.w800,
                        color: isLike ?
                          const Color(0xFF1DB954) :
                          const Color(0xFFFF5A5A),
                      ),
                    ),
                  ),
                  // Song Content
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(screenSize.width * 0.035),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Song Name
                          Text(
                            track.name,
                            style: GoogleFonts.manrope(
                              fontSize: screenSize.width * 0.042,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.1,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: screenSize.height * 0.008),
                          // Artist Name
                          Row(
                            children: [
                              Icon(
                                Icons.account_circle,
                                size: screenSize.width * 0.035,
                                color: Colors.white.withOpacity(0.6),
                              ),
                              SizedBox(width: screenSize.width * 0.015),
                              Expanded(
                                child: Text(
                                  track.artist,
                                  style: GoogleFonts.manrope(
                                    fontSize: screenSize.width * 0.035,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: screenSize.height * 0.012),
                          // Time & Heart Icon
                          Row(
                            children: [
                              Text(
                                timeAgo,
                                style: GoogleFonts.manrope(
                                  fontSize: screenSize.width * 0.03,
                                  color: Colors.white.withOpacity(0.55),
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: EdgeInsets.all(screenSize.width * 0.015),
                                decoration: BoxDecoration(
                                  color: isLike ?
                                    const Color(0xFF1DB954).withOpacity(0.2) :
                                    const Color(0xFFFF5A5A).withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isLike ? Icons.favorite : Icons.heart_broken,
                                  color: isLike ?
                                    const Color(0xFF1DB954) :
                                    const Color(0xFFFF5A5A),
                                  size: screenSize.width * 0.045,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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

  String _getMockSongName(int index) {
    List<String> songs = [
      'Blinding Lights',
      'Watermelon Sugar',
      'Shape of You',
      'levitating',
      'Stay'
    ];
    return songs[index % songs.length];
  }

  String _getMockArtistName(int index) {
    List<String> artists = [
      'The Weeknd',
      'Harry Styles',
      'Ed Sheeran',
      'Dua Lipa',
      'The Kid LAROI'
    ];
    return artists[index % artists.length];
  }

  Widget _buildGenreChip(String genre, String trend, Size screenSize) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenSize.width * 0.04,
        vertical: screenSize.height * 0.012,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: Colors.white.withOpacity(0.15),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            genre,
            style: GoogleFonts.manrope(
              fontSize: screenSize.width * 0.035,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          SizedBox(width: screenSize.width * 0.02),
          Text(
            trend,
            style: GoogleFonts.manrope(
              fontSize: screenSize.width * 0.025,
              color: const Color(0xFF1DB954),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassInsightCard({
    required String title,
    required String insight,
    required String trend,
    required Size screenSize,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.all(screenSize.width * 0.05),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.blue.withOpacity(0.1),
                Colors.purple.withOpacity(0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.tips_and_updates_outlined,
                    color: Colors.yellowAccent,
                    size: screenSize.width * 0.06,
                  ),
                  SizedBox(width: screenSize.width * 0.02),
                  Text(
                    title,
                    style: GoogleFonts.manrope(
                      fontSize: screenSize.width * 0.04,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              SizedBox(height: screenSize.height * 0.01),
              Text(
                insight,
                style: GoogleFonts.manrope(
                  fontSize: screenSize.width * 0.035,
                  color: Colors.white.withOpacity(0.8),
                  height: 1.3,
                ),
              ),
              SizedBox(height: screenSize.height * 0.015),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: screenSize.width * 0.025,
                  vertical: screenSize.height * 0.005,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1DB954).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  trend,
                  style: GoogleFonts.manrope(
                    fontSize: screenSize.width * 0.03,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1DB954),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}

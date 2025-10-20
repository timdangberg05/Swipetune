import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:swipetune/models/user_model.dart';
import 'package:swipetune/providers/spotify_data_provider.dart';
import 'package:swipetune/screens/landing_screen.dart';
import 'package:swipetune/services/auth_services.dart';
import '../providers/user_provider.dart';


class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with TickerProviderStateMixin {
  int _selectedTabIndex = 0;

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().loadUserProfile();
    });
  }

  void _onTabSelected(int index) {
    if (_selectedTabIndex == index) return;
    setState(() => _selectedTabIndex = index);
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

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final user = userProvider.user;
        
        return SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 24.0,
            right: 24.0,
            top: MediaQuery.of(context).padding.top + 80,
            bottom: MediaQuery.of(context).padding.bottom + 120,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Profile Header
              if (userProvider.isLoading)
                const Center(child: CircularProgressIndicator(color: Colors.white))
              else if (user != null)
                _buildProfileHeader(user),
              
              const SizedBox(height: 32),
              
              // Stats Cards
              _buildStatsCards(),
              
              const SizedBox(height: 32),
              
              // Tab Navigation
              _buildModernTabBar(),
              
              const SizedBox(height: 24),
              
              // Tab Content
              _buildTabContent(),
            ],
          ),
        );
      },
    );

    
  }

Widget _buildProfileHeader(SpotifyUser user) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Avatar Links - Größer & mit Gradient Ring
      Container(
        width: 100,
        height: 100,
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
          child: user.imageUrl != null
              ? Image.network(
                  user.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildAvatarFallback();
                  },
                )
              : _buildAvatarFallback(),
        ),
      ),
      
      const SizedBox(width: 16),
      
      // Info Rechts
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display Name
            Text(
              user.displayName,
              style: GoogleFonts.manrope(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.2,
              ),
            ),
            
            const SizedBox(height: 6),
            
            // Username (@id)
            Text(
              '@${user.id}',
              style: GoogleFonts.manrope(
                fontSize: 15,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Badges Row
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // Premium Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1DB954).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF1DB954).withOpacity(0.4),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Text(
                        (user.product?.toUpperCase() ?? 'FREE'),
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1DB954),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Followers Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.15),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('👥', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Text(
                        '${user.followerCount ?? 0}',
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ],
  );
}


  Widget _buildAvatarFallback() {
    return Container(
      color: Colors.white12,
      child: const Icon(Icons.person, size: 40, color: Colors.white54),
    );
  }

  Widget _buildStatsCards() {
    return Consumer<SpotifyDataProvider>(
      builder: (context, dataProvider, child) {
        final totalSwipes = dataProvider.likedCount + dataProvider.dislikedCount;
        final likeRate = totalSwipes == 0 
            ? 0 
            : ((dataProvider.likedCount / totalSwipes) * 100).round();
        
        return Row(
          children: [
            Expanded(child: _buildStatCard('$totalSwipes', 'Swipes')),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('${dataProvider.likedCount}', 'Likes')),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('$likeRate%', 'Like Rate')),
          ],
        );
      },
    );
  }


  Widget _buildStatCard(String value, String label) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
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
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernTabBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              _buildTabButton('Recent', 0),
              _buildTabButton('Following', 1),
              _buildTabButton('Playlists', 2),
              _buildTabButton('Settings', 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton(String label, int index) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onTabSelected(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 12),
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
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.white : Colors.white.withOpacity(0.6),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildRecentTab();
      case 1:
        return _buildFollowingTab();
      case 2:
        return _buildPlaylistsTab();
      case 3:
        return _buildSettingsTab();
      default:
        return const SizedBox();
    }
  }

  Widget _buildRecentTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Recent Swipes', onViewAll: () {}),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 5,
            itemBuilder: (context, index) {
              return _buildSwipeCard(
                isLike: index % 2 == 0,
                songName: 'Song Name',
                artistName: 'Artist',
                timeAgo: '${index + 1}h ago',
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFollowingTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Following Artists', subtitle: '🎵 47 Artists', onViewAll: () {}),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
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

  Widget _buildPlaylistsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('SwipeTune Playlists'),
        const SizedBox(height: 12),
        _buildPlaylistItem(
          title: '💚 Liked Songs',
          subtitle: '234 tracks · Created from your swipes',
        ),
        const SizedBox(height: 24),
        _buildSectionHeader('Your Spotify Playlists', onViewAll: () {}),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
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

  Widget _buildSettingsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Profile',
          style: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 12),
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
        const SizedBox(height: 24),
        Text(
          'Notifications',
          style: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 12),
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
        const SizedBox(height: 24),
        Text(
          'Account',
          style: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 12),
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
                  size: 14,
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
                      child: Icon(Icons.music_note, color: Colors.white24, size: 32),
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
                  child: const Icon(Icons.person, color: Colors.white24, size: 40),
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
                      child: Icon(Icons.library_music, color: Colors.white24, size: 32),
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
                size: 16,
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
                Icon(icon, color: color.withOpacity(0.8), size: 22),
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
                    size: 16,
                  ),
              ],
            ),
          ),
        ),
      ),
    )
    );
  }
}

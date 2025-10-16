import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/modals/liquid_glass_modal_base.dart';
import '../widgets/modals/settings_modals.dart';

class UserProfile {
  final String name;
  final String email;
  final String avatarUrl;
  const UserProfile({required this.name, required this.email, required this.avatarUrl});
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with TickerProviderStateMixin {
  final _user = const UserProfile(
    name: "Adrian",
    email: "adrian@swipetune.app",
    avatarUrl: 'assets/user_profile_pic_standard.png',
  );

  int _selectedTabIndex = 0;
  late final List<Widget> _tabContents;

  @override
  void initState() {
    super.initState();
    _tabContents = const [
      ProfileSettingsTab(),
      NotificationsSettingsTab(),
      SecuritySettingsTab(),
    ];
  }

  void _onTabSelected(int index) {
    if (_selectedTabIndex == index) return;
    setState(() => _selectedTabIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 24.0,
        right: 24.0,
        // The top padding is now smaller because the header lives outside this widget.
        top: MediaQuery.of(context).padding.top + 80, 
        bottom: MediaQuery.of(context).padding.bottom + 120,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileHeader(),
          const SizedBox(height: 40),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTabNavigation(),
              const SizedBox(width: 24),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  switchInCurve: Curves.easeInOut,
                  switchOutCurve: Curves.easeInOut,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: child,
                    );
                  },
                  child: _tabContents[_selectedTabIndex],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  // --- Unchanged Widgets Below ---

  Widget _buildProfileHeader() => Row(
        children: [
          GlassAvatar(assetPath: _user.avatarUrl),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_user.name, style: GoogleFonts.manrope(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 4),
              Text(_user.email, style: GoogleFonts.manrope(fontSize: 14, color: Colors.white.withOpacity(0.6))),
            ],
          ),
        ],
      );

  Widget _buildTabNavigation() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTabItem(index: 0, icon: Icons.person_outline_rounded, label: "Profile"),
          _buildTabItem(index: 1, icon: Icons.notifications_none_rounded, label: "Notifications"),
          _buildTabItem(index: 2, icon: Icons.shield_outlined, label: "Security"),
        ],
      );

  Widget _buildTabItem({required int index, required IconData icon, required String label}) {
    final bool isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () => _onTabSelected(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.white.withOpacity(0.5), size: 22),
            const SizedBox(width: 8),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : Colors.white.withOpacity(0.5),
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileSettingsTab extends StatelessWidget {
  const ProfileSettingsTab({super.key});
  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('profile'),
      children: [
        GlassSettingItem(icon: Icons.edit_outlined, title: "Edit Display Name", subtitle: "Alex"),
        GlassSettingItem(icon: Icons.image_outlined, title: "Change Avatar", subtitle: "Update your picture"),
        GlassSettingItem(icon: Icons.logout_rounded, title: "Log Out", subtitle: "You will be returned to the login screen", isDestructive: true),
      ],
    );
  }
}

class NotificationsSettingsTab extends StatelessWidget {
  const NotificationsSettingsTab({super.key});
  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('notifications'),
      children: [
        GlassSettingItem(icon: Icons.music_note_outlined, title: "New Song Suggestions", subtitle: "Daily recommendations", isToggle: true),
        GlassSettingItem(icon: Icons.playlist_add_check_rounded, title: "Playlist Updates", subtitle: "When your playlists are ready", isToggle: true, initialToggleValue: true),
      ],
    );
  }
}

class SecuritySettingsTab extends StatelessWidget {
  const SecuritySettingsTab({super.key});
  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('security'),
      children: [
        GlassSettingItem(icon: Icons.password_rounded, title: "Change Password", subtitle: "Last changed 3 months ago"),
        GlassSettingItem(icon: Icons.phonelink_lock_rounded, title: "Two-Factor Authentication", subtitle: "Disabled"),
      ],
    );
  }
}

class GlassSettingItem extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDestructive;
  final bool isToggle;
  final bool initialToggleValue;

  const GlassSettingItem({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.isDestructive = false,
    this.isToggle = false,
    this.initialToggleValue = false,
  });

  @override
  State<GlassSettingItem> createState() => _GlassSettingItemState();
}

class _GlassSettingItemState extends State<GlassSettingItem> with SingleTickerProviderStateMixin {
  late bool _isToggled;
  late AnimationController _pressController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _isToggled = widget.initialToggleValue;
    _pressController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.isToggle) return;
    
    _pressController.forward().then((_) => _pressController.reverse());
    
    // Show appropriate modal based on the title
    if (widget.title == "Edit Display Name") {
      _showEditNameModal(context);
    } else if (widget.title == "Change Avatar") {
      _showAvatarPickerModal(context);
    } else if (widget.title == "Log Out") {
      _showLogoutConfirmation(context);
    } else if (widget.title == "Change Password") {
      _showChangePasswordModal(context);
    } else if (widget.title == "Two-Factor Authentication") {
      _show2FAModal(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isDestructive ? const Color(0xFFFF5A5A) : Colors.white;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: GestureDetector(
          onTap: _handleTap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Row(
                  children: [
                    Icon(widget.icon, color: color.withOpacity(0.8), size: 24),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.title, style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
                          Text(widget.subtitle, style: GoogleFonts.manrope(fontSize: 12, color: color.withOpacity(0.6))),
                        ],
                      ),
                    ),
                    if (widget.isToggle)
                      Switch(
                        value: _isToggled,
                        onChanged: (value) => setState(() => _isToggled = value),
                        activeTrackColor: const Color(0xFF1DB954).withOpacity(0.5),
                        activeColor: const Color(0xFF1DB954),
                      )
                    else if (!widget.isDestructive)
                      const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showEditNameModal(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const EditNameModal();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOutCubicEmphasized,
        );
        return ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0).animate(curvedAnimation),
          child: FadeTransition(
            opacity: curvedAnimation,
            child: child,
          ),
        );
      },
    );
  }

  void _showAvatarPickerModal(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const AvatarPickerModal();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOutCubicEmphasized,
        );
        return ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0).animate(curvedAnimation),
          child: FadeTransition(
            opacity: curvedAnimation,
            child: child,
          ),
        );
      },
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const LogoutConfirmationModal();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOutCubicEmphasized,
        );
        return ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0).animate(curvedAnimation),
          child: FadeTransition(
            opacity: curvedAnimation,
            child: child,
          ),
        );
      },
    );
  }

  void _showChangePasswordModal(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const ChangePasswordModal();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOutCubicEmphasized,
        );
        return ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0).animate(curvedAnimation),
          child: FadeTransition(
            opacity: curvedAnimation,
            child: child,
          ),
        );
      },
    );
  }

  void _show2FAModal(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const TwoFactorAuthModal();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOutCubicEmphasized,
        );
        return ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0).animate(curvedAnimation),
          child: FadeTransition(
            opacity: curvedAnimation,
            child: child,
          ),
        );
      },
    );
  }
}

class GlassAvatar extends StatelessWidget {
  final String assetPath;
  const GlassAvatar({super.key, required this.assetPath});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Colors.white.withOpacity(0.3), Colors.white.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: ClipOval(
        child: Image.asset(
          assetPath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.white12,
              child: const Icon(Icons.person, size: 32, color: Colors.white54),
            );
          },
        ),
      ),
    );
  }
}

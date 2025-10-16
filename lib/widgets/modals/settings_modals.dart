import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'liquid_glass_modal_base.dart';
import '../../screens/landing_screen.dart';

/// Edit Display Name Modal
class EditNameModal extends StatefulWidget {
  const EditNameModal({super.key});

  @override
  State<EditNameModal> createState() => _EditNameModalState();
}

class _EditNameModalState extends State<EditNameModal> {
  final _controller = TextEditingController(text: 'Adrian');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LiquidGlassModalBase(
      title: 'Edit Display Name',
      icon: Icons.edit_rounded,
      children: [
        LiquidGlassTextField(controller: _controller, label: 'Display Name'),
        SizedBox(height: MediaQuery.of(context).size.height * 0.04),
        Row(
          children: [
            LiquidGlassButton(
              text: 'Cancel',
              onPressed: () => Navigator.of(context).pop(),
              isSecondary: true,
            ),
            const SizedBox(width: 16),
            LiquidGlassButton(
              text: 'Save',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ],
    );
  }
}

/// Avatar Picker Modal
class AvatarPickerModal extends StatelessWidget {
  const AvatarPickerModal({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return LiquidGlassModalBase(
      title: 'Change Avatar',
      icon: Icons.camera_alt_rounded,
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: WrapAlignment.center,
          children: [
            _buildAvatarOption(Icons.person),
            _buildAvatarOption(Icons.music_note),
            _buildAvatarOption(Icons.star),
            _buildAvatarOption(Icons.favorite),
          ],
        ),
        SizedBox(height: size.height * 0.04),
        LiquidGlassButton(
          text: 'Choose from Gallery',
          onPressed: () => Navigator.of(context).pop(),
          expanded: false,
        ),
        const SizedBox(height: 12),
        LiquidGlassButton(
          text: 'Cancel',
          onPressed: () => Navigator.of(context).pop(),
          isSecondary: true,
          expanded: false,
        ),
      ],
    );
  }

  Widget _buildAvatarOption(IconData icon) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.15),
            Colors.white.withOpacity(0.05),
          ],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Icon(icon, color: Colors.white.withOpacity(0.9), size: 24),
    );
  }
}

/// Logout Confirmation Modal
class LogoutConfirmationModal extends StatelessWidget {
  const LogoutConfirmationModal({super.key});

  void _handleLogout(BuildContext context) async {
    // Close the modal first
    Navigator.of(context).pop();
    
    // Small delay for modal close animation
    await Future.delayed(const Duration(milliseconds: 200));
    
    // Navigate to landing page with smooth fade transition
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) {
            // Import needed at top of file
            return const LandingScreen();
          },
          transitionDuration: const Duration(milliseconds: 800),
          reverseTransitionDuration: const Duration(milliseconds: 500),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
           
            final curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOutCubicEmphasized,
            );
            
            return FadeTransition(
              opacity: curvedAnimation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.95, end: 1.0).animate(curvedAnimation),
                child: child,
              ),
            );
          },
        ),
        (route) => false, // Remove all previous routes
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return LiquidGlassModalBase(
      title: 'Log Out',
      icon: Icons.logout_rounded,
      isDestructive: true,
      children: [
        Text(
          'Are you sure you want to log out?\nYou will be returned to the login screen.',
          textAlign: TextAlign.center,
          style: GoogleFonts.manrope(
            fontSize: 14,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
        SizedBox(height: size.height * 0.04),
        Row(
          children: [
            LiquidGlassButton(
              text: 'Cancel',
              onPressed: () => Navigator.of(context).pop(),
              isSecondary: true,
            ),
            const SizedBox(width: 16),
            LiquidGlassButton(
              text: 'Log Out',
              onPressed: () => _handleLogout(context),
              isDestructive: true,
            ),
          ],
        ),
      ],
    );
  }
}

/// Change Password Modal
class ChangePasswordModal extends StatefulWidget {
  const ChangePasswordModal({super.key});

  @override
  State<ChangePasswordModal> createState() => _ChangePasswordModalState();
}

class _ChangePasswordModalState extends State<ChangePasswordModal> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return LiquidGlassModalBase(
      title: 'Change Password',
      icon: Icons.lock_rounded,
      children: [
        LiquidGlassTextField(
          controller: _currentController,
          label: 'Current Password',
          isPassword: true,
        ),
        const SizedBox(height: 16),
        LiquidGlassTextField(
          controller: _newController,
          label: 'New Password',
          isPassword: true,
        ),
        const SizedBox(height: 16),
        LiquidGlassTextField(
          controller: _confirmController,
          label: 'Confirm New Password',
          isPassword: true,
        ),
        SizedBox(height: size.height * 0.04),
        Row(
          children: [
            LiquidGlassButton(
              text: 'Cancel',
              onPressed: () => Navigator.of(context).pop(),
              isSecondary: true,
            ),
            const SizedBox(width: 16),
            LiquidGlassButton(
              text: 'Update',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ],
    );
  }
}

/// Two Factor Authentication Modal -> kann man löschen wenn nicht gebraucht weil nur platzhalter
class TwoFactorAuthModal extends StatelessWidget {
  const TwoFactorAuthModal({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return LiquidGlassModalBase(
      title: 'Two-Factor Authentication',
      icon: Icons.security_rounded,
      children: [
        Text(
          'Add an extra layer of security to your account',
          textAlign: TextAlign.center,
          style: GoogleFonts.manrope(
            fontSize: 14,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
        SizedBox(height: size.height * 0.04),
        LiquidGlassButton(
          text: 'Enable 2FA',
          onPressed: () => Navigator.of(context).pop(),
          expanded: false,
        ),
        const SizedBox(height: 12),
        LiquidGlassButton(
          text: 'Cancel',
          onPressed: () => Navigator.of(context).pop(),
          isSecondary: true,
          expanded: false,
        ),
      ],
    );
  }
}

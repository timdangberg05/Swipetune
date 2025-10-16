import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Base modal with liquid glass design - reusable component
class LiquidGlassModalBase extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  final Color? accentColor;
  final bool isDestructive;

  const LiquidGlassModalBase({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
    this.accentColor,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final maxWidth = isTablet ? 500.0 : size.width * 0.9;
    final padding = size.width * 0.06;
    
    final effectiveAccentColor = isDestructive 
        ? const Color(0xFFFF5A5A) 
        : (accentColor ?? Colors.white);

    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
                constraints: BoxConstraints(maxWidth: maxWidth),
                padding: EdgeInsets.all(size.width * 0.08),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDestructive
                        ? [
                            const Color(0xFFFF5A5A).withOpacity(0.15),
                            Colors.white.withOpacity(0.05),
                          ]
                        : [
                            Colors.white.withOpacity(0.15),
                            Colors.white.withOpacity(0.05),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: isDestructive
                        ? const Color(0xFFFF5A5A).withOpacity(0.3)
                        : Colors.white.withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, color: effectiveAccentColor, size: 48),
                      SizedBox(height: size.height * 0.03),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.manrope(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: size.height * 0.04),
                      ...children,
                    ],
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

/// Reusable liquid glass text field
class LiquidGlassTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool isPassword;

  const LiquidGlassTextField({
    super.key,
    required this.controller,
    required this.label,
    this.isPassword = false,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword,
            style: GoogleFonts.manrope(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: GoogleFonts.manrope(color: Colors.white.withOpacity(0.6)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
          ),
        ),
      ),
    );
  }
}

/// Reusable liquid glass button
class LiquidGlassButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isSecondary;
  final bool isDestructive;
  final bool expanded;

  const LiquidGlassButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isSecondary = false,
    this.isDestructive = false,
    this.expanded = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? const Color(0xFFFF5A5A) : const Color(0xFF1DB954);

    final button = ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: isSecondary
                    ? null
                    : LinearGradient(
                        colors: [color.withOpacity(0.3), color.withOpacity(0.15)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                color: isSecondary ? Colors.white.withOpacity(0.1) : null,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSecondary ? Colors.white.withOpacity(0.2) : color.withOpacity(0.4),
                ),
              ),
              child: Center(
                child: Text(
                  text,
                  style: GoogleFonts.manrope(
                    color: isSecondary ? Colors.white.withOpacity(0.7) : Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    return expanded ? Expanded(child: button) : button;
  }
}

/// Show modal with smooth animation
void showLiquidGlassModal(BuildContext context, Widget modal) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor: Colors.black.withOpacity(0.5),
    transitionDuration: const Duration(milliseconds: 500),
    pageBuilder: (context, animation, secondaryAnimation) => modal,
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

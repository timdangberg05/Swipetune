import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:swipetune/screens/home_screen.dart';
import 'action_buttons.dart';

// --- Bestehende Widgets bleiben unverändert ---

class LoginPanel extends StatelessWidget {
    final VoidCallback onSignUp;
    const LoginPanel({super.key, required this.onSignUp});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text("Welcome Back", textAlign: TextAlign.center, style: GoogleFonts.manrope(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white)),
        const SizedBox(height: 32),
        _buildTextField(hint: "Username or Email", icon: Icons.person_outline_rounded),
        const SizedBox(height: 16),
        _buildTextField(hint: "Password", icon: Icons.lock_outline_rounded, isPassword: true),
        const SizedBox(height: 24),
        ActionButton(text: "Login", accentColor: const Color(0xFF9B51E0), onTap: () {
            Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const HomePage()),
          );
        }),
        const SizedBox(height: 16),
        Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
                const Text("Don't have an account?", style: TextStyle(color: Colors.white70)),
                TextButton(onPressed: onSignUp, child: const Text("Sign Up")),
            ],
        )
      ],
    );
  }
}

class SignUpPanel extends StatelessWidget {
    final VoidCallback onLogin;
    const SignUpPanel({super.key, required this.onLogin});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text("Create Account", textAlign: TextAlign.center, style: GoogleFonts.manrope(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white)),
        const SizedBox(height: 32),
        _buildTextField(hint: "Email", icon: Icons.email_outlined),
        const SizedBox(height: 16),
        _buildTextField(hint: "Password", icon: Icons.lock_outline_rounded, isPassword: true),
        const SizedBox(height: 16),
        _buildTextField(hint: "Confirm Password", icon: Icons.lock_outline_rounded, isPassword: true),
        const SizedBox(height: 24),
        ActionButton(text: "Sign Up", accentColor: const Color(0xFFF271B6), onTap: () {
            Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const HomePage()),
            );
        }),
         const SizedBox(height: 16),
        Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
                const Text("Already have an account?", style: TextStyle(color: Colors.white70)),
                TextButton(onPressed: onLogin, child: const Text("Log In")),
            ],
        )
      ],
    );
  }
}

Widget _buildTextField({required String hint, required IconData icon, bool isPassword = false}) {
    return TextField(
      obscureText: isPassword,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.7)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withOpacity(0.5))),
      ),
    );
  }


class AuthGlassPanel extends StatelessWidget {
  final Widget child;
  final VoidCallback onClose;
  const AuthGlassPanel({super.key, required this.child, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(onTap: onClose, child: Container(color: Colors.transparent)),
        Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24.0),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: child,
              ),
            ),
          ),
        ),
      ],
    );
  }
}


// --- NEU: Das Spotify Login Panel ---
class SpotifyLoginPanel extends StatelessWidget {
  final VoidCallback onCancel;
  const SpotifyLoginPanel({super.key, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24.0),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Connecting to Spotify...",
                  style: GoogleFonts.manrope(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white
                  ),
                ),
                const SizedBox(height: 24),
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1DB954)),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: onCancel,
                  child: const Text(
                    "Cancel",
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


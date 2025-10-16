import 'dart:ui';
import 'package:flutter/material.dart';

/// Reusable back button component with liquid glass effect
class LibraryBackButton extends StatelessWidget {
  final VoidCallback onTap;
  final double size;

  const LibraryBackButton({
    super.key,
    required this.onTap,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.15)),
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: size,
            ),
          ),
        ),
      ),
    );
  }
}

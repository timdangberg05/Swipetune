import 'dart:ui';
import 'package:flutter/material.dart';

/// Eine animierte Navigationsleiste im "Liquid Glass"-Stil.
/// Sie verwendet einen BackdropFilter, um den durchscheinenden, verschwommenen Effekt zu erzeugen.
class LiquidNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTabTapped;
  final Animation<double> animation;

  const LiquidNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTabTapped,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: const EdgeInsets.only(bottom: 30, left: 24, right: 24),
        height: 64,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(Icons.swipe_rounded, "Swipe", 0),
                  _buildNavItem(Icons.library_music_rounded, "Library", 1),
                  _buildNavItem(Icons.favorite_border_rounded, "Likes", 2),
                  _buildNavItem(Icons.settings_outlined, "Settings", 3),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Baut ein einzelnes Navigations-Element 
  Widget _buildNavItem(IconData icon, String label, int index) {
    final bool isSelected = selectedIndex == index;
    return GestureDetector(
      onTap: () => onTabTapped(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            // Animiert die Breite, um den Text ein- und auszublenden.
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              child: SizedBox(
                width: isSelected ? 60 : 0, // Feste Breite für den Text
                child: isSelected
                    ? Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Text(
                          label,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.fade,
                          softWrap: false,
                        ),
                      )
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

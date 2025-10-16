import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  final VoidCallback onReload;

  const EmptyState({super.key, required this.onReload});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.music_note, size: 72, color: Colors.white70),
          const SizedBox(height: 16),
          const Text("Keine Songs mehr",
              style: TextStyle(fontSize: 20, color: Colors.white)),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onReload,
            style: TextButton.styleFrom(foregroundColor: Colors.greenAccent),
            child: const Text("Erneut laden"),
          ),
        ],
      ),
    );
  }
}

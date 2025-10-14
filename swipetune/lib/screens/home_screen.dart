import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0E),
      appBar: AppBar(title: const Text("Swipetune Home"), backgroundColor: Colors.transparent, elevation: 0),
      body: const Center(child: Text("Welcome!")),
    );
  }
}
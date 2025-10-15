import 'package:flutter/material.dart';
import 'pages/homepage.dart';

void main() {
  runApp(SwipeTuneApp());
}

class SwipeTuneApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: SwipeHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
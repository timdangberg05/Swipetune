import 'package:flutter/material.dart';

class Blob {
  Offset position;
  final double radius;
  Offset velocity; // 'final' entfernt
  Color color;     // 'final' entfernt
  
  Blob({
    required this.position, 
    required this.radius, 
    required this.velocity, 
    required this.color
  });
}

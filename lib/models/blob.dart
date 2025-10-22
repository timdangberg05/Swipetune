import 'package:flutter/material.dart';

class Blob {
  Offset position;
  double radius;
  Offset velocity;
  Color color;
  
  Blob({
    required this.position, 
    required this.radius, 
    required this.velocity, 
    required this.color
  });
}

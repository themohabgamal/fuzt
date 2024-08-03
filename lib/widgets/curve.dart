import 'package:flutter/material.dart';

class BarcodeBackgroundClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height * 0.4); // Start from bottom left
    path.lineTo(size.width * 0.2, size.height * 0.3); // Draw a diagonal line
    path.lineTo(size.width * 0.4, size.height * 0.5); // Add another line
    path.lineTo(size.width * 0.6, size.height * 0.4); // Continue lines
    path.lineTo(size.width * 0.8, size.height * 0.5); // More lines
    path.lineTo(size.width, size.height * 0.4); // Complete the shape
    path.lineTo(size.width, 0); // Move to top right
    path.close(); // Close the path
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

import 'package:flutter/material.dart';

// Bentuk gelombang lembut untuk bagian bawah header berwarna.
// Dipakai bersama oleh LoginScreen & OnboardingScreen supaya gaya
// "header gelombang + kartu putih menimpa" terasa satu kesatuan.
class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 50);
    path.quadraticBezierTo(
        size.width * 0.25, size.height, size.width * 0.5, size.height - 26);
    path.quadraticBezierTo(
        size.width * 0.75, size.height - 52, size.width, size.height - 18);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

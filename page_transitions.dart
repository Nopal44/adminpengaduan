import 'package:flutter/material.dart';

// Transisi halaman kustom: gabungan fade + slide naik sedikit dari bawah.
// Dipakai di seluruh aplikasi supaya perpindahan antar halaman (Onboarding
// -> Login -> Daftar/Admin, dsb) terasa halus, bukan cuma "potong-ganti"
// bawaan Flutter.
Route<T> fadeSlideRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 420),
    reverseTransitionDuration: const Duration(milliseconds: 320),
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved =
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.06),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

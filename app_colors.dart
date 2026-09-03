import 'package:flutter/material.dart';

// Palet warna aplikasi, diselaraskan dengan logo SLB Marsudi Putra III
// Sanden: biru langit (lambang lingkaran), hijau (dedaunan), dan emas
// (padi/bintang). Dipakai konsisten di seluruh halaman siswa.
//
// Warna-warna statis di bawah ini (primary, leaf, gold, status, dst.)
// TIDAK berubah antara tema Terang/Gelap karena merupakan warna khas
// (brand) aplikasi dan tetap harus kontras di header gradasi berwarna.
//
// Untuk warna yang HARUS menyesuaikan tema Terang/Gelap (latar halaman,
// permukaan kartu, warna teks, garis pembatas, dsb), gunakan
// `AppColors.of(context)` yang mengembalikan `AppPalette` sesuai
// Theme.of(context).brightness saat itu.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF2D7DC0); // biru utama
  static const Color primaryDark = Color(0xFF1B5A8F); // biru gelap (gradasi)
  static const Color leaf = Color(0xFF2E8B57); // hijau daun
  static const Color gold = Color(0xFFF2B705); // emas/kuning padi

  // Dipertahankan sebagai referensi warna terang "default"/fallback.
  // Untuk pemakaian pada widget, lebih baik pakai AppColors.of(context).
  static const Color background = Color(0xFFF4F8FC);
  static const Color surface = Colors.white;

  static const Color textPrimary = Color(0xFF1E2A38);
  static const Color textSecondary = Color(0xFF6B7785);

  // Warna status pengaduan (tetap sama di kedua tema untuk konsistensi arti)
  static const Color statusMenunggu = Color(0xFFF2994A);
  static const Color statusProses = Color(0xFF2D7DC0);
  static const Color statusSelesai = Color(0xFF27AE60);

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
  );

  // Ambil palet warna yang sudah menyesuaikan tema Terang/Gelap aktif.
  static AppPalette of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppPalette._dark : AppPalette._light;
  }
}

// Kumpulan warna yang berbeda nilainya antara tema Terang & Gelap.
class AppPalette {
  const AppPalette._({
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.card,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
    required this.divider,
    required this.shadow,
    required this.iconMuted,
  });

  final Color background; // latar belakang Scaffold
  final Color surface; // kartu/kontainer utama (dulu Colors.white)
  final Color surfaceAlt; // kontainer sekunder (dulu abu-abu muda/F4F8FC)
  final Color card; // kartu di dalam list
  final Color textPrimary;
  final Color textSecondary;
  final Color border;
  final Color divider;
  final Color shadow;
  final Color iconMuted;

  static const AppPalette _light = AppPalette._(
    background: Color(0xFFF4F8FC),
    surface: Colors.white,
    surfaceAlt: Color(0xFFF4F8FC),
    card: Colors.white,
    textPrimary: Color(0xFF1E2A38),
    textSecondary: Color(0xFF6B7785),
    border: Color(0xFFE3E8EF),
    divider: Color(0xFFE3E8EF),
    shadow: Color(0x1A1E2A38),
    iconMuted: Color(0xFF6B7785),
  );

  static const AppPalette _dark = AppPalette._(
    background: Color(0xFF121417),
    surface: Color(0xFF1C1F24),
    surfaceAlt: Color(0xFF20242A),
    card: Color(0xFF1C1F24),
    textPrimary: Color(0xFFF2F4F7),
    textSecondary: Color(0xFFAEB4BB),
    border: Color(0xFF2C3138),
    divider: Color(0xFF2C3138),
    shadow: Color(0x66000000),
    iconMuted: Color(0xFF9199A3),
  );
}

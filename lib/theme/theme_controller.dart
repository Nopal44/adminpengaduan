import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Pengendali tema Gelap/Terang aplikasi secara global.
// Dipakai lewat ValueListenableBuilder di MaterialApp (lihat main.dart),
// dan bisa diubah dari mana saja (menu titik tiga Siswa maupun Admin/
// Petugas) lewat toggleThemeMode().
//
// Pilihan tema ini DISIMPAN secara permanen ke penyimpanan perangkat
// memakai shared_preferences, supaya tetap kepakai walau aplikasi
// ditutup total, atau siswa/admin logout lalu login lagi. Sebelumnya
// pilihan ini hanya tersimpan di memori (hilang tiap keluar-masuk),
// itu sebabnya tema selalu balik ke Terang.
final ValueNotifier<ThemeMode> themeModeNotifier =
    ValueNotifier(ThemeMode.light);

const String _kKeyTemaGelap = 'tema_gelap';

bool get isDarkMode => themeModeNotifier.value == ThemeMode.dark;

// Prosedur: memuat pilihan tema tersimpan dari penyimpanan perangkat.
// Dipanggil sekali di awal (main.dart) SEBELUM runApp, supaya aplikasi
// langsung tampil dengan tema yang benar sejak layar pertama muncul
// (tidak "kedip" ganti tema setelah halaman terbuka).
Future<void> muatTemaTersimpan() async {
  final prefs = await SharedPreferences.getInstance();
  final gelap = prefs.getBool(_kKeyTemaGelap) ?? false;
  themeModeNotifier.value = gelap ? ThemeMode.dark : ThemeMode.light;
}

// Prosedur: ganti tema Gelap/Terang secara global, sekaligus menyimpannya
// secara permanen ke penyimpanan perangkat supaya pilihan ini tetap
// dipakai walau aplikasi ditutup atau siswa logout & login lagi.
Future<void> toggleThemeMode() async {
  final gelapBaru = !isDarkMode;
  // Ubah tampilan dulu supaya terasa responsif (tidak menunggu penyimpanan
  // selesai), baru simpan ke perangkat di belakang layar.
  themeModeNotifier.value = gelapBaru ? ThemeMode.dark : ThemeMode.light;

  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_kKeyTemaGelap, gelapBaru);
}

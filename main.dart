import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'screens/staff_login_screen.dart';
import 'screens/admin/dashboard_admin_screen.dart';
import 'services/notification_service.dart';
import 'theme/app_colors.dart';
import 'theme/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Daftarkan handler notifikasi PUSH (FCM) untuk kondisi
  // background/aplikasi tertutup total. WAJIB didaftarkan sebelum
  // runApp() dan sebelum pemanggilan Firebase lain terkait messaging.
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  // Siapkan notifikasi lokal (pembaruan aspirasi, chat, & akun) di awal,
  // sebelum aplikasi ditampilkan.
  await NotificationService().init();
  // Muat pilihan tema Gelap/Terang yang tersimpan di perangkat, supaya
  // aplikasi terbuka langsung dengan tema terakhir yang dipilih admin/
  // petugas (tidak balik ke Terang tiap keluar-masuk).
  await muatTemaTersimpan();
  runApp(const AdminWebApp());
}

class AdminWebApp extends StatelessWidget {
  const AdminWebApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Dengarkan perubahan tema Gelap/Terang secara global, supaya menekan
    // toggle di menu titik tiga (Admin/Petugas) langsung
    // mengganti tampilan seluruh aplikasi tanpa perlu restart.
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'Admin Panel - Pengaduan Sarana Sekolah SLB Marsudi Putra 3 Sanden',
          debugShowCheckedModeBanner: false,
          themeMode: mode,
          theme: ThemeData(
            colorSchemeSeed: Colors.indigo,
            useMaterial3: true,
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFF4F8FC),
            cardColor: Colors.white,
            dialogBackgroundColor: Colors.white,
            popupMenuTheme: const PopupMenuThemeData(color: Colors.white),
          ),
          darkTheme: ThemeData(
            colorSchemeSeed: Colors.indigo,
            useMaterial3: true,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF121417),
            cardColor: const Color(0xFF1C1F24),
            dialogBackgroundColor: const Color(0xFF1C1F24),
            popupMenuTheme:
                const PopupMenuThemeData(color: Color(0xFF1C1F24)),
          ),
          home: const AuthGateAdmin(),
        );
      },
    );
  }
}

// AuthGateAdmin: versi website khusus Admin/Petugas.
// - Jika belum login → tampilkan StaffLoginScreen
// - Jika sudah login sebagai Admin/Petugas → DashboardAdminScreen
// - Jika login sebagai Siswa atau akun tidak dikenal → paksa logout
//   dan kembali ke halaman login staff (halaman siswa tidak ditampilkan).
class AuthGateAdmin extends StatelessWidget {
  const AuthGateAdmin({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
                child: CircularProgressIndicator(color: AppColors.primary)),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          return const StaffLoginScreen();
        }

        return FutureBuilder<_JenisAkun>(
          future: _cariJenisAkun(user.email ?? ''),
          builder: (context, akunSnap) {
            if (akunSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                    child: CircularProgressIndicator(color: AppColors.primary)),
              );
            }

            switch (akunSnap.data) {
              case _JenisAkun.admin:
                return const DashboardAdminScreen(isAdmin: true);
              case _JenisAkun.petugas:
                return const DashboardAdminScreen(isAdmin: false);
              case _JenisAkun.siswa:
              case _JenisAkun.tidakDikenal:
              default:
                // Website ini hanya untuk Admin/Petugas.
                // Siswa atau akun tidak dikenal → logout paksa.
                FirebaseAuth.instance.signOut();
                return const StaffLoginScreen();
            }
          },
        );
      },
    );
  }

  Future<_JenisAkun> _cariJenisAkun(String email) async {
    if (email.isEmpty) return _JenisAkun.tidakDikenal;
    final db = FirebaseFirestore.instance;

    // Cek apakah email terdaftar sebagai Admin
    final adminDoc = await db.collection('admin').doc(email).get();
    if (adminDoc.exists) return _JenisAkun.admin;

    // Cek apakah email terdaftar sebagai Petugas
    final petugasDoc = await db.collection('petugas').doc(email).get();
    if (petugasDoc.exists) return _JenisAkun.petugas;

    // Cek pola siswa (jika ada yang coba login lewat sini)
    if (email.endsWith('@siswa.sekolah.id')) {
      return _JenisAkun.siswa;
    }

    return _JenisAkun.tidakDikenal;
  }
}

enum _JenisAkun { siswa, admin, petugas, tidakDikenal }

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Handler pesan FCM saat aplikasi berada di BACKGROUND atau sudah
// DITUTUP TOTAL. WAJIB berupa top-level function (bukan method di dalam
// class) dan diberi anotasi @pragma('vm:entry-point') supaya tetap bisa
// dipanggil Android walau proses Flutter sebelumnya sudah dimatikan.
//
// Catatan: kalau pesan FCM yang dikirim dari Cloud Functions sudah
// menyertakan payload "notification" (bukan cuma "data"), sistem Android
// SUDAH otomatis menampilkannya di tray notifikasi TANPA butuh kode ini.
// Handler ini hanya untuk pemrosesan tambahan (mis. logging) saat pesan
// diterima di kondisi background/terminated.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Sengaja dibiarkan kosong: notifikasi sudah tampil otomatis oleh sistem
  // karena payload dari Cloud Functions selalu menyertakan "notification".
}

// NotificationService: menggabungkan 2 jenis notifikasi supaya penggunanya
// (Admin, Petugas, & Siswa) tetap dapat pemberitahuan di kedua kondisi:
//
// 1) NOTIFIKASI LOKAL (flutter_local_notifications) — dipicu langsung oleh
//    kode Dart saat mendeteksi perubahan data secara realtime SELAGI
//    aplikasi terbuka (foreground/background dalam sesi yang sama).
// 2) NOTIFIKASI PUSH (Firebase Cloud Messaging) — dikirim dari server
//    (Cloud Functions, lihat folder functions/) sehingga tetap muncul di
//    tray notifikasi Android WALAU APLIKASI SUDAH DITUTUP TOTAL.
//
// Dipakai untuk memberi tahu:
// - Siswa: saat ada update status/feedback aspirasi, pesan chat baru dari
//   Admin/Petugas.
// - Admin/Petugas: saat ada pengaduan baru, pendaftaran akun siswa baru,
//   rating aplikasi baru, ATAU pesan chat baru dari siswa.
class NotificationService {
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _sudahDiinisialisasi = false;
  int _idBerikutnya = 0;

  static const String _idChannel = 'pengaduan_sarana_channel';
  static const String _namaChannel = 'Pemberitahuan Pengaduan Sarana';
  static const String _deskripsiChannel =
      'Notifikasi pembaruan aspirasi, chat, dan akun';

  // Prosedur: siapkan plugin notifikasi lokal & FCM, lalu minta izin.
  // Dipanggil sekali di awal (main.dart), aman dipanggil berkali-kali
  // (idempotent).
  Future<void> init() async {
    if (_sudahDiinisialisasi) return;
    _sudahDiinisialisasi = true;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings =
        InitializationSettings(android: androidInit, iOS: iosInit);

    await _plugin.initialize(initSettings);

    // Android 13+ mewajibkan izin notifikasi diminta secara eksplisit
    // saat runtime (selain deklarasi di AndroidManifest.xml). Ini juga
    // otomatis melingkupi izin yang dibutuhkan notifikasi push (FCM).
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // ---- Firebase Cloud Messaging (notifikasi PUSH) ----
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Saat pesan push diterima SELAGI aplikasi terbuka di layar
    // (foreground), Android/iOS TIDAK menampilkannya otomatis di tray —
    // jadi kita tampilkan manual lewat notifikasi lokal supaya
    // pengalamannya konsisten dengan saat aplikasi di background/tertutup.
    FirebaseMessaging.onMessage.listen((message) {
      final judul = message.notification?.title;
      final isi = message.notification?.body;
      if (judul != null && isi != null) {
        tampilkan(judul: judul, isi: isi);
      }
    });
  }

  // Fungsi: mengambil FCM token unik perangkat ini, dipakai server (Cloud
  // Functions) sebagai "alamat" tujuan pengiriman notifikasi push.
  // Mengembalikan null kalau gagal (mis. tidak ada koneksi internet).
  Future<String?> ambilFcmToken() async {
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (e) {
      debugPrint('Gagal mengambil FCM token: $e');
      return null;
    }
  }

  // Prosedur: mendengarkan token FCM yang baru (token bisa berubah
  // sewaktu-waktu, mis. setelah aplikasi diinstal ulang), lalu memanggil
  // [simpanKeFirestore] setiap kali token baru didapat supaya data token
  // di server selalu yang terbaru.
  void pantauPerubahanToken(void Function(String token) simpanKeFirestore) {
    FirebaseMessaging.instance.onTokenRefresh.listen(simpanKeFirestore);
  }

  // Prosedur: menampilkan 1 notifikasi ke tray notifikasi perangkat.
  Future<void> tampilkan({required String judul, required String isi}) async {
    if (!_sudahDiinisialisasi) await init();

    const androidDetail = AndroidNotificationDetails(
      _idChannel,
      _namaChannel,
      channelDescription: _deskripsiChannel,
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetail = DarwinNotificationDetails();
    const detail = NotificationDetails(android: androidDetail, iOS: iosDetail);

    // id unik per notifikasi supaya tidak saling menimpa satu sama lain
    // di tray notifikasi.
    await _plugin.show(_idBerikutnya++, judul, isi, detail);
  }
}

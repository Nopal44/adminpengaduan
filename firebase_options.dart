// Konfigurasi Firebase project ini SUDAH DIISI menggunakan
// google-services.json dari project Firebase "pengaduan-sarana-f7479".
// Package name Android: com.pengaduansarana.app
// Pastikan applicationId di project FlutLab Anda SAMA PERSIS dengan
// package name ini, atau autentikasi/koneksi Firebase akan gagal.

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions belum dikonfigurasi untuk platform ini.',
        );
    }
  }

  // Konfigurasi project Firebase: pengaduan-sarana-f7479
  // (diambil dari google-services.json yang diberikan)
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAYwxTYw7l3BFXhzTStmIwgoePMxYI17yA',
    appId: '1:122902024930:android:74ce143f56dd69da06c4bb',
    messagingSenderId: '122902024930',
    projectId: 'pengaduan-sarana-f7479',
    storageBucket: 'pengaduan-sarana-f7479.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'GANTI_DENGAN_API_KEY_ANDA',
    appId: 'GANTI_DENGAN_APP_ID_IOS_ANDA',
    messagingSenderId: 'GANTI_DENGAN_SENDER_ID_ANDA',
    projectId: 'GANTI_DENGAN_PROJECT_ID_ANDA',
    storageBucket: 'GANTI_DENGAN_PROJECT_ID_ANDA.appspot.com',
    iosBundleId: 'com.sekolah.pengaduansarana',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDMHdeZ_MxLpsXvAv3I2wG6c2Lwts10J_0',
    appId: '1:122902024930:web:e2a728b6efaf2d6806c4bb',
    messagingSenderId: '122902024930',
    projectId: 'pengaduan-sarana-f7479',
    storageBucket: 'pengaduan-sarana-f7479.firebasestorage.app',
  );
}

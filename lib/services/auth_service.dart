import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase_options.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ---------------- SISWA ----------------

  // Daftar akun siswa baru. Status akun otomatis 'pending' (menunggu),
  // sehingga siswa BELUM BISA login sampai disetujui oleh Admin atau Petugas.
  Future<String?> registerSiswa({
    required String nis,
    required String nama,
    required String kelas,
    required String password,
  }) async {
    try {
      final email = _nisToEmail(nis);
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _db.collection('siswa').doc(nis).set({
        'nama': nama,
        'kelas': kelas,
        'status': 'pending',
      });

      // Langsung sign out setelah daftar: akun belum disetujui,
      // jadi jangan biarkan siswa otomatis "masuk".
      await _auth.signOut();

      return null;
    } on FirebaseAuthException catch (e) {
      return _pesanError(e.code);
    } catch (e) {
      return 'Terjadi kesalahan: $e';
    }
  }

  Future<String?> loginSiswa(String nis, String password) async {
    try {
      final email = _nisToEmail(nis);
      await _auth.signInWithEmailAndPassword(email: email, password: password);

      final doc = await _db.collection('siswa').doc(nis).get();
      if (!doc.exists) {
        await _auth.signOut();
        return 'Data siswa (NIS) tidak ditemukan di database.';
      }

      final data = doc.data() as Map<String, dynamic>;
      final status = data['status'] ?? 'approved';

      if (status == 'pending') {
        await _auth.signOut();
        return 'Akun Anda masih menunggu persetujuan Admin/Petugas.';
      }
      if (status == 'rejected') {
        await _auth.signOut();
        return 'Pendaftaran akun Anda ditolak. Hubungi Admin/Petugas sekolah.';
      }

      return null;
    } on FirebaseAuthException catch (e) {
      return _pesanError(e.code);
    } catch (e) {
      return 'Terjadi kesalahan: $e';
    }
  }

  // ---------------- ADMIN ----------------
  // Login Admin memakai EMAIL ASLI (misal Gmail), bukan format buatan.
  // Dokumen di Firestore collection 'admin' pakai ID = email tersebut.

  Future<String?> loginAdmin(String email, String password) async {
    try {
      final emailBersih = email.trim();
      await _auth.signInWithEmailAndPassword(
          email: emailBersih, password: password);

      final doc = await _db.collection('admin').doc(emailBersih).get();
      if (!doc.exists) {
        await _auth.signOut();
        return 'Akun admin tidak ditemukan di database.';
      }
      return null;
    } on FirebaseAuthException catch (e) {
      return _pesanError(e.code);
    } catch (e) {
      return 'Terjadi kesalahan: $e';
    }
  }

  // ---------------- PETUGAS ----------------
  // Login Petugas juga memakai EMAIL ASLI, sama seperti Admin.

  Future<String?> loginPetugas(String email, String password) async {
    try {
      final emailBersih = email.trim();
      await _auth.signInWithEmailAndPassword(
          email: emailBersih, password: password);

      final doc = await _db.collection('petugas').doc(emailBersih).get();
      if (!doc.exists) {
        await _auth.signOut();
        return 'Akun petugas tidak ditemukan di database.';
      }
      return null;
    } on FirebaseAuthException catch (e) {
      return _pesanError(e.code);
    } catch (e) {
      return 'Terjadi kesalahan: $e';
    }
  }

  // Prosedur: Admin membuat akun Petugas baru LANGSUNG DARI APLIKASI,
  // tanpa perlu buka Firebase Console. Petugas login pakai email aslinya
  // sendiri (Gmail dsb), bukan format buatan.
  //
  // Kenapa pakai "secondary Firebase App"?
  // Kalau kita panggil createUserWithEmailAndPassword() memakai instance
  // FirebaseAuth utama (_auth), Firebase otomatis akan login sebagai user
  // BARU tersebut dan admin yang sedang login akan ikut ter-logout.
  // Solusinya: buat instance FirebaseApp kedua ("secondary") khusus untuk
  // proses pembuatan akun ini, lalu instance itu langsung di-signOut &
  // dibuang. Sesi login Admin di instance utama sama sekali tidak
  // terganggu.
  Future<String?> createPetugas({
    required String email,
    required String nama,
    required String password,
  }) async {
    FirebaseApp? secondaryApp;
    try {
      final emailBersih = email.trim();

      // Cegah duplikat
      final existing = await _db.collection('petugas').doc(emailBersih).get();
      if (existing.exists) {
        return 'Email petugas ini sudah dipakai.';
      }

      // Jika instance sementara ini masih ada dari proses sebelumnya
      // (misal sempat gagal dibersihkan), pakai ulang saja alih-alih
      // membuat baru dengan nama yang sama (yang akan error 'duplicate-app').
      try {
        secondaryApp = Firebase.app('secondaryAppPembuatPetugas');
      } on FirebaseException {
        secondaryApp = await Firebase.initializeApp(
          name: 'secondaryAppPembuatPetugas',
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      await secondaryAuth.createUserWithEmailAndPassword(
        email: emailBersih,
        password: password,
      );

      // Simpan datanya di instance Firestore utama (Firestore tidak
      // terpengaruh oleh sesi Auth mana pun, jadi aman dipakai langsung).
      await _db.collection('petugas').doc(emailBersih).set({
        'nama': nama,
        'email': emailBersih,
      });

      await secondaryAuth.signOut();
      return null;
    } on FirebaseAuthException catch (e) {
      return _pesanError(e.code);
    } catch (e) {
      return 'Terjadi kesalahan: $e';
    } finally {
      // Selalu bersihkan app sementara ini supaya tidak menumpuk.
      if (secondaryApp != null) {
        await secondaryApp.delete();
      }
    }
  }

  // ---------------- UMUM ----------------

  Future<void> logout() async {
    await _auth.signOut();
  }

  User? get currentUser => _auth.currentUser;

  String _nisToEmail(String nis) => '${nis.trim()}@siswa.sekolah.id';

  String _pesanError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Akun tidak ditemukan.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email/NIS atau password salah.';
      case 'invalid-email':
        return 'Format email tidak valid.';
      case 'email-already-in-use':
        return 'Email ini sudah terdaftar.';
      case 'weak-password':
        return 'Password terlalu lemah, minimal 6 karakter.';
      default:
        return 'Login gagal ($code).';
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/aspirasi_model.dart';
import '../models/kategori_model.dart';
import '../models/siswa_model.dart';
import '../models/petugas_model.dart';
import '../models/rating_aplikasi_model.dart';
import '../models/chat_model.dart';

// FirestoreService berisi seluruh PROSEDUR & FUNGSI akses data
// (Create, Read, Update) terhadap struktur data aplikasi, sesuai
// ketentuan soal poin 1 & 7 (struktur data + akses data) dan
// poin 8b (gunakan prosedur dan fungsi).
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _aspirasiRef => _db.collection('aspirasi');
  CollectionReference get _kategoriRef => _db.collection('kategori');
  CollectionReference get _siswaRef => _db.collection('siswa');
  CollectionReference get _petugasRef => _db.collection('petugas');
  CollectionReference get _chatsRef => _db.collection('chats');

  // ---------------- KATEGORI ----------------

  // Fungsi: mengambil seluruh kategori (untuk dropdown form aspirasi)
  Stream<List<KategoriModel>> getKategoriStream() {
    return _kategoriRef.orderBy('ket_kategori').snapshots().map((snap) {
      return snap.docs
          .map((d) =>
              KategoriModel.fromMap(d.id, d.data() as Map<String, dynamic>))
          .toList();
    });
  }

  // Prosedur: menambah kategori baru (dipakai admin, opsional)
  Future<void> tambahKategori(String idKategori, String ketKategori) async {
    await _kategoriRef.doc(idKategori).set({'ket_kategori': ketKategori});
  }

  // ---------------- SISWA ----------------

  // Fungsi: mengambil data profil siswa berdasarkan NIS
  Future<SiswaModel?> getSiswa(String nis) async {
    final doc = await _siswaRef.doc(nis).get();
    if (!doc.exists) return null;
    return SiswaModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
  }

  // ---------------- PETUGAS (dikelola oleh Admin) ----------------

  // Fungsi: stream seluruh akun petugas (untuk halaman "Kelola Petugas"
  // milik Admin). Diurutkan di sisi aplikasi supaya tidak perlu index.
  Stream<List<PetugasModel>> getPetugasStream() {
    return _petugasRef.snapshots().map((snap) {
      final list = snap.docs
          .map((d) =>
              PetugasModel.fromMap(d.id, d.data() as Map<String, dynamic>))
          .toList();
      list.sort((a, b) => a.nama.compareTo(b.nama));
      return list;
    });
  }

  // Catatan: PEMBUATAN akun petugas (Firebase Auth + dokumen Firestore-nya)
  // dilakukan lewat AuthService.createPetugas(), BUKAN di sini, karena
  // prosesnya perlu membuat user login (butuh instance Firebase Auth
  // terpisah). Fungsi ini hanya untuk menghapus data petugas dari Firestore.
  Future<void> hapusDataPetugas(String username) async {
    await _petugasRef.doc(username).delete();
  }

  // ---------------- RATING APLIKASI (bukan rating per-pengaduan) ----------------
  // Ditampilkan secara publik di halaman sebelum Login, agar siapa pun
  // (termasuk calon siswa/orang tua) bisa melihat ulasan siswa terhadap
  // aplikasi ini secara umum.
  CollectionReference get _ratingAplikasiRef =>
      _db.collection('rating_aplikasi');

  // Fungsi: stream seluruh rating aplikasi, terbaru dulu.
  Stream<List<RatingAplikasiModel>> getRatingAplikasiStream() {
    return _ratingAplikasiRef.snapshots().map((snap) {
      final list = snap.docs
          .map((d) => RatingAplikasiModel.fromMap(
              d.id, d.data() as Map<String, dynamic>))
          .toList();
      list.sort((a, b) => b.tanggal.compareTo(a.tanggal));
      return list;
    });
  }

  // Fungsi: mengambil rating aplikasi milik satu siswa (untuk pre-isi form
  // saat siswa ingin mengubah rating yang pernah diberikan).
  Future<RatingAplikasiModel?> getRatingAplikasiSiswa(String nis) async {
    final doc = await _ratingAplikasiRef.doc(nis).get();
    if (!doc.exists) return null;
    return RatingAplikasiModel.fromMap(
        doc.id, doc.data() as Map<String, dynamic>);
  }

  // Prosedur: siswa mengirim/mengubah rating aplikasi (satu siswa = satu
  // rating, dokumen di-ID-kan dengan NIS supaya otomatis menimpa rating
  // lama kalau siswa mengubahnya).
  Future<void> kirimRatingAplikasi({
    required String nis,
    required String nama,
    required int rating,
    required String komentar,
  }) async {
    await _ratingAplikasiRef.doc(nis).set(
      RatingAplikasiModel(
        nis: nis,
        nama: nama,
        rating: rating,
        komentar: komentar,
        tanggal: DateTime.now(),
      ).toMap(),
    );
  }

  // ---------------- PERSETUJUAN AKUN SISWA ----------------

  // Fungsi: stream SELURUH akun siswa apa pun statusnya (pending/approved/
  // rejected), dipakai di halaman "Data Akun Siswa" milik Admin untuk
  // melihat profil semua siswa yang terdaftar. Diurutkan di sisi aplikasi
  // supaya tidak perlu index tambahan.
  Stream<List<SiswaModel>> getSemuaSiswaStream() {
    return _siswaRef.snapshots().map((snap) {
      final list = snap.docs
          .map((d) =>
              SiswaModel.fromMap(d.id, d.data() as Map<String, dynamic>))
          .toList();
      list.sort((a, b) => a.nama.compareTo(b.nama));
      return list;
    });
  }

  // Fungsi: stream siswa yang berstatus 'pending' (menunggu persetujuan),
  // dipakai di halaman "Persetujuan Akun Siswa" milik Admin & Petugas.
  Stream<List<SiswaModel>> getSiswaPendingStream() {
    return _siswaRef.where('status', isEqualTo: 'pending').snapshots().map(
        (snap) => snap.docs
            .map((d) =>
                SiswaModel.fromMap(d.id, d.data() as Map<String, dynamic>))
            .toList());
  }

  // Prosedur: menyetujui pendaftaran akun siswa.
  Future<void> setujuiSiswa(String nis) async {
    await _siswaRef.doc(nis).update({'status': 'approved'});
  }

  // Prosedur: menolak pendaftaran akun siswa.
  Future<void> tolakSiswa(String nis) async {
    await _siswaRef.doc(nis).update({'status': 'rejected'});
  }

  // ---------------- ASPIRASI ----------------

  // Prosedur: menyimpan aspirasi/pengaduan baru dari siswa (Halaman Form
  // Aspirasi Siswa pada soal). ID dibuat otomatis (auto-increment sederhana
  // memakai timestamp) supaya query tetap efisien tanpa perlu counter global.
  Future<void> tambahAspirasi(AspirasiModel aspirasi) async {
    final id = 'ASP${DateTime.now().millisecondsSinceEpoch}';
    await _aspirasiRef.doc(id).set(aspirasi.toMap());
  }

  // Fungsi: stream seluruh aspirasi milik satu siswa (untuk histori),
  // diurutkan dari yang terbaru. Pengurutan dilakukan di sisi aplikasi
  // (bukan lewat orderBy di query) supaya TIDAK memerlukan composite index
  // tambahan di Firestore, sehingga langsung berjalan tanpa setup ekstra.
  Stream<List<AspirasiModel>> getAspirasiBySiswa(String nis) {
    return _aspirasiRef.where('nis', isEqualTo: nis).snapshots().map((snap) {
      final list = snap.docs
          .map((d) =>
              AspirasiModel.fromMap(d.id, d.data() as Map<String, dynamic>))
          .toList();
      list.sort((a, b) => b.tanggal.compareTo(a.tanggal)); // terbaru dulu
      return list;
    });
  }

  // Fungsi: stream seluruh aspirasi (untuk Admin - list keseluruhan),
  // dengan filter opsional per kategori, per status, dan rentang tanggal
  // (mendukung kebutuhan "per tanggal, per bulan, per siswa, per kategori").
  // Catatan: filter kategori & status SENGAJA tidak dikirim sebagai
  // `where(...)` ke Firestore bersamaan dengan `orderBy('tanggal')`,
  // karena kombinasi itu butuh composite index (baru bisa jalan setelah
  // index-nya dibuat manual di Firebase Console -> error
  // "failed-precondition: query requires an index"). Supaya app langsung
  // jalan tanpa perlu bikin index apa pun, kita ambil semua data terurut
  // tanggal dari server, lalu filter kategori/status di sisi aplikasi
  // (sama seperti filter pencarian NIS yang juga dilakukan di client).
  Stream<List<AspirasiModel>> getAllAspirasi({
    String? idKategori,
    StatusAspirasi? status,
    DateTime? mulai,
    DateTime? akhir,
  }) {
    Query query = _aspirasiRef.orderBy('tanggal', descending: true);

    if (mulai != null) {
      query = query.where('tanggal',
          isGreaterThanOrEqualTo: Timestamp.fromDate(mulai));
    }
    if (akhir != null) {
      query = query.where('tanggal',
          isLessThanOrEqualTo: Timestamp.fromDate(akhir));
    }

    return query.snapshots().map((snap) {
      var list = snap.docs
          .map((d) =>
              AspirasiModel.fromMap(d.id, d.data() as Map<String, dynamic>))
          .toList();
      if (idKategori != null && idKategori.isNotEmpty) {
        list = list.where((a) => a.idKategori == idKategori).toList();
      }
      if (status != null) {
        list = list.where((a) => a.status == status).toList();
      }
      return list;
    });
  }

  // Fungsi: sama seperti getAllAspirasi, tapi pengambilan SEKALI (bukan
  // stream) dan wajib rentang tanggal — dipakai halaman Cetak Laporan
  // (mingguan/bulanan) supaya tidak perlu terus memantau perubahan data
  // secara real-time saat PDF sedang dibuat.
  Future<List<AspirasiModel>> getAspirasiRentang({
    required DateTime mulai,
    required DateTime akhir,
  }) async {
    final snap = await _aspirasiRef
        .orderBy('tanggal', descending: false)
        .where('tanggal', isGreaterThanOrEqualTo: Timestamp.fromDate(mulai))
        .where('tanggal', isLessThanOrEqualTo: Timestamp.fromDate(akhir))
        .get();
    return snap.docs
        .map((d) =>
            AspirasiModel.fromMap(d.id, d.data() as Map<String, dynamic>))
        .toList();
  }

  // Prosedur: admin memberi umpan balik & mengubah status penyelesaian
  // (Halaman Umpan Balik Aspirasi pada soal). Setiap kali admin mengubah
  // ini, aspirasi ditandai 'belum dibaca' supaya siswa dapat notifikasi
  // di dalam aplikasi (badge) saat membuka lagi.
  // [fotoBuktiPetugasBase64]: null = foto tidak diubah sama sekali,
  // string kosong '' = foto lama dihapus, string berisi = foto baru/ganti.
  Future<void> updateFeedbackStatus({
    required String idPelaporan,
    required String feedback,
    required StatusAspirasi status,
    String? fotoBuktiPetugasBase64,
  }) async {
    final data = <String, dynamic>{
      'feedback': feedback,
      'status': statusToString(status),
      'sudah_dibaca': false,
    };
    if (fotoBuktiPetugasBase64 != null) {
      data['foto_bukti_petugas'] =
          fotoBuktiPetugasBase64.isEmpty ? null : fotoBuktiPetugasBase64;
    }
    await _aspirasiRef.doc(idPelaporan).update(data);
  }

  // Prosedur: Admin meneruskan satu pengaduan ke Petugas untuk diproses.
  // Sebelum ini dipanggil, pengaduan HANYA terlihat oleh Admin — Petugas
  // baru bisa melihat & memproses pengaduan setelah diteruskan.
  Future<void> teruskanKePetugas(String idPelaporan) async {
    await _aspirasiRef
        .doc(idPelaporan)
        .update({'diteruskan_petugas': true});
  }

  // Prosedur: menandai seluruh aspirasi milik siswa sebagai sudah dibaca.
  // Dipanggil saat siswa membuka halaman Histori, supaya badge notifikasi
  // di halaman utama hilang.
  // Fungsi: mengambil ID-ID aspirasi milik seorang siswa yang statusnya
  // masih 'belum dibaca' (sekali ambil, bukan stream). Dipakai supaya saat
  // notifikasi pembaruan ditekan, aplikasi tahu persis aspirasi mana yang
  // baru saja diperbarui admin/petugas, untuk langsung disorot & di-scroll
  // ke posisinya di halaman Histori — SEBELUM status dibaca-nya diubah.
  Future<List<String>> getIdAspirasiBelumDibaca(String nis) async {
    final snap = await _aspirasiRef
        .where('nis', isEqualTo: nis)
        .where('sudah_dibaca', isEqualTo: false)
        .get();
    return snap.docs.map((d) => d.id).toList();
  }

  // CATATAN PERBAIKAN: sebelumnya fungsi ini menandai dibaca satu per satu
  // secara berurutan (await di dalam for-loop). Kalau jumlah pengaduan yang
  // belum dibaca cukup banyak, proses itu butuh beberapa kali round-trip
  // jaringan sehingga belum tentu selesai semua saat siswa sudah kembali
  // ke halaman utama — akibatnya pita notifikasi kuning muncul lagi karena
  // sebagian dokumen belum sempat ter-update. Sekarang memakai WriteBatch
  // supaya SEMUA dokumen ditandai dibaca dalam satu kali operasi atomik
  // (jauh lebih cepat & tidak ada yang "ketinggalan").
  Future<void> tandaiSemuaDibaca(String nis) async {
    final snap = await _aspirasiRef
        .where('nis', isEqualTo: nis)
        .where('sudah_dibaca', isEqualTo: false)
        .get();

    if (snap.docs.isEmpty) return;

    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'sudah_dibaca': true});
    }
    await batch.commit();
  }

  // Prosedur: siswa memberi penilaian bintang & komentar terhadap
  // aspirasi yang statusnya sudah Selesai (fitur Badge/Bintang & Komentar)
  Future<void> beriRating({
    required String idPelaporan,
    required int rating,
    String? komentar,
  }) async {
    await _aspirasiRef.doc(idPelaporan).update({
      'rating': rating,
      'komentar_rating': komentar ?? '',
    });
  }

  // Fungsi: menghitung ringkasan jumlah aspirasi per status (untuk dashboard
  // admin), menggunakan array agar efisien (poin 8c: gunakan array)
  Future<Map<String, int>> hitungRingkasanStatus() async {
    final snap = await _aspirasiRef.get();
    final List<QueryDocumentSnapshot> docs = snap.docs;

    // array penampung jumlah per status
    final List<String> label = ['Menunggu', 'Proses', 'Selesai'];
    final List<int> jumlah = [0, 0, 0];

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final s = data['status'] ?? 'Menunggu';
      final idx = label.indexOf(s);
      if (idx != -1) jumlah[idx]++;
    }

    return {
      for (int i = 0; i < label.length; i++) label[i]: jumlah[i],
    };
  }

  // ---------------- CHAT (Hubungi Petugas) ----------------
  // Pengganti tombol WhatsApp/Telepon/Email di Pusat Bantuan: siswa hanya
  // bisa chat langsung dengan Admin/Petugas di dalam aplikasi. Satu siswa
  // punya satu percakapan privat (dokumen 'chats/{nis}').

  // Fungsi: stream seluruh isi pesan pada 1 percakapan, terurut dari yang
  // paling lama (supaya tampil dari atas ke bawah seperti chat pada
  // umumnya). Pengurutan dilakukan di sisi aplikasi supaya tidak perlu
  // composite index tambahan.
  Stream<List<PesanChatModel>> streamPesanChat(String nis) {
    return _chatsRef.doc(nis).collection('pesan').snapshots().map((snap) {
      final list = snap.docs
          .map((d) =>
              PesanChatModel.fromMap(d.id, d.data() as Map<String, dynamic>))
          .toList();
      list.sort((a, b) => a.waktu.compareTo(b.waktu));
      return list;
    });
  }

  // Fungsi: stream data ringkasan 1 percakapan (dipakai untuk badge
  // notifikasi pesan baru di halaman utama siswa).
  Stream<ChatModel?> streamRingkasanChat(String nis) {
    return _chatsRef.doc(nis).snapshots().map((snap) {
      if (!snap.exists) return null;
      return ChatModel.fromMap(snap.id, snap.data() as Map<String, dynamic>);
    });
  }

  // Fungsi: stream seluruh percakapan (dipakai halaman "Pesan" milik
  // Admin/Petugas), diurutkan dari yang terbaru.
  Stream<List<ChatModel>> streamDaftarChat() {
    return _chatsRef.snapshots().map((snap) {
      final list = snap.docs
          .map((d) => ChatModel.fromMap(d.id, d.data() as Map<String, dynamic>))
          .toList();
      list.sort((a, b) => b.waktuTerakhir.compareTo(a.waktuTerakhir));
      return list;
    });
  }

  // Prosedur: mengirim 1 pesan pada percakapan siswa <-> Admin/Petugas,
  // sekaligus memperbarui ringkasan (pesan terakhir & penanda belum
  // dibaca) supaya kedua sisi mendapat notifikasi yang sesuai.
  Future<void> kirimPesanChat({
    required String nis,
    required String namaSiswa,
    required PengirimPesan pengirim,
    required String namaPengirim,
    required String isi,
  }) async {
    final sekarang = DateTime.now();
    final pesan = PesanChatModel(
      idPesan: '',
      pengirim: pengirim,
      namaPengirim: namaPengirim,
      isi: isi,
      waktu: sekarang,
    );

    await _chatsRef.doc(nis).collection('pesan').add(pesan.toMap());

    final dariSiswa = pengirim == PengirimPesan.siswa;
    await _chatsRef.doc(nis).set({
      'nama_siswa': namaSiswa,
      'pesan_terakhir': isi,
      'waktu_terakhir': Timestamp.fromDate(sekarang),
      // Jika siswa yang mengirim -> tandai belum dibaca di sisi Admin.
      // Jika Admin/Petugas yang mengirim -> tandai belum dibaca di sisi siswa.
      'belum_dibaca_admin': dariSiswa,
      'belum_dibaca_siswa': !dariSiswa,
    }, SetOptions(merge: true));
  }

  // Prosedur: menandai percakapan sudah dibaca oleh siswa (dipanggil saat
  // siswa membuka halaman chat).
  Future<void> tandaiChatDibacaSiswa(String nis) async {
    await _chatsRef
        .doc(nis)
        .set({'belum_dibaca_siswa': false}, SetOptions(merge: true));
  }

  // Prosedur: menandai percakapan sudah dibaca oleh Admin/Petugas (dipanggil
  // saat Admin/Petugas membuka detail chat seorang siswa).
  Future<void> tandaiChatDibacaAdmin(String nis) async {
    await _chatsRef
        .doc(nis)
        .set({'belum_dibaca_admin': false}, SetOptions(merge: true));
  }

  // ---------------- FCM TOKEN (untuk notifikasi PUSH) ----------------
  // Token FCM disimpan menempel pada dokumen akun masing-masing (siswa/
  // admin/petugas) supaya Cloud Functions (server) tahu ke perangkat mana
  // notifikasi push harus dikirim saat ada data baru.

  // Prosedur: menyimpan/memperbarui FCM token milik siswa.
  Future<void> simpanFcmTokenSiswa(String nis, String token) async {
    await _siswaRef.doc(nis).set({'fcm_token': token}, SetOptions(merge: true));
  }

  // Prosedur: menyimpan/memperbarui FCM token milik Admin atau Petugas.
  // [koleksi] diisi 'admin' atau 'petugas' sesuai peran yang sedang login.
  Future<void> simpanFcmTokenStaff(String koleksi, String email, String token) async {
    await _db
        .collection(koleksi)
        .doc(email)
        .set({'fcm_token': token}, SetOptions(merge: true));
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

// Model: Rating Aplikasi
// Berbeda dari rating per-pengaduan (yang sudah dihapus dari halaman
// Histori) — ini adalah penilaian siswa terhadap APLIKASI secara umum,
// ditampilkan secara publik di halaman sebelum Login supaya calon
// pengguna lain bisa melihatnya.
class RatingAplikasiModel {
  final String nis;
  final String nama;
  final int rating;
  final String komentar;
  final DateTime tanggal;

  RatingAplikasiModel({
    required this.nis,
    required this.nama,
    required this.rating,
    required this.komentar,
    required this.tanggal,
  });

  factory RatingAplikasiModel.fromMap(String id, Map<String, dynamic> map) {
    return RatingAplikasiModel(
      nis: id,
      nama: map['nama'] ?? '',
      rating: map['rating'] ?? 0,
      komentar: map['komentar'] ?? '',
      tanggal: (map['tanggal'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nama': nama,
      'rating': rating,
      'komentar': komentar,
      'tanggal': Timestamp.fromDate(tanggal),
    };
  }
}

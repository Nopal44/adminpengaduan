import 'package:cloud_firestore/cloud_firestore.dart';

// Model: Aspirasi
// Gabungan tabel "Input Aspirasi" & "Aspirasi" pada ERD soal:
// Id_pelaporan, nis, id_kategori, lokasi, ket, status(enum), feedback
enum StatusAspirasi { menunggu, proses, selesai }

StatusAspirasi statusFromString(String s) {
  switch (s) {
    case 'Proses':
      return StatusAspirasi.proses;
    case 'Selesai':
      return StatusAspirasi.selesai;
    case 'Menunggu':
    default:
      return StatusAspirasi.menunggu;
  }
}

String statusToString(StatusAspirasi s) {
  switch (s) {
    case StatusAspirasi.proses:
      return 'Proses';
    case StatusAspirasi.selesai:
      return 'Selesai';
    case StatusAspirasi.menunggu:
      return 'Menunggu';
  }
}

class AspirasiModel {
  final String idPelaporan; // id_aspirasi / id_pelaporan (document id)
  final String nis;
  final String idKategori;
  final String namaKategori; // hasil join untuk tampilan (denormalisasi)
  final String lokasi;
  final String ket; // deskripsi keterangan/pengaduan
  final StatusAspirasi status;
  final String feedback; // umpan balik dari admin
  final String? fotoUrl; // URL foto bukti pengaduan (opsional, tidak dipakai)
  final String?
      fotoBase64; // foto bukti pengaduan, disimpan sbg base64 di Firestore
  final String?
      fotoBuktiPetugas; // foto bukti perbaikan dari petugas (proofing)
  final bool
      sudahDibaca; // penanda notifikasi: false jika ada update belum dilihat siswa
  final bool
      diteruskanPetugas; // true jika Admin sudah meneruskan pengaduan ini ke
  // Petugas untuk diproses. Sebelum ini true, Petugas TIDAK melihat
  // pengaduan yang bersangkutan sama sekali — pengaduan baru selalu
  // masuk ke Admin dulu.
  final int?
      rating; // penilaian siswa (1-5 bintang), diisi setelah status Selesai
  final String? komentarRating; // komentar singkat siswa terkait penilaian
  final DateTime tanggal;

  AspirasiModel({
    required this.idPelaporan,
    required this.nis,
    required this.idKategori,
    required this.namaKategori,
    required this.lokasi,
    required this.ket,
    required this.status,
    required this.feedback,
    this.fotoUrl,
    this.fotoBase64,
    this.fotoBuktiPetugas,
    this.sudahDibaca = true,
    this.diteruskanPetugas = false,
    this.rating,
    this.komentarRating,
    required this.tanggal,
  });

  factory AspirasiModel.fromMap(String id, Map<String, dynamic> map) {
    return AspirasiModel(
      idPelaporan: id,
      nis: map['nis'] ?? '',
      idKategori: map['id_kategori'] ?? '',
      namaKategori: map['nama_kategori'] ?? '',
      lokasi: map['lokasi'] ?? '',
      ket: map['ket'] ?? '',
      status: statusFromString(map['status'] ?? 'Menunggu'),
      feedback: map['feedback'] ?? '',
      fotoUrl: map['foto_url'],
      fotoBase64: map['foto_base64'],
      fotoBuktiPetugas: map['foto_bukti_petugas'],
      sudahDibaca: map['sudah_dibaca'] ?? true,
      diteruskanPetugas: map['diteruskan_petugas'] ?? false,
      rating: map['rating'],
      komentarRating: map['komentar_rating'],
      tanggal: (map['tanggal'] is Timestamp)
          ? (map['tanggal'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nis': nis,
      'id_kategori': idKategori,
      'nama_kategori': namaKategori,
      'lokasi': lokasi,
      'ket': ket,
      'status': statusToString(status),
      'feedback': feedback,
      'foto_url': fotoUrl,
      'foto_base64': fotoBase64,
      'foto_bukti_petugas': fotoBuktiPetugas,
      'sudah_dibaca': sudahDibaca,
      'diteruskan_petugas': diteruskanPetugas,
      'rating': rating,
      'komentar_rating': komentarRating,
      'tanggal': Timestamp.fromDate(tanggal),
    };
  }
}

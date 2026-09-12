// Model: Siswa
// Sesuai ERD -> Siswa(nis(int,10), kelas(varchar,10))
// Ditambah nama & password untuk keperluan login (pengembangan dari ERD dasar)
// Ditambah 'status' untuk fitur persetujuan akun oleh Admin/Petugas:
// 'pending'  -> baru daftar, belum boleh login
// 'approved' -> sudah disetujui, boleh login
// 'rejected' -> ditolak, tidak boleh login
class SiswaModel {
  final String nis;
  final String nama;
  final String kelas;
  final String status;

  SiswaModel({
    required this.nis,
    required this.nama,
    required this.kelas,
    this.status = 'approved',
  });

  factory SiswaModel.fromMap(String id, Map<String, dynamic> map) {
    return SiswaModel(
      nis: id,
      nama: map['nama'] ?? '',
      kelas: map['kelas'] ?? '',
      // Data siswa lama (dibuat sebelum fitur ini ada) tidak punya field
      // 'status' sama sekali -> dianggap 'approved' supaya akun lama tidak
      // mendadak terkunci.
      status: map['status'] ?? 'approved',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nama': nama,
      'kelas': kelas,
      'status': status,
    };
  }
}

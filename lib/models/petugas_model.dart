// Model: Petugas
// Akun Petugas dibuat oleh Admin dari dalam aplikasi (bukan lewat Firebase
// Console). Petugas login memakai EMAIL ASLI (Gmail dsb), sama seperti
// Admin, tapi TIDAK bisa membuat akun Petugas lain.
class PetugasModel {
  final String email;
  final String nama;

  PetugasModel({
    required this.email,
    required this.nama,
  });

  factory PetugasModel.fromMap(String id, Map<String, dynamic> map) {
    return PetugasModel(
      email: id,
      nama: map['nama'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nama': nama,
      'email': email,
    };
  }
}

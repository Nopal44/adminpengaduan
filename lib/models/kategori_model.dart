// Model: Kategori
// Sesuai ERD -> Kategori(Id_kategori(int,5), ket_kategori(varchar,30))
class KategoriModel {
  final String idKategori; // disimpan sbg document id string di Firestore
  final String ketKategori;

  KategoriModel({
    required this.idKategori,
    required this.ketKategori,
  });

  factory KategoriModel.fromMap(String id, Map<String, dynamic> map) {
    return KategoriModel(
      idKategori: id,
      ketKategori: map['ket_kategori'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ket_kategori': ketKategori,
    };
  }

  // PENTING: KategoriModel dipakai sebagai `value` DropdownButtonFormField.
  // Setiap kali StreamBuilder menerima data baru dari Firestore, objek
  // KategoriModel dibuat ULANG (instance baru), termasuk objek "Lainnya"
  // yang dibuat manual di form_aspirasi_screen.dart. Tanpa override == dan
  // hashCode di sini, Dart membandingkan objek berdasarkan identitas
  // (bukan isi), sehingga nilai yang sudah dipilih dianggap "tidak cocok"
  // dengan item di list yang baru -> dropdown menampilkan teks lama/baru
  // tumpang tindih (glitch tampilan yang dilaporkan saat memilih "Lainnya").
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KategoriModel &&
          runtimeType == other.runtimeType &&
          idKategori == other.idKategori);

  @override
  int get hashCode => idKategori.hashCode;
}

import 'package:flutter_test/flutter_test.dart';
import 'package:pengaduan_sarana/models/chat_model.dart';

// Test dasar (smoke test) supaya perintah `flutter test` tidak gagal
// karena folder test/ kosong. Sengaja menguji fungsi murni Dart di
// chat_model.dart (bukan widget/UI) supaya tidak perlu inisialisasi
// Firebase sama sekali saat menjalankan test.
void main() {
  group('Konversi PengirimPesan', () {
    test('pengirimFromString mengenali "petugas"', () {
      expect(pengirimFromString('petugas'), PengirimPesan.petugas);
    });

    test('pengirimFromString mengenali "siswa"', () {
      expect(pengirimFromString('siswa'), PengirimPesan.siswa);
    });

    test('pengirimFromString default ke siswa untuk nilai tidak dikenal', () {
      expect(pengirimFromString('tidak_valid'), PengirimPesan.siswa);
    });

    test('pengirimToString mengubah enum kembali ke string yang benar', () {
      expect(pengirimToString(PengirimPesan.siswa), 'siswa');
      expect(pengirimToString(PengirimPesan.petugas), 'petugas');
    });
  });

  group('PesanChatModel', () {
    test('toMap() lalu fromMap() menghasilkan data yang sama', () {
      final asli = PesanChatModel(
        idPesan: 'p1',
        pengirim: PengirimPesan.siswa,
        namaPengirim: 'Yanto',
        isi: 'Kran air di kelas 2 bocor',
        waktu: DateTime(2026, 8, 31, 10, 0),
      );

      final hasilBaca = PesanChatModel.fromMap(asli.idPesan, asli.toMap());

      expect(hasilBaca.pengirim, asli.pengirim);
      expect(hasilBaca.namaPengirim, asli.namaPengirim);
      expect(hasilBaca.isi, asli.isi);
      expect(hasilBaca.waktu, asli.waktu);
    });
  });
}

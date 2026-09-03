import 'package:cloud_firestore/cloud_firestore.dart';

// Model: Chat (Hubungi Petugas)
// Percakapan privat antara 1 siswa <-> Admin/Petugas, disimpan di
// 'chats/{nis}' (ringkasan) dan sub-collection 'chats/{nis}/pesan' (isi pesan).
enum PengirimPesan { siswa, petugas }

PengirimPesan pengirimFromString(String s) {
  switch (s) {
    case 'petugas':
      return PengirimPesan.petugas;
    case 'siswa':
    default:
      return PengirimPesan.siswa;
  }
}

String pengirimToString(PengirimPesan p) {
  switch (p) {
    case PengirimPesan.petugas:
      return 'petugas';
    case PengirimPesan.siswa:
      return 'siswa';
  }
}

// Ringkasan 1 percakapan (dokumen 'chats/{nis}').
class ChatModel {
  final String nis; // document id
  final String namaSiswa;
  final String pesanTerakhir;
  final DateTime waktuTerakhir;
  final bool belumDibacaAdmin;
  final bool belumDibacaSiswa;

  ChatModel({
    required this.nis,
    required this.namaSiswa,
    required this.pesanTerakhir,
    required this.waktuTerakhir,
    this.belumDibacaAdmin = false,
    this.belumDibacaSiswa = false,
  });

  factory ChatModel.fromMap(String id, Map<String, dynamic> map) {
    return ChatModel(
      nis: id,
      namaSiswa: map['nama_siswa'] ?? '',
      pesanTerakhir: map['pesan_terakhir'] ?? '',
      waktuTerakhir: (map['waktu_terakhir'] is Timestamp)
          ? (map['waktu_terakhir'] as Timestamp).toDate()
          : DateTime.now(),
      belumDibacaAdmin: map['belum_dibaca_admin'] ?? false,
      belumDibacaSiswa: map['belum_dibaca_siswa'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nama_siswa': namaSiswa,
      'pesan_terakhir': pesanTerakhir,
      'waktu_terakhir': Timestamp.fromDate(waktuTerakhir),
      'belum_dibaca_admin': belumDibacaAdmin,
      'belum_dibaca_siswa': belumDibacaSiswa,
    };
  }
}

// Satu pesan dalam percakapan (dokumen 'chats/{nis}/pesan/{idPesan}').
class PesanChatModel {
  final String idPesan; // document id
  final PengirimPesan pengirim;
  final String namaPengirim;
  final String isi;
  final DateTime waktu;

  PesanChatModel({
    required this.idPesan,
    required this.pengirim,
    required this.namaPengirim,
    required this.isi,
    required this.waktu,
  });

  factory PesanChatModel.fromMap(String id, Map<String, dynamic> map) {
    return PesanChatModel(
      idPesan: id,
      pengirim: pengirimFromString(map['pengirim'] ?? 'siswa'),
      namaPengirim: map['nama_pengirim'] ?? '',
      isi: map['isi'] ?? '',
      waktu: (map['waktu'] is Timestamp)
          ? (map['waktu'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'pengirim': pengirimToString(pengirim),
      'nama_pengirim': namaPengirim,
      'isi': isi,
      'waktu': Timestamp.fromDate(waktu),
    };
  }
}

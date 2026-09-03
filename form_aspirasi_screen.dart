import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/aspirasi_model.dart';
import '../../models/chat_model.dart';
import '../../models/kategori_model.dart';
import '../../models/rating_aplikasi_model.dart';
import '../../models/siswa_model.dart';
import '../../services/firestore_service.dart';
import '../../services/notification_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/theme_controller.dart';
import '../login_screen.dart';
import '../../services/auth_service.dart';
import '../../widgets/page_transitions.dart';
import '../../widgets/wave_clipper.dart';
import '../../widgets/rating_stars.dart';
import 'chat_screen.dart';
import 'histori_aspirasi_screen.dart';
import '../help_screen.dart';

// Halaman Form Aspirasi Siswa (sesuai soal poin III.1)
// Dipakai siswa untuk menyampaikan pengaduan/masukan sarana & prasarana.
class FormAspirasiScreen extends StatefulWidget {
  final String nis;
  const FormAspirasiScreen({super.key, required this.nis});

  @override
  State<FormAspirasiScreen> createState() => _FormAspirasiScreenState();
}

class _FormAspirasiScreenState extends State<FormAspirasiScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestoreService = FirestoreService();
  final _authService = AuthService();

  final _lokasiController = TextEditingController();
  final _ketController = TextEditingController();
  final _kategoriLainnyaController = TextEditingController();
  KategoriModel? _kategoriTerpilih;
  bool _saving = false;

  final _picker = ImagePicker();
  File? _fotoTerpilih;
  bool _kompresFoto = false;

  static const _idKategoriLainnya = 'LAINNYA';

  SiswaModel? _dataSiswa;
  bool _loadingSiswa = true;

  // ---- Pemantauan notifikasi lokal (aspirasi & chat) ----
  final _notifService = NotificationService();
  StreamSubscription<List<AspirasiModel>>? _subAspirasi;
  StreamSubscription<List<PesanChatModel>>? _subPesanChat;
  Map<String, AspirasiModel> _aspirasiSebelumnya = {};
  bool _aspirasiPertamaKali = true;
  int _jumlahPesanSebelumnya = -1;

  @override
  void initState() {
    super.initState();
    _muatDataSiswa();
    _mulaiPemantauNotifikasi();
    _daftarkanTokenPush();
  }

  // Prosedur: mengambil FCM token perangkat ini lalu menyimpannya ke
  // dokumen siswa, supaya server (Cloud Functions) bisa mengirim
  // notifikasi PUSH ke siswa ini walau aplikasinya sedang tertutup total.
  // Juga memantau kalau token berubah (mis. setelah instal ulang) agar
  // data di server selalu yang terbaru.
  void _daftarkanTokenPush() {
    _notifService.ambilFcmToken().then((token) {
      if (token != null) {
        _firestoreService.simpanFcmTokenSiswa(widget.nis, token);
      }
    });
    _notifService.pantauPerubahanToken((token) {
      _firestoreService.simpanFcmTokenSiswa(widget.nis, token);
    });
  }

  // Prosedur: memantau perubahan aspirasi & pesan chat milik siswa ini
  // secara realtime, lalu menampilkan notifikasi lokal HANYA untuk data
  // yang benar-benar baru (bukan data yang sudah ada sejak awal dibuka).
  void _mulaiPemantauNotifikasi() {
    _subAspirasi =
        _firestoreService.getAspirasiBySiswa(widget.nis).listen((list) {
      if (_aspirasiPertamaKali) {
        // Pemuatan pertama hanya untuk mencatat kondisi awal, tidak perlu
        // memicu notifikasi (supaya tidak "membanjiri" saat baru buka app).
        _aspirasiPertamaKali = false;
        _aspirasiSebelumnya = {for (final a in list) a.idPelaporan: a};
        return;
      }

      for (final a in list) {
        final sebelumnya = _aspirasiSebelumnya[a.idPelaporan];
        final adaPembaruan = sebelumnya != null &&
            (sebelumnya.status != a.status ||
                sebelumnya.feedback != a.feedback);
        if (adaPembaruan) {
          _notifService.tampilkan(
            judul: 'Update Pengaduan: ${a.namaKategori}',
            isi: 'Status sekarang "${statusToString(a.status)}"'
                '${a.feedback.isNotEmpty ? ' — ${a.feedback}' : ''}',
          );
        }
      }
      _aspirasiSebelumnya = {for (final a in list) a.idPelaporan: a};
    });

    _subPesanChat =
        _firestoreService.streamPesanChat(widget.nis).listen((list) {
      if (_jumlahPesanSebelumnya == -1) {
        _jumlahPesanSebelumnya = list.length;
        return;
      }
      if (list.length > _jumlahPesanSebelumnya) {
        final pesanBaru = list.sublist(_jumlahPesanSebelumnya);
        for (final p in pesanBaru) {
          if (p.pengirim == PengirimPesan.petugas) {
            _notifService.tampilkan(
              judul: 'Pesan baru dari '
                  '${p.namaPengirim.isNotEmpty ? p.namaPengirim : 'Admin/Petugas'}',
              isi: p.isi,
            );
          }
        }
      }
      _jumlahPesanSebelumnya = list.length;
    });
  }

  Future<void> _muatDataSiswa() async {
    final siswa = await _firestoreService.getSiswa(widget.nis);
    if (!mounted) return;
    setState(() {
      _dataSiswa = siswa;
      _loadingSiswa = false;
    });
  }

  Future<void> _pilihFoto() async {
    final sumber = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded,
                  color: AppColors.primary),
              title: const Text('Ambil Foto (Kamera)'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded,
                  color: AppColors.primary),
              title: const Text('Pilih dari Galeri'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (sumber == null) return;

    // Kompres cukup agresif (kualitas 40%, maks lebar 700px) supaya hasil
    // base64-nya tetap di bawah batas ukuran dokumen Firestore (1MB).
    final gambar = await _picker.pickImage(
      source: sumber,
      imageQuality: 40,
      maxWidth: 700,
    );

    if (gambar != null) {
      setState(() => _fotoTerpilih = File(gambar.path));
    }
  }

  // Fungsi: mengubah file foto menjadi base64, dengan pengecekan ukuran
  // supaya tidak melebihi batas 1 dokumen Firestore.
  Future<String?> _fotoKeBase64() async {
    if (_fotoTerpilih == null) return null;
    final Uint8List bytes = await _fotoTerpilih!.readAsBytes();

    if (bytes.lengthInBytes > 700 * 1024) {
      throw Exception(
          'Ukuran foto masih terlalu besar, coba pilih foto lain atau foto ulang.');
    }
    return base64Encode(bytes);
  }

  Future<void> _kirimAspirasi() async {
    if (!_formKey.currentState!.validate() || _kategoriTerpilih == null) {
      if (_kategoriTerpilih == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Pilih kategori pengaduan terlebih dahulu.')),
        );
      }
      return;
    }

    final apakahLainnya = _kategoriTerpilih!.idKategori == _idKategoriLainnya;
    final namaKategoriFinal = apakahLainnya
        ? _kategoriLainnyaController.text.trim()
        : _kategoriTerpilih!.ketKategori;

    if (apakahLainnya && namaKategoriFinal.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Tuliskan kategori pengaduannya terlebih dahulu.')),
      );
      return;
    }

    setState(() => _saving = true);

    String? fotoBase64;
    try {
      fotoBase64 = await _fotoKeBase64();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
      return;
    }

    final aspirasi = AspirasiModel(
      idPelaporan: '',
      nis: widget.nis,
      idKategori: _kategoriTerpilih!.idKategori,
      namaKategori: namaKategoriFinal,
      lokasi: _lokasiController.text.trim(),
      ket: _ketController.text.trim(),
      status: StatusAspirasi.menunggu,
      feedback: '',
      fotoBase64: fotoBase64,
      tanggal: DateTime.now(),
    );

    try {
      await _firestoreService.tambahAspirasi(aspirasi);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengirim aspirasi: $e')),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _saving = false);

    _lokasiController.clear();
    _ketController.clear();
    _kategoriLainnyaController.clear();
    setState(() {
      _kategoriTerpilih = null;
      _fotoTerpilih = null;
    });

    _tampilkanDialogSukses();
  }

  // Dialog ucapan terima kasih setelah aspirasi berhasil dikirim.
  void _tampilkanDialogSukses() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          decoration: BoxDecoration(
            color: AppColors.of(context).surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.statusSelesai,
                      AppColors.statusSelesai.withValues(alpha: 0.7),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.statusSelesai.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(Icons.check_rounded,
                    color: Colors.white, size: 40),
              ),
              const SizedBox(height: 18),
              Text(
                'Terima Kasih!',
                style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: AppColors.of(context).textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                'Aspirasimu sudah berhasil dikirim. Sekolah akan segera menindaklanjutinya. Kamu bisa memantau perkembangannya lewat menu Histori.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13.5,
                    height: 1.4,
                    color: AppColors.of(context).textSecondary),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: Material(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => Navigator.of(ctx).pop(),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 13),
                      child: Text(
                        'Oke, Siap!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _subAspirasi?.cancel();
    _subPesanChat?.cancel();
    super.dispose();
  }

  InputDecoration _dekorasiInput(
      {required String label, required IconData icon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: AppColors.of(context).textSecondary,
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
      ),
      floatingLabelStyle: const TextStyle(
        color: AppColors.primary,
        fontWeight: FontWeight.w800,
      ),
      prefixIcon: Padding(
        padding: const EdgeInsets.all(12),
        child: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 17),
        ),
      ),
      prefixIconConstraints: BoxConstraints(minWidth: 0, minHeight: 0),
      filled: true,
      fillColor: AppColors.of(context).background,
      contentPadding:
          const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      body: SafeArea(
        child: Column(
          children: [
            // ---- Header gradien berisi identitas siswa & aksi ----
            ClipPath(
              clipper: WaveClipper(),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 46),
                decoration:
                    const BoxDecoration(gradient: AppColors.headerGradient),
                child: Stack(
                  children: [
                    Positioned(
                      top: -34,
                      right: -26,
                      child: Container(
                        width: 130,
                        height: 130,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.07)),
                      ),
                    ),
                    Positioned(
                      bottom: -10,
                      left: -30,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.05)),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.white
                                        .withValues(alpha: 0.16),
                                    borderRadius: BorderRadius.circular(9),
                                  ),
                                  child: const Icon(Icons.school_rounded,
                                      color: Colors.white, size: 13),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'PENGADUAN SARANA',
                                  style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.1),
                                ),
                              ],
                            ),
                            StreamBuilder<List<AspirasiModel>>(
                              stream: _firestoreService
                                  .getAspirasiBySiswa(widget.nis),
                              builder: (context, aspirasiSnapshot) {
                                final belumDibacaAspirasi =
                                    (aspirasiSnapshot.data ?? [])
                                        .where((a) => !a.sudahDibaca)
                                        .length;
                                return StreamBuilder<ChatModel?>(
                                  stream: _firestoreService
                                      .streamRingkasanChat(widget.nis),
                                  builder: (context, chatSnapshot) {
                                    final belumDibacaChat = chatSnapshot
                                            .data?.belumDibacaSiswa ==
                                        true;
                                    final adaNotifikasi =
                                        belumDibacaAspirasi > 0 ||
                                            belumDibacaChat;
                                    return _menuHeader(
                                      adaNotifikasi: adaNotifikasi,
                                      belumDibacaAspirasi: belumDibacaAspirasi,
                                      belumDibacaChat: belumDibacaChat,
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color:
                                        Colors.white.withValues(alpha: 0.35),
                                    width: 2),
                              ),
                              child: CircleAvatar(
                                radius: 25,
                                backgroundColor: Colors.white,
                                child: Text(
                                  (_dataSiswa?.nama.isNotEmpty == true
                                          ? _dataSiswa!.nama[0]
                                          : '?')
                                      .toUpperCase(),
                                  style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 20),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: _loadingSiswa
                                  ? const SizedBox(
                                      height: 16,
                                      child: LinearProgressIndicator(
                                          color: Colors.white,
                                          backgroundColor: Colors.white24),
                                    )
                                  : Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Halo, ${_dataSiswa?.nama.isNotEmpty == true ? _dataSiswa!.nama.split(' ').first : 'Siswa'} 👋',
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 19,
                                              letterSpacing: 0.1),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 9, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: Colors.white
                                                .withValues(alpha: 0.16),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            'NIS ${widget.nis}'
                                            '${_dataSiswa != null && _dataSiswa!.kelas.isNotEmpty ? ' • Kelas ${_dataSiswa!.kelas}' : ''}',
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ---- Konten form ----
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ---- Pita notifikasi pembaruan pengaduan ----
                      StreamBuilder<List<AspirasiModel>>(
                        stream:
                            _firestoreService.getAspirasiBySiswa(widget.nis),
                        builder: (context, snapshot) {
                          final belumDibaca = (snapshot.data ?? [])
                              .where((a) => !a.sudahDibaca)
                              .length;
                          if (belumDibaca == 0) return const SizedBox.shrink();

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(14),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: _bukaHistori,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: AppColors.gold.withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                        color: AppColors.gold.withValues(alpha: 0.4)),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: const BoxDecoration(
                                          color: AppColors.gold,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                            Icons.notifications_active_rounded,
                                            color: Colors.white,
                                            size: 16),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          belumDibaca == 1
                                              ? 'Ada 1 pembaruan pada pengaduan kamu'
                                              : 'Ada $belumDibaca pembaruan pada pengaduan kamu',
                                          style: TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.of(context).textPrimary),
                                        ),
                                      ),
                                      Icon(
                                          Icons.arrow_forward_ios_rounded,
                                          size: 13,
                                          color: AppColors.of(context).textSecondary),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      // ---- Pita notifikasi pesan baru dari Admin/Petugas ----
                      StreamBuilder<ChatModel?>(
                        stream:
                            _firestoreService.streamRingkasanChat(widget.nis),
                        builder: (context, snapshot) {
                          final chat = snapshot.data;
                          if (chat == null || !chat.belumDibacaSiswa) {
                            return const SizedBox.shrink();
                          }

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(14),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ChatScreen(
                                      nis: widget.nis,
                                      namaSiswa: _dataSiswa?.nama ?? '',
                                    ),
                                  ),
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 12),
                                  decoration: BoxDecoration(
                                    color:
                                        AppColors.leaf.withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                        color: AppColors.leaf
                                            .withValues(alpha: 0.4)),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: const BoxDecoration(
                                          color: AppColors.leaf,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                            Icons.chat_bubble_rounded,
                                            color: Colors.white,
                                            size: 16),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Admin membalas pesanmu',
                                              style: TextStyle(
                                                  fontSize: 12.5,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.of(context)
                                                      .textPrimary),
                                            ),
                                            if (chat.pesanTerakhir.isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 2),
                                                child: Text(
                                                  chat.pesanTerakhir,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                      fontSize: 11.5,
                                                      color: AppColors.of(
                                                              context)
                                                          .textSecondary),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                          Icons.arrow_forward_ios_rounded,
                                          size: 13,
                                          color: AppColors.of(context)
                                              .textSecondary),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.of(context).surface,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.07),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        AppColors.primary,
                                        AppColors.leaf
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(Icons.edit_note_rounded,
                                      color: Colors.white, size: 22),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Ajukan Pengaduan',
                                        style: TextStyle(
                                            fontSize: 16.5,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.of(context).textPrimary),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Sampaikan kerusakan atau masukan sarana sekolah di sini.',
                                        style: TextStyle(
                                            fontSize: 12.5,
                                            color: AppColors.of(context).textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                      StreamBuilder<List<KategoriModel>>(
                        stream: _firestoreService.getKategoriStream(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: LinearProgressIndicator(),
                            );
                          }
                          final kategoriList = [
                            ...snapshot.data!,
                            KategoriModel(
                                idKategori: _idKategoriLainnya,
                                ketKategori: 'Lainnya'),
                          ];
                          return DropdownButtonFormField<KategoriModel>(
                            value: _kategoriTerpilih,
                            isExpanded: true,
                            decoration: _dekorasiInput(
                                label: 'Kategori Pengaduan',
                                icon: Icons.category_rounded),
                            borderRadius: BorderRadius.circular(14),
                            items: kategoriList
                                .map((k) => DropdownMenuItem(
                                    value: k,
                                    child: Text(
                                      k.ketKategori,
                                      overflow: TextOverflow.ellipsis,
                                    )))
                                .toList(),
                            onChanged: (val) =>
                                setState(() => _kategoriTerpilih = val),
                          );
                        },
                      ),
                      if (_kategoriTerpilih?.idKategori ==
                          _idKategoriLainnya) ...[
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _kategoriLainnyaController,
                          maxLength: 30,
                          decoration: _dekorasiInput(
                              label: 'Tulis Kategori Pengaduan',
                              icon: Icons.edit_rounded),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Kategori wajib diisi'
                              : null,
                        ),
                      ],
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _lokasiController,
                        maxLength: 50,
                        decoration: _dekorasiInput(
                            label: 'Lokasi Sarana', icon: Icons.place_rounded),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Lokasi wajib diisi'
                            : null,
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _ketController,
                        maxLength: 50,
                        maxLines: 3,
                        decoration: _dekorasiInput(
                            label: 'Keterangan / Isi Pengaduan',
                            icon: Icons.description_rounded),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Keterangan wajib diisi'
                            : null,
                      ),
                      const SizedBox(height: 6),
                      Text('Foto Bukti (opsional)',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.of(context).textPrimary)),
                      const SizedBox(height: 8),
                      if (_fotoTerpilih != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.file(_fotoTerpilih!,
                              height: 170,
                              width: double.infinity,
                              fit: BoxFit.cover),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _pilihFoto,
                                icon:
                                    const Icon(Icons.refresh_rounded, size: 18),
                                label: const Text('Ganti'),
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () =>
                                    setState(() => _fotoTerpilih = null),
                                icon: const Icon(Icons.delete_outline_rounded,
                                    size: 18, color: Colors.redAccent),
                                label: const Text('Hapus',
                                    style: TextStyle(color: Colors.redAccent)),
                                style: OutlinedButton.styleFrom(
                                  side:
                                      const BorderSide(color: Colors.redAccent),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ] else
                        InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: _pilihFoto,
                          child: CustomPaint(
                            painter: _DashedBorderPainter(
                              color: AppColors.primary.withValues(alpha: 0.35),
                              radius: 16,
                            ),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 22),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.045),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(13),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          AppColors.primary,
                                          AppColors.leaf
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primary
                                              .withValues(alpha: 0.25),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                        Icons.add_a_photo_rounded,
                                        color: Colors.white,
                                        size: 22),
                                  ),
                                  const SizedBox(height: 10),
                                  const Text('Tambah Foto',
                                      style: TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13.5)),
                                  SizedBox(height: 2),
                                  Text('Opsional, maks. sekitar 700 KB',
                                      style: TextStyle(
                                          color: AppColors.of(context).textSecondary
                                              .withValues(alpha: 0.8),
                                          fontSize: 11)),
                                ],
                              ),
                            ),
                          ),
                        ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 56,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            gradient: const LinearGradient(
                              colors: [AppColors.primary, AppColors.leaf],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    AppColors.primary.withValues(alpha: 0.35),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(30),
                              onTap: _saving ? null : _kirimAspirasi,
                              child: Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.white
                                            .withValues(alpha: 0.22),
                                        shape: BoxShape.circle,
                                      ),
                                      child: _saving
                                          ? const SizedBox(
                                              height: 16,
                                              width: 16,
                                              child:
                                                  CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Icon(Icons.send_rounded,
                                              color: Colors.white, size: 16),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      _saving
                                          ? 'Mengirim...'
                                          : 'Kirim Aspirasi',
                                      style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                          letterSpacing: 0.2),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Prosedur: buka halaman histori, sekaligus tandai semua aspirasi
  // sebagai sudah dibaca supaya badge notifikasi hilang.
  //
  // CATATAN PERBAIKAN: sempat dicoba men-"await" proses tandai-dibaca
  // SEBELUM pindah halaman supaya tidak ada yang "ketinggalan" — tapi itu
  // malah bikin tombol terasa cuma "kedip" tanpa pindah halaman. Sebabnya:
  // begitu batch.commit() dipanggil, Firestore langsung menerapkan
  // perubahan itu ke cache lokal SAAT ITU JUGA, jadi pita notifikasi yang
  // baru saja ditekan langsung hilang dari layar (itu "kedip"-nya) —
  // padahal Navigator.push baru dijalankan setelah menunggu balasan dari
  // server, yang makan waktu (atau nyangkut kalau koneksi lambat). Hasilnya
  // terasa seperti tidak terjadi apa-apa.
  //
  // Solusinya: pindah halaman LANGSUNG begitu ID yang perlu disorot sudah
  // didapat, sementara proses tandai-dibaca (sudah pakai WriteBatch, jadi
  // satu kali operasi & cepat) berjalan di belakang layar tanpa ditunggu.
  Future<void> _bukaHistori() async {
    // Ambil dulu ID aspirasi yang masih "belum dibaca" SEBELUM ditandai
    // dibaca, supaya kita tahu item mana yang perlu disorot & langsung
    // ditampilkan ke siswa di halaman Histori.
    final idBelumDibaca =
        await _firestoreService.getIdAspirasiBelumDibaca(widget.nis);
    if (!mounted) return;

    // Pindah halaman dulu supaya terasa langsung responsif...
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HistoriAspirasiScreen(
          nis: widget.nis,
          highlightIds: idBelumDibaca.toSet(),
        ),
      ),
    );

    // ...baru tandai dibaca di belakang layar. Karena sekarang berupa satu
    // batch tunggal (bukan loop satu-per-satu seperti sebelumnya), ini
    // selesai dalam sekali round-trip jaringan — jauh lebih kecil
    // kemungkinan siswa sempat kembali sebelum prosesnya selesai.
    unawaited(_firestoreService.tandaiSemuaDibaca(widget.nis));
  }

  // Prosedur: membuka bottom sheet untuk siswa memberi/mengubah rating
  // APLIKASI (bukan rating per-pengaduan) — hasilnya tampil publik di
  // halaman Rating Aplikasi sebelum Login.
  Future<void> _bukaRatingAplikasi() async {
    RatingAplikasiModel? ratingLama;
    try {
      ratingLama = await _firestoreService.getRatingAplikasiSiswa(widget.nis);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat rating: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 18, right: 18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
          decoration: BoxDecoration(
            color: AppColors.of(context).surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Rating Aplikasi',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.of(context).textPrimary)),
              const SizedBox(height: 4),
              Text(
                'Penilaianmu akan tampil di halaman Rating Aplikasi yang '
                'bisa dilihat semua orang.',
                style: TextStyle(fontSize: 12, color: AppColors.of(context).textSecondary),
              ),
              RatingStars(
                ratingAwal: ratingLama?.rating,
                komentarAwal: ratingLama?.komentar,
                onSimpan: (rating, komentar) =>
                    _firestoreService.kirimRatingAplikasi(
                  nis: widget.nis,
                  nama: _dataSiswa?.nama ?? 'Siswa',
                  rating: rating,
                  komentar: komentar,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Prosedur: ganti tema Gelap/Terang aplikasi secara global.
  void _gantiTema() {
    toggleThemeMode();
  }

  // Widget: tombol menu (titik tiga) di header yang menggabungkan Histori,
  // Chat Admin, Bantuan, & Keluar menjadi satu, supaya header tidak penuh
  // dengan banyak ikon. Titik merah kecil muncul di ikon utama kalau ada
  // notifikasi belum dibaca di salah satu menu di dalamnya.
  Widget _menuHeader({
    required bool adaNotifikasi,
    required int belumDibacaAspirasi,
    required bool belumDibacaChat,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: Colors.white.withValues(alpha: 0.15),
          shape: const CircleBorder(),
          child: PopupMenuButton<String>(
            tooltip: 'Menu',
            icon: const Icon(Icons.more_vert_rounded,
                color: Colors.white, size: 21),
            color: AppColors.of(context).surface,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            onSelected: (value) {
              switch (value) {
                case 'histori':
                  _bukaHistori();
                  break;
                case 'chat':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        nis: widget.nis,
                        namaSiswa: _dataSiswa?.nama ?? '',
                      ),
                    ),
                  );
                  break;
                case 'bantuan':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => HelpScreen(
                              nis: widget.nis,
                              namaSiswa: _dataSiswa?.nama,
                            )),
                  );
                  break;
                case 'rating_app':
                  _bukaRatingAplikasi();
                  break;
                case 'tema':
                  _gantiTema();
                  break;
                case 'keluar':
                  () async {
                    await _authService.logout();
                    if (!mounted) return;
                    Navigator.pushReplacement(
                        context, fadeSlideRoute(const LoginScreen()));
                  }();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'histori',
                child: _menuItemRow(
                  icon: Icons.history_rounded,
                  label: 'Histori Aspirasi',
                  badgeCount: belumDibacaAspirasi,
                ),
              ),
              PopupMenuItem(
                value: 'chat',
                child: _menuItemRow(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Chat Admin',
                  badgeCount: belumDibacaChat ? 1 : 0,
                ),
              ),
              PopupMenuItem(
                value: 'bantuan',
                child: _menuItemRow(
                  icon: Icons.help_outline_rounded,
                  label: 'Bantuan',
                ),
              ),
              PopupMenuItem(
                value: 'rating_app',
                child: _menuItemRow(
                  icon: Icons.star_outline_rounded,
                  label: 'Beri Rating Aplikasi',
                ),
              ),
              PopupMenuItem(
                value: 'tema',
                child: _menuItemRow(
                  icon: isDarkMode
                      ? Icons.light_mode_rounded
                      : Icons.dark_mode_rounded,
                  label: isDarkMode ? 'Tema Terang' : 'Tema Gelap',
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'keluar',
                child: _menuItemRow(
                  icon: Icons.logout_rounded,
                  label: 'Keluar',
                  danger: true,
                ),
              ),
            ],
          ),
        ),
        if (adaNotifikasi)
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              width: 9,
              height: 9,
              decoration: const BoxDecoration(
                  color: Colors.redAccent, shape: BoxShape.circle),
            ),
          ),
      ],
    );
  }

  // Widget: satu baris item di dalam menu titik-tiga (ikon + label +
  // jumlah notifikasi belum dibaca, kalau ada).
  Widget _menuItemRow({
    required IconData icon,
    required String label,
    int badgeCount = 0,
    bool danger = false,
  }) {
    final warna = danger ? Colors.redAccent : AppColors.of(context).textPrimary;
    return Row(
      children: [
        Icon(icon, size: 19, color: warna),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(color: warna, fontSize: 13.5)),
        if (badgeCount > 0) ...[
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: const BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.all(Radius.circular(10))),
            child: Text(
              badgeCount > 9 ? '9+' : '$badgeCount',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ],
    );
  }
}

// Widget: menggambar garis putus-putus (dashed border) di sekeliling kotak
// upload foto, supaya terlihat seperti area "drop/tap to upload" yang lebih
// modern dibanding garis solid biasa.
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;
  const _DashedBorderPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);

    const dashWidth = 6.0;
    const dashGap = 4.0;
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}

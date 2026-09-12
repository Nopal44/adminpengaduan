import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../models/aspirasi_model.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/status_badge.dart';

// Halaman Umpan Balik Aspirasi (sesuai soal III.2):
// digunakan admin/petugas untuk memberi umpan balik dan mengubah status
// penyelesaian atas satu pengaduan siswa.
class DetailAspirasiScreen extends StatefulWidget {
  final AspirasiModel aspirasi;
  const DetailAspirasiScreen({super.key, required this.aspirasi});

  @override
  State<DetailAspirasiScreen> createState() => _DetailAspirasiScreenState();
}

class _DetailAspirasiScreenState extends State<DetailAspirasiScreen> {
  final _service = FirestoreService();
  late TextEditingController _feedbackController;
  late StatusAspirasi _statusTerpilih;
  bool _saving = false;

  // ---- Foto bukti perbaikan (opsional) ----
  final _picker = ImagePicker();
  File? _fotoBaruTerpilih; // foto baru yang baru saja dipilih, belum disimpan
  bool _fotoLamaDihapus = false; // true jika admin memilih hapus foto lama

  @override
  void initState() {
    super.initState();
    _feedbackController = TextEditingController(text: widget.aspirasi.feedback);
    _statusTerpilih = widget.aspirasi.status;
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Color _warnaStatus(StatusAspirasi s) {
    switch (s) {
      case StatusAspirasi.proses:
        return AppColors.statusProses;
      case StatusAspirasi.selesai:
        return AppColors.statusSelesai;
      case StatusAspirasi.menunggu:
        return AppColors.statusMenunggu;
    }
  }

  IconData _ikonStatus(StatusAspirasi s) {
    switch (s) {
      case StatusAspirasi.menunggu:
        return Icons.hourglass_top_rounded;
      case StatusAspirasi.proses:
        return Icons.build_rounded;
      case StatusAspirasi.selesai:
        return Icons.check_circle_rounded;
    }
  }

  // Prosedur: menampilkan pilihan Kamera/Galeri untuk foto bukti perbaikan.
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
      setState(() {
        _fotoBaruTerpilih = File(gambar.path);
        _fotoLamaDihapus = false;
      });
    }
  }

  Future<String?> _fotoBaruKeBase64() async {
    if (_fotoBaruTerpilih == null) return null;
    final Uint8List bytes = await _fotoBaruTerpilih!.readAsBytes();
    if (bytes.lengthInBytes > 700 * 1024) {
      throw Exception(
          'Ukuran foto masih terlalu besar, coba pilih foto lain atau foto ulang.');
    }
    return base64Encode(bytes);
  }

  // Prosedur: menyimpan perubahan umpan balik & status ke Firestore
  Future<void> _simpanPerubahan() async {
    setState(() => _saving = true);

    // null = foto tidak diubah, '' = foto lama dihapus, string = foto baru.
    String? fotoUntukDisimpan;
    try {
      if (_fotoBaruTerpilih != null) {
        fotoUntukDisimpan = await _fotoBaruKeBase64();
      } else if (_fotoLamaDihapus) {
        fotoUntukDisimpan = '';
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      return;
    }

    try {
      await _service.updateFeedbackStatus(
        idPelaporan: widget.aspirasi.idPelaporan,
        feedback: _feedbackController.text.trim(),
        status: _statusTerpilih,
        fotoBuktiPetugasBase64: fotoUntukDisimpan,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
      return;
    }
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.statusSelesai,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            SizedBox(width: 10),
            Expanded(
              child: Text('Umpan balik & status berhasil disimpan.'),
            ),
          ],
        ),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.aspirasi;
    final formatTanggal = DateFormat('dd MMM yyyy, HH:mm');
    final adaFoto = a.fotoBase64 != null && a.fotoBase64!.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      body: SafeArea(
        child: Column(
          children: [
            // ---- Header ----
            ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(8, 6, 20, 20),
                decoration:
                    const BoxDecoration(gradient: AppColors.headerGradient),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded,
                          color: Colors.white),
                    ),
                    const SizedBox(width: 4),
                    const Expanded(
                      child: Text(
                        'Detail & Umpan Balik',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800),
                      ),
                    ),
                    StatusBadge(status: a.status),
                  ],
                ),
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
                children: [
                  // ---- Kartu ringkasan pengaduan ----
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.of(context).surface,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.category_rounded,
                                  color: AppColors.primary, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                a.namaKategori,
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.of(context).textPrimary),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _barisInfo(Icons.badge_rounded, 'NIS Pelapor', a.nis),
                        const SizedBox(height: 10),
                        _barisInfo(
                            Icons.place_rounded, 'Lokasi', a.lokasi),
                        const SizedBox(height: 10),
                        _barisInfo(Icons.schedule_rounded, 'Waktu Lapor',
                            formatTanggal.format(a.tanggal)),
                        const Divider(height: 28),
                        Text('Keterangan / Isi Pengaduan',
                            style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.of(context).textSecondary)),
                        const SizedBox(height: 6),
                        Text(
                          a.ket,
                          style: TextStyle(
                              fontSize: 14,
                              height: 1.45,
                              color: AppColors.of(context).textPrimary),
                        ),
                        if (adaFoto) ...[
                          const SizedBox(height: 16),
                          Text('Foto Bukti dari Siswa',
                              style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.of(context).textSecondary)),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => showDialog(
                              context: context,
                              builder: (_) => Dialog(
                                backgroundColor: Colors.transparent,
                                child: InteractiveViewer(
                                  child: Image.memory(
                                      base64Decode(a.fotoBase64!)),
                                ),
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.memory(
                                base64Decode(a.fotoBase64!),
                                height: 160,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stack) =>
                                    Container(
                                  height: 100,
                                  color: Colors.grey.shade100,
                                  child: const Center(
                                      child: Icon(Icons.broken_image_rounded,
                                          color: Colors.grey)),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  // ---- Status penyelesaian ----
                  Text('Status Penyelesaian',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.of(context).textPrimary)),
                  const SizedBox(height: 10),
                  Row(
                    children: StatusAspirasi.values.map((s) {
                      final terpilih = s == _statusTerpilih;
                      final warna = _warnaStatus(s);
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                              right: s != StatusAspirasi.values.last ? 8 : 0),
                          child: Material(
                            color: terpilih
                                ? warna.withValues(alpha: 0.12)
                                : AppColors.of(context).surface,
                            borderRadius: BorderRadius.circular(14),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () => setState(() => _statusTerpilih = s),
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: terpilih
                                        ? warna
                                        : Colors.black.withValues(alpha: 0.08),
                                    width: terpilih ? 1.4 : 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(_ikonStatus(s),
                                        size: 20,
                                        color: terpilih
                                            ? warna
                                            : AppColors.of(context).textSecondary),
                                    const SizedBox(height: 6),
                                    Text(
                                      statusToString(s),
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: terpilih
                                              ? warna
                                              : AppColors.of(context).textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 22),

                  // ---- Umpan balik ----
                  Text('Umpan Balik untuk Siswa',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.of(context).textPrimary)),
                  SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.of(context).surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: Colors.black.withValues(alpha: 0.08)),
                    ),
                    child: TextField(
                      controller: _feedbackController,
                      maxLines: 5,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(16),
                        hintText: 'Tuliskan progres perbaikan / tanggapan...',
                        hintStyle: TextStyle(
                            color: AppColors.of(context).textSecondary, fontSize: 13.5),
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  // ---- Foto bukti perbaikan (opsional) ----
                  Text('Foto Bukti Perbaikan (opsional)',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.of(context).textPrimary)),
                  const SizedBox(height: 10),
                  _kartuFotoBukti(a),

                  const SizedBox(height: 26),

                  // ---- Tombol simpan ----
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: Material(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.transparent,
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.leaf],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: _saving ? null : _simpanPerubahan,
                          child: Center(
                            child: _saving
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2.4, color: Colors.white))
                                : const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.save_rounded,
                                          color: Colors.white, size: 19),
                                      SizedBox(width: 8),
                                      Text(
                                        'Simpan Perubahan',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700),
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
          ],
        ),
      ),
    );
  }

  // Widget: kartu foto bukti perbaikan — menampilkan foto baru yang baru
  // dipilih, foto lama dari Firestore (bila belum dihapus), atau tombol
  // "Tambah Foto" bila belum ada foto sama sekali.
  Widget _kartuFotoBukti(AspirasiModel a) {
    final adaFotoLama =
        !_fotoLamaDihapus && a.fotoBuktiPetugas != null && a.fotoBuktiPetugas!.isNotEmpty;

    Widget? preview;
    if (_fotoBaruTerpilih != null) {
      preview = ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.file(_fotoBaruTerpilih!,
            height: 170, width: double.infinity, fit: BoxFit.cover),
      );
    } else if (adaFotoLama) {
      preview = ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.memory(base64Decode(a.fotoBuktiPetugas!),
            height: 170,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
                  height: 170,
                  color: Colors.grey.shade100,
                  child: const Center(
                      child: Icon(Icons.broken_image_rounded,
                          color: Colors.grey)),
                )),
      );
    }

    if (preview != null) {
      return Column(
        children: [
          preview,
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pilihFoto,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Ganti'),
                  style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => setState(() {
                    _fotoBaruTerpilih = null;
                    _fotoLamaDihapus = true;
                  }),
                  icon: const Icon(Icons.delete_outline_rounded,
                      size: 18, color: Colors.redAccent),
                  label: const Text('Hapus',
                      style: TextStyle(color: Colors.redAccent)),
                  style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.redAccent),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                ),
              ),
            ],
          ),
        ],
      );
    }

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: _pilihFoto,
      child: CustomPaint(
        painter: _DashedBorderPainterAdmin(

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
                    colors: [AppColors.primary, AppColors.leaf],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4)),
                  ],
                ),
                child: const Icon(Icons.add_a_photo_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(height: 10),
              const Text('Tambah Foto',
                  style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5)),
              const SizedBox(height: 2),
              Text('Opsional, maks. sekitar 700 KB',
                  style: TextStyle(
                      color: AppColors.of(context)
                          .textSecondary
                          .withValues(alpha: 0.8),
                      fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _barisInfo(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.of(context).textSecondary),
        const SizedBox(width: 8),
        SizedBox(
          width: 90,
          child: Text(label,
              style: TextStyle(
                  fontSize: 12.5, color: AppColors.of(context).textSecondary)),
        ),
        Expanded(
          child: Text(value,
              style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.of(context).textPrimary)),
        ),
      ],
    );
  }
}

// Widget: menggambar garis putus-putus (dashed border) di sekeliling kotak
// upload foto bukti perbaikan, senada dengan kotak upload foto di Form
// Aspirasi Siswa.
class _DashedBorderPainterAdmin extends CustomPainter {
  final Color color;
  final double radius;
  const _DashedBorderPainterAdmin({required this.color, required this.radius});

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
  bool shouldRepaint(covariant _DashedBorderPainterAdmin oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}

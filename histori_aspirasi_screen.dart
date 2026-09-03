import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/aspirasi_model.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/status_badge.dart';

// Halaman histori aspirasi milik siswa: siswa dapat melihat status
// penyelesaian, umpan balik, dan progres perbaikan (soal: kolom "User").
class HistoriAspirasiScreen extends StatefulWidget {
  final String nis;
  // ID aspirasi yang barusan punya pembaruan belum dibaca (dari notifikasi
  // kuning). Item-item ini akan disorot & halaman otomatis scroll ke
  // posisi item pertamanya begitu dibuka.
  final Set<String> highlightIds;

  const HistoriAspirasiScreen({
    super.key,
    required this.nis,
    this.highlightIds = const {},
  });

  @override
  State<HistoriAspirasiScreen> createState() => _HistoriAspirasiScreenState();
}

class _HistoriAspirasiScreenState extends State<HistoriAspirasiScreen> {
  final Map<String, GlobalKey> _itemKeys = {};
  bool _sudahScroll = false;

  // ID aspirasi yang badge "BARU"-nya sudah dihilangkan karena kartunya
  // sudah dipencet/dilihat siswa di sesi Histori ini.
  final Set<String> _sudahDipencet = {};

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

  // Prosedur: scroll otomatis ke aspirasi pertama yang barusan diperbarui,
  // supaya siswa langsung diarahkan ke pembaruan itu tanpa perlu mencari.
  void _scrollKePembaruanJikaPerlu(List<AspirasiModel> data) {
    if (_sudahScroll || widget.highlightIds.isEmpty) return;
    final target = data.firstWhere(
      (a) => widget.highlightIds.contains(a.idPelaporan),
      orElse: () => data.first,
    );
    final key = _itemKeys[target.idPelaporan];
    if (key?.currentContext == null) return;
    _sudahScroll = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = key?.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          alignment: 0.08,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final service = FirestoreService();
    final nis = widget.nis;
    final formatTanggal = DateFormat('dd MMM yyyy');
    final formatJam = DateFormat('HH:mm');

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
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
                decoration:
                    const BoxDecoration(gradient: AppColors.headerGradient),
                child: Stack(
                  children: [
                    Positioned(
                      top: -26,
                      right: -26,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.07)),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Material(
                              color: Colors.white.withValues(alpha: 0.15),
                              shape: const CircleBorder(),
                              child: IconButton(
                                icon: const Icon(Icons.arrow_back_rounded,
                                    color: Colors.white),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Riwayat Pengaduan',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Legenda status dalam kartu putih transparan
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _legenda(Icons.hourglass_top_rounded, 'Menunggu'),
                              _pemisahLegenda(),
                              _legenda(Icons.build_rounded, 'Diproses'),
                              _pemisahLegenda(),
                              _legenda(Icons.check_circle_rounded, 'Selesai'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ---- List histori ----
            Expanded(
              child: StreamBuilder<List<AspirasiModel>>(
                stream: service.getAspirasiBySiswa(nis),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primary));
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline_rounded,
                                color: Colors.redAccent, size: 44),
                            const SizedBox(height: 12),
                            Text(
                              'Gagal memuat histori:\n${snapshot.error}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.redAccent),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final data = snapshot.data ?? [];
                  if (data.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox_rounded,
                                size: 56, color: Colors.grey.shade300),
                            const SizedBox(height: 14),
                            Text(
                              'Belum ada pengaduan',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: AppColors.of(context).textPrimary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Aspirasi yang kamu kirim akan muncul di sini.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: AppColors.of(context).textSecondary, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  _scrollKePembaruanJikaPerlu(data);

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                    itemCount: data.length,
                    itemBuilder: (context, i) {
                      final a = data[i];
                      final warna = _warnaStatus(a.status);
                      final isBaru = widget.highlightIds
                              .contains(a.idPelaporan) &&
                          !_sudahDipencet.contains(a.idPelaporan);
                      final itemKey =
                          _itemKeys.putIfAbsent(a.idPelaporan, () => GlobalKey());

                      return Material(
                        key: itemKey,
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: isBaru
                              ? () => setState(
                                  () => _sudahDipencet.add(a.idPelaporan))
                              : null,
                          child: Container(
                          margin: EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: AppColors.of(context).surface,
                            borderRadius: BorderRadius.circular(16),
                            border: isBaru
                                ? Border.all(color: AppColors.gold, width: 1.6)
                                : null,
                            boxShadow: [
                              BoxShadow(
                                color: isBaru
                                    ? AppColors.gold.withValues(alpha: 0.25)
                                    : Colors.black.withValues(alpha: 0.04),
                                blurRadius: isBaru ? 16 : 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Aksen warna di sisi kiri sesuai status
                                Container(
                                  width: 5,
                                  decoration: BoxDecoration(
                                    color: warna,
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(16),
                                      bottomLeft: Radius.circular(16),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Row(
                                                children: [
                                                  Flexible(
                                                    child: Text(
                                                      a.namaKategori,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.w800,
                                                          fontSize: 15,
                                                          color: AppColors
                                                              .textPrimary),
                                                    ),
                                                  ),
                                                  if (isBaru) ...[
                                                    const SizedBox(width: 6),
                                                    Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 7,
                                                          vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: AppColors.gold,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(20),
                                                      ),
                                                      child: const Text(
                                                        'BARU',
                                                        style: TextStyle(
                                                            fontSize: 9.5,
                                                            fontWeight:
                                                                FontWeight.w800,
                                                            color: Colors.white),
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                            StatusBadge(
                                                status: a.status, compact: true),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Icon(Icons.place_rounded,
                                                size: 15,
                                                color: AppColors.of(context).textSecondary),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(a.lokasi,
                                                  style: const TextStyle(
                                                      fontSize: 13,
                                                      color: AppColors
                                                          .textSecondary)),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          a.ket,
                                          style: TextStyle(
                                              fontSize: 13.5,
                                              color: AppColors.of(context).textPrimary,
                                              height: 1.4),
                                        ),
                                        if (a.fotoBase64 != null &&
                                            a.fotoBase64!.isNotEmpty) ...[
                                          const SizedBox(height: 10),
                                          GestureDetector(
                                            onTap: () => showDialog(
                                              context: context,
                                              builder: (_) => Dialog(
                                                backgroundColor:
                                                    Colors.transparent,
                                                child: InteractiveViewer(
                                                  child: Image.memory(
                                                      base64Decode(
                                                          a.fotoBase64!)),
                                                ),
                                              ),
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              child: Image.memory(
                                                base64Decode(a.fotoBase64!),
                                                height: 150,
                                                width: double.infinity,
                                                fit: BoxFit.cover,
                                                errorBuilder:
                                                    (context, error, stack) =>
                                                        Container(
                                                  height: 80,
                                                  color: Colors.grey.shade100,
                                                  child: const Center(
                                                      child: Icon(
                                                          Icons
                                                              .broken_image_rounded,
                                                          color: Colors.grey)),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                        if (a.fotoBuktiPetugas != null &&
                                            a.fotoBuktiPetugas!.isNotEmpty) ...[
                                          const SizedBox(height: 10),
                                          Row(
                                            children: const [
                                              Icon(Icons.verified_rounded,
                                                  size: 14,
                                                  color: AppColors.statusSelesai),
                                              SizedBox(width: 5),
                                              Text('Bukti Perbaikan dari Petugas',
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w700,
                                                      color: AppColors
                                                          .statusSelesai)),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          GestureDetector(
                                            onTap: () => showDialog(
                                              context: context,
                                              builder: (_) => Dialog(
                                                backgroundColor:
                                                    Colors.transparent,
                                                child: InteractiveViewer(
                                                  child: Image.memory(
                                                      base64Decode(
                                                          a.fotoBuktiPetugas!)),
                                                ),
                                              ),
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              child: Image.memory(
                                                base64Decode(a.fotoBuktiPetugas!),
                                                height: 150,
                                                width: double.infinity,
                                                fit: BoxFit.cover,
                                                errorBuilder:
                                                    (context, error, stack) =>
                                                        Container(
                                                  height: 80,
                                                  color: Colors.grey.shade100,
                                                  child: const Center(
                                                      child: Icon(
                                                          Icons
                                                              .broken_image_rounded,
                                                          color: Colors.grey)),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                        if (a.feedback.isNotEmpty) ...[
                                          const SizedBox(height: 10),
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary
                                                  .withValues(alpha: 0.06),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Row(
                                                  children: [
                                                    Icon(Icons.forum_rounded,
                                                        size: 14,
                                                        color: AppColors.primary),
                                                    SizedBox(width: 6),
                                                    Text(
                                                      'Umpan Balik Admin',
                                                      style: TextStyle(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color:
                                                              AppColors.primary),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Text(a.feedback,
                                                    style: const TextStyle(
                                                        fontSize: 13,
                                                        color: AppColors
                                                            .textPrimary)),
                                              ],
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            Icon(Icons.calendar_today_rounded,
                                                size: 12,
                                                color: Colors.grey.shade500),
                                            const SizedBox(width: 4),
                                            Text(formatTanggal.format(a.tanggal),
                                                style: TextStyle(
                                                    fontSize: 11.5,
                                                    color: Colors.grey.shade500)),
                                            const SizedBox(width: 10),
                                            Icon(Icons.access_time_rounded,
                                                size: 12,
                                                color: Colors.grey.shade500),
                                            const SizedBox(width: 4),
                                            Text(formatJam.format(a.tanggal),
                                                style: TextStyle(
                                                    fontSize: 11.5,
                                                    color: Colors.grey.shade500)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legenda(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.white),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 11.5,
                fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _pemisahLegenda() {
    return Container(height: 14, width: 1, color: Colors.white24);
  }
}

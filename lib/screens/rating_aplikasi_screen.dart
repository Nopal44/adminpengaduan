import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/rating_aplikasi_model.dart';
import '../services/firestore_service.dart';
import '../theme/app_colors.dart';
import '../widgets/page_transitions.dart';
import 'login_screen.dart';

// Halaman Rating Aplikasi: muncul SEBELUM halaman Login (setelah
// Onboarding), menampilkan ulasan bintang dari SEMUA siswa terhadap
// aplikasi ini secara terbuka, supaya siapa pun yang belum masuk (calon
// siswa, orang tua, dsb.) bisa melihatnya.
//
// Bisa juga dibuka dari dalam aplikasi (mis. menu Admin) dengan
// `modePraLogin: false` — dalam mode ini tombol "Lanjut ke Login"
// disembunyikan dan diganti tombol kembali biasa.
class RatingAplikasiScreen extends StatelessWidget {
  final bool modePraLogin;
  const RatingAplikasiScreen({super.key, this.modePraLogin = true});

  void _lanjutKeLogin(BuildContext context) {
    Navigator.of(context).pushReplacement(fadeSlideRoute(const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final service = FirestoreService();
    final formatTanggal = DateFormat('dd MMM yyyy');

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
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
                decoration:
                    const BoxDecoration(gradient: AppColors.headerGradient),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (!modePraLogin)
                          Material(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: const CircleBorder(),
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back_rounded,
                                  color: Colors.white),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                        if (!modePraLogin) const SizedBox(width: 6),
                        Image.asset(
                          'assets/images/logo.png',
                          height: 34,
                          width: 34,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stack) =>
                              const Icon(Icons.school_rounded,
                                  color: Colors.white, size: 30),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Rating Aplikasi dari Siswa',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Padding(
                      padding: EdgeInsets.only(left: 2),
                      child: Text(
                        'Lihat penilaian jujur dari siswa yang sudah memakai '
                        'aplikasi pengaduan sarana ini.',
                        style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12.5,
                            height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ---- Ringkasan & daftar ----
            Expanded(
              child: StreamBuilder<List<RatingAplikasiModel>>(
                stream: service.getRatingAplikasiStream(),
                builder: (context, snapshot) {
                  final list = snapshot.data ?? [];
                  final rataRata = list.isEmpty
                      ? 0.0
                      : list.map((r) => r.rating).reduce((a, b) => a + b) /
                          list.length;

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                    children: [
                      // ---- Kartu ringkasan rata-rata ----
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.of(context).surface,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              list.isEmpty ? '-' : rataRata.toStringAsFixed(1),
                              style: TextStyle(
                                  fontSize: 42,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.of(context).textPrimary),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(5, (i) {
                                final penuh = i < rataRata.round();
                                return Icon(
                                  penuh
                                      ? Icons.star_rounded
                                      : Icons.star_border_rounded,
                                  color: AppColors.gold,
                                  size: 26,
                                );
                              }),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              list.isEmpty
                                  ? 'Belum ada ulasan'
                                  : '${list.length} ulasan dari siswa',
                              style: TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.of(context).textSecondary),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      if (list.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 30),
                          child: Column(
                            children: [
                              Icon(Icons.reviews_outlined,
                                  size: 48, color: Colors.grey.shade300),
                              const SizedBox(height: 10),
                              Text(
                                'Belum ada siswa yang memberi rating aplikasi.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: AppColors.of(context).textSecondary,
                                    fontSize: 13),
                              ),
                            ],
                          ),
                        )
                      else
                        ...list.map((r) => Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.of(context).surface,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 16,
                                        backgroundColor: AppColors.primary
                                            .withValues(alpha: 0.12),
                                        child: Text(
                                          r.nama.isNotEmpty
                                              ? r.nama[0].toUpperCase()
                                              : '?',
                                          style: const TextStyle(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 13),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          r.nama.isEmpty ? 'Siswa' : r.nama,
                                          style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13.5,
                                              color: AppColors.of(context).textPrimary),
                                        ),
                                      ),
                                      Text(formatTanggal.format(r.tanggal),
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey.shade500)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: List.generate(5, (i) {
                                      return Icon(
                                        i < r.rating
                                            ? Icons.star_rounded
                                            : Icons.star_border_rounded,
                                        size: 16,
                                        color: AppColors.gold,
                                      );
                                    }),
                                  ),
                                  if (r.komentar.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      r.komentar,
                                      style: TextStyle(
                                          fontSize: 13,
                                          height: 1.4,
                                          color: AppColors.of(context).textPrimary),
                                    ),
                                  ],
                                ],
                              ),
                            )),
                    ],
                  );
                },
              ),
            ),

            // ---- Tombol lanjut ke Login (hanya saat mode pra-login) ----
            if (modePraLogin)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () => _lanjutKeLogin(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: AppColors.primaryDark,
                      elevation: 4,
                      shadowColor: AppColors.gold.withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text(
                      'Lanjut ke Login',
                      style: TextStyle(
                          fontSize: 15.5, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

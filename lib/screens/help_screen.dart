import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/page_transitions.dart';
import 'siswa/chat_screen.dart';

// Halaman Bantuan / Manual Pengguna + Kontak Petugas.
// Kontak petugas TIDAK LAGI menampilkan nomor telepon/WhatsApp maupun
// alamat email. Satu-satunya cara menghubungi Admin adalah lewat
// chat privat di dalam aplikasi (lihat _KartuHubungiPetugas di bawah).
class HelpScreen extends StatelessWidget {
  // nis & namaSiswa hanya terisi jika halaman ini dibuka SETELAH siswa
  // login (dari halaman utama). Jika null (dibuka sebelum login, misal
  // dari halaman Masuk atau Onboarding), tombol chat akan meminta siswa
  // masuk terlebih dahulu karena percakapan bersifat privat per siswa.
  final String? nis;
  final String? namaSiswa;
  const HelpScreen({super.key, this.nis, this.namaSiswa});

  static const List<_HelpItem> _daftarBantuan = [
    _HelpItem(
      ikon: Icons.login_rounded,
      judul: 'Masuk & Daftar Akun',
      penjelasan:
          'Gunakan NIS dan password untuk masuk. Jika belum punya akun, '
          'tekan "Daftar di sini" pada halaman masuk. Akun baru perlu '
          'disetujui Admin dulu sebelum bisa dipakai.',
    ),
    _HelpItem(
      ikon: Icons.edit_note_rounded,
      judul: 'Mengajukan Pengaduan',
      penjelasan: 'Pada halaman utama, pilih kategori pengaduan (atau pilih '
          '"Lainnya" untuk menulis sendiri), isi lokasi sarana yang '
          'rusak, dan tulis keterangan lengkap. Tekan "Kirim Aspirasi" '
          'untuk mengirim.',
    ),
    _HelpItem(
      ikon: Icons.history_rounded,
      judul: 'Melihat Riwayat & Status',
      penjelasan: 'Tekan ikon jam di pojok atas atau tombol "Lihat Status & '
          'Histori Aspirasi" untuk melihat semua pengaduan yang pernah '
          'dikirim beserta status terkininya: Menunggu, Diproses, atau '
          'Selesai.',
    ),
    _HelpItem(
      ikon: Icons.notifications_active_rounded,
      judul: 'Notifikasi Pembaruan',
      penjelasan: 'Tanda merah (badge) dan pita pemberitahuan di halaman '
          'utama menunjukkan ada pembaruan status atau umpan balik baru '
          'yang belum kamu lihat.',
    ),
    _HelpItem(
      ikon: Icons.star_rounded,
      judul: 'Memberi Penilaian',
      penjelasan:
          'Setelah status pengaduan menjadi "Selesai", kamu bisa memberi '
          'penilaian bintang (1-5) dan komentar singkat sebagai umpan '
          'balik atas hasil perbaikan.',
    ),
    _HelpItem(
      ikon: Icons.logout_rounded,
      judul: 'Keluar Akun',
      penjelasan: 'Tekan ikon keluar di pojok atas untuk logout. Selama belum '
          'logout, sesi akan tetap tersimpan meski aplikasi ditutup.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
              decoration: const BoxDecoration(
                gradient: AppColors.headerGradient,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: Row(
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
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Bantuan',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.w800)),
                      Text('Panduan penggunaan & kontak petugas',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ---- Kartu Hubungi Petugas: tombol aksi langsung ----
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.of(context).surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.15)),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.leaf.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.support_agent_rounded,
                                  color: AppColors.leaf, size: 20),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text('Hubungi Petugas',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                      color: AppColors.of(context).textPrimary)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          nis != null
                              ? 'Tidak perlu nomor telepon atau email — chat '
                                  'langsung dengan Admin di dalam aplikasi.'
                              : 'Masuk terlebih dahulu untuk bisa chat langsung '
                                  'dengan Admin.',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppColors.of(context).textSecondary,
                              height: 1.4),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                            icon:
                                const Icon(Icons.chat_bubble_rounded, size: 19),
                            label: const Text('Chat dengan Admin',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13.5)),
                            onPressed: nis == null
                                ? null
                                : () => Navigator.push(
                                      context,
                                      fadeSlideRoute(
                                        ChatScreen(
                                          nis: nis!,
                                          namaSiswa: namaSiswa ?? '',
                                        ),
                                      ),
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Text('Panduan Penggunaan',
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: AppColors.of(context).textPrimary)),
                  ),
                  const SizedBox(height: 10),

                  ..._daftarBantuan.map((item) => Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.of(context).surface,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 3)),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(item.ikon,
                                  color: AppColors.primary, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.judul,
                                      style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14,
                                          color: AppColors.of(context).textPrimary)),
                                  const SizedBox(height: 4),
                                  Text(item.penjelasan,
                                      style: TextStyle(
                                          fontSize: 12.5,
                                          color: AppColors.of(context).textSecondary,
                                          height: 1.4)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HelpItem {
  final IconData ikon;
  final String judul;
  final String penjelasan;
  const _HelpItem(
      {required this.ikon, required this.judul, required this.penjelasan});
}

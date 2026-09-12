import 'package:flutter/material.dart';
import '../../models/siswa_model.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_colors.dart';

// Halaman khusus ADMIN: melihat profil SELURUH akun siswa yang terdaftar
// (nama, NIS/username login, kelas, dan status akun), lengkap dengan
// pencarian. Dipakai sebagai pusat data akun siswa di luar antrean
// "Persetujuan Akun Siswa" yang hanya menampilkan yang masih pending.
//
// CATATAN KEAMANAN: layar ini SENGAJA tidak menampilkan password siswa.
// Firebase Authentication menyimpan password dalam bentuk hash satu-arah,
// jadi password asli tidak pernah bisa diambil kembali oleh siapa pun,
// termasuk Admin — ini standar keamanan, bukan keterbatasan aplikasi.
// Jika Admin perlu mereset akses siswa yang lupa password, gunakan menu
// reset password (kirim tautan reset) alih-alih menampilkan password.
class DaftarAkunSiswaScreen extends StatefulWidget {
  const DaftarAkunSiswaScreen({super.key});

  @override
  State<DaftarAkunSiswaScreen> createState() => _DaftarAkunSiswaScreenState();
}

class _DaftarAkunSiswaScreenState extends State<DaftarAkunSiswaScreen> {
  final _service = FirestoreService();
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _inisial(String nama) {
    final bagian = nama.trim().split(RegExp(r'\s+'));
    if (bagian.isEmpty || bagian.first.isEmpty) return '?';
    if (bagian.length == 1) return bagian.first.substring(0, 1).toUpperCase();
    return (bagian.first.substring(0, 1) + bagian.last.substring(0, 1))
        .toUpperCase();
  }

  Color _warnaStatus(String status) {
    switch (status) {
      case 'pending':
        return AppColors.statusMenunggu;
      case 'rejected':
        return Colors.redAccent;
      default:
        return AppColors.statusSelesai;
    }
  }

  String _labelStatus(String status) {
    switch (status) {
      case 'pending':
        return 'Menunggu';
      case 'rejected':
        return 'Ditolak';
      default:
        return 'Aktif';
    }
  }

  void _bukaDetail(SiswaModel s) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 28),
        decoration: BoxDecoration(
          color: AppColors.of(context).surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  child: Text(_inisial(s.nama),
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 16)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.nama,
                          style: TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.of(context).textPrimary)),
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                          color: _warnaStatus(s.status).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(_labelStatus(s.status),
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: _warnaStatus(s.status))),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _barisDetail(Icons.badge_rounded, 'NIS (Username Login)', s.nis),
            const SizedBox(height: 12),
            _barisDetail(Icons.class_rounded, 'Kelas', s.kelas),
            const SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.of(context).background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lock_outline_rounded,
                      size: 16, color: AppColors.of(context).textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Password tidak bisa ditampilkan di sini karena disimpan '
                      'terenkripsi (hash) oleh sistem login, demi keamanan data '
                      'siswa. Jika siswa lupa password, arahkan untuk memakai '
                      'fitur lupa password saat login.',
                      style: TextStyle(
                          fontSize: 11.5,
                          height: 1.4,
                          color: AppColors.of(context).textSecondary),
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

  Widget _barisDetail(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.of(context).textSecondary),
        const SizedBox(width: 8),
        Text('$label: ',
            style: TextStyle(
                fontSize: 12.5, color: AppColors.of(context).textSecondary)),
        Text(value,
            style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: AppColors.of(context).textPrimary)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      appBar: AppBar(
        title: const Text('Data Akun Siswa'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.headerGradient),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Cari nama, NIS, atau kelas...',
                prefixIcon: const Icon(Icons.search_rounded,
                    color: AppColors.primary, size: 20),
                filled: true,
                fillColor: AppColors.of(context).surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<SiswaModel>>(
              stream: _service.getSemuaSiswaStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                var list = snapshot.data ?? [];
                if (_query.isNotEmpty) {
                  list = list
                      .where((s) =>
                          s.nama.toLowerCase().contains(_query) ||
                          s.nis.toLowerCase().contains(_query) ||
                          s.kelas.toLowerCase().contains(_query))
                      .toList();
                }
                if (list.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.people_outline_rounded,
                            size: 52, color: Colors.grey.shade300),
                        const SizedBox(height: 10),
                        Text(
                          _query.isEmpty
                              ? 'Belum ada akun siswa.'
                              : 'Tidak ditemukan hasil untuk "$_query".',
                          style:
                              TextStyle(color: AppColors.of(context).textSecondary),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    final s = list[i];
                    final warna = _warnaStatus(s.status);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: AppColors.of(context).surface,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ListTile(
                        onTap: () => _bukaDetail(s),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 4),
                        leading: CircleAvatar(
                          radius: 20,
                          backgroundColor:
                              AppColors.primary.withValues(alpha: 0.12),
                          child: Text(_inisial(s.nama),
                              style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w800)),
                        ),
                        title: Text(s.nama,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 14)),
                        subtitle: Text('NIS ${s.nis} • Kelas ${s.kelas}',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.of(context).textSecondary)),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: warna.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(_labelStatus(s.status),
                              style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: warna)),
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
    );
  }
}

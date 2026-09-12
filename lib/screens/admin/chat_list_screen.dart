import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/chat_model.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_colors.dart';
import 'chat_detail_screen.dart';

// Halaman "Pesan" milik Admin/Petugas: daftar seluruh percakapan privat
// dengan siswa (pengganti tombol WhatsApp/telepon/email di Pusat Bantuan
// siswa). Setiap siswa punya satu percakapan sendiri.
class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = FirestoreService();
    final formatWaktu = DateFormat('dd/MM HH:mm');

    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Pesan Siswa',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: StreamBuilder<List<ChatModel>>(
        stream: service.streamDaftarChat(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final daftar = snapshot.data ?? [];

          if (daftar.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.chat_bubble_outline_rounded,
                      size: 56, color: Colors.grey.shade300),
                  const SizedBox(height: 10),
                  Text('Belum ada pesan dari siswa.',
                      style: TextStyle(color: AppColors.of(context).textSecondary)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
            itemCount: daftar.length,
            itemBuilder: (context, i) {
              final c = daftar[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: AppColors.of(context).surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  leading: CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.10),
                    child: Text(
                      c.namaSiswa.isNotEmpty
                          ? c.namaSiswa[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800),
                    ),
                  ),
                  title: Text(
                    c.namaSiswa.isNotEmpty ? c.namaSiswa : 'NIS ${c.nis}',
                    style: TextStyle(
                        fontWeight: c.belumDibacaAdmin
                            ? FontWeight.w800
                            : FontWeight.w600,
                        fontSize: 14),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      c.pesanTerakhir,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: c.belumDibacaAdmin
                            ? AppColors.of(context).textPrimary
                            : AppColors.of(context).textSecondary,
                        fontWeight: c.belumDibacaAdmin
                            ? FontWeight.w700
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(formatWaktu.format(c.waktuTerakhir),
                          style: TextStyle(
                              fontSize: 10.5, color: AppColors.of(context).textSecondary)),
                      if (c.belumDibacaAdmin) ...[
                        const SizedBox(height: 6),
                        Container(
                          width: 9,
                          height: 9,
                          decoration: const BoxDecoration(
                              color: Colors.redAccent, shape: BoxShape.circle),
                        ),
                      ],
                    ],
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatDetailScreen(
                        nis: c.nis,
                        namaSiswa: c.namaSiswa,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/chat_model.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_colors.dart';

// Halaman balas chat 1 siswa, dibuka dari daftar "Pesan" milik Admin/Petugas.
class ChatDetailScreen extends StatefulWidget {
  final String nis;
  final String namaSiswa;
  const ChatDetailScreen(
      {super.key, required this.nis, required this.namaSiswa});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _service = FirestoreService();
  final _pesanController = TextEditingController();
  final _scrollController = ScrollController();
  bool _mengirim = false;
  String _namaPembalas = 'Admin/Petugas';

  @override
  void initState() {
    super.initState();
    _service.tandaiChatDibacaAdmin(widget.nis);
    _muatNamaPembalas();
  }

  // Fungsi: mengambil nama Admin/Petugas yang sedang login (dari
  // collection 'admin' atau 'petugas'), supaya siswa tahu siapa yang
  // membalas pesannya.
  Future<void> _muatNamaPembalas() async {
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email == null) return;
    final db = FirebaseFirestore.instance;

    final adminDoc = await db.collection('admin').doc(email).get();
    if (adminDoc.exists) {
      final nama = (adminDoc.data()?['nama'] as String?) ?? '';
      if (mounted && nama.isNotEmpty) setState(() => _namaPembalas = nama);
      return;
    }
    final petugasDoc = await db.collection('petugas').doc(email).get();
    if (petugasDoc.exists) {
      final nama = (petugasDoc.data()?['nama'] as String?) ?? '';
      if (mounted && nama.isNotEmpty) setState(() => _namaPembalas = nama);
    }
  }

  @override
  void dispose() {
    _pesanController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _kirim() async {
    final isi = _pesanController.text.trim();
    if (isi.isEmpty || _mengirim) return;

    setState(() => _mengirim = true);
    _pesanController.clear();

    try {
      await _service.kirimPesanChat(
        nis: widget.nis,
        namaSiswa: widget.namaSiswa,
        pengirim: PengirimPesan.petugas,
        namaPengirim: _namaPembalas,
        isi: isi,
      );
      _gulirKeBawah();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengirim pesan: $e')),
      );
    } finally {
      if (mounted) setState(() => _mengirim = false);
    }
  }

  void _gulirKeBawah() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final formatJam = DateFormat('HH:mm');

    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.namaSiswa.isNotEmpty ? widget.namaSiswa : 'Siswa',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            Text('NIS ${widget.nis}',
                style: const TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<PesanChatModel>>(
              stream: _service.streamPesanChat(widget.nis),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final pesanList = snapshot.data ?? [];

                if (pesanList.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.forum_rounded,
                            size: 56, color: Colors.grey.shade300),
                        const SizedBox(height: 10),
                        Text('Belum ada percakapan.',
                            style: TextStyle(color: AppColors.of(context).textSecondary)),
                      ],
                    ),
                  );
                }

                _gulirKeBawah();

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(14),
                  itemCount: pesanList.length,
                  itemBuilder: (context, i) {
                    final p = pesanList[i];
                    final dariPetugas = p.pengirim == PengirimPesan.petugas;
                    return Align(
                      alignment: dariPetugas
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75),
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: dariPetugas
                              ? AppColors.primary
                              : AppColors.of(context).surface,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: Radius.circular(dariPetugas ? 16 : 4),
                            bottomRight: Radius.circular(dariPetugas ? 4 : 16),
                          ),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 6,
                                offset: const Offset(0, 2)),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!dariPetugas)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 3),
                                child: Text(
                                  p.namaPengirim.isNotEmpty
                                      ? p.namaPengirim
                                      : widget.namaSiswa,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.leaf),
                                ),
                              ),
                            Text(
                              p.isi,
                              style: TextStyle(
                                fontSize: 13.5,
                                height: 1.35,
                                color: dariPetugas
                                    ? Colors.white
                                    : AppColors.of(context).textPrimary,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              formatJam.format(p.waktu),
                              style: TextStyle(
                                fontSize: 10,
                                color: dariPetugas
                                    ? Colors.white70
                                    : AppColors.of(context).textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // ---- Kolom input balasan ----
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
              decoration: BoxDecoration(
                color: AppColors.of(context).surface,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, -2)),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _pesanController,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _kirim(),
                      decoration: InputDecoration(
                        hintText: 'Tulis balasan...',
                        filled: true,
                        fillColor: AppColors.of(context).background,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Material(
                    color: AppColors.primary,
                    shape: const CircleBorder(),
                    child: IconButton(
                      icon: _mengirim
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.send_rounded,
                              color: Colors.white, size: 20),
                      onPressed: _mengirim ? null : _kirim,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

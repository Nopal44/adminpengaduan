import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/aspirasi_model.dart';
import '../../models/chat_model.dart';
import '../../models/kategori_model.dart';
import '../../models/siswa_model.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/theme_controller.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/page_transitions.dart';
import '../login_screen.dart';
import '../rating_aplikasi_screen.dart';
import 'chat_list_screen.dart';
import 'daftar_akun_siswa_screen.dart';
import 'detail_aspirasi_screen.dart';
import 'kelola_petugas_screen.dart';
import 'laporan_screen.dart';
import 'persetujuan_siswa_screen.dart';

// Halaman Admin & Petugas: List Aspirasi Keseluruhan (per tanggal, per
// bulan, per siswa, per kategori) sesuai soal III (kolom "Admin").
//
// isAdmin membedakan hak akses:
// - Admin  -> bisa buka "Kelola Petugas" + "Persetujuan Akun Siswa"
// - Petugas -> hanya bisa buka "Persetujuan Akun Siswa"
class DashboardAdminScreen extends StatefulWidget {
  final bool isAdmin;
  const DashboardAdminScreen({super.key, this.isAdmin = true});

  @override
  State<DashboardAdminScreen> createState() => _DashboardAdminScreenState();
}

class _DashboardAdminScreenState extends State<DashboardAdminScreen> {
  final _service = FirestoreService();
  final _authService = AuthService();

  String? _filterKategori;
  StatusAspirasi? _filterStatus;
  DateTime? _filterMulai;
  DateTime? _filterAkhir;
  final _searchNisController = TextEditingController();

  // ---- Pemantauan notifikasi lokal (pengaduan baru, pendaftaran akun
  // baru, & pesan chat baru dari siswa) ----
  final _notifService = NotificationService();
  StreamSubscription<List<AspirasiModel>>? _subAspirasiBaru;
  StreamSubscription<List<SiswaModel>>? _subPendaftaranBaru;
  StreamSubscription<List<ChatModel>>? _subChatBaru;
  Set<String> _idAspirasiDiketahui = {};
  bool _aspirasiPertamaKali = true;
  Set<String> _nisPendaftaranDiketahui = {};
  bool _pendaftaranPertamaKali = true;
  Map<String, bool> _statusBelumDibacaChat = {};
  bool _chatPertamaKali = true;

  // Nama Admin/Petugas yang sedang login, untuk ditampilkan di header.
  String? _namaStaff;

  @override
  void initState() {
    super.initState();
    _mulaiPemantauNotifikasi();
    _muatNamaStaff();
    _daftarkanTokenPush();
  }

  // Prosedur: mengambil FCM token perangkat ini lalu menyimpannya ke
  // dokumen admin/petugas yang sedang login, supaya server (Cloud
  // Functions) bisa mengirim notifikasi PUSH walau aplikasinya sedang
  // tertutup total. Juga memantau kalau token berubah (mis. setelah
  // instal ulang) agar data di server selalu yang terbaru.
  void _daftarkanTokenPush() {
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email == null) return;
    final koleksi = widget.isAdmin ? 'admin' : 'petugas';
    _notifService.ambilFcmToken().then((token) {
      if (token != null) {
        _service.simpanFcmTokenStaff(koleksi, email, token);
      }
    });
    _notifService.pantauPerubahanToken((token) {
      _service.simpanFcmTokenStaff(koleksi, email, token);
    });
  }

  // Fungsi: ambil nama staff yang sedang login dari collection 'admin'
  // atau 'petugas' (sesuai peran), supaya header dashboard tidak generik
  // ("Dashboard Petugas" saja) tapi menyapa dengan nama pemiliknya.
  Future<void> _muatNamaStaff() async {
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email == null) return;
    final db = FirebaseFirestore.instance;
    final koleksi = widget.isAdmin ? 'admin' : 'petugas';
    final doc = await db.collection(koleksi).doc(email).get();
    final nama = (doc.data()?['nama'] as String?) ?? '';
    if (mounted && nama.isNotEmpty) setState(() => _namaStaff = nama);
  }

  @override
  void dispose() {
    _subAspirasiBaru?.cancel();
    _subPendaftaranBaru?.cancel();
    _subChatBaru?.cancel();
    _searchNisController.dispose();
    super.dispose();
  }

  // Prosedur: memantau data secara realtime (pengaduan, pendaftaran akun
  // siswa, & chat) lalu menampilkan notifikasi lokal HANYA untuk data yang
  // benar-benar baru sejak halaman ini dibuka (bukan data lama).
  void _mulaiPemantauNotifikasi() {
    _subAspirasiBaru = _service.getAllAspirasi().listen((list) {
      if (_aspirasiPertamaKali) {
        _aspirasiPertamaKali = false;
        _idAspirasiDiketahui = list.map((a) => a.idPelaporan).toSet();
        return;
      }
      for (final a in list) {
        if (!_idAspirasiDiketahui.contains(a.idPelaporan)) {
          _notifService.tampilkan(
            judul: 'Pengaduan Baru',
            isi: '${a.namaKategori} — NIS ${a.nis} (${a.lokasi})',
          );
        }
      }
      _idAspirasiDiketahui = list.map((a) => a.idPelaporan).toSet();
    });

    _subPendaftaranBaru = _service.getSiswaPendingStream().listen((list) {
      if (_pendaftaranPertamaKali) {
        _pendaftaranPertamaKali = false;
        _nisPendaftaranDiketahui = list.map((s) => s.nis).toSet();
        return;
      }
      for (final s in list) {
        if (!_nisPendaftaranDiketahui.contains(s.nis)) {
          _notifService.tampilkan(
            judul: 'Pendaftaran Akun Baru',
            isi: '${s.nama} (NIS ${s.nis}) menunggu persetujuan.',
          );
        }
      }
      _nisPendaftaranDiketahui = list.map((s) => s.nis).toSet();
    });

    // Chat hanya milik Admin, jadi Petugas tidak perlu dipantau/notifikasi
    // pesan chat sama sekali.
    if (!widget.isAdmin) return;
    _subChatBaru = _service.streamDaftarChat().listen((list) {
      if (_chatPertamaKali) {
        _chatPertamaKali = false;
        _statusBelumDibacaChat = {
          for (final c in list) c.nis: c.belumDibacaAdmin
        };
        return;
      }
      for (final c in list) {
        final sudahBelumDibacaSebelumnya =
            _statusBelumDibacaChat[c.nis] ?? false;
        if (c.belumDibacaAdmin && !sudahBelumDibacaSebelumnya) {
          _notifService.tampilkan(
            judul: 'Pesan Baru dari '
                '${c.namaSiswa.isNotEmpty ? c.namaSiswa : 'Siswa'}',
            isi: c.pesanTerakhir,
          );
        }
      }
      _statusBelumDibacaChat = {
        for (final c in list) c.nis: c.belumDibacaAdmin
      };
    });
  }

  // Prosedur: memilih rentang tanggal filter (per tanggal / per bulan)
  Future<void> _pilihRentangTanggal() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime(2100),
    );
    if (range != null) {
      setState(() {
        _filterMulai =
            DateTime(range.start.year, range.start.month, range.start.day);
        _filterAkhir = DateTime(
            range.end.year, range.end.month, range.end.day, 23, 59, 59);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatTanggal = DateFormat('dd/MM/yyyy');

    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            pinned: true,
            elevation: 0,
            expandedHeight: 120,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: Text(
                _namaStaff != null && _namaStaff!.isNotEmpty
                    ? (widget.isAdmin
                        ? 'Halo, Admin $_namaStaff'
                        : 'Halo, $_namaStaff')
                    : (widget.isAdmin
                        ? 'Dashboard Admin'
                        : 'Dashboard Petugas'),
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 18),
              ),
              background: Container(
                decoration:
                    const BoxDecoration(gradient: AppColors.headerGradient),
                child: Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6, right: 4),
                    child: Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              StreamBuilder<List<ChatModel>>(
                // Kalau Petugas (tidak punya akses chat), stream ini tidak
                // perlu didengarkan; pakai Stream kosong supaya tidak ada
                // query Firestore yang sia-sia.
                stream: widget.isAdmin
                    ? _service.streamDaftarChat()
                    : const Stream<List<ChatModel>>.empty(),
                builder: (context, snapshot) {
                  final daftarChat = snapshot.data ?? [];
                  final jumlahPesanBaru =
                      daftarChat.where((c) => c.belumDibacaAdmin).length;
                  return _menuHeaderAdmin(jumlahPesanBaru: jumlahPesanBaru);
                },
              ),
              const SizedBox(width: 4),
            ],
          ),
        ],
        body: Column(
          children: [
            // ---- Ringkasan jumlah per status (poin 8c: gunakan array) ----
            FutureBuilder<Map<String, int>>(
              future: _service.hitungRingkasanStatus(),
              builder: (context, snapshot) {
                final data =
                    snapshot.data ?? {'Menunggu': 0, 'Proses': 0, 'Selesai': 0};
                final warna = {
                  'Menunggu': AppColors.statusMenunggu,
                  'Proses': AppColors.statusProses,
                  'Selesai': AppColors.statusSelesai,
                };
                final ikon = {
                  'Menunggu': Icons.hourglass_top_rounded,
                  'Proses': Icons.autorenew_rounded,
                  'Selesai': Icons.check_circle_rounded,
                };
                return Padding(
                  padding: const EdgeInsets.fromLTRB(12, 14, 12, 6),
                  child: Row(
                    children: data.entries.map((e) {
                      final c = warna[e.key] ?? AppColors.primary;
                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          padding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 8),
                          decoration: BoxDecoration(
                            color: AppColors.of(context).surface,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: c.withValues(alpha: 0.15),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Icon(ikon[e.key], color: c, size: 22),
                              const SizedBox(height: 6),
                              Text('${e.value}',
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: c)),
                              const SizedBox(height: 2),
                              Text(e.key,
                                  style: TextStyle(
                                      fontSize: 11.5,
                                      color: AppColors.of(context).textSecondary,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),

            // ---- Filter: per kategori, per status, per tanggal ----
            Container(
              margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
              child: Row(
                children: [
                  Expanded(
                    child: StreamBuilder<List<KategoriModel>>(
                      stream: _service.getKategoriStream(),
                      builder: (context, snapshot) {
                        final list = snapshot.data ?? [];
                        return DropdownButtonFormField<String>(
                          value: _filterKategori,
                          isExpanded: true,
                          decoration: const InputDecoration(
                              labelText: 'Kategori',
                              isDense: true,
                              border: InputBorder.none),
                          items: [
                            const DropdownMenuItem(
                                value: null, child: Text('Semua')),
                            ...list.map((k) => DropdownMenuItem(
                                value: k.idKategori,
                                child: Text(k.ketKategori))),
                          ],
                          onChanged: (v) => setState(() => _filterKategori = v),
                        );
                      },
                    ),
                  ),
                  Container(width: 1, height: 30, color: Colors.grey.shade200),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<StatusAspirasi?>(
                      value: _filterStatus,
                      isExpanded: true,
                      decoration: const InputDecoration(
                          labelText: 'Status',
                          isDense: true,
                          border: InputBorder.none),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('Semua')),
                        DropdownMenuItem(
                            value: StatusAspirasi.menunggu,
                            child: Text('Menunggu')),
                        DropdownMenuItem(
                            value: StatusAspirasi.proses,
                            child: Text('Proses')),
                        DropdownMenuItem(
                            value: StatusAspirasi.selesai,
                            child: Text('Selesai')),
                      ],
                      onChanged: (v) => setState(() => _filterStatus = v),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.date_range_rounded,
                        color: AppColors.primary),
                    tooltip: 'Filter Tanggal / Bulan',
                    onPressed: _pilihRentangTanggal,
                  ),
                  if (_filterMulai != null)
                    IconButton(
                      icon: const Icon(Icons.clear_rounded,
                          color: Colors.redAccent),
                      onPressed: () => setState(() {
                        _filterMulai = null;
                        _filterAkhir = null;
                      }),
                    ),
                ],
              ),
            ),
            if (_filterMulai != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Periode: ${formatTanggal.format(_filterMulai!)} - ${formatTanggal.format(_filterAkhir!)}',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.of(context).textSecondary),
                  ),
                ),
              ),

            const SizedBox(height: 8),

            // ---- List aspirasi (realtime) ----
            Expanded(
              child: StreamBuilder<List<AspirasiModel>>(
                stream: _service.getAllAspirasi(
                  idKategori: _filterKategori,
                  status: _filterStatus,
                  mulai: _filterMulai,
                  akhir: _filterAkhir,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.wifi_off_rounded,
                                size: 48, color: Colors.grey.shade300),
                            const SizedBox(height: 10),
                            Text(
                              'Gagal memuat data. Periksa koneksi internet lalu coba lagi.',
                              textAlign: TextAlign.center,
                              style:
                                  TextStyle(color: AppColors.of(context).textSecondary),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  var data = snapshot.data ?? [];

                  // Petugas hanya boleh melihat pengaduan yang SUDAH
                  // diteruskan oleh Admin. Pengaduan baru selalu masuk ke
                  // Admin dulu; Admin yang memutuskan meneruskannya.
                  if (!widget.isAdmin) {
                    data =
                        data.where((a) => a.diteruskanPetugas).toList();
                  }

                  // Filter per siswa (pencarian NIS) dilakukan di sisi client
                  // karena dikombinasikan dengan filter lain.
                  final keyword = _searchNisController.text.trim();
                  if (keyword.isNotEmpty) {
                    data = data.where((a) => a.nis.contains(keyword)).toList();
                  }

                  if (data.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.inbox_rounded,
                              size: 56, color: Colors.grey.shade300),
                          const SizedBox(height: 10),
                          Text(
                            widget.isAdmin
                                ? 'Tidak ada data aspirasi.'
                                : 'Belum ada pengaduan yang diteruskan Admin.',
                            style: TextStyle(
                                color: AppColors.of(context).textSecondary),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                    itemCount: data.length,
                    itemBuilder: (context, i) {
                      final a = data[i];
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
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          leading: CircleAvatar(
                            radius: 22,
                            backgroundColor:
                                AppColors.primary.withValues(alpha: 0.10),
                            child: const Icon(Icons.description_rounded,
                                color: AppColors.primary),
                          ),
                          title: Text('${a.namaKategori} · NIS ${a.nis}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 14)),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                                '${a.lokasi}\n${formatTanggal.format(a.tanggal)}',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.of(context).textSecondary)),
                          ),
                          isThreeLine: true,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              StatusBadge(status: a.status),
                              if (widget.isAdmin) ...[
                                const SizedBox(width: 4),
                                if (a.diteruskanPetugas)
                                  Tooltip(
                                    message: 'Sudah diteruskan ke Petugas',
                                    child: Icon(Icons.check_circle_rounded,
                                        size: 18,
                                        color: Colors.green.shade400),
                                  )
                                else
                                  Tooltip(
                                    message: 'Teruskan ke Petugas',
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(24),
                                        onTap: () async {
                                          try {
                                            await _service.teruskanKePetugas(
                                                a.idPelaporan);
                                            if (!mounted) return;
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(const SnackBar(
                                                    content: Text(
                                                        'Pengaduan diteruskan ke Petugas.')));
                                          } catch (e) {
                                            if (!mounted) return;
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(SnackBar(
                                                    content: Text(
                                                        'Gagal meneruskan: $e')));
                                          }
                                        },
                                        child: const SizedBox(
                                          width: 44,
                                          height: 44,
                                          child: Icon(
                                              Icons.send_to_mobile_rounded,
                                              size: 20,
                                              color: AppColors.primary),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ],
                          ),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    DetailAspirasiScreen(aspirasi: a)),
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

  // Widget: tombol menu (titik tiga) di header dashboard Admin/Petugas,
  // menggabungkan Kelola Petugas, Pesan Siswa, Persetujuan Akun Siswa, &
  // Keluar menjadi satu -- sama seperti menu titik-tiga di halaman
  // Pengaduan Sarana milik siswa. Untuk Petugas, hanya menu 'Keluar' yang
  // tampil karena fitur lain (Kelola Petugas, Chat, Persetujuan Akun Siswa)
  // sekarang khusus Admin saja.
  Widget _menuHeaderAdmin({required int jumlahPesanBaru}) {
    final adaNotifikasi = widget.isAdmin && jumlahPesanBaru > 0;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: Colors.white.withValues(alpha: 0.15),
          shape: const CircleBorder(),
          child: PopupMenuButton<String>(
            tooltip: 'Menu',
            icon: const Icon(Icons.more_vert_rounded,
                color: Colors.white, size: 22),
            color: AppColors.of(context).surface,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            onSelected: (value) {
              switch (value) {
                case 'kelola_petugas':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const KelolaPetugasScreen()),
                  );
                  break;
                case 'chat':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ChatListScreen()),
                  );
                  break;
                case 'persetujuan':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const PersetujuanSiswaScreen()),
                  );
                  break;
                case 'data_siswa':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const DaftarAkunSiswaScreen()),
                  );
                  break;
                case 'cetak_laporan':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LaporanScreen()),
                  );
                  break;
                case 'rating_app':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            const RatingAplikasiScreen(modePraLogin: false)),
                  );
                  break;
                case 'tema':
                  toggleThemeMode();
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
              // Kelola Petugas, Pesan Siswa, & Persetujuan Akun Siswa
              // KHUSUS ADMIN. Petugas tidak melihat menu-menu ini sama
              // sekali.
              if (widget.isAdmin) ...[
                PopupMenuItem(
                  value: 'kelola_petugas',
                  child: _menuItemRowAdmin(
                    icon: Icons.badge_outlined,
                    label: 'Kelola Petugas',
                  ),
                ),
                PopupMenuItem(
                  value: 'chat',
                  child: _menuItemRowAdmin(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: 'Pesan Siswa',
                    badgeCount: jumlahPesanBaru,
                  ),
                ),
                PopupMenuItem(
                  value: 'persetujuan',
                  child: _menuItemRowAdmin(
                    icon: Icons.person_add_alt_1,
                    label: 'Persetujuan Akun Siswa',
                  ),
                ),
                PopupMenuItem(
                  value: 'data_siswa',
                  child: _menuItemRowAdmin(
                    icon: Icons.people_alt_rounded,
                    label: 'Data Akun Siswa',
                  ),
                ),
                PopupMenuItem(
                  value: 'cetak_laporan',
                  child: _menuItemRowAdmin(
                    icon: Icons.picture_as_pdf_rounded,
                    label: 'Cetak Laporan',
                  ),
                ),
                const PopupMenuDivider(),
              ],
              PopupMenuItem(
                value: 'rating_app',
                child: _menuItemRowAdmin(
                  icon: Icons.star_outline_rounded,
                  label: 'Rating Aplikasi',
                ),
              ),
              PopupMenuItem(
                value: 'tema',
                child: _menuItemRowAdmin(
                  icon: isDarkMode
                      ? Icons.light_mode_rounded
                      : Icons.dark_mode_rounded,
                  label: isDarkMode ? 'Tema Terang' : 'Tema Gelap',
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'keluar',
                child: _menuItemRowAdmin(
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

  // Widget: satu baris item di dalam menu titik-tiga dashboard Admin
  // (ikon + label + jumlah notifikasi belum dibaca, kalau ada).
  Widget _menuItemRowAdmin({
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

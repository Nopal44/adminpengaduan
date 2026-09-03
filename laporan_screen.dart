import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../models/aspirasi_model.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_colors.dart';

// Halaman Cetak Laporan Pengaduan (Admin): membuat & mengekspor laporan
// rekap pengaduan sarana & prasarana untuk periode Mingguan atau Bulanan
// dalam bentuk PDF, yang bisa langsung diprint, dibagikan, atau disimpan
// oleh Admin.
class LaporanScreen extends StatefulWidget {
  const LaporanScreen({super.key});

  @override
  State<LaporanScreen> createState() => _LaporanScreenState();
}

enum _ModePeriode { mingguan, bulanan }

class _LaporanScreenState extends State<LaporanScreen> {
  final _service = FirestoreService();

  _ModePeriode _mode = _ModePeriode.mingguan;
  DateTime _tanggalAcuan = DateTime.now(); // acuan minggu ATAU bulan terpilih
  bool _membuatLaporan = false;

  // ---- Perhitungan rentang tanggal sesuai mode ----
  DateTime get _mulai {
    if (_mode == _ModePeriode.mingguan) {
      // Senin sebagai awal minggu.
      final senin =
          _tanggalAcuan.subtract(Duration(days: _tanggalAcuan.weekday - 1));
      return DateTime(senin.year, senin.month, senin.day);
    }
    return DateTime(_tanggalAcuan.year, _tanggalAcuan.month, 1);
  }

  DateTime get _akhir {
    if (_mode == _ModePeriode.mingguan) {
      final akhir = _mulai.add(const Duration(days: 6));
      return DateTime(akhir.year, akhir.month, akhir.day, 23, 59, 59);
    }
    final akhirBulan = DateTime(_tanggalAcuan.year, _tanggalAcuan.month + 1, 0);
    return DateTime(
        akhirBulan.year, akhirBulan.month, akhirBulan.day, 23, 59, 59);
  }

  String get _labelPeriode {
    if (_mode == _ModePeriode.mingguan) {
      final f = DateFormat('dd MMM yyyy');
      return '${f.format(_mulai)} – ${f.format(_akhir)}';
    }
    return DateFormat('MMMM yyyy').format(_tanggalAcuan);
  }

  Future<void> _pilihMinggu() async {
    final dipilih = await showDatePicker(
      context: context,
      initialDate: _tanggalAcuan,
      firstDate: DateTime(2023),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Pilih tanggal di minggu yang diinginkan',
    );
    if (dipilih != null) setState(() => _tanggalAcuan = dipilih);
  }

  Future<void> _pilihBulan() async {
    final dipilih = await showDatePicker(
      context: context,
      initialDate: _tanggalAcuan,
      firstDate: DateTime(2023),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Pilih tanggal di bulan yang diinginkan',
      initialDatePickerMode: DatePickerMode.year,
    );
    if (dipilih != null) setState(() => _tanggalAcuan = dipilih);
  }

  // Prosedur: mengambil data pengaduan pada rentang terpilih, menyusun
  // dokumen PDF rekap, lalu membuka dialog print/bagikan/simpan bawaan
  // perangkat (ditangani package `printing`).
  Future<void> _buatDanCetakLaporan() async {
    setState(() => _membuatLaporan = true);
    try {
      final data =
          await _service.getAspirasiRentang(mulai: _mulai, akhir: _akhir);
      final pdfBytes = await _susunPdf(data);
      if (!mounted) return;
      await Printing.layoutPdf(
        onLayout: (format) async => pdfBytes,
        name: 'Laporan Pengaduan '
            '${_mode == _ModePeriode.mingguan ? 'Mingguan' : 'Bulanan'} '
            '${DateFormat('yyyyMMdd').format(_mulai)}.pdf',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membuat laporan: $e')),
      );
    } finally {
      if (mounted) setState(() => _membuatLaporan = false);
    }
  }

  Future<Uint8List> _susunPdf(List<AspirasiModel> data) async {
    final doc = pw.Document();
    final formatTanggal = DateFormat('dd/MM/yyyy');

    final totalMenunggu =
        data.where((a) => a.status == StatusAspirasi.menunggu).length;
    final totalProses =
        data.where((a) => a.status == StatusAspirasi.proses).length;
    final totalSelesai =
        data.where((a) => a.status == StatusAspirasi.selesai).length;

    // Rekap per kategori.
    final Map<String, int> perKategori = {};
    for (final a in data) {
      perKategori[a.namaKategori] = (perKategori[a.namaKategori] ?? 0) + 1;
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Laporan Pengaduan Sarana & Prasarana',
                style: pw.TextStyle(
                    fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 2),
            pw.Text(
                'Periode ${_mode == _ModePeriode.mingguan ? 'Mingguan' : 'Bulanan'}: $_labelPeriode',
                style: const pw.TextStyle(fontSize: 11)),
            pw.Text(
                'Dicetak: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
            pw.SizedBox(height: 10),
            pw.Divider(thickness: 1),
          ],
        ),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
              'Halaman ${context.pageNumber} dari ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
        ),
        build: (context) => [
          // ---- Ringkasan ----
          pw.Text('Ringkasan',
              style:
                  pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
            children: [
              pw.TableRow(children: [
                _selRingkasan('Total Pengaduan', '${data.length}'),
                _selRingkasan('Menunggu', '$totalMenunggu'),
                _selRingkasan('Proses', '$totalProses'),
                _selRingkasan('Selesai', '$totalSelesai'),
              ]),
            ],
          ),
          pw.SizedBox(height: 16),

          // ---- Rekap per kategori ----
          pw.Text('Rekap per Kategori',
              style:
                  pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          if (perKategori.isEmpty)
            pw.Text('Tidak ada data pada periode ini.',
                style: const pw.TextStyle(
                    fontSize: 10, color: PdfColors.grey700))
          else
            pw.Table.fromTextArray(
              headers: ['Kategori', 'Jumlah'],
              data: perKategori.entries
                  .map((e) => [e.key, '${e.value}'])
                  .toList(),
              headerStyle: pw.TextStyle(
                  fontSize: 10, fontWeight: pw.FontWeight.bold),
              cellStyle: const pw.TextStyle(fontSize: 9.5),
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.blueGrey100),
              cellHeight: 22,
              columnWidths: {
                0: const pw.FlexColumnWidth(4),
                1: const pw.FlexColumnWidth(1),
              },
            ),
          pw.SizedBox(height: 16),

          // ---- Detail pengaduan ----
          pw.Text('Detail Pengaduan',
              style:
                  pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          if (data.isEmpty)
            pw.Text('Tidak ada pengaduan pada periode ini.',
                style: const pw.TextStyle(
                    fontSize: 10, color: PdfColors.grey700))
          else
            pw.Table.fromTextArray(
              headers: [
                'No',
                'Tanggal',
                'NIS',
                'Kategori',
                'Lokasi',
                'Status',
                'Umpan Balik'
              ],
              data: List.generate(data.length, (i) {
                final a = data[i];
                return [
                  '${i + 1}',
                  formatTanggal.format(a.tanggal),
                  a.nis,
                  a.namaKategori,
                  a.lokasi,
                  statusToString(a.status),
                  a.feedback.isEmpty ? '-' : a.feedback,
                ];
              }),
              headerStyle: pw.TextStyle(
                  fontSize: 9, fontWeight: pw.FontWeight.bold),
              cellStyle: const pw.TextStyle(fontSize: 8.5),
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.blueGrey100),
              cellHeight: 20,
              cellAlignment: pw.Alignment.centerLeft,
              columnWidths: {
                0: const pw.FlexColumnWidth(0.6),
                1: const pw.FlexColumnWidth(1.6),
                2: const pw.FlexColumnWidth(1.2),
                3: const pw.FlexColumnWidth(2),
                4: const pw.FlexColumnWidth(1.6),
                5: const pw.FlexColumnWidth(1.3),
                6: const pw.FlexColumnWidth(2.6),
              },
            ),
        ],
      ),
    );

    return doc.save();
  }

  pw.Widget _selRingkasan(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label,
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
          pw.SizedBox(height: 2),
          pw.Text(value,
              style:
                  pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        ],
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
                        'Cetak Laporan Pengaduan',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  Text('Periode Laporan',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.of(context).textPrimary)),
                  const SizedBox(height: 10),

                  // ---- Pilihan mode: Mingguan / Bulanan ----
                  Row(
                    children: [
                      Expanded(
                        child: _tombolMode(
                          label: 'Mingguan',
                          icon: Icons.view_week_rounded,
                          terpilih: _mode == _ModePeriode.mingguan,
                          onTap: () =>
                              setState(() => _mode = _ModePeriode.mingguan),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _tombolMode(
                          label: 'Bulanan',
                          icon: Icons.calendar_view_month_rounded,
                          terpilih: _mode == _ModePeriode.bulanan,
                          onTap: () =>
                              setState(() => _mode = _ModePeriode.bulanan),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // ---- Kartu ringkasan periode terpilih ----
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.of(context).surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: Colors.black.withValues(alpha: 0.06)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.date_range_rounded,
                              color: AppColors.primary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _mode == _ModePeriode.mingguan
                                    ? 'Minggu terpilih'
                                    : 'Bulan terpilih',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.of(context)
                                        .textSecondary),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _labelPeriode,
                                style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w800,
                                    color:
                                        AppColors.of(context).textPrimary),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: _mode == _ModePeriode.mingguan
                              ? _pilihMinggu
                              : _pilihBulan,
                          child: const Text('Ubah'),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ---- Tombol buat laporan ----
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
                          onTap: _membuatLaporan ? null : _buatDanCetakLaporan,
                          child: Center(
                            child: _membuatLaporan
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2.4, color: Colors.white))
                                : const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.picture_as_pdf_rounded,
                                          color: Colors.white, size: 19),
                                      SizedBox(width: 8),
                                      Text(
                                        'Buat & Cetak Laporan',
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
                  const SizedBox(height: 10),
                  Text(
                    'Laporan berisi rekap jumlah pengaduan (Menunggu/Proses/'
                    'Selesai), rekap per kategori, dan daftar detail seluruh '
                    'pengaduan pada periode yang dipilih. Setelah dibuat, '
                    'kamu bisa langsung mencetak, membagikan, atau menyimpan '
                    'file PDF-nya.',
                    style: TextStyle(
                        fontSize: 12,
                        color: AppColors.of(context).textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tombolMode({
    required String label,
    required IconData icon,
    required bool terpilih,
    required VoidCallback onTap,
  }) {
    return Material(
      color: terpilih
          ? AppColors.primary.withValues(alpha: 0.1)
          : AppColors.of(context).surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: terpilih
                  ? AppColors.primary
                  : Colors.black.withValues(alpha: 0.08),
              width: terpilih ? 1.4 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  size: 20,
                  color: terpilih
                      ? AppColors.primary
                      : AppColors.of(context).textSecondary),
              const SizedBox(height: 6),
              Text(label,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: terpilih
                          ? AppColors.primary
                          : AppColors.of(context).textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}


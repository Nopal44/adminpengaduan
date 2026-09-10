import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

// Widget kartu penilaian bintang, muncul di kartu histori saat status
// aspirasi sudah "Selesai". Siswa bisa kasih 1-5 bintang + komentar
// singkat sebagai bentuk umpan balik kepuasan (fitur Badge/Bintang &
// Komentar sesuai checklist UKK).
class RatingStars extends StatefulWidget {
  final int? ratingAwal;
  final String? komentarAwal;
  final Future<void> Function(int rating, String komentar) onSimpan;

  const RatingStars({
    super.key,
    required this.ratingAwal,
    required this.komentarAwal,
    required this.onSimpan,
  });

  @override
  State<RatingStars> createState() => _RatingStarsState();
}

class _RatingStarsState extends State<RatingStars> {
  late int _bintangDipilih;
  final _komentarController = TextEditingController();
  bool _modeEdit = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _bintangDipilih = widget.ratingAwal ?? 0;
    _komentarController.text = widget.komentarAwal ?? '';
    _modeEdit = widget.ratingAwal ==
        null; // langsung mode isi kalau belum pernah rating
  }

  Future<void> _simpan() async {
    if (_bintangDipilih == 0) return;
    setState(() => _saving = true);
    try {
      await widget.onSimpan(_bintangDipilih, _komentarController.text.trim());
      if (!mounted) return;
      setState(() {
        _saving = false;
        _modeEdit = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengirim rating: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_modeEdit && widget.ratingAwal != null) {
      // Tampilan setelah rating sudah diberikan (ringkas)
      return Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.gold.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Row(
              children: List.generate(5, (i) {
                return Icon(
                  i < widget.ratingAwal!
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  size: 16,
                  color: AppColors.gold,
                );
              }),
            ),
            const SizedBox(width: 8),
            if ((widget.komentarAwal ?? '').isNotEmpty)
              Expanded(
                child: Text(
                  widget.komentarAwal!,
                  style: TextStyle(
                      fontSize: 12, color: AppColors.of(context).textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            TextButton(
              onPressed: () => setState(() => _modeEdit = true),
              style: TextButton.styleFrom(
                  padding: EdgeInsets.zero, minimumSize: const Size(0, 0)),
              child: const Text('Ubah',
                  style: TextStyle(fontSize: 11, color: AppColors.primary)),
            ),
          ],
        ),
      );
    }

    // Mode isi/ubah rating
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Beri penilaian untuk perbaikan ini',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.of(context).textPrimary),
          ),
          const SizedBox(height: 6),
          Row(
            children: List.generate(5, (i) {
              return GestureDetector(
                onTap: () => setState(() => _bintangDipilih = i + 1),
                child: Padding(
                  padding: const EdgeInsets.only(right: 2),
                  child: Icon(
                    i < _bintangDipilih
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    size: 26,
                    color: AppColors.gold,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _komentarController,
            maxLength: 80,
            style: const TextStyle(fontSize: 12.5),
            decoration: const InputDecoration(
              isDense: true,
              hintText: 'Komentar singkat (opsional)',
              border: OutlineInputBorder(),
              counterText: '',
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_bintangDipilih == 0 || _saving) ? null : _simpan,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              child: _saving
                  ? const SizedBox(
                      height: 14,
                      width: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Kirim Penilaian',
                      style: TextStyle(fontSize: 12.5)),
            ),
          ),
        ],
      ),
    );
  }
}

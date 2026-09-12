import 'package:flutter/material.dart';
import '../models/aspirasi_model.dart';
import '../theme/app_colors.dart';

// Widget kecil reusable untuk menampilkan status penyelesaian dengan
// warna & ikon berbeda, supaya siswa langsung paham tanpa perlu baca teks.
class StatusBadge extends StatelessWidget {
  final StatusAspirasi status;
  final bool compact;
  const StatusBadge({super.key, required this.status, this.compact = false});

  Color get _warna {
    switch (status) {
      case StatusAspirasi.proses:
        return AppColors.statusProses;
      case StatusAspirasi.selesai:
        return AppColors.statusSelesai;
      case StatusAspirasi.menunggu:
        return AppColors.statusMenunggu;
    }
  }

  IconData get _ikon {
    switch (status) {
      case StatusAspirasi.menunggu:
        return Icons.hourglass_top_rounded;
      case StatusAspirasi.proses:
        return Icons.build_rounded;
      case StatusAspirasi.selesai:
        return Icons.check_circle_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 12, vertical: compact ? 4 : 6),
      decoration: BoxDecoration(
        color: _warna.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: _warna.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_ikon, size: compact ? 12 : 14, color: _warna),
          const SizedBox(width: 4),
          Text(
            statusToString(status),
            style: TextStyle(
              color: _warna,
              fontWeight: FontWeight.w700,
              fontSize: compact ? 11 : 12,
            ),
          ),
        ],
      ),
    );
  }
}

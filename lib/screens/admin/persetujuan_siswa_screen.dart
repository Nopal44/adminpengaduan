import 'package:flutter/material.dart';
import '../../models/siswa_model.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_colors.dart';

// Halaman untuk ADMIN dan PETUGAS: menyetujui atau menolak pendaftaran
// akun siswa baru yang statusnya masih 'pending' (menunggu).
class PersetujuanSiswaScreen extends StatefulWidget {
  const PersetujuanSiswaScreen({super.key});

  @override
  State<PersetujuanSiswaScreen> createState() => _PersetujuanSiswaScreenState();
}

class _PersetujuanSiswaScreenState extends State<PersetujuanSiswaScreen> {
  final _service = FirestoreService();

  Future<void> _setujui(SiswaModel s) async {
    await _service.setujuiSiswa(s.nis);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Akun ${s.nama} disetujui.')),
    );
  }

  Future<void> _tolak(SiswaModel s) async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tolak Pendaftaran?'),
        content: Text('Tolak pendaftaran akun ${s.nama} (NIS ${s.nis})?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Tolak', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (konfirmasi != true) return;

    await _service.tolakSiswa(s.nis);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Akun ${s.nama} ditolak.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Persetujuan Akun Siswa'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<SiswaModel>>(
        stream: _service.getSiswaPendingStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = snapshot.data ?? [];
          if (list.isEmpty) {
            return const Center(
                child: Text('Tidak ada pendaftaran yang menunggu.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: list.length,
            itemBuilder: (context, i) {
              final s = list[i];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  leading: const Icon(Icons.person_outline,
                      color: AppColors.primary),
                  title: Text(s.nama),
                  subtitle: Text('NIS: ${s.nis}  •  Kelas: ${s.kelas}'),
                  isThreeLine: false,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon:
                            const Icon(Icons.check_circle, color: Colors.green),
                        tooltip: 'Setujui',
                        onPressed: () => _setujui(s),
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        tooltip: 'Tolak',
                        onPressed: () => _tolak(s),
                      ),
                    ],
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

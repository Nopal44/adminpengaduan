import 'package:flutter/material.dart';
import '../../models/petugas_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_colors.dart';

// Halaman khusus ADMIN: membuat akun Petugas baru LANGSUNG dari aplikasi
// (tanpa perlu buka Firebase Console), dan melihat daftar petugas yang ada.
class KelolaPetugasScreen extends StatefulWidget {
  const KelolaPetugasScreen({super.key});

  @override
  State<KelolaPetugasScreen> createState() => _KelolaPetugasScreenState();
}

class _KelolaPetugasScreenState extends State<KelolaPetugasScreen> {
  final _authService = AuthService();
  final _service = FirestoreService();
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _namaController = TextEditingController();
  final _passController = TextEditingController();

  bool _loading = false;
  bool _lihatPassword = false;
  String? _errorMsg;

  Future<void> _buatPetugas() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _errorMsg = null;
    });

    final error = await _authService.createPetugas(
      email: _emailController.text.trim(),
      nama: _namaController.text.trim(),
      password: _passController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (error != null) {
      setState(() => _errorMsg = error);
      return;
    }

    _emailController.clear();
    _namaController.clear();
    _passController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.statusSelesai,
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Akun petugas berhasil dibuat.'),
          ],
        ),
      ),
    );
  }

  InputDecoration _dekorasi(String label, IconData icon, {Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20, color: AppColors.primary),
      suffixIcon: suffix,
      filled: true,
      fillColor: AppColors.of(context).background,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  String _inisial(String nama) {
    final bagian = nama.trim().split(RegExp(r'\s+'));
    if (bagian.isEmpty || bagian.first.isEmpty) return '?';
    if (bagian.length == 1) return bagian.first.substring(0, 1).toUpperCase();
    return (bagian.first.substring(0, 1) + bagian.last.substring(0, 1))
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      appBar: AppBar(
        title: const Text('Kelola Akun Petugas'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.headerGradient),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.of(context).surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: AppColors.gold.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.person_add_alt_1_rounded,
                              color: AppColors.gold, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Text('Tambah Akun Petugas',
                            style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15.5,
                                color: AppColors.of(context).textPrimary)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _dekorasi('Email Petugas (Gmail dsb)',
                          Icons.alternate_email_rounded),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Wajib diisi';
                        if (!v.contains('@') || !v.contains('.')) {
                          return 'Format email tidak valid';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _namaController,
                      decoration:
                          _dekorasi('Nama Lengkap', Icons.badge_outlined),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Wajib diisi'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passController,
                      obscureText: !_lihatPassword,
                      decoration: _dekorasi(
                        'Password (min. 6 karakter)',
                        Icons.lock_outline_rounded,
                        suffix: IconButton(
                          icon: Icon(
                            _lihatPassword
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            size: 19,
                            color: AppColors.of(context).textSecondary,
                          ),
                          onPressed: () =>
                              setState(() => _lihatPassword = !_lihatPassword),
                        ),
                      ),
                      validator: (v) => (v == null || v.length < 6)
                          ? 'Minimal 6 karakter'
                          : null,
                    ),
                    if (_errorMsg != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded,
                                size: 16, color: Colors.red),
                            const SizedBox(width: 6),
                            Expanded(
                                child: Text(_errorMsg!,
                                    style: const TextStyle(
                                        color: Colors.red, fontSize: 12.5))),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    SizedBox(
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _loading ? null : _buatPetugas,
                        icon: _loading
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.person_add_rounded, size: 19),
                        label:
                            Text(_loading ? 'Membuat...' : 'Buat Akun Petugas'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          textStyle: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Row(
              children: [
                Icon(Icons.groups_rounded,
                    size: 18, color: AppColors.of(context).textSecondary),
                const SizedBox(width: 6),
                Text('Daftar Petugas',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.of(context).textPrimary)),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<PetugasModel>>(
              stream: _service.getPetugasStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final list = snapshot.data ?? [];
                if (list.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.badge_outlined,
                            size: 52, color: Colors.grey.shade300),
                        const SizedBox(height: 10),
                        Text('Belum ada akun petugas.',
                            style: TextStyle(color: AppColors.of(context).textSecondary)),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    final p = list[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
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
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                          child: Text(_inisial(p.nama),
                              style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w800)),
                        ),
                        title: Text(p.nama,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 14)),
                        subtitle: Text(p.email,
                            style: TextStyle(
                                fontSize: 12, color: AppColors.of(context).textSecondary)),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.leaf.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text('Petugas',
                              style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.leaf)),
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

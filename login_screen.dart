import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../widgets/page_transitions.dart';
import 'siswa/form_aspirasi_screen.dart';
import 'register_screen.dart';
import 'staff_login_screen.dart';
import 'help_screen.dart';

// Halaman Login khusus SISWA.
// Struktur SANGAT sederhana: latar gradasi polos + Column lurus berisi
// logo, judul, kartu form putih, dan tautan. Tidak ada ClipPath/Positioned
// rumit supaya tidak ada bagian yang berisiko hilang/kepotong.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _authService = AuthService();
  final _nisController = TextEditingController();
  final _passController = TextEditingController();
  bool _loading = false;
  bool _lihatPassword = false;
  String? _errorMsg;

  @override
  void dispose() {
    _nisController.dispose();
    _passController.dispose();
    super.dispose();
  }

  Future<void> _prosesLogin() async {
    setState(() {
      _loading = true;
      _errorMsg = null;
    });
    final nis = _nisController.text.trim();
    final pass = _passController.text.trim();

    if (nis.isEmpty || pass.isEmpty) {
      setState(() {
        _loading = false;
        _errorMsg = 'NIS dan password wajib diisi.';
      });
      return;
    }

    final error = await _authService.loginSiswa(nis, pass);
    if (!mounted) return;
    setState(() => _loading = false);

    if (error != null) {
      setState(() => _errorMsg = error);
      return;
    }
    Navigator.of(context)
        .pushReplacement(fadeSlideRoute(FormAspirasiScreen(nis: nis)));
  }

  Widget _kolomInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color warnaIkon,
    bool obscure = false,
    Widget? suffix,
    TextInputType? keyboardType,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: warnaIkon.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: warnaIkon, size: 21),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: controller,
            obscureText: obscure,
            keyboardType: keyboardType,
            style: TextStyle(
                fontWeight: FontWeight.w600, color: AppColors.of(context).textPrimary),
            decoration: InputDecoration(
              labelText: label,
              labelStyle:
                  TextStyle(color: AppColors.of(context).textSecondary, fontSize: 13),
              suffixIcon: suffix,
              filled: true,
              fillColor: AppColors.of(context).background,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: warnaIkon, width: 1.6),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primaryDark, AppColors.primary],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 26, vertical: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 36),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 18,
                              offset: const Offset(0, 8)),
                        ],
                      ),
                      child: Image.asset(
                        'assets/images/logo.png',
                        height: 90,
                        width: 90,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stack) => const Icon(
                            Icons.school_rounded,
                            size: 64,
                            color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'SLB Marsudi Putra 3 Sanden',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 18),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pengaduan Sarana Sekolah',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 12.5),
                    ),
                    const SizedBox(height: 30),

                    // ---- Kartu form (putih solid) ----
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 22,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 4,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: AppColors.gold,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text('Masuk sebagai Siswa',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                      color: AppColors.of(context).textPrimary)),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _kolomInput(
                            controller: _nisController,
                            label: 'Nomor Induk Siswa (NIS)',
                            icon: Icons.badge_rounded,
                            warnaIkon: AppColors.primary,
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 14),
                          _kolomInput(
                            controller: _passController,
                            label: 'Password',
                            icon: Icons.lock_rounded,
                            warnaIkon: AppColors.leaf,
                            obscure: !_lihatPassword,
                            suffix: IconButton(
                              icon: Icon(
                                _lihatPassword
                                    ? Icons.visibility_off_rounded
                                    : Icons.visibility_rounded,
                                size: 19,
                                color: AppColors.of(context).textSecondary,
                              ),
                              onPressed: () => setState(
                                  () => _lihatPassword = !_lihatPassword),
                            ),
                          ),
                          if (_errorMsg != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 9),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline_rounded,
                                      size: 16, color: Colors.red),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(_errorMsg!,
                                        style: const TextStyle(
                                            color: Colors.red, fontSize: 12)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 22),
                          SizedBox(
                            height: 54,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _prosesLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.gold,
                                foregroundColor: AppColors.primaryDark,
                                elevation: 4,
                                shadowColor: AppColors.gold.withValues(alpha: 0.5),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16)),
                              ),
                              child: _loading
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2.4,
                                          color: AppColors.primaryDark),
                                    )
                                  : const Text('Masuk',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => Navigator.push(
                          context, fadeSlideRoute(const RegisterScreen())),
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.9)),
                          children: const [
                            TextSpan(text: 'Belum punya akun? '),
                            TextSpan(
                              text: 'Daftar di sini',
                              style: TextStyle(
                                  color: AppColors.gold,
                                  fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),

              // Akses Bantuan di pojok kiri atas — tetap sama alasannya
              // (ditaruh SETELAH ScrollView di dalam Stack) supaya bisa
              // disentuh. Ini membuat halaman Bantuan bisa dibuka bahkan
              // SEBELUM login.
              Positioned(
                top: 6,
                left: 6,
                child: Material(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => Navigator.push(
                        context, fadeSlideRoute(const HelpScreen())),
                    child: const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.help_outline_rounded,
                              color: Colors.white, size: 20),
                          SizedBox(height: 2),
                          Text('Bantuan',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Akses Admin/Petugas di pojok kanan atas — ditaruh SETELAH
              // area scroll di dalam Stack supaya berada di lapisan paling
              // atas dan bisa disentuh (kalau ditaruh sebelum ScrollView,
              // area kosong ScrollView yang transparan justru menutupi
              // ikon ini walau kelihatan, sehingga tombolnya tidak
              // bereaksi saat ditekan).
              Positioned(
                top: 6,
                right: 6,
                child: Material(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => Navigator.push(
                        context, fadeSlideRoute(const StaffLoginScreen())),
                    child: const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.admin_panel_settings_rounded,
                              color: Colors.white, size: 20),
                          SizedBox(height: 2),
                          Text('Admin',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

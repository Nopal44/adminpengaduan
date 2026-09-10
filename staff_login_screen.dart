import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../widgets/page_transitions.dart';
import 'admin/dashboard_admin_screen.dart';

// Halaman login untuk ADMIN dan PETUGAS.
// Gaya visual disamakan dengan Login Siswa: gradasi warna sekolah +
// kartu kaca buram (glassmorphism), supaya tidak terasa terpisah/kaku.
class StaffLoginScreen extends StatefulWidget {
  const StaffLoginScreen({super.key});

  @override
  State<StaffLoginScreen> createState() => _StaffLoginScreenState();
}

enum _PeranStaff { admin, petugas }

class _StaffLoginScreenState extends State<StaffLoginScreen> {
  final _authService = AuthService();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();

  _PeranStaff _peran = _PeranStaff.admin;
  bool _loading = false;
  bool _lihatPassword = false;
  String? _errorMsg;

  Future<void> _prosesLogin() async {
    final email = _emailController.text.trim();
    final pass = _passController.text.trim();

    if (email.isEmpty || pass.isEmpty) {
      setState(() => _errorMsg = 'Email dan password wajib diisi.');
      return;
    }

    setState(() {
      _loading = true;
      _errorMsg = null;
    });

    final error = _peran == _PeranStaff.admin
        ? await _authService.loginAdmin(email, pass)
        : await _authService.loginPetugas(email, pass);

    if (!mounted) return;
    setState(() => _loading = false);

    if (error != null) {
      setState(() => _errorMsg = error);
      return;
    }

    Navigator.of(context).pushReplacement(
      fadeSlideRoute(
        DashboardAdminScreen(isAdmin: _peran == _PeranStaff.admin),
      ),
    );
  }

  InputDecoration _dekorasiInput(
      {required String label, required IconData icon, Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70, fontSize: 13.5),
      prefixIcon: Icon(icon, size: 20, color: Colors.white70),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.gold, width: 1.4),
      ),
    );
  }

  Widget _pilihanPeran(_PeranStaff nilai, String label, IconData icon) {
    final aktif = _peran == nilai;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _peran = nilai),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: aktif ? AppColors.gold : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Icon(icon,
                  size: 20,
                  color: aktif ? AppColors.primaryDark : Colors.white70),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: aktif ? AppColors.primaryDark : Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryDark,
                  AppColors.primary,
                  AppColors.leaf,
                ],
              ),
            ),
          ),
          Positioned(
            top: -90,
            right: -70,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.gold.withValues(alpha: 0.14)),
            ),
          ),
          Positioned(
            bottom: -110,
            left: -90,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06)),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_rounded,
                            color: Colors.white),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 26, vertical: 10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 24,
                                  offset: const Offset(0, 10)),
                            ],
                          ),
                          child: const Icon(Icons.shield_moon_rounded,
                              size: 52, color: AppColors.primary),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Portal Admin & Petugas',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Kelola aspirasi, akun petugas & persetujuan siswa',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 12.5,
                              color: Colors.white.withValues(alpha: 0.75)),
                        ),
                        const SizedBox(height: 28),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(26),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                            child: Container(
                              padding: const EdgeInsets.all(22),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(26),
                                border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.22),
                                    width: 1.2),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.16),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Row(
                                      children: [
                                        _pilihanPeran(
                                            _PeranStaff.admin,
                                            'Admin',
                                            Icons.admin_panel_settings_rounded),
                                        _pilihanPeran(_PeranStaff.petugas,
                                            'Petugas', Icons.badge_rounded),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  TextField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: _dekorasiInput(
                                        label: 'Email',
                                        icon: Icons.alternate_email_rounded),
                                  ),
                                  const SizedBox(height: 14),
                                  TextField(
                                    controller: _passController,
                                    obscureText: !_lihatPassword,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: _dekorasiInput(
                                      label: 'Password',
                                      icon: Icons.lock_rounded,
                                      suffix: IconButton(
                                        icon: Icon(
                                          _lihatPassword
                                              ? Icons.visibility_off_rounded
                                              : Icons.visibility_rounded,
                                          color: Colors.white54,
                                          size: 19,
                                        ),
                                        onPressed: () => setState(() =>
                                            _lihatPassword = !_lihatPassword),
                                      ),
                                    ),
                                  ),
                                  if (_errorMsg != null) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withValues(alpha: 0.18),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                              Icons.error_outline_rounded,
                                              size: 15,
                                              color: Colors.white),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(_errorMsg!,
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 20),
                                  SizedBox(
                                    height: 52,
                                    child: ElevatedButton(
                                      onPressed: _loading ? null : _prosesLogin,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.gold,
                                        foregroundColor: AppColors.primaryDark,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(14)),
                                        elevation: 0,
                                      ),
                                      child: _loading
                                          ? const SizedBox(
                                              height: 22,
                                              width: 22,
                                              child: CircularProgressIndicator(
                                                  strokeWidth: 2.4,
                                                  color: AppColors.primaryDark),
                                            )
                                          : Text(
                                              _peran == _PeranStaff.admin
                                                  ? 'Masuk sebagai Admin'
                                                  : 'Masuk sebagai Petugas',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 15.5),
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

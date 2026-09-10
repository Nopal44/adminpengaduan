import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/page_transitions.dart';
import 'rating_aplikasi_screen.dart';
import 'help_screen.dart';

// Halaman Onboarding: muncul SEBELUM halaman Login.
// Struktur SANGAT sederhana: latar gradasi polos + Column lurus ke bawah.
// Tidak ada ClipPath/Positioned rumit.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _halamanAktif = 0;

  final List<_SlideOnboarding> _slides = const [
    _SlideOnboarding(
      ikon: Icons.school_rounded,
      judul: 'Selamat Datang',
      isi: 'Aplikasi Pengaduan Sarana Sekolah SLB Marsudi Putra 3 Sanden. '
          'Sampaikan laporan kerusakan atau masukan sarana sekolah dengan '
          'mudah dan cepat.',
      tampilkanLogo: true,
    ),
    _SlideOnboarding(
      ikon: Icons.login_rounded,
      judul: 'Cara Masuk & Daftar',
      isi: 'Gunakan NIS dan password untuk masuk. Jika belum punya akun, '
          'tekan "Daftar di sini" pada halaman masuk, lalu isi data diri '
          'dan buat password sendiri.',
    ),
    _SlideOnboarding(
      ikon: Icons.edit_note_rounded,
      judul: 'Ajukan & Pantau Pengaduan',
      isi: 'Pilih kategori kerusakan, isi lokasi & keterangan. Pantau status '
          'pengaduan (Menunggu, Diproses, Selesai) lewat menu Histori.',
    ),
  ];

  void _lanjut() {
    if (_halamanAktif < _slides.length - 1) {
      _pageController.nextPage(
          duration: const Duration(milliseconds: 350), curve: Curves.easeOut);
    } else {
      _mulai();
    }
  }

  void _mulai() {
    Navigator.of(context)
        .pushReplacement(fadeSlideRoute(const RatingAplikasiScreen()));
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
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: () => Navigator.push(
                        context, fadeSlideRoute(const HelpScreen())),
                    icon: const Icon(Icons.help_outline_rounded,
                        color: Colors.white, size: 18),
                    label: const Text('Bantuan',
                        style: TextStyle(color: Colors.white, fontSize: 13)),
                  ),
                  TextButton(
                    onPressed: _mulai,
                    child: const Text('Lewati',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _slides.length,
                  onPageChanged: (i) => setState(() => _halamanAktif = i),
                  itemBuilder: (context, i) => _kontenSlide(_slides[i]),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_slides.length, (i) {
                  final aktif = i == _halamanAktif;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 8,
                    width: aktif ? 24 : 8,
                    decoration: BoxDecoration(
                      color:
                          aktif ? Colors.white : Colors.white.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  );
                }),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _lanjut,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: AppColors.primaryDark,
                      elevation: 4,
                      shadowColor: AppColors.gold.withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      _halamanAktif < _slides.length - 1 ? 'Lanjut' : 'Mulai',
                      style: const TextStyle(
                          fontSize: 15.5, fontWeight: FontWeight.w800),
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

  Widget _kontenSlide(_SlideOnboarding slide) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.22),
                    blurRadius: 16,
                    offset: const Offset(0, 6)),
              ],
            ),
            child: slide.tampilkanLogo
                ? Image.asset(
                    'assets/images/logo.png',
                    height: 96,
                    width: 96,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stack) =>
                        Icon(slide.ikon, size: 70, color: Colors.white),
                  )
                : Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(slide.ikon, size: 56, color: Colors.white),
                  ),
          ),
          const SizedBox(height: 28),
          Text(
            slide.judul,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 21, fontWeight: FontWeight.w800, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Text(
            slide.isi,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 13.5,
                color: Colors.white.withValues(alpha: 0.85),
                height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _SlideOnboarding {
  final IconData ikon;
  final String judul;
  final String isi;
  final bool tampilkanLogo;
  const _SlideOnboarding({
    required this.ikon,
    required this.judul,
    required this.isi,
    this.tampilkanLogo = false,
  });
}

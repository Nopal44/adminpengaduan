# Admin Panel Web - Pengaduan Sarana Sekolah

**Versi website khusus Admin & Petugas**  
SLB Marsudi Putra 3 Sanden

Aplikasi ini adalah **versi web-only untuk Admin/Petugas**.  
Halaman yang ditampilkan hanya:

1. **Login Staff** (Admin / Petugas)
2. **Dashboard Admin** (setelah berhasil login)

Halaman siswa, onboarding, register, form aspirasi siswa **tidak ditampilkan**.

---

## Fitur Admin yang tersedia

- Dashboard ringkasan pengaduan
- Daftar & detail aspirasi / pengaduan
- Persetujuan akun siswa
- Kelola petugas
- Chat dengan siswa
- Laporan (mingguan / bulanan) + ekspor PDF
- Tema Gelap / Terang

---

## Cara menjalankan lokal (Flutter Web)

```bash
# Pastikan Flutter sudah terinstall
flutter pub get
flutter run -d chrome
# atau
flutter run -d web-server --web-port 8080
```

---

## Deploy ke GitHub Pages

### 1. Buat repository baru di GitHub
Contoh nama repo: `sekolah-admin-web`

### 2. Push kode ini ke repository

```bash
git init
git add .
git commit -m "Initial commit - Admin Web Panel"
git branch -M main
git remote add origin https://github.com/USERNAME/sekolah-admin-web.git
git push -u origin main
```

### 3. Build untuk web (penting: sesuaikan base-href)

Ganti `USERNAME` dan `REPO` sesuai repository Anda:

```bash
flutter build web --base-href "/sekolah-admin-web/"
```

### 4. Deploy hasil build ke branch `gh-pages`

**Opsi A - Manual:**
```bash
# Setelah build
cd build/web
git init
git add .
git commit -m "Deploy admin web"
git branch -M gh-pages
git remote add origin https://github.com/USERNAME/sekolah-admin-web.git
git push -u origin gh-pages --force
```

**Opsi B - Pakai GitHub Actions** (rekomendasi)

Buat file `.github/workflows/deploy.yml` dengan isi berikut (lihat di repo setelah di-push, atau buat manual).

Setelah itu aktifkan **GitHub Pages** di Settings → Pages → Source: GitHub Actions.

Website akan tersedia di:  
`https://USERNAME.github.io/sekolah-admin-web/`

---

## Catatan Firebase

- Project Firebase: `pengaduan-sarana-f7479`
- Konfigurasi web sudah ada di `lib/firebase_options.dart`
- Pastikan di Firebase Console → Authentication → Settings → Authorized domains  
  sudah menambahkan domain GitHub Pages Anda (`USERNAME.github.io`)

---

## Struktur penting

```
lib/
├── main.dart                    ← Entry point (hanya Admin/Petugas)
├── screens/
│   ├── staff_login_screen.dart  ← Halaman login yang ditampilkan
│   └── admin/                   ← Semua halaman dashboard admin
├── services/
└── theme/
```

---

Dibuat berdasarkan proyek Flutter asli `sekolah_fixed_v17`.

# Portal Resmi & Sistem Antrean Digital Rutan Kelas IIB Siak Sri Indrapura

Sistem Informasi Terpadu Pelayanan Pemasyarakatan Digital dan Antrean Pendaftaran Kunjungan Online berbasis Suara Pemanggilan Otomatis (Text-to-Speech) untuk **Rumah Tahanan Negara Kelas IIB Siak Sri Indrapura**, Ditjen Pemasyarakatan, Kementerian Imigrasi dan Pemasyarakatan Republik Indonesia.

---

## ⚡ Deployment Stack (Vercel + Supabase)

Aplikasi ini dioptimalkan untuk hosting di **Vercel** dengan arsitektur backend tanpa server (*serverless*) menggunakan **Supabase (PostgreSQL 15+, Supabase Cloud Storage, & Supabase Realtime)**:

- **Frontend Hosting:** Vercel (Fast Global Edge CDN)
- **Database Engine:** Supabase PostgreSQL Relational Database
- **Cloud Storage:** Supabase Storage (Bucket: `berkas-kunjungan` untuk foto e-KTP & Surat Izin)
- **Realtime Sync:** Supabase Realtime Channels (Instant Broadcast ke Monitor TV & Panel Petugas)
- **Audio Voice Calling:** Web Audio Synthesizer (Harmonic Chime) + Indonesian Speech Synthesis API

---

## 🏛️ Ketentuan & Jadwal Pelayanan Kunjungan (1 Sesi: 09.00 - 11.00 WIB)

Pelayanan kunjungan tatap muka diselenggarakan dalam **1 sesi pukul 09.00 s/d 11.00 WIB** sesuai kategori perkara WBP:

| Hari | Kategori Perkara WBP | Waktu Layanan | Ketentuan Khusus | Kode Antrean |
| :--- | :--- | :--- | :--- | :--- |
| **Senin** | **Khusus Kasus Narkotika** | 09.00 - 11.00 WIB | WBP Perkara Tindak Pidana Narkotika (Wajib e-KTP fisik asli) | `N-001`, `N-002`, ... |
| **Selasa** | **Khusus Pidana Umum** | 09.00 - 11.00 WIB | WBP Perkara Tindak Pidana Umum / Tipidum (Wajib e-KTP fisik asli) | `P-001`, `P-002`, ... |
| **Rabu** | **Khusus Kasus Narkotika** | 09.00 - 11.00 WIB | WBP Perkara Tindak Pidana Narkotika (Wajib e-KTP fisik asli) | `N-001`, `N-002`, ... |
| **Kamis** | **Khusus Pidana Umum** | 09.00 - 11.00 WIB | WBP Perkara Tindak Pidana Umum / Tipidum (Wajib e-KTP fisik asli) | `P-001`, `P-002`, ... |
| **Jumat** | **Titipan Makanan & Barang** | 09.00 - 11.00 WIB | Layanan tatap muka **LIBUR**, hanya melayani penitipan barang/makanan (09.00 - 11.00 WIB) | - |
| **Sabtu & Minggu** | **LIBUR** | - | Seluruh layanan kunjungan tatap muka tutup | - |

> **Catatan Integritas:** Seluruh pengurusan pendaftaran antrean, kunjungan keluarga, dan layanan integrasi (PB/CB/CMB) adalah **100% GRATIS (Bebas Pungli)**.

---

## 🛠️ Panduan Setup Supabase & Deploy ke Vercel

### Langkah 1: Buat Project di Supabase
1. Buka [https://supabase.com](https://supabase.com) dan buat project baru (misal: `rutan-siak-antrian`).
2. Pilih region terdekat (misal: **Singapore**).
3. Salin **Project URL** dan **Anon Public API Key** dari menu `Project Settings > API`.

### Langkah 2: Jalankan Script SQL di Supabase
1. Masuk ke menu **SQL Editor** di dashboard Supabase Anda.
2. Buka file [`database_antrian_rutansiak.sql`](file:///f:/BMN%20FAJAR%20GD/FGD%20Work/NEW%20WEBSITE/database_antrian_rutansiak.sql).
3. Salin seluruh isi file SQL dan tempelkan ke **SQL Editor** Supabase.
4. Klik tombol **Run**. Script ini secara otomatis akan membuat:
   - Seluruh tabel PostgreSQL (`users_admin`, `loket_layanan`, `jadwal_kunjungan`, `data_wbp`, `pendaftaran_antrian`, `log_pemanggilan`, `audit_trail`).
   - Bucket Supabase Storage (`berkas-kunjungan`) dan kebijakan akses publik.
   - Row Level Security (RLS) policies untuk publik dan admin.
   - Publikasi **Supabase Realtime** untuk sinkronisasi pemanggilan langsung ke layar TV Display.
   - Fungsi PL/pgSQL otomatisasi antrean.
   - Seed data awal akun petugas dan jadwal kunjungan resmi.

### Langkah 3: Hubungkan Aplikasi ke Supabase
1. Buka halaman `antrian.html` di browser.
2. Klik tombol **Supabase: Mode Lokal** di bilah atas (Top Bar).
3. Masukkan:
   - **Supabase Project URL**: `https://xyz.supabase.co`
   - **Supabase Anon Key**: `eyJhbGciOi...`
   - **Bucket Storage**: `berkas-kunjungan`
4. Klik **Tes Koneksi** lalu klik **Simpan & Terapkan**.
5. Indikator di pojok atas akan berubah menjadi `🟢 Supabase: Terhubung` / `Realtime Aktif`.

### Langkah 4: Deploy ke Vercel
1. Hubungkan repository GitHub Anda ke [Vercel](https://vercel.com).
2. Pilih project repository dan klik **Deploy**.
3. Website akan langsung aktif secara global dengan performa instan tanpa perlu setting server tambahan!

---

## 💾 Struktur Database Supabase (`database_antrian_rutansiak.sql`)

### 1. Daftar Tabel Utama
- **`public.users_admin`**: Data autentikasi akun administrator, pengawas, dan petugas loket pemanggilan.
- **`public.loket_layanan`**: Konfigurasi loket fisik (Loket 1 Reguler, Loket 2 Titipan Barang, Loket 3 Khusus Lansia & Disabilitas).
- **`public.jadwal_kunjungan`**: Konfigurasi hari, kategori perkara (`Narkotika` / `Pidana_Umum`), jam operasional (09.00–11.00 WIB), dan total kuota harian (60 antrean).
- **`public.data_wbp`**: Master data WBP (nomor register, nama, kategori perkara, blok/kamar, status hak kunjungan).
- **`public.pendaftaran_antrian`**: Transaksi antrean pengunjung (`kode_booking`, `nomor_antrian` `N-001`/`P-001`, identitas NIK, relasi, status antrean, link URL foto KTP/berkas di Cloud Storage).
- **`public.log_pemanggilan`**: Log audit pemanggilan loket untuk memicu suara & tampilan live di layar TV monitor.
- **`public.audit_trail`**: Log keamanan seluruh aktivitas operasional sistem.

### 2. Fitur Supabase Tambahan
- **Supabase Storage:** Bucket `berkas-kunjungan` untuk menyimpan unggahan foto e-KTP asli dan surat izin kunjungan.
- **Supabase Realtime:** `ALTER PUBLICATION supabase_realtime ADD TABLE pendaftaran_antrian, log_pemanggilan;` yang menyinkronkan seluruh perubahan status dan panggilan ke monitor TV secara instan tanpa refresh browser.

---

## 🔐 Portal Akses Petugas & Super Admin (`admin.html`)

Sistem menyediakan halaman kerja terdedikasi bagi operator dan administrator di **[`admin.html`](file:///f:/BMN%20FAJAR%20GD/FGD%20Work/NEW%20WEBSITE/admin.html)** dengan otorisasi berbasis peran (Role-Based Access Control) yang terhubung langsung ke tabel `public.users_admin` Supabase PostgreSQL:

| Username | Password Default | Nama Petugas | Role / Tingkat Akses | Hak Akses Utama |
| :--- | :--- | :--- | :--- | :--- |
| **`admin.kunjungan`** | `rutansiak2026` | Administrator Pelayanan Tahanan | **SUPERADMIN** | Akses Penuh: Manajemen Petugas, Master WBP, Konfigurasi Jadwal/Loket, Audit Trail, Backup/Reset DB, Panggilan Antrean |
| **`petugas.loket1`** | `rutansiak2026` | Ahmad Fadillah, A.Md.P | **PETUGAS_LOKET** | Stasiun Pemanggilan Loket 1 (Reguler), Verifikasi Berkas e-KTP, Input Walk-in, Layani & Selesaikan Antrean |
| **`petugas.loket2`** | `rutansiak2026` | Siti Rahmayani, S.H. | **PETUGAS_LOKET** | Stasiun Pemanggilan Loket 2 (Titipan Barang/Makanan), Verifikasi Barang, Update Status Antrean |
| **`petugas.loket3`** | `rutansiak2026` | Budi Hartanto, S.Sos | **PETUGAS_LOKET** | Stasiun Pemanggilan Loket 3 (Prioritas Lansia/Disabilitas), Input Walk-in Khusus |
| **`kasubsi.yantah`** | `rutansiak2026` | Okta Adi Putra, S.H. | **PENGAWAS** | Monitoring Live Realtime, Analitik Durasi Layanan, Lembar Rekap Berita Acara, Audit Trail Aktivitas |

---

## 🚀 Fitur Lengkap Sistem Antrean & Panel Admin

1. **Pendaftaran Antrean Online Publik (`antrian.html`)**:
   - Validasi jadwal cerdas (otomatis mendeteksi hari dan mengunci kategori Narkotika / Pidana Umum).
   - Layanan 1 sesi terpadu pukul 09.00 - 11.00 WIB.
   - Upload foto e-KTP dan surat izin ke Supabase Cloud Storage bucket `berkas-kunjungan`.
   - Generator E-Tiket Digital resmi ber-QR Code dengan tombol Cetak / PDF dan Bagikan ke WhatsApp.
2. **Stasiun Pemanggilan Suara Operator (`admin.html`)**:
   - Audio Chime Synthesizer 3 nada harmonik + Pelafalan Suara Otomatis Bahasa Indonesia (*"Nomor antrean N-001 atas nama ..., silakan menuju Loket 1"*).
   - Tombol operasional cepat: **Panggil Berikutnya**, **Panggil Ulang**, **Mulai Layani** (live stopwatch), **Selesai**, **Lewati**, dan **Batalkan**.
   - Input pendaftaran **Walk-in Langsung di Loket Fisik**.
3. **Verifikasi Berkas Kunjungan (`admin.html`)**:
   - Pratinjau foto e-KTP digital & surat izin dari Supabase Cloud Storage.
   - Validasi berkas fisik & pencatatan catatan petugas.
4. **Master Data WBP (`public.data_wbp`)**:
   - CRUD data Warga Binaan Pemasyarakatan (Nomor Register, Nama, Kategori Perkara, Status Tahanan/Napi, Blok Kamar, Status Hak Kunjungan).
5. **Manajemen Akun Petugas & Administrator (`public.users_admin`)**:
   - Tambah petugas baru, atur NIP, jabatan, role, dan loket default.
6. **Layar Display TV Ruang Tunggu (Supabase Realtime)**:
   - Tampilan monitor fullscreen TV untuk ruang tunggu pendaftaran yang tersambung langsung ke Supabase Realtime channel.
7. **Laporan & Cetak Berita Acara**:
   - Unduh rekapitulasi data ke format Excel/CSV.
   - Cetak Berita Acara Rekapitulasi Kunjungan Harian resmi bertanda tangan Kasubsi Yantah & Petugas Loket.
   - Catatan keamanan audit trail aktivitas pengguna.

---
© 2026 Rumah Tahanan Negara Kelas IIB Siak Sri Indrapura — Ditjen Pemasyarakatan, Kementerian Imigrasi dan Pemasyarakatan RI.

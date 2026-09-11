# Portal Resmi & Sistem Antrean Digital Rutan Kelas IIB Siak Sri Indrapura

Sistem Informasi Terpadu Pelayanan Pemasyarakatan Digital dan Antrean Pendaftaran Kunjungan Online berbasis Suara Pemanggilan Otomatis (Text-to-Speech) untuk **Rumah Tahanan Negara Kelas IIB Siak Sri Indrapura**, Ditjen Pemasyarakatan, Kementerian Imigrasi dan Pemasyarakatan Republik Indonesia.

---

## 🏛️ Ketentuan & Jadwal Pelayanan Kunjungan (1 Sesi: 09.00 - 11.00 WIB)

Pelayanan kunjungan tatap muka diselenggarakan dalam **1 sesi pukul 09.00 s/d 11.00 WIB** sesuai kategori perkara WBP:

| Hari | Kategori Perkara WBP | Waktu Layanan | Ketentuan Khusus |
| :--- | :--- | :--- | :--- |
| **Senin** | **Khusus Kasus Narkotika** | 09.00 - 11.00 WIB | WBP Perkara Tindak Pidana Narkotika (Wajib e-KTP fisik asli) |
| **Selasa** | **Khusus Pidana Umum** | 09.00 - 11.00 WIB | WBP Perkara Tindak Pidana Umum / Tipidum (Wajib e-KTP fisik asli) |
| **Rabu** | **Khusus Kasus Narkotika** | 09.00 - 11.00 WIB | WBP Perkara Tindak Pidana Narkotika (Wajib e-KTP fisik asli) |
| **Kamis** | **Khusus Pidana Umum** | 09.00 - 11.00 WIB | WBP Perkara Tindak Pidana Umum / Tipidum (Wajib e-KTP fisik asli) |
| **Jumat** | **Titipan Makanan & Barang** | 09.00 - 11.00 WIB | Layanan tatap muka **LIBUR**, hanya melayani penitipan barang/makanan |
| **Sabtu & Minggu** | **LIBUR** | - | Seluruh layanan kunjungan tatap muka tutup |

> **Catatan Integritas:** Seluruh pengurusan pendaftaran antrean, kunjungan keluarga, dan layanan integrasi (PB/CB/CMB) adalah **100% GRATIS (Bebas Pungli)**.

---

## 💾 Struktur Database SQL (`database_antrian_rutansiak.sql`)

Skema database relasional lengkap telah dirancang secara modular dan dapat diimpor ke **MySQL 8.0+ / MariaDB 10.4+ / PostgreSQL / SQLite / phpMyAdmin**:

### 1. Daftar Tabel Utama
- **`users_admin`**: Data autentikasi akun administrator, pengawas, dan petugas loket pendaftaran.
- **`loket_layanan`**: Konfigurasi loket fisik (Loket 1 Reguler, Loket 2 Titipan Barang, Loket 3 Khusus Lansia & Disabilitas).
- **`jadwal_kunjungan`**: Konfigurasi hari, kategori perkara (`Narkotika` / `Pidana_Umum`), jam operasional (09.00–11.00 WIB), dan total kuota harian (60 antrean).
- **`data_wbp`**: Master data WBP (nomor register, nama, kategori perkara, blok/kamar, status hak kunjungan).
- **`pendaftaran_antrian`**: Transaksi pendaftaran antrean pengunjung (kode booking, nomor urut `N-001`/`P-001`, identitas NIK, relasi keluarga, status antrean, timestamp pemanggilan).
- **`log_pemanggilan`**: Audit trail setiap aksi pemanggilan audio oleh petugas loket.
- **`audit_trail`**: Log keamanan seluruh aktivitas operasional sistem.

### 2. Views & Stored Procedures
- `v_antrian_hari_ini`: View antrean aktif terurut berdasarkan prioritas status pemanggilan.
- `v_statistik_kunjungan_harian`: Rekapitulasi kuota, total pengunjung selesai, dan waktu tunggu.
- `sp_daftar_antrian_online()`: Generator nomor tiket otomatis `N-XXX` (Narkotika) dan `P-XXX` (Pidana Umum).
- `sp_panggil_antrian()`: Logika update status dan pencatatan log pemanggilan loket.

---

## 🔐 Akun Akses Administrator & Petugas Loket

Untuk mengakses **Panel Pemanggilan Antrean** (`antrian.html#admin`), gunakan kredensial berikut:

| Username | Password Default | Nama Petugas | Role / Jabatan | Penugasan Default |
| :--- | :--- | :--- | :--- | :--- |
| **`admin.kunjungan`** | `rutansiak2026` | Administrator Pelayanan Tahanan | SUPERADMIN | Loket 1 / Semua Loket |
| **`petugas.loket1`** | `rutansiak2026` | Ahmad Fadillah, A.Md.P | PETUGAS_LOKET | Loket 1 (Pendaftaran Reguler) |
| **`petugas.loket2`** | `rutansiak2026` | Siti Rahmayani, S.H. | PETUGAS_LOKET | Loket 2 (Titipan Barang) |
| **`petugas.loket3`** | `rutansiak2026` | Budi Hartanto, S.Sos | PETUGAS_LOKET | Loket 3 (Prioritas Lansia) |
| **`kasubsi.yantah`** | `rutansiak2026` | Okta Adi Putra, S.H. | PENGAWAS | Kasubsi Pelayanan Tahanan |

---

## 🚀 Fitur Utama Sistem Antrean (`antrian.html`)

1. **Pendaftaran Antrean Online (Publik)**:
   - Validasi jadwal cerdas (otomatis mendeteksi hari dan mengunci kategori Narkotika / Pidana Umum).
   - Layanan 1 sesi terpadu pukul 09.00 - 11.00 WIB.
   - Generator E-Tiket Digital resmi ber-QR Code dengan tombol Cetak / PDF dan Kirim ke WhatsApp.
2. **Panel Pemanggilan Suara Berbasis Text-to-Speech (Administrator)**:
   - Audio Chime Synthesizer 3 nada harmonik + Pelafalan Suara Otomatis Bahasa Indonesia (*"Nomor antrean N-001 atas nama ..., silakan menuju Loket 1"*).
   - Tombol operasional cepat: **Panggil Berikutnya**, **Panggil Ulang**, **Mulai Layani**, **Selesai**, **Lewati**, dan **Input Walk-in**.
3. **Layar Display TV Ruang Tunggu**:
   - Tampilan monitor fullscreen TV untuk ruang tunggu pendaftaran dengan sinkronisasi real-time nomor yang sedang dipanggil dan antrean berikutnya.
4. **Pelacakan Tiket (Tracking Status)**:
   - Cek posisi nomor urut antrean secara langsung cukup dengan memasukkan NIK atau Kode Tiket.
5. **Ekspor & Laporan**:
   - Unduh rekapitulasi data ke format Excel/CSV.
   - Cetak Berita Acara / Lembar Rekap Kunjungan Harian (09.00 - 11.00 WIB).
   - Backup & Restore Database ke file SQL / JSON.

---

## 🛠️ Panduan Menjalankan & Impor Database

### Menjalankan Website Secara Lokal:
Buka file `index.html` atau `antrian.html` langsung di browser modern (Google Chrome, Microsoft Edge, Mozilla Firefox) atau gunakan ekstensi Live Server.

### Mengimpor ke Server MySQL / phpMyAdmin:
1. Buka phpMyAdmin / MySQL Workbench.
2. Buat database baru bernama `rutan_siak_antrian`.
3. Klik menu **Import** dan pilih file `database_antrian_rutansiak.sql`.
4. Klik **Go / Eksekusi**. Database siap digunakan.

---
© 2026 Rumah Tahanan Negara Kelas IIB Siak Sri Indrapura — Kementerian Imigrasi dan Pemasyarakatan RI.

-- ==============================================================================
-- DATABASE SISTEM ANTREAN PENDAFTARAN ONLINE & ADMINISTRATOR PEMANGGILAN
-- RUMAH TAHANAN NEGARA KELAS IIB SIAK SRI INDRAPURA
-- KEMENTERIAN IMIGRASI DAN PEMASYARAKATAN REPUBLIK INDONESIA
-- ==============================================================================
-- Aturan Operasional Kunjungan:
-- • Waktu Layanan: 1 Sesi Pukul 09.00 s/d 11.00 WIB
-- • Senin & Rabu   : Khusus Perkara / Kasus NARKOTIKA
-- • Selasa & Kamis : Khusus Perkara / Kasus PIDANA UMUM
-- • Jumat          : Khusus Titipan Barang / Makanan (09.00 - 11.00 WIB)
-- • Sabtu & Minggu : LIBUR Pelayanan Kunjungan
-- ==============================================================================

CREATE DATABASE IF NOT EXISTS `rutan_siak_antrian` 
DEFAULT CHARACTER SET utf8mb4 
COLLATE utf8mb4_unicode_ci;

USE `rutan_siak_antrian`;

-- ==============================================================================
-- 1. TABEL PENGGUNA & ADMINISTRATOR (AUTHENTICATION & ROLES)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS `users_admin` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `username` VARCHAR(50) NOT NULL UNIQUE,
    `password_hash` VARCHAR(255) NOT NULL COMMENT 'Bcrypt / SHA-256 password hash',
    `nama_lengkap` VARCHAR(100) NOT NULL,
    `nip` VARCHAR(30) DEFAULT NULL,
    `jabatan` VARCHAR(100) NOT NULL DEFAULT 'Petugas Pelayanan Kunjungan',
    `role` ENUM('superadmin', 'admin_layanan', 'petugas_loket', 'pengawas') NOT NULL DEFAULT 'petugas_loket',
    `nomor_loket_default` INT DEFAULT 1 COMMENT 'Loket yang biasa dioperasikan',
    `status_aktif` TINYINT(1) NOT NULL DEFAULT 1,
    `last_login` DATETIME DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `idx_username` (`username`),
    INDEX `idx_role` (`role`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Akun administrator dan petugas loket pemanggilan';

-- ==============================================================================
-- 2. TABEL LOKET LAYANAN PENDAFTARAN FISIK
-- ==============================================================================
CREATE TABLE IF NOT EXISTS `loket_layanan` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `nomor_loket` INT NOT NULL UNIQUE,
    `nama_loket` VARCHAR(50) NOT NULL,
    `keterangan` VARCHAR(150) DEFAULT NULL,
    `tipe_loket` ENUM('umum', 'prioritas_lansia_disabilitas', 'narkotika', 'pidana_umum') NOT NULL DEFAULT 'umum',
    `status_aktif` TINYINT(1) NOT NULL DEFAULT 1,
    `petugas_aktif_id` INT DEFAULT NULL,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (`petugas_aktif_id`) REFERENCES `users_admin` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Daftar loket fisik di ruang pelayanan Rutan Siak';

-- ==============================================================================
-- 3. TABEL JADWAL KUNJUNGAN RUTAN SIAK (SCHEDULE RULES)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS `jadwal_kunjungan` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `hari_indonesia` ENUM('Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu') NOT NULL,
    `day_of_week` TINYINT NOT NULL COMMENT '1=Senin, 2=Selasa, ... 7=Minggu',
    `kategori_wbp` ENUM('Narkotika', 'Pidana_Umum', 'Semua', 'Tutup') NOT NULL,
    `jam_buka` TIME NOT NULL DEFAULT '09:00:00',
    `jam_tutup` TIME NOT NULL DEFAULT '11:00:00',
    `sesi_kunjungan` VARCHAR(50) NOT NULL DEFAULT '09:00 - 11:00 WIB',
    `total_kuota_harian` INT NOT NULL DEFAULT 60,
    `status_layanan` ENUM('Aktif', 'Libur', 'Khusus_Titipan_Barang') NOT NULL DEFAULT 'Aktif',
    `keterangan` TEXT DEFAULT NULL,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY `uk_hari` (`hari_indonesia`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Konfigurasi jadwal kunjungan resmi Rutan Siak 1 sesi';

-- ==============================================================================
-- 4. TABEL DATA WARGA BINAAN PEMASYARAKATAN (WBP)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS `data_wbp` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `nomor_register` VARCHAR(50) NOT NULL UNIQUE,
    `nama_wbp` VARCHAR(100) NOT NULL,
    `jenis_kelamin` ENUM('L', 'P') NOT NULL DEFAULT 'L',
    `kategori_perkara` ENUM('Narkotika', 'Pidana_Umum') NOT NULL,
    `status_tahanan_napi` ENUM('Tahanan', 'Narapidana') NOT NULL DEFAULT 'Narapidana',
    `blok_kamar` VARCHAR(50) NOT NULL COMMENT 'Contoh: Blok A Kamar 04',
    `pasal_kejahatan` VARCHAR(100) DEFAULT NULL,
    `status_hak_kunjungan` ENUM('Diizinkan', 'Dicabut_Sementara', 'Isolasi') NOT NULL DEFAULT 'Diizinkan',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_nama_wbp` (`nama_wbp`),
    INDEX `idx_kategori_perkara` (`kategori_perkara`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Data master WBP untuk validasi penerima kunjungan';

-- ==============================================================================
-- 5. TABEL UTAMA: PENDAFTARAN ANTREAN PENGUNJUNG ONLINE & WALK-IN
-- ==============================================================================
CREATE TABLE IF NOT EXISTS `pendaftaran_antrian` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
    `kode_booking` VARCHAR(30) NOT NULL UNIQUE COMMENT 'Format: SIK-YYYYMMDD-N001 / P001',
    `nomor_antrian` VARCHAR(10) NOT NULL COMMENT 'Format: N-001 (Narkotika) atau P-001 (Pidana Umum)',
    `nomor_urut` INT NOT NULL COMMENT '1, 2, 3 urutan hari berjalan',
    `tgl_kunjungan` DATE NOT NULL,
    `sesi_kunjungan` VARCHAR(50) NOT NULL DEFAULT '09:00 - 11:00 WIB',
    `kategori_kunjungan` ENUM('Narkotika', 'Pidana_Umum') NOT NULL,
    
    -- DATA IDENTITAS PENGUNJUNG
    `nik_pengunjung` VARCHAR(16) NOT NULL,
    `nama_pengunjung` VARCHAR(100) NOT NULL,
    `jenis_kelamin` ENUM('L', 'P') NOT NULL,
    `no_whatsapp` VARCHAR(20) NOT NULL,
    `alamat_domisili` TEXT NOT NULL,
    `hubungan_wbp` ENUM(
        'Orang Tua (Ayah/Ibu)',
        'Suami / Istri Sah',
        'Anak Kandung',
        'Saudara Kandung (Kakak/Adik)',
        'Kakek / Nenek Kandung',
        'Kuasa Hukum / Pengacara',
        'Lainnya (Izin Khusus)'
    ) NOT NULL,
    `jumlah_pengikut_dewasa` INT NOT NULL DEFAULT 0,
    `jumlah_pengikut_anak` INT NOT NULL DEFAULT 0,

    -- DATA WBP YANG DIKUNJUNGI
    `wbp_id` INT DEFAULT NULL,
    `nama_wbp` VARCHAR(100) NOT NULL,
    `blok_kamar_wbp` VARCHAR(50) DEFAULT NULL,
    `nomor_surat_izin` VARCHAR(100) DEFAULT NULL COMMENT 'Surat izin jika WBP masih berstatus tahanan',
    
    -- TITIPAN & BARANG
    `membawa_barang_titipan` TINYINT(1) NOT NULL DEFAULT 0,
    `rincian_barang_titipan` TEXT DEFAULT NULL,

    -- STATUS ANTREAN & PEMANGGILAN
    `status_antrian` ENUM(
        'Menunggu',         -- Belum dipanggil
        'Dipanggil',        -- Sedang disuarakan melalui audio loket
        'Sedang_Dilayani',  -- Berada di meja loket pendaftaran
        'Selesai',          -- Verifikasi selesai dan masuk ke ruang kunjungan
        'Batal',            -- Dibatalkan sistem/pengunjung
        'Dilewati'          -- Pengunjung tidak hadir saat 3x pemanggilan
    ) NOT NULL DEFAULT 'Menunggu',
    
    `loket_pemanggil_id` INT DEFAULT NULL,
    `petugas_pemanggil_id` INT DEFAULT NULL,
    `jumlah_panggilan` INT NOT NULL DEFAULT 0,
    `waktu_daftar` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `waktu_panggil_pertama` DATETIME DEFAULT NULL,
    `waktu_panggil_terakhir` DATETIME DEFAULT NULL,
    `waktu_mulai_layanan` DATETIME DEFAULT NULL,
    `waktu_selesai_layanan` DATETIME DEFAULT NULL,
    `durasi_layanan_menit` INT DEFAULT NULL,
    
    -- METADATA DIGITAL
    `asal_pendaftaran` ENUM('Online_Website', 'Walk_in_Loket', 'Kiosk_Mandiri') NOT NULL DEFAULT 'Online_Website',
    `catatan_petugas` TEXT DEFAULT NULL,
    `qr_code_token` VARCHAR(64) DEFAULT NULL,
    `is_checked_in` TINYINT(1) NOT NULL DEFAULT 0,
    `waktu_check_in` DATETIME DEFAULT NULL,

    FOREIGN KEY (`wbp_id`) REFERENCES `data_wbp` (`id`) ON DELETE SET NULL,
    FOREIGN KEY (`loket_pemanggil_id`) REFERENCES `loket_layanan` (`id`) ON DELETE SET NULL,
    FOREIGN KEY (`petugas_pemanggil_id`) REFERENCES `users_admin` (`id`) ON DELETE SET NULL,
    
    INDEX `idx_tgl_antrian` (`tgl_kunjungan`, `status_antrian`),
    INDEX `idx_nik_pengunjung` (`nik_pengunjung`),
    INDEX `idx_kode_booking` (`kode_booking`),
    INDEX `idx_nomor_antrian` (`nomor_antrian`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Data pendaftaran antrean 1 sesi Rutan Siak';

-- ==============================================================================
-- 6. TABEL LOG PEMANGGILAN ANTREAN (VOICE CALL AUDIT)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS `log_pemanggilan` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
    `antrian_id` BIGINT NOT NULL,
    `kode_booking` VARCHAR(30) NOT NULL,
    `nomor_antrian` VARCHAR(10) NOT NULL,
    `loket_nomor` INT NOT NULL,
    `petugas_id` INT NOT NULL,
    `petugas_nama` VARCHAR(100) NOT NULL,
    `panggilan_ke` INT NOT NULL DEFAULT 1,
    `waktu_panggil` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `teks_suara` TEXT DEFAULT NULL,
    FOREIGN KEY (`antrian_id`) REFERENCES `pendaftaran_antrian` (`id`) ON DELETE CASCADE,
    FOREIGN KEY (`petugas_id`) REFERENCES `users_admin` (`id`) ON DELETE CASCADE,
    INDEX `idx_log_antrian` (`antrian_id`),
    INDEX `idx_waktu_panggil` (`waktu_panggil`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Log audit pemanggilan antrean oleh petugas loket';

-- ==============================================================================
-- 7. TABEL AUDIT AKTIVITAS SISTEM (SECURITY & OPERATIONAL LOG)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS `audit_trail` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
    `user_id` INT DEFAULT NULL,
    `aktivitas` VARCHAR(100) NOT NULL,
    `modul` VARCHAR(50) NOT NULL DEFAULT 'ANTREAN',
    `keterangan` TEXT NOT NULL,
    `ip_address` VARCHAR(45) DEFAULT '127.0.0.1',
    `user_agent` TEXT DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`user_id`) REFERENCES `users_admin` (`id`) ON DELETE SET NULL,
    INDEX `idx_audit_waktu` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Catatan jejak audit sistem keamanan dan operasional';

-- ==============================================================================
-- 8. VIEWS UNTUK MONITORING REALTIME & LAPORAN
-- ==============================================================================

-- View: Antrean Aktif Hari Ini
CREATE OR REPLACE VIEW `v_antrian_hari_ini` AS
SELECT 
    p.id,
    p.kode_booking,
    p.nomor_antrian,
    p.nomor_urut,
    p.tgl_kunjungan,
    p.sesi_kunjungan,
    p.kategori_kunjungan,
    p.nama_pengunjung,
    p.nik_pengunjung,
    p.no_whatsapp,
    p.hubungan_wbp,
    p.nama_wbp,
    p.blok_kamar_wbp,
    p.status_antrian,
    p.jumlah_panggilan,
    p.waktu_daftar,
    p.waktu_panggil_terakhir,
    l.nomor_loket,
    l.nama_loket,
    u.nama_lengkap AS nama_petugas
FROM `pendaftaran_antrian` p
LEFT JOIN `loket_layanan` l ON p.loket_pemanggil_id = l.id
LEFT JOIN `users_admin` u ON p.petugas_pemanggil_id = u.id
WHERE p.tgl_kunjungan = CURDATE()
ORDER BY 
    CASE p.status_antrian
        WHEN 'Dipanggil' THEN 1
        WHEN 'Sedang_Dilayani' THEN 2
        WHEN 'Menunggu' THEN 3
        WHEN 'Dilewati' THEN 4
        WHEN 'Selesai' THEN 5
        WHEN 'Batal' THEN 6
        ELSE 7
    END,
    p.nomor_urut ASC;

-- View: Statistik Harian Layanan Kunjungan
CREATE OR REPLACE VIEW `v_statistik_kunjungan_harian` AS
SELECT 
    tgl_kunjungan,
    kategori_kunjungan,
    COUNT(id) AS total_pendaftar,
    SUM(CASE WHEN status_antrian = 'Selesai' THEN 1 ELSE 0 END) AS total_selesai,
    SUM(CASE WHEN status_antrian = 'Sedang_Dilayani' THEN 1 ELSE 0 END) AS total_sedang_dilayani,
    SUM(CASE WHEN status_antrian = 'Menunggu' THEN 1 ELSE 0 END) AS total_menunggu,
    SUM(CASE WHEN status_antrian = 'Dilewati' THEN 1 ELSE 0 END) AS total_dilewati,
    SUM(CASE WHEN status_antrian = 'Batal' THEN 1 ELSE 0 END) AS total_batal,
    AVG(durasi_layanan_menit) AS rata_durasi_menit
FROM `pendaftaran_antrian`
GROUP BY tgl_kunjungan, kategori_kunjungan;

-- ==============================================================================
-- 9. STORED PROCEDURES (PROSEDUR LOGIKA ANTREAN N-XXX / P-XXX)
-- ==============================================================================

DELIMITER //

-- Prosedur: Pendaftaran Antrean Baru (N = Narkotika, P = Pidana Umum)
CREATE PROCEDURE `sp_daftar_antrian_online`(
    IN p_tgl_kunjungan DATE,
    IN p_kategori VARCHAR(20),
    IN p_nik VARCHAR(16),
    IN p_nama VARCHAR(100),
    IN p_jk VARCHAR(1),
    IN p_wa VARCHAR(20),
    IN p_alamat TEXT,
    IN p_hubungan VARCHAR(50),
    IN p_jml_dewasa INT,
    IN p_jml_anak INT,
    IN p_nama_wbp VARCHAR(100),
    IN p_blok_kamar VARCHAR(50),
    IN p_surat_izin VARCHAR(100),
    IN p_bawa_barang TINYINT,
    IN p_rincian_barang TEXT,
    OUT p_nomor_antrian_out VARCHAR(10),
    OUT p_kode_booking_out VARCHAR(30)
)
BEGIN
    DECLARE v_prefix CHAR(1);
    DECLARE v_next_urut INT DEFAULT 1;
    DECLARE v_nomor_antrian VARCHAR(10);
    DECLARE v_kode_booking VARCHAR(30);

    -- Tentukan prefix kode: N = Narkotika, P = Pidana Umum
    IF p_kategori = 'Narkotika' THEN
        SET v_prefix = 'N';
    ELSE
        SET v_prefix = 'P';
    END IF;

    -- Dapatkan nomor urut berikutnya untuk tanggal dan kategori terkait
    SELECT IFNULL(MAX(nomor_urut), 0) + 1 INTO v_next_urut
    FROM `pendaftaran_antrian`
    WHERE `tgl_kunjungan` = p_tgl_kunjungan AND `kategori_kunjungan` = p_kategori;

    -- Format nomor antrean (contoh: N-001 atau P-001)
    SET v_nomor_antrian = CONCAT(v_prefix, '-', LPAD(v_next_urut, 3, '0'));
    
    -- Format kode booking unik (contoh: SIK-20260912-N001)
    SET v_kode_booking = CONCAT('SIK-', DATE_FORMAT(p_tgl_kunjungan, '%Y%m%d'), '-', v_prefix, LPAD(v_next_urut, 3, '0'));

    -- Masukkan ke tabel pendaftaran_antrian (1 Sesi: 09:00 - 11:00 WIB)
    INSERT INTO `pendaftaran_antrian` (
        `kode_booking`, `nomor_antrian`, `nomor_urut`, `tgl_kunjungan`, `sesi_kunjungan`, `kategori_kunjungan`,
        `nik_pengunjung`, `nama_pengunjung`, `jenis_kelamin`, `no_whatsapp`, `alamat_domisili`, `hubungan_wbp`,
        `jumlah_pengikut_dewasa`, `jumlah_pengikut_anak`, `nama_wbp`, `blok_kamar_wbp`, `nomor_surat_izin`,
        `membawa_barang_titipan`, `rincian_barang_titipan`, `status_antrian`, `asal_pendaftaran`
    ) VALUES (
        v_kode_booking, v_nomor_antrian, v_next_urut, p_tgl_kunjungan, '09:00 - 11:00 WIB', p_kategori,
        p_nik, p_nama, p_jk, p_wa, p_alamat, p_hubungan,
        p_jml_dewasa, p_jml_anak, p_nama_wbp, p_blok_kamar, p_surat_izin,
        p_bawa_barang, p_rincian_barang, 'Menunggu', 'Online_Website'
    );

    SET p_nomor_antrian_out = v_nomor_antrian;
    SET p_kode_booking_out = v_kode_booking;
END //

-- Prosedur: Pemanggilan Nomor Antrean oleh Petugas Loket
CREATE PROCEDURE `sp_panggil_antrian`(
    IN p_antrian_id BIGINT,
    IN p_loket_id INT,
    IN p_petugas_id INT,
    OUT p_status_out VARCHAR(50)
)
BEGIN
    DECLARE v_nomor_antrian VARCHAR(10);
    DECLARE v_kode_booking VARCHAR(30);
    DECLARE v_nama_pengunjung VARCHAR(100);
    DECLARE v_nomor_loket INT;
    DECLARE v_nama_petugas VARCHAR(100);
    DECLARE v_jml_panggilan INT;

    SELECT nomor_antrian, kode_booking, nama_pengunjung, jumlah_panggilan
    INTO v_nomor_antrian, v_kode_booking, v_nama_pengunjung, v_jml_panggilan
    FROM `pendaftaran_antrian`
    WHERE id = p_antrian_id;

    SELECT nomor_loket INTO v_nomor_loket FROM `loket_layanan` WHERE id = p_loket_id;
    SELECT nama_lengkap INTO v_nama_petugas FROM `users_admin` WHERE id = p_petugas_id;

    UPDATE `pendaftaran_antrian`
    SET 
        status_antrian = 'Dipanggil',
        loket_pemanggil_id = p_loket_id,
        petugas_pemanggil_id = p_petugas_id,
        jumlah_panggilan = v_jml_panggilan + 1,
        waktu_panggil_pertama = IFNULL(waktu_panggil_pertama, NOW()),
        waktu_panggil_terakhir = NOW()
    WHERE id = p_antrian_id;

    INSERT INTO `log_pemanggilan` (
        antrian_id, kode_booking, nomor_antrian, loket_nomor, 
        petugas_id, petugas_nama, panggilan_ke, waktu_panggil, teks_suara
    ) VALUES (
        p_antrian_id, v_kode_booking, v_nomor_antrian, v_nomor_loket,
        p_petugas_id, v_nama_petugas, v_jml_panggilan + 1, NOW(),
        CONCAT('Nomor antrean ', v_nomor_antrian, ', atas nama ', v_nama_pengunjung, ', silakan menuju Loket ', v_nomor_loket)
    );

    SET p_status_out = 'SUKSES_DIPANGGIL';
END //

DELIMITER ;

-- ==============================================================================
-- 10. SEED DATA DEFAULT (INITIAL CONFIGURATION & ACCOUNTS)
-- ==============================================================================

-- A. Akun Administrator & Petugas Loket (Password: 'rutansiak2026')
INSERT INTO `users_admin` (`id`, `username`, `password_hash`, `nama_lengkap`, `nip`, `jabatan`, `role`, `nomor_loket_default`, `status_aktif`) VALUES
(1, 'admin.kunjungan', '$2y$10$e8T7Q0z.P1zF3vUqJ.yJ0eG6h9e0v4u7m9w3q2y1x0z8r7s6t5u4v', 'Administrator Pelayanan Tahanan', '198705122008011002', 'Admin Sistem Terpadu', 'superadmin', 1, 1),
(2, 'petugas.loket1', '$2y$10$e8T7Q0z.P1zF3vUqJ.yJ0eG6h9e0v4u7m9w3q2y1x0z8r7s6t5u4v', 'Ahmad Fadillah, A.Md.P', '199508142017121001', 'Petugas Loket Pelayanan 1', 'petugas_loket', 1, 1),
(3, 'petugas.loket2', '$2y$10$e8T7Q0z.P1zF3vUqJ.yJ0eG6h9e0v4u7m9w3q2y1x0z8r7s6t5u4v', 'Siti Rahmayani, S.H.', '199611202019012003', 'Petugas Loket Pelayanan 2', 'petugas_loket', 2, 1),
(4, 'petugas.loket3', '$2y$10$e8T7Q0z.P1zF3vUqJ.yJ0eG6h9e0v4u7m9w3q2y1x0z8r7s6t5u4v', 'Budi Hartanto, S.Sos', '199203102015031002', 'Petugas Loket Prioritas (Lansia/Disabilitas)', 'petugas_loket', 3, 1),
(5, 'kasubsi.yantah', '$2y$10$e8T7Q0z.P1zF3vUqJ.yJ0eG6h9e0v4u7m9w3q2y1x0z8r7s6t5u4v', 'Okta Adi Putra, S.H.', '198904012010121001', 'Kasubsi Pelayanan Tahanan', 'pengawas', 1, 1)
ON DUPLICATE KEY UPDATE `nama_lengkap` = VALUES(`nama_lengkap`);

-- B. Konfigurasi Loket Fisik Pelayanan Rutan Siak
INSERT INTO `loket_layanan` (`id`, `nomor_loket`, `nama_loket`, `keterangan`, `tipe_loket`, `status_aktif`, `petugas_aktif_id`) VALUES
(1, 1, 'Loket 1 — Pendaftaran Reguler', 'Loket Verifikasi Berkas & Identitas Pengunjung', 'umum', 1, 2),
(2, 2, 'Loket 2 — Pendaftaran & Titipan Barang', 'Loket Verifikasi & Pemeriksaan Titipan Makanan/Barang', 'umum', 1, 3),
(3, 3, 'Loket 3 — Khusus Prioritas & Bantuan', 'Loket Lansia, Ibu Hamil, Penyandang Disabilitas, & Konsultasi', 'prioritas_lansia_disabilitas', 1, 4)
ON DUPLICATE KEY UPDATE `nama_loket` = VALUES(`nama_loket`);

-- C. Konfigurasi Jadwal Kunjungan Resmi Rutan Siak (1 Sesi: 09.00 - 11.00 WIB)
INSERT INTO `jadwal_kunjungan` (`id`, `hari_indonesia`, `day_of_week`, `kategori_wbp`, `jam_buka`, `jam_tutup`, `sesi_kunjungan`, `total_kuota_harian`, `status_layanan`, `keterangan`) VALUES
(1, 'Senin', 1, 'Narkotika', '09:00:00', '11:00:00', '09:00 - 11:00 WIB', 60, 'Aktif', 'Khusus Warga Binaan Pemasyarakatan Perkara Narkotika'),
(2, 'Selasa', 2, 'Pidana_Umum', '09:00:00', '11:00:00', '09:00 - 11:00 WIB', 60, 'Aktif', 'Khusus Warga Binaan Pemasyarakatan Perkara Pidana Umum (Tipidum)'),
(3, 'Rabu', 3, 'Narkotika', '09:00:00', '11:00:00', '09:00 - 11:00 WIB', 60, 'Aktif', 'Khusus Warga Binaan Pemasyarakatan Perkara Narkotika'),
(4, 'Kamis', 4, 'Pidana_Umum', '09:00:00', '11:00:00', '09:00 - 11:00 WIB', 60, 'Aktif', 'Khusus Warga Binaan Pemasyarakatan Perkara Pidana Umum (Tipidum)'),
(5, 'Jumat', 5, 'Tutup', '09:00:00', '11:00:00', '09:00 - 11:00 WIB', 0, 'Khusus_Titipan_Barang', 'Layanan Kunjungan Tatap Muka LIBUR. Hanya melayani penitipan barang/makanan'),
(6, 'Sabtu', 6, 'Tutup', '00:00:00', '00:00:00', '-', 0, 'Libur', 'Layanan Kunjungan Tatap Muka LIBUR'),
(7, 'Minggu', 7, 'Tutup', '00:00:00', '00:00:00', '-', 0, 'Libur', 'Layanan Kunjungan Tatap Muka LIBUR')
ON DUPLICATE KEY UPDATE `kategori_wbp` = VALUES(`kategori_wbp`), `keterangan` = VALUES(`keterangan`);

-- D. Contoh Data Master WBP Rutan Siak (Narkotika & Pidana Umum)
INSERT INTO `data_wbp` (`id`, `nomor_register`, `nama_wbp`, `jenis_kelamin`, `kategori_perkara`, `status_tahanan_napi`, `blok_kamar`, `pasal_kejahatan`, `status_hak_kunjungan`) VALUES
(1, 'REG/2026/N/00142', 'Rahmat Hidayat bin Rusli', 'L', 'Narkotika', 'Narapidana', 'Blok A (Kamar 03)', 'UU Narkotika No. 35/2009', 'Diizinkan'),
(2, 'REG/2026/P/00088', 'Surya Dharma Putra', 'L', 'Pidana_Umum', 'Narapidana', 'Blok B (Kamar 07)', 'Pasal 363 KUHP (Pencurian)', 'Diizinkan'),
(3, 'REG/2026/N/00155', 'Bambang Irawan', 'L', 'Narkotika', 'Tahanan', 'Blok A (Kamar 05)', 'Pasal 114 UU Narkotika', 'Diizinkan'),
(4, 'REG/2026/P/00104', 'Hendri Saputra', 'L', 'Pidana_Umum', 'Narapidana', 'Blok C (Kamar 02)', 'Pasal 378 KUHP (Penipuan)', 'Diizinkan')
ON DUPLICATE KEY UPDATE `nama_wbp` = VALUES(`nama_wbp`);

-- E. Contoh Data Pendaftaran Antrean Demo (1 Sesi: 09:00 - 11:00 WIB)
INSERT INTO `pendaftaran_antrian` (
    `id`, `kode_booking`, `nomor_antrian`, `nomor_urut`, `tgl_kunjungan`, `sesi_kunjungan`, `kategori_kunjungan`,
    `nik_pengunjung`, `nama_pengunjung`, `jenis_kelamin`, `no_whatsapp`, `alamat_domisili`, `hubungan_wbp`,
    `jumlah_pengikut_dewasa`, `jumlah_pengikut_anak`, `nama_wbp`, `blok_kamar_wbp`, `membawa_barang_titipan`,
    `status_antrian`, `asal_pendaftaran`
) VALUES
(1, CONCAT('SIK-', DATE_FORMAT(CURDATE(), '%Y%m%d'), '-N001'), 'N-001', 1, CURDATE(), '09:00 - 11:00 WIB', 'Narkotika', '1408011205850001', 'Zulkifli Mansyur', 'L', '081276543210', 'Jl. Sutomo No. 14, Siak', 'Orang Tua (Ayah/Ibu)', 1, 0, 'Rahmat Hidayat bin Rusli', 'Blok A (Kamar 03)', 1, 'Menunggu', 'Online_Website'),
(2, CONCAT('SIK-', DATE_FORMAT(CURDATE(), '%Y%m%d'), '-N002'), 'N-002', 2, CURDATE(), '09:00 - 11:00 WIB', 'Narkotika', '1408015509920003', 'Nurhasanah Lubis', 'P', '082165438890', 'Kp. Rempak, Kec. Siak', 'Suami / Istri Sah', 0, 1, 'Bambang Irawan', 'Blok A (Kamar 05)', 1, 'Menunggu', 'Online_Website')
ON DUPLICATE KEY UPDATE `nama_pengunjung` = VALUES(`nama_pengunjung`);

-- ==============================================================================
-- AKHIR DARI FILE SKEMA DATABASE RUTAN KELAS IIB SIAK SRI INDRAPURA
-- ==============================================================================

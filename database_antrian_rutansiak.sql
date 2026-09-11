-- ==============================================================================
-- DATABASE SISTEM ANTREAN ONLINE & ADMINISTRATOR PEMANGGILAN (SUPABASE POSTGRESQL)
-- RUMAH TAHANAN NEGARA KELAS IIB SIAK SRI INDRAPURA
-- KEMENTERIAN IMIGRASI DAN PEMASYARAKATAN REPUBLIK INDONESIA
-- ==============================================================================
-- TARGET PLATFORM: SUPABASE (PostgreSQL 15+) + VERCEL HOSTING
-- FITUR: Realtime Pub/Sub, Cloud Storage (KTP/Berkas), Row Level Security (RLS)
-- ATURAN JADWAL OPERASIONAL:
-- • Waktu Layanan : 1 Sesi Pukul 09.00 s/d 11.00 WIB
-- • Senin & Rabu  : Khusus Kasus / Perkara NARKOTIKA (Kode Antrean: N-XXX)
-- • Selasa & Kamis: Khusus Kasus / Perkara PIDANA UMUM (Kode Antrean: P-XXX)
-- • Jumat         : Khusus Titipan Makanan & Barang (09.00 - 11.00 WIB, Tatap Muka Tutup)
-- • Sabtu & Minggu: LIBUR Pelayanan Kunjungan
-- ==============================================================================

-- 0. EKSTENSI POSTGRESQL (SUPABASE STANDARD)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==============================================================================
-- 1. TABEL PENGGUNA & ADMINISTRATOR (AUTHENTICATION & ROLES)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.users_admin (
    id BIGSERIAL PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    nama_lengkap VARCHAR(100) NOT NULL,
    nip VARCHAR(30) DEFAULT NULL,
    jabatan VARCHAR(100) NOT NULL DEFAULT 'Petugas Pelayanan Kunjungan',
    role VARCHAR(30) NOT NULL DEFAULT 'petugas_loket' 
        CHECK (role IN ('superadmin', 'admin_layanan', 'petugas_loket', 'pengawas')),
    nomor_loket_default INT DEFAULT 1,
    status_aktif BOOLEAN NOT NULL DEFAULT true,
    last_login TIMESTAMPTZ DEFAULT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Indexing
CREATE INDEX IF NOT EXISTS idx_users_admin_username ON public.users_admin (username);
CREATE INDEX IF NOT EXISTS idx_users_admin_role ON public.users_admin (role);

-- ==============================================================================
-- 2. TABEL LOKET LAYANAN FISIK
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.loket_layanan (
    id BIGSERIAL PRIMARY KEY,
    nomor_loket INT NOT NULL UNIQUE,
    nama_loket VARCHAR(100) NOT NULL,
    keterangan VARCHAR(200) DEFAULT NULL,
    tipe_loket VARCHAR(50) NOT NULL DEFAULT 'umum'
        CHECK (tipe_loket IN ('umum', 'prioritas_lansia_disabilitas', 'narkotika', 'pidana_umum')),
    status_aktif BOOLEAN NOT NULL DEFAULT true,
    petugas_aktif_id BIGINT REFERENCES public.users_admin(id) ON DELETE SET NULL,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ==============================================================================
-- 3. TABEL JADWAL KUNJUNGAN RUTAN SIAK (1 SESI: 09.00 - 11.00 WIB)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.jadwal_kunjungan (
    id BIGSERIAL PRIMARY KEY,
    hari_indonesia VARCHAR(20) NOT NULL UNIQUE
        CHECK (hari_indonesia IN ('Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu')),
    day_of_week SMALLINT NOT NULL CHECK (day_of_week BETWEEN 1 AND 7), -- 1=Senin, 7=Minggu
    kategori_wbp VARCHAR(30) NOT NULL 
        CHECK (kategori_wbp IN ('Narkotika', 'Pidana_Umum', 'Semua', 'Tutup')),
    jam_buka TIME NOT NULL DEFAULT '09:00:00',
    jam_tutup TIME NOT NULL DEFAULT '11:00:00',
    sesi_kunjungan VARCHAR(50) NOT NULL DEFAULT '09:00 - 11:00 WIB',
    total_kuota_harian INT NOT NULL DEFAULT 60,
    status_layanan VARCHAR(30) NOT NULL DEFAULT 'Aktif'
        CHECK (status_layanan IN ('Aktif', 'Libur', 'Khusus_Titipan_Barang')),
    keterangan TEXT DEFAULT NULL,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ==============================================================================
-- 4. TABEL MASTER DATA WARGA BINAAN PEMASYARAKATAN (WBP)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.data_wbp (
    id BIGSERIAL PRIMARY KEY,
    nomor_register VARCHAR(50) NOT NULL UNIQUE,
    nama_wbp VARCHAR(100) NOT NULL,
    jenis_kelamin CHAR(1) NOT NULL DEFAULT 'L' CHECK (jenis_kelamin IN ('L', 'P')),
    kategori_perkara VARCHAR(30) NOT NULL CHECK (kategori_perkara IN ('Narkotika', 'Pidana_Umum')),
    status_tahanan_napi VARCHAR(30) NOT NULL DEFAULT 'Narapidana' CHECK (status_tahanan_napi IN ('Tahanan', 'Narapidana')),
    blok_kamar VARCHAR(50) NOT NULL,
    pasal_kejahatan VARCHAR(150) DEFAULT NULL,
    status_hak_kunjungan VARCHAR(30) NOT NULL DEFAULT 'Diizinkan' CHECK (status_hak_kunjungan IN ('Diizinkan', 'Dicabut_Sementara', 'Isolasi')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_wbp_nama ON public.data_wbp (nama_wbp);
CREATE INDEX IF NOT EXISTS idx_wbp_kategori ON public.data_wbp (kategori_perkara);

-- ==============================================================================
-- 5. TABEL UTAMA: PENDAFTARAN ANTREAN PENGUNJUNG ONLINE & WALK-IN
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.pendaftaran_antrian (
    id BIGSERIAL PRIMARY KEY,
    kode_booking VARCHAR(35) NOT NULL UNIQUE, -- Format: SIK-YYYYMMDD-N001 / P001
    nomor_antrian VARCHAR(12) NOT NULL,        -- Format: N-001 / P-001
    nomor_urut INT NOT NULL,                  -- Urutan 1, 2, 3 per hari & kategori
    tgl_kunjungan DATE NOT NULL,
    sesi_kunjungan VARCHAR(50) NOT NULL DEFAULT '09:00 - 11:00 WIB',
    kategori_kunjungan VARCHAR(30) NOT NULL CHECK (kategori_kunjungan IN ('Narkotika', 'Pidana_Umum')),
    
    -- DATA PENGUNJUNG
    nik_pengunjung VARCHAR(16) NOT NULL,
    nama_pengunjung VARCHAR(100) NOT NULL,
    jenis_kelamin CHAR(1) NOT NULL CHECK (jenis_kelamin IN ('L', 'P')),
    no_whatsapp VARCHAR(20) NOT NULL,
    alamat_domisili TEXT NOT NULL,
    hubungan_wbp VARCHAR(50) NOT NULL,
    jumlah_pengikut_dewasa INT NOT NULL DEFAULT 0,
    jumlah_pengikut_anak INT NOT NULL DEFAULT 0,

    -- DATA WBP YANG DIKUNJUNGI
    wbp_id BIGINT REFERENCES public.data_wbp(id) ON DELETE SET NULL,
    nama_wbp VARCHAR(100) NOT NULL,
    blok_kamar_wbp VARCHAR(50) DEFAULT NULL,
    nomor_surat_izin VARCHAR(100) DEFAULT NULL,
    
    -- TITIPAN BARANG & MAKANAN
    membawa_barang_titipan BOOLEAN NOT NULL DEFAULT false,
    rincian_barang_titipan TEXT DEFAULT NULL,

    -- STATUS ANTREAN & PEMANGGILAN
    status_antrian VARCHAR(30) NOT NULL DEFAULT 'Menunggu'
        CHECK (status_antrian IN ('Menunggu', 'Dipanggil', 'Sedang_Dilayani', 'Selesai', 'Batal', 'Dilewati')),
    loket_pemanggil_id BIGINT REFERENCES public.loket_layanan(id) ON DELETE SET NULL,
    petugas_pemanggil_id BIGINT REFERENCES public.users_admin(id) ON DELETE SET NULL,
    jumlah_panggilan INT NOT NULL DEFAULT 0,
    waktu_daftar TIMESTAMPTZ NOT NULL DEFAULT now(),
    waktu_panggil_pertama TIMESTAMPTZ DEFAULT NULL,
    waktu_panggil_terakhir TIMESTAMPTZ DEFAULT NULL,
    waktu_mulai_layanan TIMESTAMPTZ DEFAULT NULL,
    waktu_selesai_layanan TIMESTAMPTZ DEFAULT NULL,
    durasi_layanan_menit INT DEFAULT NULL,

    -- CLOUD STORAGE & DIGITAL METADATA
    berkas_ktp_url TEXT DEFAULT NULL,          -- URL Supabase Cloud Storage (Bucket berkas-kunjungan)
    berkas_surat_izin_url TEXT DEFAULT NULL,   -- URL Supabase Cloud Storage
    asal_pendaftaran VARCHAR(30) NOT NULL DEFAULT 'Online_Website'
        CHECK (asal_pendaftaran IN ('Online_Website', 'Walk_in_Loket', 'Kiosk_Mandiri')),
    catatan_petugas TEXT DEFAULT NULL,
    qr_code_token VARCHAR(64) DEFAULT NULL,
    is_checked_in BOOLEAN NOT NULL DEFAULT false,
    waktu_check_in TIMESTAMPTZ DEFAULT NULL
);

-- Indeks Performa Query
CREATE INDEX IF NOT EXISTS idx_antrian_tgl_status ON public.pendaftaran_antrian (tgl_kunjungan, status_antrian);
CREATE INDEX IF NOT EXISTS idx_antrian_nik ON public.pendaftaran_antrian (nik_pengunjung);
CREATE INDEX IF NOT EXISTS idx_antrian_kode_booking ON public.pendaftaran_antrian (kode_booking);
CREATE INDEX IF NOT EXISTS idx_antrian_nomor ON public.pendaftaran_antrian (nomor_antrian);

-- ==============================================================================
-- 6. TABEL LOG PEMANGGILAN ANTREAN (VOICE CALL AUDIT & REALTIME TV DISPLAY)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.log_pemanggilan (
    id BIGSERIAL PRIMARY KEY,
    antrian_id BIGINT REFERENCES public.pendaftaran_antrian(id) ON DELETE CASCADE,
    kode_booking VARCHAR(35) NOT NULL,
    nomor_antrian VARCHAR(12) NOT NULL,
    loket_nomor INT NOT NULL,
    petugas_id BIGINT REFERENCES public.users_admin(id) ON DELETE SET NULL,
    petugas_nama VARCHAR(100) NOT NULL,
    panggilan_ke INT NOT NULL DEFAULT 1,
    waktu_panggil TIMESTAMPTZ NOT NULL DEFAULT now(),
    teks_suara TEXT DEFAULT NULL
);

CREATE INDEX IF NOT EXISTS idx_log_antrian_id ON public.log_pemanggilan (antrian_id);
CREATE INDEX IF NOT EXISTS idx_log_waktu_panggil ON public.log_pemanggilan (waktu_panggil);

-- ==============================================================================
-- 7. TABEL AUDIT AKTIVITAS SISTEM (SECURITY AUDIT)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.audit_trail (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT REFERENCES public.users_admin(id) ON DELETE SET NULL,
    aktivitas VARCHAR(100) NOT NULL,
    modul VARCHAR(50) NOT NULL DEFAULT 'ANTREAN',
    keterangan TEXT NOT NULL,
    ip_address VARCHAR(45) DEFAULT '127.0.0.1',
    user_agent TEXT DEFAULT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_audit_created_at ON public.audit_trail (created_at);

-- ==============================================================================
-- 8. SUPABASE STORAGE BUCKET (BERKAS KUNJUNGAN & IDENTITAS KTP)
-- ==============================================================================
-- Membuat bucket storage 'berkas-kunjungan' jika belum ada
INSERT INTO storage.buckets (id, name, public)
VALUES ('berkas-kunjungan', 'berkas-kunjungan', true)
ON CONFLICT (id) DO UPDATE SET public = true;

-- Kebijakan Storage: Hapus kebijakan lama jika ada agar aman di-run berulang kali
DROP POLICY IF EXISTS "Public Upload Berkas Kunjungan" ON storage.objects;
DROP POLICY IF EXISTS "Public Read Berkas Kunjungan" ON storage.objects;
DROP POLICY IF EXISTS "Admin Delete Berkas Kunjungan" ON storage.objects;

-- Kebijakan Storage: Publik Anonymous dapat mengunggah (upload) dokumen pendaftaran
CREATE POLICY "Public Upload Berkas Kunjungan"
ON storage.objects FOR INSERT
TO public
WITH CHECK (bucket_id = 'berkas-kunjungan');

-- Kebijakan Storage: Dokumen dapat dibaca/diakses publik
CREATE POLICY "Public Read Berkas Kunjungan"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'berkas-kunjungan');

-- Kebijakan Storage: Petugas/Admin dapat menghapus/memperbarui
CREATE POLICY "Admin Delete Berkas Kunjungan"
ON storage.objects FOR DELETE
TO public
USING (bucket_id = 'berkas-kunjungan');

-- ==============================================================================
-- 9. ROW LEVEL SECURITY (RLS) & POLICIES UNTUK KEAMANAN DATA
-- ==============================================================================
-- Aktifkan RLS di setiap tabel
ALTER TABLE public.users_admin ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.loket_layanan ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.jadwal_kunjungan ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.data_wbp ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pendaftaran_antrian ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.log_pemanggilan ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_trail ENABLE ROW LEVEL SECURITY;

-- Hapus kebijakan lama pada tabel antrean jika ada (Idempotent Safe)
DROP POLICY IF EXISTS "Public Anon Insert Antrian" ON public.pendaftaran_antrian;
DROP POLICY IF EXISTS "Public Read Antrian" ON public.pendaftaran_antrian;
DROP POLICY IF EXISTS "Allow Update Antrian" ON public.pendaftaran_antrian;
DROP POLICY IF EXISTS "Allow Delete Antrian" ON public.pendaftaran_antrian;

DROP POLICY IF EXISTS "Public Read Log Pemanggilan" ON public.log_pemanggilan;
DROP POLICY IF EXISTS "Allow Insert Log Pemanggilan" ON public.log_pemanggilan;

DROP POLICY IF EXISTS "Public Read Jadwal" ON public.jadwal_kunjungan;
DROP POLICY IF EXISTS "Public Read Loket" ON public.loket_layanan;
DROP POLICY IF EXISTS "Public Read WBP" ON public.data_wbp;
DROP POLICY IF EXISTS "Public Read Users Admin" ON public.users_admin;
DROP POLICY IF EXISTS "Allow Insert Audit" ON public.audit_trail;

-- A. Policies untuk pendaftaran_antrian:
-- 1. Pengunjung / Publik dapat mendaftar (INSERT)
CREATE POLICY "Public Anon Insert Antrian"
ON public.pendaftaran_antrian FOR INSERT
TO anon, authenticated
WITH CHECK (true);

-- 2. Pengunjung & Display TV dapat membaca data antrean (SELECT)
CREATE POLICY "Public Read Antrian"
ON public.pendaftaran_antrian FOR SELECT
TO anon, authenticated
USING (true);

-- 3. Petugas/Admin & Sistem dapat mengupdate status antrean (UPDATE)
CREATE POLICY "Allow Update Antrian"
ON public.pendaftaran_antrian FOR UPDATE
TO anon, authenticated
USING (true)
WITH CHECK (true);

-- 4. Petugas dapat menghapus antrean (DELETE)
CREATE POLICY "Allow Delete Antrian"
ON public.pendaftaran_antrian FOR DELETE
TO anon, authenticated
USING (true);

-- B. Policies untuk log_pemanggilan:
CREATE POLICY "Public Read Log Pemanggilan"
ON public.log_pemanggilan FOR SELECT
TO anon, authenticated
USING (true);

CREATE POLICY "Allow Insert Log Pemanggilan"
ON public.log_pemanggilan FOR INSERT
TO anon, authenticated
WITH CHECK (true);

-- C. Policies untuk referensi: jadwal_kunjungan, loket_layanan, data_wbp, users_admin
CREATE POLICY "Public Read Jadwal" ON public.jadwal_kunjungan FOR SELECT TO anon, authenticated USING (true);
CREATE POLICY "Public Read Loket" ON public.loket_layanan FOR SELECT TO anon, authenticated USING (true);
CREATE POLICY "Public Read WBP" ON public.data_wbp FOR SELECT TO anon, authenticated USING (true);
CREATE POLICY "Public Read Users Admin" ON public.users_admin FOR SELECT TO anon, authenticated USING (true);
CREATE POLICY "Allow Insert Audit" ON public.audit_trail FOR INSERT TO anon, authenticated WITH CHECK (true);

-- ==============================================================================
-- 10. SUPABASE REALTIME REPLICATION (INSTANT SYNC FOR TV & ADMIN)
-- ==============================================================================
-- Menambahkan tabel antrean ke publikasi Supabase Realtime
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' AND tablename = 'pendaftaran_antrian'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.pendaftaran_antrian;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' AND tablename = 'log_pemanggilan'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.log_pemanggilan;
    END IF;
END $$;

-- ==============================================================================
-- 11. POSTGRESQL FUNCTIONS (LOGIKA ANTREAN OTOMATIS)
-- ==============================================================================

-- Fungsi: Generate Nomor Antrean & Kode Booking Berikutnya
CREATE OR REPLACE FUNCTION public.fn_generate_nomor_antrian(
    p_tgl DATE,
    p_kategori TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
AS $$
DECLARE
    v_prefix CHAR(1);
    v_next_urut INT;
    v_nomor_antrian TEXT;
    v_kode_booking TEXT;
    v_clean_date TEXT;
BEGIN
    -- Prefix: N = Narkotika, P = Pidana Umum
    IF p_kategori = 'Narkotika' THEN
        v_prefix := 'N';
    ELSE
        v_prefix := 'P';
    END IF;

    -- Cari nomor urut berikutnya untuk tanggal dan kategori terkait
    SELECT COALESCE(MAX(nomor_urut), 0) + 1 INTO v_next_urut
    FROM public.pendaftaran_antrian
    WHERE tgl_kunjungan = p_tgl AND kategori_kunjungan = p_kategori;

    -- Format nomor antrean (misal: N-001 atau P-001)
    v_nomor_antrian := v_prefix || '-' || LPAD(v_next_urut::TEXT, 3, '0');

    -- Format kode booking (misal: SIK-20260912-N001)
    v_clean_date := TO_CHAR(p_tgl, 'YYYYMMDD');
    v_kode_booking := 'SIK-' || v_clean_date || '-' || v_prefix || LPAD(v_next_urut::TEXT, 3, '0');

    RETURN jsonb_build_object(
        'nomor_urut', v_next_urut,
        'nomor_antrian', v_nomor_antrian,
        'kode_booking', v_kode_booking
    );
END;
$$;

-- Fungsi: Pemanggilan Antrean dengan Catatan Suara & Log Realtime
CREATE OR REPLACE FUNCTION public.fn_panggil_antrian(
    p_antrian_id BIGINT,
    p_loket_id INT,
    p_petugas_id BIGINT
)
RETURNS JSONB
LANGUAGE plpgsql
AS $$
DECLARE
    v_antrian RECORD;
    v_loket RECORD;
    v_petugas RECORD;
    v_teks_suara TEXT;
    v_panggilan_ke INT;
BEGIN
    SELECT * INTO v_antrian FROM public.pendaftaran_antrian WHERE id = p_antrian_id;
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'message', 'Data antrean tidak ditemukan');
    END IF;

    SELECT * INTO v_loket FROM public.loket_layanan WHERE id = p_loket_id;
    SELECT * INTO v_petugas FROM public.users_admin WHERE id = p_petugas_id;

    v_panggilan_ke := v_antrian.jumlah_panggilan + 1;
    v_teks_suara := 'Nomor antrean ' || REPLACE(v_antrian.nomor_antrian, '-', ' ') || ', atas nama ' || v_antrian.nama_pengunjung || ', silakan menuju ke Loket ' || COALESCE(v_loket.nomor_loket, 1);

    -- Update status di tabel pendaftaran_antrian
    UPDATE public.pendaftaran_antrian
    SET 
        status_antrian = 'Dipanggil',
        loket_pemanggil_id = p_loket_id,
        petugas_pemanggil_id = p_petugas_id,
        jumlah_panggilan = v_panggilan_ke,
        waktu_panggil_pertama = COALESCE(waktu_panggil_pertama, now()),
        waktu_panggil_terakhir = now()
    WHERE id = p_antrian_id;

    -- Rekam di log_pemanggilan untuk memicu Realtime Broadcast ke Display TV
    INSERT INTO public.log_pemanggilan (
        antrian_id, kode_booking, nomor_antrian, loket_nomor,
        petugas_id, petugas_nama, panggilan_ke, waktu_panggil, teks_suara
    ) VALUES (
        p_antrian_id, v_antrian.kode_booking, v_antrian.nomor_antrian, COALESCE(v_loket.nomor_loket, 1),
        p_petugas_id, COALESCE(v_petugas.nama_lengkap, 'Petugas Loket'), v_panggilan_ke, now(), v_teks_suara
    );

    RETURN jsonb_build_object(
        'success', true,
        'nomor_antrian', v_antrian.nomor_antrian,
        'nama_pengunjung', v_antrian.nama_pengunjung,
        'loket_nomor', COALESCE(v_loket.nomor_loket, 1),
        'panggilan_ke', v_panggilan_ke,
        'teks_suara', v_teks_suara
    );
END;
$$;

-- ==============================================================================
-- 12. VIEWS MONITORING & STATISTIK
-- ==============================================================================

-- View: Antrean Aktif Hari Ini
CREATE OR REPLACE VIEW public.v_antrian_hari_ini AS
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
    p.berkas_ktp_url,
    p.waktu_daftar,
    p.waktu_panggil_terakhir,
    l.nomor_loket,
    l.nama_loket,
    u.nama_lengkap AS nama_petugas
FROM public.pendaftaran_antrian p
LEFT JOIN public.loket_layanan l ON p.loket_pemanggil_id = l.id
LEFT JOIN public.users_admin u ON p.petugas_pemanggil_id = u.id
WHERE p.tgl_kunjungan = CURRENT_DATE
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

-- View: Statistik Harian Layanan
CREATE OR REPLACE VIEW public.v_statistik_kunjungan_harian AS
SELECT 
    tgl_kunjungan,
    kategori_kunjungan,
    COUNT(id) AS total_pendaftar,
    COUNT(id) FILTER (WHERE status_antrian = 'Selesai') AS total_selesai,
    COUNT(id) FILTER (WHERE status_antrian = 'Sedang_Dilayani') AS total_sedang_dilayani,
    COUNT(id) FILTER (WHERE status_antrian = 'Menunggu') AS total_menunggu,
    COUNT(id) FILTER (WHERE status_antrian = 'Dilewati') AS total_dilewati,
    COUNT(id) FILTER (WHERE status_antrian = 'Batal') AS total_batal,
    AVG(durasi_layanan_menit) AS rata_durasi_menit
FROM public.pendaftaran_antrian
GROUP BY tgl_kunjungan, kategori_kunjungan;

-- ==============================================================================
-- 13. SEED DATA AWAL (INITIAL CONFIGURATION & ACCOUNTS)
-- ==============================================================================

-- A. Akun Administrator & Petugas Loket (Default Password: 'rutansiak2026')
INSERT INTO public.users_admin (id, username, password_hash, nama_lengkap, nip, jabatan, role, nomor_loket_default, status_aktif)
VALUES
(1, 'admin.kunjungan', '$2y$10$e8T7Q0z.P1zF3vUqJ.yJ0eG6h9e0v4u7m9w3q2y1x0z8r7s6t5u4v', 'Administrator Pelayanan Tahanan', '198705122008011002', 'Admin Sistem Terpadu', 'superadmin', 1, true),
(2, 'petugas.loket1', '$2y$10$e8T7Q0z.P1zF3vUqJ.yJ0eG6h9e0v4u7m9w3q2y1x0z8r7s6t5u4v', 'Ahmad Fadillah, A.Md.P', '199508142017121001', 'Petugas Loket Pelayanan 1', 'petugas_loket', 1, true),
(3, 'petugas.loket2', '$2y$10$e8T7Q0z.P1zF3vUqJ.yJ0eG6h9e0v4u7m9w3q2y1x0z8r7s6t5u4v', 'Siti Rahmayani, S.H.', '199611202019012003', 'Petugas Loket Pelayanan 2', 'petugas_loket', 2, true),
(4, 'petugas.loket3', '$2y$10$e8T7Q0z.P1zF3vUqJ.yJ0eG6h9e0v4u7m9w3q2y1x0z8r7s6t5u4v', 'Budi Hartanto, S.Sos', '199203102015031002', 'Petugas Loket Prioritas (Lansia/Disabilitas)', 'petugas_loket', 3, true),
(5, 'kasubsi.yantah', '$2y$10$e8T7Q0z.P1zF3vUqJ.yJ0eG6h9e0v4u7m9w3q2y1x0z8r7s6t5u4v', 'Okta Adi Putra, S.H.', '198904012010121001', 'Kasubsi Pelayanan Tahanan', 'pengawas', 1, true)
ON CONFLICT (id) DO UPDATE SET nama_lengkap = EXCLUDED.nama_lengkap;

-- B. Konfigurasi Loket Fisik Pelayanan Rutan Siak
INSERT INTO public.loket_layanan (id, nomor_loket, nama_loket, keterangan, tipe_loket, status_aktif, petugas_aktif_id)
VALUES
(1, 1, 'Loket 1 — Pendaftaran Reguler', 'Loket Verifikasi Berkas & Identitas Pengunjung', 'umum', true, 2),
(2, 2, 'Loket 2 — Pendaftaran & Titipan Barang', 'Loket Verifikasi & Pemeriksaan Titipan Makanan/Barang', 'umum', true, 3),
(3, 3, 'Loket 3 — Khusus Prioritas & Bantuan', 'Loket Lansia, Ibu Hamil, Penyandang Disabilitas, & Konsultasi', 'prioritas_lansia_disabilitas', true, 4)
ON CONFLICT (id) DO UPDATE SET nama_loket = EXCLUDED.nama_loket;

-- C. Konfigurasi Jadwal Kunjungan Resmi Rutan Siak (1 Sesi: 09.00 - 11.00 WIB)
INSERT INTO public.jadwal_kunjungan (id, hari_indonesia, day_of_week, kategori_wbp, jam_buka, jam_tutup, sesi_kunjungan, total_kuota_harian, status_layanan, keterangan)
VALUES
(1, 'Senin', 1, 'Narkotika', '09:00:00', '11:00:00', '09:00 - 11:00 WIB', 60, 'Aktif', 'Khusus Warga Binaan Pemasyarakatan Perkara Narkotika'),
(2, 'Selasa', 2, 'Pidana_Umum', '09:00:00', '11:00:00', '09:00 - 11:00 WIB', 60, 'Aktif', 'Khusus Warga Binaan Pemasyarakatan Perkara Pidana Umum (Tipidum)'),
(3, 'Rabu', 3, 'Narkotika', '09:00:00', '11:00:00', '09:00 - 11:00 WIB', 60, 'Aktif', 'Khusus Warga Binaan Pemasyarakatan Perkara Narkotika'),
(4, 'Kamis', 4, 'Pidana_Umum', '09:00:00', '11:00:00', '09:00 - 11:00 WIB', 60, 'Aktif', 'Khusus Warga Binaan Pemasyarakatan Perkara Pidana Umum (Tipidum)'),
(5, 'Jumat', 5, 'Tutup', '09:00:00', '11:00:00', '09:00 - 11:00 WIB', 0, 'Khusus_Titipan_Barang', 'Layanan Kunjungan Tatap Muka LIBUR. Hanya melayani penitipan barang/makanan (09.00 - 11.00 WIB)'),
(6, 'Sabtu', 6, 'Tutup', '00:00:00', '00:00:00', '-', 0, 'Libur', 'Layanan Kunjungan Tatap Muka LIBUR'),
(7, 'Minggu', 7, 'Tutup', '00:00:00', '00:00:00', '-', 0, 'Libur', 'Layanan Kunjungan Tatap Muka LIBUR')
ON CONFLICT (id) DO UPDATE SET kategori_wbp = EXCLUDED.kategori_wbp, keterangan = EXCLUDED.keterangan;

-- D. Master Data WBP (Narkotika & Pidana Umum)
INSERT INTO public.data_wbp (id, nomor_register, nama_wbp, jenis_kelamin, kategori_perkara, status_tahanan_napi, blok_kamar, pasal_kejahatan, status_hak_kunjungan)
VALUES
(1, 'REG/2026/N/00142', 'Rahmat Hidayat bin Rusli', 'L', 'Narkotika', 'Narapidana', 'Blok A (Kamar 03)', 'UU Narkotika No. 35/2009', 'Diizinkan'),
(2, 'REG/2026/P/00088', 'Surya Dharma Putra', 'L', 'Pidana_Umum', 'Narapidana', 'Blok B (Kamar 07)', 'Pasal 363 KUHP (Pencurian)', 'Diizinkan'),
(3, 'REG/2026/N/00155', 'Bambang Irawan', 'L', 'Narkotika', 'Tahanan', 'Blok A (Kamar 05)', 'Pasal 114 UU Narkotika', 'Diizinkan'),
(4, 'REG/2026/P/00104', 'Hendri Saputra', 'L', 'Pidana_Umum', 'Narapidana', 'Blok C (Kamar 02)', 'Pasal 378 KUHP (Penipuan)', 'Diizinkan')
ON CONFLICT (id) DO UPDATE SET nama_wbp = EXCLUDED.nama_wbp;

-- E. Contoh Data Antrean Demo (1 Sesi: 09:00 - 11:00 WIB)
INSERT INTO public.pendaftaran_antrian (
    id, kode_booking, nomor_antrian, nomor_urut, tgl_kunjungan, sesi_kunjungan, kategori_kunjungan,
    nik_pengunjung, nama_pengunjung, jenis_kelamin, no_whatsapp, alamat_domisili, hubungan_wbp,
    jumlah_pengikut_dewasa, jumlah_pengikut_anak, nama_wbp, blok_kamar_wbp, membawa_barang_titipan,
    status_antrian, asal_pendaftaran
) VALUES
(1, 'SIK-' || TO_CHAR(CURRENT_DATE, 'YYYYMMDD') || '-N001', 'N-001', 1, CURRENT_DATE, '09:00 - 11:00 WIB', 'Narkotika', '1408011205850001', 'Zulkifli Mansyur', 'L', '081276543210', 'Jl. Sutomo No. 14, Siak', 'Orang Tua (Ayah/Ibu)', 1, 0, 'Rahmat Hidayat bin Rusli', 'Blok A (Kamar 03)', true, 'Menunggu', 'Online_Website'),
(2, 'SIK-' || TO_CHAR(CURRENT_DATE, 'YYYYMMDD') || '-N002', 'N-002', 2, CURRENT_DATE, '09:00 - 11:00 WIB', 'Narkotika', '1408015509920003', 'Nurhasanah Lubis', 'P', '082165438890', 'Kp. Rempak, Kec. Siak', 'Suami / Istri Sah', 0, 1, 'Bambang Irawan', 'Blok A (Kamar 05)', true, 'Menunggu', 'Online_Website')
ON CONFLICT (id) DO UPDATE SET nama_pengunjung = EXCLUDED.nama_pengunjung;

-- Sinkronisasi urutan sequence serial PostgreSQL
SELECT setval('public.users_admin_id_seq', (SELECT COALESCE(MAX(id), 1) FROM public.users_admin));
SELECT setval('public.loket_layanan_id_seq', (SELECT COALESCE(MAX(id), 1) FROM public.loket_layanan));
SELECT setval('public.jadwal_kunjungan_id_seq', (SELECT COALESCE(MAX(id), 1) FROM public.jadwal_kunjungan));
SELECT setval('public.data_wbp_id_seq', (SELECT COALESCE(MAX(id), 1) FROM public.data_wbp));
SELECT setval('public.pendaftaran_antrian_id_seq', (SELECT COALESCE(MAX(id), 1) FROM public.pendaftaran_antrian));

-- ==============================================================================
-- SELESAI: SKEMA SUPABASE POSTGRESQL RUTAN KELAS IIB SIAK SRI INDRAPURA
-- ==============================================================================

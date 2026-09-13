import { z } from 'zod';

export const PengikutItemSchema = z.object({
  nama: z.string().min(3, 'Nama pengikut minimal 3 karakter'),
  nik: z.string().regex(/^\d{16}$/, 'NIK pengikut harus 16 digit angka').optional().or(z.literal('')),
  hubungan: z.string().min(2, 'Hubungan wajib diisi'),
});

export const FormKunjunganSchema = z.object({
  // 1. Data Pengunjung Utama
  nik_pengunjung: z
    .string()
    .length(16, 'NIK harus tepat 16 digit angka')
    .regex(/^\d+$/, 'NIK hanya boleh berisi karakter angka'),
  nama_pengunjung: z
    .string()
    .min(3, 'Nama lengkap minimal 3 karakter')
    .max(100, 'Nama lengkap maksimal 100 karakter'),
  no_whatsapp: z
    .string()
    .min(10, 'Nomor WhatsApp minimal 10 digit')
    .max(15, 'Nomor WhatsApp maksimal 15 digit')
    .regex(/^(08|\+628)[0-9]+$/, 'Format nomor WhatsApp harus diawali 08 atau +628'),
  jenis_kelamin: z.enum(['L', 'P'], {
    errorMap: () => ({ message: 'Pilih jenis kelamin yang valid' }),
  }),
  alamat_lengkap: z.string().min(8, 'Alamat domisili lengkap wajib diisi'),
  hubungan_wbp: z.enum([
    'ORANG_TUA',
    'SUAMI_ISTRI',
    'ANAK_KANDUNG',
    'SAUDARA_KANDUNG',
    'KUASA_HUKUM',
    'KERABAT_LAIN'
  ], {
    errorMap: () => ({ message: 'Pilih hubungan keluarga yang sah' }),
  }),

  // 2. Data Warga Binaan
  nama_wbp: z.string().min(3, 'Nama Warga Binaan wajib diisi'),
  blok_kamar_wbp: z.string().optional(),
  kategori_perkara: z.enum(['NARKOTIKA', 'PIDANA_UMUM', 'TIPIKOR', 'TERORISME', 'LAINNYA'], {
    errorMap: () => ({ message: 'Pilih kategori perkara WBP' }),
  }),

  // 3. Waktu & Sesi Kunjungan
  tanggal_kunjungan: z.string().refine((val: string) => {
    const selected = new Date(val + 'T00:00:00');
    const day = selected.getDay();
    // 0 = Minggu, 6 = Sabtu (Kunjungan Tatap Muka Libur)
    return day !== 0 && day !== 6;
  }, { message: 'Kunjungan tatap muka libur pada hari Sabtu dan Minggu' }),
  sesi_kunjungan: z.string().min(1, 'Pilih sesi kunjungan yang tersedia'),

  // 4. Pengikut & Titipan Barang
  jumlah_pengikut: z.number().min(0).max(3),
  daftar_pengikut: z.array(PengikutItemSchema).max(3),
  membawa_titipan: z.boolean().default(false),
  deskripsi_titipan: z.string().optional(),

  // 5. Persetujuan Syarat & Tata Tertib
  persetujuan_tata_tertib: z.boolean().refine((val: boolean) => val === true, {
    message: 'Anda wajib menyetujui seluruh tata tertib kunjungan',
  }),
});

export type FormKunjunganInput = z.infer<typeof FormKunjunganSchema>;

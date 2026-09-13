'use server';

import { createServerSupabaseClient } from '@/lib/supabase/server';
import { FormKunjunganSchema } from '@/lib/validations/kunjungan';
import { revalidatePath } from 'next/cache';

export async function submitPendaftaranKunjungan(formData: FormData) {
  const supabase = createServerSupabaseClient();

  try {
    const rawData = {
      nik_pengunjung: formData.get('nik_pengunjung'),
      nama_pengunjung: formData.get('nama_pengunjung'),
      no_whatsapp: formData.get('no_whatsapp'),
      jenis_kelamin: formData.get('jenis_kelamin'),
      alamat_lengkap: formData.get('alamat_lengkap'),
      hubungan_wbp: formData.get('hubungan_wbp'),
      nama_wbp: formData.get('nama_wbp'),
      blok_kamar_wbp: formData.get('blok_kamar_wbp') || '',
      kategori_perkara: formData.get('kategori_perkara'),
      tanggal_kunjungan: formData.get('tanggal_kunjungan'),
      sesi_kunjungan: formData.get('sesi_kunjungan'),
      jumlah_pengikut: Number(formData.get('jumlah_pengikut') || 0),
      daftar_pengikut: JSON.parse((formData.get('daftar_pengikut') as string) || '[]'),
      membawa_titipan: formData.get('membawa_titipan') === 'true',
      deskripsi_titipan: formData.get('deskripsi_titipan') || '',
      persetujuan_tata_tertib: formData.get('persetujuan_tata_tertib') === 'true',
    };

    // Validasi Zod
    const validated = FormKunjunganSchema.parse(rawData);

    // Cek Batasan Kuota (Maks 60 per Sesi)
    const { count: existingCount, error: countErr } = await supabase
      .from('pendaftaran_kunjungan')
      .select('*', { count: 'exact', head: true })
      .eq('tanggal_kunjungan', validated.tanggal_kunjungan)
      .eq('sesi_kunjungan', validated.sesi_kunjungan)
      .neq('status', 'BATAL');

    if (countErr) throw new Error(`Gagal verifikasi kuota: ${countErr.message}`);
    if ((existingCount || 0) >= 60) {
      return { success: false, message: 'Mohon maaf, kuota kunjungan untuk sesi ini telah penuh (Maksimal 60 pendaftar).' };
    }

    // Upload Foto KTP ke Supabase Storage
    let fotoKtpUrl = null;
    const fileKtp = formData.get('foto_ktp') as File | null;
    if (fileKtp && fileKtp.size > 0) {
      const ext = fileKtp.name.split('.').pop();
      const fileName = `ktp_${validated.nik_pengunjung}_${Date.now()}.${ext}`;
      const buffer = Buffer.from(await fileKtp.arrayBuffer());

      const { data: uploadData, error: uploadErr } = await supabase.storage
        .from('berkas-ktp')
        .upload(fileName, buffer, { contentType: fileKtp.type, upsert: true });

      if (!uploadErr && uploadData) {
        const { data: publicUrlData } = supabase.storage
          .from('berkas-ktp')
          .getPublicUrl(fileName);
        fotoKtpUrl = publicUrlData.publicUrl;
      }
    }

    // Generate Nomor Urut & Kode Booking
    const nextUrut = (existingCount || 0) + 1;
    const prefix = validated.kategori_perkara === 'NARKOTIKA' ? 'N' : 'P';
    const nomorAntrean = `${prefix}-${String(nextUrut).padStart(3, '0')}`;
    const cleanDate = validated.tanggal_kunjungan.replace(/-/g, '');
    const kodeBooking = `KJG-${cleanDate}-${String(nextUrut).padStart(3, '0')}`;

    // Simpan ke PostgreSQL
    const { data: inserted, error: insertErr } = await supabase
      .from('pendaftaran_kunjungan')
      .insert([
        {
          kode_booking: kodeBooking,
          nomor_antrean: nomorAntrean,
          nomor_urut: nextUrut,
          nik_pengunjung: validated.nik_pengunjung,
          nama_pengunjung: validated.nama_pengunjung,
          no_whatsapp: validated.no_whatsapp,
          jenis_kelamin: validated.jenis_kelamin,
          alamat_lengkap: validated.alamat_lengkap,
          hubungan_wbp: validated.hubungan_wbp,
          foto_ktp_url: fotoKtpUrl,
          nama_wbp: validated.nama_wbp,
          blok_kamar_wbp: validated.blok_kamar_wbp,
          kategori_perkara: validated.kategori_perkara,
          tanggal_kunjungan: validated.tanggal_kunjungan,
          sesi_kunjungan: validated.sesi_kunjungan,
          jumlah_pengikut: validated.jumlah_pengikut,
          daftar_pengikut: validated.daftar_pengikut,
          membawa_titipan: validated.membawa_titipan,
          deskripsi_titipan: validated.deskripsi_titipan,
          status: 'MENUNGGU',
        },
      ])
      .select()
      .single();

    if (insertErr) throw new Error(insertErr.message);

    revalidatePath('/admin');
    return {
      success: true,
      kodeBooking: inserted.kode_booking,
      message: 'Pendaftaran berhasil dikonfirmasi!',
    };
  } catch (error: any) {
    return {
      success: false,
      message: error?.message || 'Terjadi kendala saat memproses pendaftaran.',
    };
  }
}

export async function updateStatusKunjungan(id: string, status: string, catatan = '') {
  const supabase = createServerSupabaseClient();
  const { error } = await supabase
    .from('pendaftaran_kunjungan')
    .update({
      status,
      catatan_petugas: catatan,
      waktu_verifikasi: new Date().toISOString(),
    })
    .eq('id', id);

  if (error) return { success: false, message: error.message };
  revalidatePath('/admin');
  return { success: true };
}

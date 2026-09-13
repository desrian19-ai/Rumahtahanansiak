import { NextResponse } from 'next/server';
import { createServerSupabaseClient } from '@/lib/supabase/server';

export async function GET() {
  const supabase = createServerSupabaseClient();
  const { data, error } = await supabase
    .from('pendaftaran_kunjungan')
    .select('*')
    .order('tanggal_kunjungan', { ascending: false });

  if (error || !data) {
    return NextResponse.json({ error: 'Gagal mengambil data pendaftaran' }, { status: 500 });
  }

  // Header CSV
  const headers = [
    'Kode Booking',
    'No Antrean',
    'Tanggal Kunjungan',
    'Sesi Kunjungan',
    'NIK Pengunjung',
    'Nama Pengunjung',
    'WhatsApp',
    'Hubungan',
    'Nama WBP',
    'Kategori Perkara',
    'Jumlah Pengikut',
    'Titipan Barang',
    'Status'
  ];

  const rows = data.map((item: any) => [
    item.kode_booking,
    item.nomor_antrean,
    item.tanggal_kunjungan,
    `"${item.sesi_kunjungan}"`,
    `'${item.nik_pengunjung}`,
    `"${item.nama_pengunjung}"`,
    `'${item.no_whatsapp}`,
    item.hubungan_wbp,
    `"${item.nama_wbp}"`,
    item.kategori_perkara,
    item.jumlah_pengikut,
    item.membawa_titipan ? 'Ya' : 'Tidak',
    item.status
  ]);

  const csvContent = [headers.join(','), ...rows.map((r: any) => r.join(','))].join('\n');

  return new NextResponse(csvContent, {
    headers: {
      'Content-Type': 'text/csv; charset=utf-8',
      'Content-Disposition': `attachment; filename="rekap_kunjungan_wbp_${new Date().toISOString().split('T')[0]}.csv"`,
    },
  });
}

import { NextRequest, NextResponse } from 'next/server';
import { createServerSupabaseClient } from '@/lib/supabase/server';

export async function GET(request: NextRequest) {
  const { searchParams } = new URL(request.url);
  const tgl = searchParams.get('tgl');
  const sesi = searchParams.get('sesi');

  if (!tgl || !sesi) {
    return NextResponse.json({ error: 'Parameter tgl dan sesi wajib ada' }, { status: 400 });
  }

  const supabase = createServerSupabaseClient();
  const { count, error } = await supabase
    .from('pendaftaran_kunjungan')
    .select('*', { count: 'exact', head: true })
    .eq('tanggal_kunjungan', tgl)
    .eq('sesi_kunjungan', sesi)
    .neq('status', 'BATAL');

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }

  const MAX_KUOTA = 60;
  const available = Math.max(0, MAX_KUOTA - (count || 0));

  return NextResponse.json({
    totalRegistered: count || 0,
    maxQuota: MAX_KUOTA,
    available,
  });
}

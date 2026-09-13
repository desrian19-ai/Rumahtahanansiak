import React from 'react';
import { createServerSupabaseClient } from '@/lib/supabase/server';
import { updateStatusKunjungan } from '@/app/actions/kunjungan';
import { 
  Users, CheckCircle2, XCircle, Clock, 
  FileSpreadsheet, Search, RefreshCw, Eye, ShieldCheck 
} from 'lucide-react';
import Link from 'next/link';

export const revalidate = 0; // Real-time data on every request

export default async function AdminDashboardPage() {
  const supabase = createServerSupabaseClient();
  const todayStr = new Date().toISOString().split('T')[0];

  const { data: antreanHariIni } = await supabase
    .from('pendaftaran_kunjungan')
    .select('*')
    .eq('tanggal_kunjungan', todayStr)
    .order('nomor_urut', { ascending: true });

  const total = antreanHariIni?.length || 0;
  const menunggu = antreanHariIni?.filter(q => q.status === 'MENUNGGU').length || 0;
  const disetujui = antreanHariIni?.filter(q => q.status === 'DISETUJUI').length || 0;
  const selesai = antreanHariIni?.filter(q => q.status === 'SELESAI').length || 0;

  return (
    <div className="min-h-screen bg-slate-950 text-slate-100 p-6 sm:p-10">
      <div className="max-w-7xl mx-auto space-y-8">

        {/* Top Header */}
        <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 border-b border-white/10 pb-6">
          <div className="flex items-center gap-3">
            <div className="w-12 h-12 rounded-2xl bg-amber-500/10 border border-amber-500/30 flex items-center justify-center text-amber-400">
              <ShieldCheck className="w-7 h-7" />
            </div>
            <div>
              <h1 className="text-2xl font-black text-white">PANEL KONTROL PETUGAS KUNJUNGAN</h1>
              <p className="text-xs text-slate-400 mt-0.5">Monitoring & Verifikasi Pendaftaran Kunjungan Hari Ini ({todayStr})</p>
            </div>
          </div>

          <div className="flex gap-2">
            <Link
              href="/api/export-kunjungan"
              className="px-4 py-2.5 bg-emerald-600 hover:bg-emerald-500 text-white rounded-xl text-xs font-bold flex items-center gap-2 shadow-lg transition"
            >
              <FileSpreadsheet className="w-4 h-4" /> Ekspor Data (CSV)
            </Link>
            <Link
              href="/daftar"
              className="px-4 py-2.5 bg-slate-800 hover:bg-slate-700 text-slate-200 rounded-xl text-xs font-bold border border-white/10 transition"
            >
              Form Publik
            </Link>
          </div>
        </div>

        {/* Statistik Bento Grid */}
        <div className="grid grid-cols-2 sm:grid-cols-4 gap-4">
          <div className="bg-slate-900 border border-white/10 p-5 rounded-2xl">
            <span className="text-xs font-mono text-slate-400">Total Terdaftar</span>
            <div className="text-3xl font-black text-white font-mono mt-1">{total}</div>
          </div>
          <div className="bg-slate-900 border border-amber-500/30 p-5 rounded-2xl">
            <span className="text-xs font-mono text-amber-400">Menunggu Verifikasi</span>
            <div className="text-3xl font-black text-amber-400 font-mono mt-1">{menunggu}</div>
          </div>
          <div className="bg-slate-900 border border-cyan-500/30 p-5 rounded-2xl">
            <span className="text-xs font-mono text-cyan-400">Disetujui / Hadir</span>
            <div className="text-3xl font-black text-cyan-400 font-mono mt-1">{disetujui}</div>
          </div>
          <div className="bg-slate-900 border border-emerald-500/30 p-5 rounded-2xl">
            <span className="text-xs font-mono text-emerald-400">Selesai Kunjungan</span>
            <div className="text-3xl font-black text-emerald-400 font-mono mt-1">{selesai}</div>
          </div>
        </div>

        {/* Tabel Antrean */}
        <div className="bg-slate-900 border border-white/10 rounded-3xl overflow-hidden shadow-2xl">
          <div className="p-6 border-b border-white/10 flex justify-between items-center">
            <h2 className="text-base font-bold text-white flex items-center gap-2">
              <Users className="w-5 h-5 text-amber-400" />
              Daftar Antrean Kunjungan Hari Ini
            </h2>
          </div>

          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs text-slate-300">
              <thead className="bg-slate-950 font-mono uppercase text-[11px] text-slate-400 border-b border-white/10">
                <tr>
                  <th className="p-4">No. Antrean</th>
                  <th className="p-4">Kode Booking</th>
                  <th className="p-4">Pengunjung Utama</th>
                  <th className="p-4">WBP Tujuan</th>
                  <th className="p-4">Kategori / Sesi</th>
                  <th className="p-4">Foto KTP</th>
                  <th className="p-4">Status</th>
                  <th className="p-4 text-center">Aksi Verifikasi</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-white/5">
                {antreanHariIni && antreanHariIni.length > 0 ? (
                  antreanHariIni.map((item) => (
                    <tr key={item.id} className="hover:bg-white/5 transition font-sans">
                      <td className="p-4 font-mono font-black text-amber-400 text-sm">{item.nomor_antrean}</td>
                      <td className="p-4 font-mono font-bold text-white">{item.kode_booking}</td>
                      <td className="p-4">
                        <div className="font-bold text-white">{item.nama_pengunjung}</div>
                        <div className="text-[11px] text-slate-400 font-mono">NIK: {item.nik_pengunjung} • WA: {item.no_whatsapp}</div>
                      </td>
                      <td className="p-4">
                        <div className="font-semibold text-slate-200">{item.nama_wbp}</div>
                        <div className="text-[10px] text-cyan-400">{item.blok_kamar_wbp || 'Blok Hunian'}</div>
                      </td>
                      <td className="p-4">
                        <span className="px-2 py-0.5 rounded text-[10px] font-bold bg-slate-800 text-amber-300">
                          {item.kategori_perkara}
                        </span>
                        <div className="text-[10px] text-slate-400 mt-0.5">{item.sesi_kunjungan}</div>
                      </td>
                      <td className="p-4">
                        {item.foto_ktp_url ? (
                          <a
                            href={item.foto_ktp_url}
                            target="_blank"
                            rel="noreferrer"
                            className="px-2.5 py-1 rounded bg-cyan-500/20 text-cyan-300 text-[10px] font-bold flex items-center gap-1 hover:bg-cyan-500/30 w-fit"
                          >
                            <Eye className="w-3 h-3" /> Lihat KTP
                          </a>
                        ) : (
                          <span className="text-[10px] text-slate-500">Fisik</span>
                        )}
                      </td>
                      <td className="p-4">
                        <span className={`px-2.5 py-1 rounded-full text-[10px] font-bold ${
                          item.status === 'MENUNGGU' ? 'bg-amber-500/20 text-amber-300 border border-amber-500/30' :
                          item.status === 'DISETUJUI' ? 'bg-cyan-500/20 text-cyan-300 border border-cyan-500/30' :
                          item.status === 'SELESAI' ? 'bg-emerald-500/20 text-emerald-300 border border-emerald-500/30' :
                          'bg-red-500/20 text-red-300 border border-red-500/30'
                        }`}>
                          {item.status}
                        </span>
                      </td>
                      <td className="p-4">
                        <div className="flex items-center justify-center gap-1.5">
                          {item.status === 'MENUNGGU' && (
                            <form action={async () => {
                              'use server';
                              await updateStatusKunjungan(item.id, 'DISETUJUI');
                            }}>
                              <button type="submit" className="p-2 bg-cyan-500/20 hover:bg-cyan-500 text-cyan-300 hover:text-slate-950 rounded-xl transition" title="Setujui / Check-in">
                                <CheckCircle2 className="w-4 h-4" />
                              </button>
                            </form>
                          )}
                          {item.status === 'DISETUJUI' && (
                            <form action={async () => {
                              'use server';
                              await updateStatusKunjungan(item.id, 'SELESAI');
                            }}>
                              <button type="submit" className="p-2 bg-emerald-500/20 hover:bg-emerald-500 text-emerald-300 hover:text-slate-950 rounded-xl transition" title="Selesai Berkunjung">
                                <CheckCircle2 className="w-4 h-4" />
                              </button>
                            </form>
                          )}
                          <form action={async () => {
                            'use server';
                            await updateStatusKunjungan(item.id, 'DITOLAK', 'Berkas tidak lengkap / Melanggar aturan');
                          }}>
                            <button type="submit" className="p-2 bg-red-500/20 hover:bg-red-500 text-red-300 hover:text-white rounded-xl transition" title="Tolak Pendaftaran">
                              <XCircle className="w-4 h-4" />
                            </button>
                          </form>
                        </div>
                      </td>
                    </tr>
                  ))
                ) : (
                  <tr>
                    <td colSpan={8} className="text-center p-8 text-slate-500">
                      Belum ada antrean kunjungan terdaftar untuk hari ini.
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </div>

      </div>
    </div>
  );
}

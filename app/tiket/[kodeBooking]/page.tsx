import React from 'react';
import { createServerSupabaseClient } from '@/lib/supabase/server';
import { notFound } from 'next/navigation';
import { QRCodeSVG } from 'qrcode.react';
import { Shield, Printer, ArrowLeft } from 'lucide-react';
import Link from 'next/link';

interface TicketPageProps {
  params: { kodeBooking: string };
}

export default async function TiketKunjunganPage({ params }: TicketPageProps) {
  const supabase = createServerSupabaseClient();

  const { data: ticket, error } = await supabase
    .from('pendaftaran_kunjungan')
    .select('*')
    .eq('kode_booking', params.kodeBooking)
    .single();

  if (error || !ticket) {
    notFound();
  }

  return (
    <div className="min-h-screen bg-slate-950 text-white py-12 px-4 flex flex-col items-center justify-center">
      
      {/* Kartu Tiket */}
      <div className="max-w-md w-full bg-slate-900 border border-white/10 rounded-3xl p-6 sm:p-8 shadow-2xl relative overflow-hidden print:bg-white print:text-black print:border-black print:shadow-none">
        
        {/* Header Tiket */}
        <div className="text-center border-b border-white/10 print:border-black/20 pb-6 mb-6">
          <div className="inline-flex p-2 bg-amber-500/10 rounded-xl text-amber-400 mb-2">
            <Shield className="w-8 h-8" />
          </div>
          <h2 className="text-xs font-mono font-bold tracking-widest text-amber-400 uppercase">
            RESI BUKTI KUNJUNGAN ONLINE
          </h2>
          <h1 className="text-lg font-black text-white print:text-black">
            LEMBAGA PEMASYARAKATAN / RUTAN
          </h1>
        </div>

        {/* Nomor Antrean & QR Code */}
        <div className="text-center bg-slate-950 print:bg-slate-100 rounded-2xl p-6 border border-white/5 print:border-black/10 mb-6">
          <span className="text-[11px] font-mono text-slate-400 uppercase tracking-wider block">
            Nomor Antrean Anda
          </span>
          <div className="text-5xl font-black text-amber-400 print:text-black font-mono my-2 tracking-wider">
            {ticket.nomor_antrean}
          </div>
          <div className="text-xs font-mono text-slate-400 print:text-slate-600">
            Kode Booking: <strong>{ticket.kode_booking}</strong>
          </div>

          <div className="mt-4 flex justify-center bg-white p-3 rounded-xl w-fit mx-auto shadow-md">
            <QRCodeSVG
              value={JSON.stringify({
                kode: ticket.kode_booking,
                nik: ticket.nik_pengunjung,
                wbp: ticket.nama_wbp,
                tgl: ticket.tanggal_kunjungan,
              })}
              size={130}
              level="H"
            />
          </div>
          <p className="text-[10px] text-slate-400 mt-2 font-mono">Pindai QR Code di Pintu Masuk Utama (P2U)</p>
        </div>

        {/* Ringkasan Data */}
        <div className="space-y-3 text-xs border-b border-white/10 print:border-black/20 pb-6 mb-6 font-mono">
          <div className="flex justify-between">
            <span className="text-slate-400">Pengunjung:</span>
            <span className="font-bold text-white print:text-black">{ticket.nama_pengunjung}</span>
          </div>
          <div className="flex justify-between">
            <span className="text-slate-400">NIK:</span>
            <span className="font-bold text-white print:text-black">{ticket.nik_pengunjung}</span>
          </div>
          <div className="flex justify-between">
            <span className="text-slate-400">WBP Dikunjungi:</span>
            <span className="font-bold text-amber-300 print:text-black">{ticket.nama_wbp}</span>
          </div>
          <div className="flex justify-between">
            <span className="text-slate-400">Waktu Layanan:</span>
            <span className="font-bold text-white print:text-black">{ticket.tanggal_kunjungan}</span>
          </div>
          <div className="flex justify-between">
            <span className="text-slate-400">Pengikut:</span>
            <span className="font-bold text-white print:text-black">{ticket.jumlah_pengikut} Orang</span>
          </div>
          <div className="flex justify-between">
            <span className="text-slate-400">Status:</span>
            <span className="px-2 py-0.5 rounded bg-emerald-500/20 text-emerald-300 font-bold border border-emerald-500/30">
              {ticket.status}
            </span>
          </div>
        </div>

        {/* Petunjuk Kedatangan */}
        <div className="text-[11px] text-slate-400 leading-relaxed mb-6 space-y-1">
          <p>⚠️ Harap hadir di Rutan/Lapas <strong>15 menit</strong> sebelum sesi kunjungan dimulai.</p>
          <p>⚠️ Wajib membawa e-KTP fisik asli seluruh anggota keluarga yang terdaftar.</p>
        </div>

        {/* Tombol Aksi */}
        <div className="flex gap-3 print:hidden">
          <Link
            href="/daftar"
            className="flex-1 px-4 py-3 bg-slate-800 hover:bg-slate-700 text-slate-200 rounded-xl font-bold text-xs flex items-center justify-center gap-1.5 transition"
          >
            <ArrowLeft className="w-4 h-4" /> Daftar Baru
          </Link>
          <button
            onClick={() => window.print()}
            className="flex-1 px-4 py-3 bg-amber-500 hover:bg-amber-400 text-slate-950 rounded-xl font-black text-xs flex items-center justify-center gap-1.5 transition shadow-lg shadow-amber-500/20"
          >
            <Printer className="w-4 h-4" /> Cetak Resi
          </button>
        </div>
      </div>
    </div>
  );
}

import Link from 'next/link';
import { ShieldCheck, Calendar, QrCode, FileText, UserCheck, ArrowRight, Clock, MapPin } from 'lucide-react';

export default function HomePage() {
  return (
    <div className="min-h-screen bg-slate-950 text-slate-100 flex flex-col justify-between">
      
      {/* Navbar */}
      <header className="border-b border-white/10 bg-slate-900/60 backdrop-blur-md sticky top-0 z-50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-16 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-amber-500/20 border border-amber-500/40 flex items-center justify-center text-amber-400">
              <ShieldCheck className="w-6 h-6" />
            </div>
            <div>
              <span className="font-black text-sm text-white tracking-tight block">KUNJUNGAN ONLINE WBP</span>
              <span className="text-[10px] text-slate-400 font-mono block">SISTEM INFORMASI PELAYANAN TERPADU</span>
            </div>
          </div>

          <div className="flex items-center gap-3">
            <Link
              href="/daftar"
              className="px-4 py-2 rounded-xl bg-amber-500 hover:bg-amber-400 text-slate-950 font-bold text-xs transition shadow-lg shadow-amber-500/20"
            >
              Daftar Kunjungan
            </Link>
            <Link
              href="/admin"
              className="px-4 py-2 rounded-xl bg-slate-800 hover:bg-slate-700 text-slate-300 font-semibold text-xs border border-white/10 transition"
            >
              Portal Petugas
            </Link>
          </div>
        </div>
      </header>

      {/* Hero Section */}
      <main className="max-w-5xl mx-auto px-4 py-16 sm:py-24 text-center">
        <div className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full bg-amber-500/10 border border-amber-500/30 text-amber-300 text-xs font-semibold mb-6">
          <Clock className="w-4 h-4" /> Waktu Layanan: Senin - Kamis | 09.00 - 11.00 WIB
        </div>

        <h1 className="text-4xl sm:text-6xl font-black text-white tracking-tight leading-tight max-w-4xl mx-auto">
          Pendaftaran Kunjungan Online <span className="text-transparent bg-clip-text bg-gradient-to-r from-amber-400 to-yellow-500">Warga Binaan</span> Lebih Cepat & Transparan
        </h1>

        <p className="mt-6 text-base sm:text-lg text-slate-400 max-w-2xl mx-auto leading-relaxed">
          Daftarkan kunjungan keluarga Anda secara online, pilih jadwal yang tersedia, dan dapatkan E-Tiket instan lengkap dengan QR Code verifikasi.
        </p>

        {/* CTA Buttons */}
        <div className="mt-10 flex flex-col sm:flex-row items-center justify-center gap-4">
          <Link
            href="/daftar"
            className="w-full sm:w-auto px-8 py-4 rounded-2xl bg-gradient-to-r from-amber-500 via-amber-600 to-yellow-500 hover:from-amber-400 hover:to-amber-500 text-slate-950 font-black text-sm uppercase tracking-wider shadow-2xl shadow-amber-500/30 transition-all flex items-center justify-center gap-2"
          >
            Mulai Pendaftaran Sekarang <ArrowRight className="w-4 h-4" />
          </Link>
        </div>

        {/* Feature Cards Grid */}
        <div className="mt-20 grid grid-cols-1 md:grid-cols-3 gap-6 text-left">
          <div className="p-6 rounded-3xl bg-slate-900/60 border border-white/10 hover:border-amber-500/30 transition">
            <div className="w-12 h-12 rounded-2xl bg-amber-500/10 text-amber-400 flex items-center justify-center mb-4">
              <Calendar className="w-6 h-6" />
            </div>
            <h3 className="text-lg font-bold text-white mb-2">Kuota & Jadwal Pasti</h3>
            <p className="text-xs text-slate-400 leading-relaxed">
              Melihat sisa kuota kunjungan secara real-time dan memilih tanggal yang sesuai dengan kategori perkara WBP.
            </p>
          </div>

          <div className="p-6 rounded-3xl bg-slate-900/60 border border-white/10 hover:border-cyan-500/30 transition">
            <div className="w-12 h-12 rounded-2xl bg-cyan-500/10 text-cyan-400 flex items-center justify-center mb-4">
              <QrCode className="w-6 h-6" />
            </div>
            <h3 className="text-lg font-bold text-white mb-2">E-Tiket & QR Code</h3>
            <p className="text-xs text-slate-400 leading-relaxed">
              Dapatkan nomor antrean digital dan QR Code resmi untuk pemindaian cepat di pintu masuk P2U.
            </p>
          </div>

          <div className="p-6 rounded-3xl bg-slate-900/60 border border-white/10 hover:border-emerald-500/30 transition">
            <div className="w-12 h-12 rounded-2xl bg-emerald-500/10 text-emerald-400 flex items-center justify-center mb-4">
              <UserCheck className="w-6 h-6" />
            </div>
            <h3 className="text-lg font-bold text-white mb-2">Bebas Pungli & Transparan</h3>
            <p className="text-xs text-slate-400 leading-relaxed">
              Seluruh alur pelayanan kunjungan terdata secara transparan, bebas biaya (GRATIS), dan terintegrasi ke database pusat.
            </p>
          </div>
        </div>
      </main>

      {/* Footer */}
      <footer className="border-t border-white/10 bg-slate-950 py-8 text-center text-xs text-slate-500">
        <p>© 2026 Sistem Informasi Pelayanan Kunjungan Online WBP. Kementerian Imigrasi dan Pemasyarakatan RI.</p>
      </footer>
    </div>
  );
}

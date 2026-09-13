'use client';

import React, { useState, useEffect } from 'react';
import { useForm, useFieldArray } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { FormKunjunganSchema, FormKunjunganInput } from '@/lib/validations/kunjungan';
import { submitPendaftaranKunjungan } from '@/app/actions/kunjungan';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { 
  User, Shield, Calendar, Users, Package, 
  AlertCircle, CheckCircle2, Loader2, Plus, Trash2, ShieldCheck, ArrowLeft 
} from 'lucide-react';

export default function PendaftaranKunjunganPage() {
  const router = useRouter();
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [sisaKuota, setSisaKuota] = useState<number | null>(60);
  const [serverError, setServerError] = useState<string | null>(null);

  const {
    register,
    handleSubmit,
    control,
    watch,
    setValue,
    formState: { errors },
  } = useForm<FormKunjunganInput>({
    resolver: zodResolver(FormKunjunganSchema),
    defaultValues: {
      jumlah_pengikut: 0,
      daftar_pengikut: [],
      membawa_titipan: false,
      kategori_perkara: 'PIDANA_UMUM',
      sesi_kunjungan: 'Sesi Pagi (09.00 - 11.00 WIB)',
      tanggal_kunjungan: new Date().toISOString().split('T')[0],
      persetujuan_tata_tertib: false,
    },
  });

  const { fields, append, remove } = useFieldArray({
    control,
    name: 'daftar_pengikut',
  });

  const watchTanggal = watch('tanggal_kunjungan');
  const watchSesi = watch('sesi_kunjungan');
  const watchBawaTitipan = watch('membawa_titipan');

  useEffect(() => {
    async function checkQuota() {
      if (!watchTanggal || !watchSesi) return;
      try {
        const res = await fetch(`/api/kuota?tgl=${watchTanggal}&sesi=${encodeURIComponent(watchSesi)}`);
        const data = await res.json();
        if (data.available !== undefined) {
          setSisaKuota(data.available);
        }
      } catch (err) {
        setSisaKuota(60);
      }
    }
    checkQuota();
  }, [watchTanggal, watchSesi]);

  const onSubmit = async (data: FormKunjunganInput) => {
    setIsSubmitting(true);
    setServerError(null);

    const formData = new FormData();
    Object.entries(data).forEach(([key, value]) => {
      if (key === 'daftar_pengikut') {
        formData.append(key, JSON.stringify(value));
      } else {
        formData.append(key, String(value));
      }
    });

    const fileInput = document.getElementById('foto_ktp') as HTMLInputElement;
    if (fileInput?.files?.[0]) {
      formData.append('foto_ktp', fileInput.files[0]);
    }

    const res = await submitPendaftaranKunjungan(formData);
    setIsSubmitting(false);

    if (res.success && res.kodeBooking) {
      router.push(`/tiket/${res.kodeBooking}`);
    } else {
      setServerError(res.message);
    }
  };

  return (
    <div className="min-h-screen bg-slate-950 text-slate-100 py-12 px-4 sm:px-6 lg:px-8">
      <div className="max-w-4xl mx-auto">
        
        {/* Nav Back */}
        <div className="mb-6">
          <Link href="/" className="inline-flex items-center gap-2 text-xs text-slate-400 hover:text-white transition">
            <ArrowLeft className="w-4 h-4" /> Kembali ke Halaman Utama
          </Link>
        </div>

        {/* Header Branding */}
        <div className="text-center mb-10">
          <div className="inline-flex p-3 bg-amber-500/10 border border-amber-500/30 rounded-2xl text-amber-400 mb-4 shadow-xl shadow-amber-500/10">
            <ShieldCheck className="w-10 h-10" />
          </div>
          <h1 className="text-3xl font-black tracking-tight text-white sm:text-4xl">
            PENDAFTARAN KUNJUNGAN ONLINE WBP
          </h1>
          <p className="mt-2 text-sm text-slate-400">
            Sistem Informasi Pelayanan Kunjungan Terpadu Lembaga Pemasyarakatan / Rumah Tahanan
          </p>
        </div>

        {serverError && (
          <div className="mb-6 p-4 rounded-2xl bg-red-500/10 border border-red-500/30 text-red-300 text-sm flex items-center gap-3">
            <AlertCircle className="w-5 h-5 shrink-0 text-red-400" />
            <span>{serverError}</span>
          </div>
        )}

        <form onSubmit={handleSubmit(onSubmit)} className="space-y-8">

          {/* 1. DATA PENGUNJUNG UTAMA */}
          <div className="bg-slate-900/80 border border-white/10 rounded-3xl p-6 sm:p-8 backdrop-blur-md shadow-2xl">
            <h2 className="text-lg font-bold text-white flex items-center gap-2 mb-6 border-b border-white/10 pb-4">
              <User className="text-amber-400 w-5 h-5" />
              1. Identitas Pengunjung Utama
            </h2>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-6 text-sm">
              <div>
                <label className="block font-semibold text-slate-300 mb-2">NIK Sesuai e-KTP (16 Digit) *</label>
                <input
                  {...register('nik_pengunjung')}
                  maxLength={16}
                  placeholder="Contoh: 140801xxxxxxxxxx"
                  className="w-full bg-slate-950 border border-white/10 focus:border-amber-400 rounded-xl px-4 py-3 text-white font-mono outline-none transition"
                />
                {errors.nik_pengunjung && <p className="text-xs text-red-400 mt-1">{errors.nik_pengunjung.message}</p>}
              </div>

              <div>
                <label className="block font-semibold text-slate-300 mb-2">Nama Lengkap Sesuai KTP *</label>
                <input
                  {...register('nama_pengunjung')}
                  placeholder="Nama lengkap pengunjung"
                  className="w-full bg-slate-950 border border-white/10 focus:border-amber-400 rounded-xl px-4 py-3 text-white outline-none transition"
                />
                {errors.nama_pengunjung && <p className="text-xs text-red-400 mt-1">{errors.nama_pengunjung.message}</p>}
              </div>

              <div>
                <label className="block font-semibold text-slate-300 mb-2">Nomor WhatsApp Aktif *</label>
                <input
                  {...register('no_whatsapp')}
                  placeholder="Contoh: 081234567890"
                  className="w-full bg-slate-950 border border-white/10 focus:border-amber-400 rounded-xl px-4 py-3 text-white font-mono outline-none transition"
                />
                {errors.no_whatsapp && <p className="text-xs text-red-400 mt-1">{errors.no_whatsapp.message}</p>}
              </div>

              <div>
                <label className="block font-semibold text-slate-300 mb-2">Jenis Kelamin *</label>
                <select
                  {...register('jenis_kelamin')}
                  className="w-full bg-slate-950 border border-white/10 focus:border-amber-400 rounded-xl px-4 py-3 text-white outline-none transition"
                >
                  <option value="L">Laki-laki</option>
                  <option value="P">Perempuan</option>
                </select>
              </div>

              <div>
                <label className="block font-semibold text-slate-300 mb-2">Hubungan Keluarga Sah *</label>
                <select
                  {...register('hubungan_wbp')}
                  className="w-full bg-slate-950 border border-white/10 focus:border-amber-400 rounded-xl px-4 py-3 text-white outline-none transition"
                >
                  <option value="ORANG_TUA">Orang Tua (Ayah / Ibu)</option>
                  <option value="SUAMI_ISTRI">Suami / Istri Sah</option>
                  <option value="ANAK_KANDUNG">Anak Kandung</option>
                  <option value="SAUDARA_KANDUNG">Saudara Kandung (Kakak / Adik)</option>
                  <option value="KUASA_HUKUM">Kuasa Hukum / Advokat</option>
                  <option value="KERABAT_LAIN">Kerabat Lainnya</option>
                </select>
              </div>

              <div>
                <label className="block font-semibold text-slate-300 mb-2">Upload Foto e-KTP Asli (Maks 2MB)</label>
                <input
                  type="file"
                  id="foto_ktp"
                  accept="image/png, image/jpeg, image/jpg"
                  className="w-full text-xs text-slate-400 file:mr-4 file:py-2.5 file:px-4 file:rounded-xl file:border-0 file:text-xs file:font-semibold file:bg-amber-500/20 file:text-amber-300 hover:file:bg-amber-500/30 cursor-pointer"
                />
              </div>

              <div className="md:col-span-2">
                <label className="block font-semibold text-slate-300 mb-2">Alamat Domisili Lengkap *</label>
                <textarea
                  {...register('alamat_lengkap')}
                  rows={2}
                  placeholder="Jalan, Kelurahan, Kecamatan, Kota/Kabupaten"
                  className="w-full bg-slate-950 border border-white/10 focus:border-amber-400 rounded-xl px-4 py-3 text-white outline-none transition"
                />
                {errors.alamat_lengkap && <p className="text-xs text-red-400 mt-1">{errors.alamat_lengkap.message}</p>}
              </div>
            </div>
          </div>

          {/* 2. DATA WARGA BINAAN */}
          <div className="bg-slate-900/80 border border-white/10 rounded-3xl p-6 sm:p-8 backdrop-blur-md shadow-2xl">
            <h2 className="text-lg font-bold text-white flex items-center gap-2 mb-6 border-b border-white/10 pb-4">
              <Shield className="text-cyan-400 w-5 h-5" />
              2. Data Warga Binaan Pemasyarakatan (WBP)
            </h2>

            <div className="grid grid-cols-1 md:grid-cols-3 gap-6 text-sm">
              <div className="md:col-span-2">
                <label className="block font-semibold text-slate-300 mb-2">Nama Warga Binaan *</label>
                <input
                  {...register('nama_wbp')}
                  placeholder="Contoh: Rahmat Hidayat bin Rusli"
                  className="w-full bg-slate-950 border border-white/10 focus:border-amber-400 rounded-xl px-4 py-3 text-white outline-none transition"
                />
                {errors.nama_wbp && <p className="text-xs text-red-400 mt-1">{errors.nama_wbp.message}</p>}
              </div>

              <div>
                <label className="block font-semibold text-slate-300 mb-2">Kategori Perkara *</label>
                <select
                  {...register('kategori_perkara')}
                  className="w-full bg-slate-950 border border-white/10 focus:border-amber-400 rounded-xl px-4 py-3 text-white outline-none transition"
                >
                  <option value="PIDANA_UMUM">Pidana Umum</option>
                  <option value="NARKOTIKA">Narkotika</option>
                  <option value="TIPIKOR">Korupsi / Tipikor</option>
                  <option value="TERORISME">Terorisme</option>
                  <option value="LAINNYA">Lainnya</option>
                </select>
              </div>
            </div>
          </div>

          {/* 3. WAKTU KUNJUNGAN & KUOTA */}
          <div className="bg-slate-900/80 border border-white/10 rounded-3xl p-6 sm:p-8 backdrop-blur-md shadow-2xl">
            <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 mb-6 border-b border-white/10 pb-4">
              <h2 className="text-lg font-bold text-white flex items-center gap-2">
                <Calendar className="text-emerald-400 w-5 h-5" />
                3. Waktu Kunjungan & Sisa Kuota
              </h2>
              <div className="px-3.5 py-1.5 rounded-full bg-emerald-500/10 border border-emerald-500/30 text-emerald-400 text-xs font-mono font-bold">
                Sisa Kuota: {sisaKuota !== null ? `${sisaKuota} / 60` : 'Memuat...'}
              </div>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-6 text-sm">
              <div>
                <label className="block font-semibold text-slate-300 mb-2">Tanggal Rencana Kunjungan *</label>
                <input
                  type="date"
                  {...register('tanggal_kunjungan')}
                  min={new Date().toISOString().split('T')[0]}
                  className="w-full bg-slate-950 border border-white/10 focus:border-amber-400 rounded-xl px-4 py-3 text-white font-mono outline-none transition"
                />
                {errors.tanggal_kunjungan && <p className="text-xs text-red-400 mt-1">{errors.tanggal_kunjungan.message}</p>}
              </div>

              <div>
                <label className="block font-semibold text-slate-300 mb-2">Pilihan Sesi Layanan *</label>
                <select
                  {...register('sesi_kunjungan')}
                  className="w-full bg-slate-950 border border-white/10 focus:border-amber-400 rounded-xl px-4 py-3 text-white outline-none transition"
                >
                  <option value="Sesi Pagi (09.00 - 11.00 WIB)">Sesi Pagi (09.00 - 11.00 WIB)</option>
                </select>
              </div>
            </div>
          </div>

          {/* 4. PENGIKUT & TITIPAN BARANG */}
          <div className="bg-slate-900/80 border border-white/10 rounded-3xl p-6 sm:p-8 backdrop-blur-md shadow-2xl">
            <div className="flex items-center justify-between mb-6 border-b border-white/10 pb-4">
              <h2 className="text-lg font-bold text-white flex items-center gap-2">
                <Users className="text-purple-400 w-5 h-5" />
                4. Pengikut Kunjungan (Maks. 3 Orang)
              </h2>
              {fields.length < 3 && (
                <button
                  type="button"
                  onClick={() => {
                    append({ nama: '', nik: '', hubungan: '' });
                    setValue('jumlah_pengikut', fields.length + 1);
                  }}
                  className="px-3 py-1.5 bg-purple-500/20 hover:bg-purple-500/30 text-purple-300 border border-purple-500/30 rounded-xl text-xs font-bold flex items-center gap-1.5 transition"
                >
                  <Plus className="w-4 h-4" /> Tambah Pengikut
                </button>
              )}
            </div>

            {fields.length === 0 ? (
              <p className="text-xs text-slate-500 italic">Tidak ada pengikut tambahan.</p>
            ) : (
              <div className="space-y-4 mb-6">
                {fields.map((item, index) => (
                  <div key={item.id} className="p-4 bg-slate-950 border border-white/5 rounded-2xl flex flex-col sm:flex-row gap-4 items-start sm:items-center">
                    <span className="font-mono text-xs text-purple-400 font-bold px-2 py-1 rounded bg-purple-500/10">#{index + 1}</span>
                    <input
                      {...register(`daftar_pengikut.${index}.nama` as const)}
                      placeholder="Nama lengkap pengikut"
                      className="flex-1 bg-slate-900 border border-white/10 rounded-xl px-3 py-2 text-xs text-white outline-none"
                    />
                    <input
                      {...register(`daftar_pengikut.${index}.nik` as const)}
                      maxLength={16}
                      placeholder="NIK (Opsional)"
                      className="w-full sm:w-44 bg-slate-900 border border-white/10 rounded-xl px-3 py-2 text-xs text-white font-mono outline-none"
                    />
                    <button
                      type="button"
                      onClick={() => {
                        remove(index);
                        setValue('jumlah_pengikut', fields.length - 1);
                      }}
                      className="text-red-400 hover:text-red-300 p-2"
                    >
                      <Trash2 className="w-4 h-4" />
                    </button>
                  </div>
                ))}
              </div>
            )}

            {/* Titipan Barang */}
            <div className="pt-6 border-t border-white/10">
              <label className="flex items-center gap-3 cursor-pointer">
                <input
                  type="checkbox"
                  {...register('membawa_titipan')}
                  className="w-4 h-4 rounded border-white/20 bg-slate-950 text-amber-500 focus:ring-0 cursor-pointer"
                />
                <span className="text-sm font-semibold text-white flex items-center gap-2">
                  <Package className="w-4 h-4 text-amber-400" />
                  Membawa Barang Titipan / Makanan untuk WBP
                </span>
              </label>

              {watchBawaTitipan && (
                <div className="mt-4">
                  <textarea
                    {...register('deskripsi_titipan')}
                    placeholder="Sebutkan rincian barang/makanan (Contoh: Nasi kotak 1 porsi, pakaian ganti 2 stel)"
                    rows={2}
                    className="w-full bg-slate-950 border border-white/10 focus:border-amber-400 rounded-xl px-4 py-3 text-xs text-white outline-none transition"
                  />
                </div>
              )}
            </div>
          </div>

          {/* 5. LEMBAR PERSETUJUAN */}
          <div className="p-6 rounded-3xl bg-amber-500/10 border border-amber-500/30">
            <label className="flex items-start gap-3 cursor-pointer">
              <input
                type="checkbox"
                {...register('persetujuan_tata_tertib')}
                className="mt-1 w-4 h-4 rounded border-amber-500/40 bg-slate-950 text-amber-500 focus:ring-0"
              />
              <span className="text-xs leading-relaxed text-amber-200">
                Saya menyatakan data yang diisi adalah benar, bersedia membawa fisik asli <strong>e-KTP</strong> saat berkunjung, mematuhi protokol keamanan bebas <strong>HALINAR (HP, Pungli, Narkoba)</strong>, dan menaati tata tertib berpakaian sopan.
              </span>
            </label>
            {errors.persetujuan_tata_tertib && (
              <p className="text-xs text-red-400 mt-2">{errors.persetujuan_tata_tertib.message}</p>
            )}
          </div>

          {/* Submit Button */}
          <button
            type="submit"
            disabled={isSubmitting || sisaKuota === 0}
            className="w-full bg-gradient-to-r from-amber-500 via-amber-600 to-yellow-500 hover:from-amber-400 hover:to-amber-500 text-slate-950 font-black py-4 rounded-2xl shadow-xl shadow-amber-500/20 text-sm uppercase tracking-wider transition-all transform active:scale-95 flex items-center justify-center gap-2 disabled:opacity-50"
          >
            {isSubmitting ? (
              <>
                <Loader2 className="w-5 h-5 animate-spin" /> Memproses Data...
              </>
            ) : (
              <>
                <CheckCircle2 className="w-5 h-5" /> Dapatkan E-Tiket Kunjungan
              </>
            )}
          </button>
        </form>
      </div>
    </div>
  );
}

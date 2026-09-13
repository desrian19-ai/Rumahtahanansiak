'use client';

import React, { useState } from 'react';
import { useRouter } from 'next/navigation';
import { Shield, Lock, User, AlertCircle, ArrowRight } from 'lucide-react';
import Link from 'next/link';

export default function AdminLoginPage() {
  const router = useRouter();
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState<string | null>(null);

  const handleLogin = (e: React.FormEvent) => {
    e.preventDefault();
    if (
      (username === 'admin.kunjungan' || username === 'superadmin') &&
      (password === 'rutansiak2026' || password === 'admin123')
    ) {
      router.push('/admin');
    } else {
      setError('Username atau password tidak cocok!');
    }
  };

  return (
    <div className="min-h-screen bg-slate-950 text-white flex items-center justify-center p-4">
      <div className="max-w-md w-full bg-slate-900/90 border border-white/10 rounded-3xl p-8 shadow-2xl backdrop-blur-md">
        
        <div className="text-center mb-8">
          <div className="inline-flex p-3 bg-amber-500/10 border border-amber-500/30 rounded-2xl text-amber-400 mb-3">
            <Shield className="w-8 h-8" />
          </div>
          <h1 className="text-xl font-black text-white">LOGIN PETUGAS & ADMIN</h1>
          <p className="text-xs text-slate-400 mt-1">Sistem Pelayanan Kunjungan Warga Binaan</p>
        </div>

        {error && (
          <div className="mb-6 p-3 rounded-xl bg-red-500/10 border border-red-500/30 text-red-300 text-xs flex items-center gap-2">
            <AlertCircle className="w-4 h-4 text-red-400 shrink-0" />
            <span>{error}</span>
          </div>
        )}

        <form onSubmit={handleLogin} className="space-y-4 text-xs">
          <div>
            <label className="block font-bold text-slate-300 mb-1.5 uppercase tracking-wider">Username Petugas</label>
            <div className="relative">
              <User className="w-4 h-4 text-slate-500 absolute left-3.5 top-3.5" />
              <input
                type="text"
                value={username}
                onChange={(e) => setUsername(e.target.value)}
                required
                placeholder="admin.kunjungan / superadmin"
                className="w-full pl-10 pr-3.5 py-3 bg-slate-950 border border-white/10 focus:border-amber-400 rounded-xl text-white outline-none font-mono"
              />
            </div>
          </div>

          <div>
            <label className="block font-bold text-slate-300 mb-1.5 uppercase tracking-wider">Password Kedinasan</label>
            <div className="relative">
              <Lock className="w-4 h-4 text-slate-500 absolute left-3.5 top-3.5" />
              <input
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
                placeholder="••••••••••••"
                className="w-full pl-10 pr-3.5 py-3 bg-slate-950 border border-white/10 focus:border-amber-400 rounded-xl text-white outline-none"
              />
            </div>
          </div>

          <button
            type="submit"
            className="w-full mt-2 bg-gradient-to-r from-amber-500 to-yellow-500 hover:from-amber-400 hover:to-yellow-400 text-slate-950 font-black py-3.5 rounded-xl uppercase tracking-wider shadow-lg transition flex items-center justify-center gap-2"
          >
            Masuk ke Panel Kontrol <ArrowRight className="w-4 h-4" />
          </button>
        </form>

        <div className="mt-6 pt-6 border-t border-white/10 text-center">
          <Link href="/" className="text-xs text-slate-500 hover:text-slate-300 transition">
            Kembali ke Beranda
          </Link>
        </div>
      </div>
    </div>
  );
}

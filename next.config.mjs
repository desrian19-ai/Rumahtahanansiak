/** @type {import('next').NextConfig} */
const nextConfig = {
  images: {
    remotePatterns: [
      {
        protocol: 'https',
        hostname: '**.supabase.co',
      },
    ],
  },
  async redirects() {
    return [
      {
        source: '/admin.html',
        destination: '/admin',
        permanent: true,
      },
      {
        source: '/index.html',
        destination: '/',
        permanent: true,
      },
      {
        source: '/daftar.html',
        destination: '/daftar',
        permanent: true,
      },
      {
        source: '/tiket.html',
        destination: '/tiket',
        permanent: true,
      },
      {
        source: '/antrian.html',
        destination: '/admin',
        permanent: true,
      },
      {
        source: '/berita.html',
        destination: '/',
        permanent: true,
      },
    ];
  },
};

export default nextConfig;


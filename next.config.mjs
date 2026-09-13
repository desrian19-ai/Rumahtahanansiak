/** @type {import('next').NextConfig} */
const nextConfig = {
  typescript: {
    ignoreBuildErrors: true,
  },
  eslint: {
    ignoreDuringBuilds: true,
  },
  images: {
    unoptimized: true,
    remotePatterns: [
      {
        protocol: 'https',
        hostname: '**.supabase.co',
      },
    ],
  },
  async rewrites() {
    return [
      {
        source: '/admin',
        destination: '/admin.html',
      },
      {
        source: '/antrian',
        destination: '/antrian.html',
      },
      {
        source: '/berita',
        destination: '/berita.html',
      },
    ];
  },
};

export default nextConfig;




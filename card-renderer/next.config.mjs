/** @type {import('next').NextConfig} */
const nextConfig = {
  experimental: {
    outputFileTracingIncludes: {
      '/api/generate-card': ['./assets/cards/templates/**/*'],
    },
  },
};

export default nextConfig;

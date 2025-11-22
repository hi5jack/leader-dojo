import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  reactStrictMode: true,
  output: "standalone",
  serverExternalPackages: ["bcryptjs"],
  typedRoutes: true,
};

export default nextConfig;

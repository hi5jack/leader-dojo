import { withAuth } from "next-auth/middleware";

export default withAuth({
  pages: {
    signIn: "/auth/signin",
  },
});

export const config = {
  matcher: [
    "/dashboard/:path*",
    "/projects/:path*",
    "/commitments/:path*",
    "/reflections/:path*",
    "/capture/:path*",
    "/api/secure/:path*",
  ],
};


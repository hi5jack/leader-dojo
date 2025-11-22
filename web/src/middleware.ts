import { withAuth } from "next-auth/middleware";

import { verifyMobileToken } from "@/lib/auth/tokens";

export default withAuth({
  pages: {
    signIn: "/auth/signin",
  },
  callbacks: {
    authorized: async ({ req, token }) => {
      if (token) {
        return true;
      }

      const authHeader = req.headers.get("authorization");
      if (authHeader?.startsWith("Bearer ")) {
        const bearer = authHeader.replace(/^Bearer\s+/i, "");
        const result = await verifyMobileToken(bearer);

        if (result?.userId) {
          return true;
        }
      }

      return false;
    },
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


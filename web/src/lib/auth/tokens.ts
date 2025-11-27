import { jwtVerify, SignJWT } from "jose";

import { env } from "@/lib/config/env";

const encoder = new TextEncoder();
const secretKey = encoder.encode(env.MOBILE_TOKEN_SECRET);

const DEFAULT_EXPIRATION = "30d";

export const generateMobileToken = async (
  userId: string,
  expiresIn: string = DEFAULT_EXPIRATION,
) => {
  return new SignJWT({
    type: "mobile",
  })
    .setProtectedHeader({ alg: "HS256" })
    .setIssuedAt()
    .setSubject(userId)
    .setExpirationTime(expiresIn)
    .sign(secretKey);
};

export const verifyMobileToken = async (token: string) => {
  try {
    const { payload } = await jwtVerify(token, secretKey, {
      algorithms: ["HS256"],
    });

    if (!payload.sub) {
      return null;
    }

    return {
      userId: payload.sub,
    };
  } catch {
    return null;
  }
};







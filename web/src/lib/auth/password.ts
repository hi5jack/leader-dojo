import bcrypt from "bcryptjs";

const WORK_FACTOR = 12;

export const hashPassword = async (password: string) => {
  return bcrypt.hash(password, WORK_FACTOR);
};

export const verifyPassword = async (
  password: string,
  hashedPassword: string,
) => {
  if (!hashedPassword) return false;
  return bcrypt.compare(password, hashedPassword);
};


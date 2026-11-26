import jwt from 'jsonwebtoken';

const getSecret = () => {
  const secret = process.env.JWT_SECRET;
  if (!secret || secret.length < 32) {
    throw new Error('JWT_SECRET wajib diisi dengan secret acak minimal 32 karakter.');
  }
  return secret;
};

export const assertJwtSecret = () => getSecret();

export const signToken = (payload) => jwt.sign(payload, getSecret(), { expiresIn: '1d' });

export const verifyToken = (token) => jwt.verify(token, getSecret());

import { verifyToken as verifyJwt } from '../utils/jwtHelper.js';

export const verifyToken = (req, res, next) => {
  const header = req.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : null;

  if (!token) {
    return res.status(401).json({ success: false, message: 'Token tidak ditemukan. Silakan login.' });
  }

  try {
    const payload = verifyJwt(token);
    req.user = { id: payload.id };
    next();
  } catch {
    return res.status(401).json({ success: false, message: 'Token tidak valid atau kedaluwarsa. Silakan login kembali.' });
  }
};

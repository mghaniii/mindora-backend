import jwt from 'jsonwebtoken';

// Dibaca saat fungsi dipanggil (bukan saat modul dimuat) agar tidak
// bergantung pada urutan evaluasi import terhadap dotenv.config().
const getSecret = () => process.env.JWT_SECRET || 'mindora_dev_secret';

export const signToken = (payload) => jwt.sign(payload, getSecret(), { expiresIn: '1d' });

export const verifyToken = (token) => jwt.verify(token, getSecret());

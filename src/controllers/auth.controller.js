import bcrypt from 'bcrypt';
import { findUserByEmail, findUserById, createUser } from '../models/user.model.js';
import { signToken } from '../utils/jwtHelper.js';
import { toUserDTO } from '../utils/userDto.js';

const EMAIL_PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const normalizeEmail = (email) => String(email || '').trim().toLowerCase();

export const register = async (req, res, next) => {
  try {
    const name = String(req.body?.name || '').trim().replace(/\s+/g, ' ');
    const email = normalizeEmail(req.body?.email);
    const password = String(req.body?.password || '');

    if (!name) {
      return res.status(400).json({ success: false, field: 'name', message: 'Nama lengkap wajib diisi.' });
    }
    if (!EMAIL_PATTERN.test(email)) {
      return res.status(400).json({ success: false, field: 'email', message: 'Format email tidak valid.' });
    }
    if (password.length < 8) {
      return res.status(400).json({ success: false, field: 'password', message: 'Password minimal 8 karakter.' });
    }

    const existing = await findUserByEmail(email);
    if (existing) {
      return res.status(409).json({ success: false, field: 'email', message: 'Email ini sudah terdaftar. Silakan masuk.' });
    }

    const passwordHash = await bcrypt.hash(password, 10);
    const userId = await createUser({ name, email, passwordHash });
    const user = await findUserById(userId);
    const token = signToken({ id: userId });

    return res.status(201).json({
      success: true,
      message: 'Registrasi berhasil!',
      token,
      user: toUserDTO(user),
    });
  } catch (error) {
    next(error);
  }
};

export const login = async (req, res, next) => {
  try {
    const email = normalizeEmail(req.body?.email);
    const password = String(req.body?.password || '');

    if (!email || !password) {
      return res.status(400).json({ success: false, message: 'Email dan password wajib diisi.' });
    }

    const user = await findUserByEmail(email);
    const isMatch = user ? await bcrypt.compare(password, user.password) : false;
    // Pesan sengaja sama untuk email tidak ada & password salah.
    if (!user || !isMatch) {
      return res.status(401).json({ success: false, message: 'Email atau password salah.' });
    }

    const token = signToken({ id: user.id });
    return res.status(200).json({
      success: true,
      message: 'Login berhasil!',
      token,
      user: toUserDTO(user),
    });
  } catch (error) {
    next(error);
  }
};

export const me = async (req, res, next) => {
  try {
    const user = await findUserById(req.user.id);
    if (!user) {
      return res.status(401).json({ success: false, message: 'Sesi tidak valid. Silakan login kembali.' });
    }
    return res.status(200).json({ success: true, user: toUserDTO(user) });
  } catch (error) {
    next(error);
  }
};

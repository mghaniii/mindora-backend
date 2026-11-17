export const notFound = (req, res) => {
  res.status(404).json({ success: false, message: `Endpoint tidak ditemukan: ${req.method} ${req.originalUrl}` });
};

export const errorHandler = (err, req, res, next) => {
  console.error('[Error]', err);
  const status = err.status || 500;
  res.status(status).json({
    success: false,
    message: status === 500 ? 'Terjadi kesalahan pada server.' : err.message,
  });
};

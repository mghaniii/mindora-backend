// Satu pintu konversi baris users -> bentuk yang diharapkan frontend.
// id wajib string (Rencana auth.md #4); password tidak pernah ikut keluar.
export const toUserDTO = (u) => ({
  id: String(u.id),
  name: u.name,
  email: u.email,
  kelas: u.kelas,
  hasCompletedDiagnostic: Boolean(u.has_completed_diagnostic),
});

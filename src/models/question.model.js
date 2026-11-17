import pool from '../config/database.js';

// MariaDB menyimpan kolom JSON sebagai LONGTEXT, jadi mysql2
// mengembalikannya sebagai string. Normalisasi ke objek/array JS.
const asJson = (value) => (typeof value === 'string' ? JSON.parse(value) : value);

const normalizeQuestionRow = (q) => ({
  ...q,
  options: asJson(q.options),
  steps: asJson(q.steps),
  final_result: asJson(q.final_result),
});

// Soal diagnostik aktif, urut berdasarkan nomor soal.
export const getQuestionsList = async () => {
  const [rows] = await pool.query(
    `SELECT id, no_soal, category, topik, pertanyaan, options, jawaban_benar,
            instruction, alert_message, steps_header, steps_badge, steps,
            final_result, hint, hint_tag
     FROM diagnostic_questions
     WHERE is_active = 1
     ORDER BY no_soal ASC`
  );
  return rows.map(normalizeQuestionRow);
};

// Satu transaksi: simpan hasil tes + seluruh jawaban, lalu perbarui streak
// belajar user (logika hari-berurutan dengan CASE agar tetap satu perintah UPDATE).
export const saveDiagnosticResult = async ({
  userId,
  totalQuestions,
  answeredCount,
  correctCount,
  score,
  statusLevel,
  totalTimeSpentSeconds,
  answerRows,
}) => {
  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();

    const [result] = await conn.query(
      `INSERT INTO diagnostic_history
         (user_id, total_questions, answered_count, correct_count, score, status_level, total_time_spent_seconds)
       VALUES (?, ?, ?, ?, ?, ?, ?)`,
      [userId, totalQuestions, answeredCount, correctCount, score, statusLevel, totalTimeSpentSeconds]
    );
    const diagnosticId = result.insertId;

    if (Array.isArray(answerRows) && answerRows.length > 0) {
      const values = answerRows.map((a) => [
        diagnosticId,
        a.questionId,
        a.selectedOption || null,
        a.isCorrect ? 1 : 0,
        a.isDoubtful ? 1 : 0,
      ]);
      await conn.query(
        `INSERT INTO user_diagnostic_answers
           (diagnostic_id, question_id, selected_option, is_correct, is_doubtful)
         VALUES ?`,
        [values]
      );
    }

    await conn.query(
      `UPDATE users SET
         streak_days = CASE
           WHEN last_activity_date = CURDATE() THEN streak_days
           WHEN last_activity_date = DATE_SUB(CURDATE(), INTERVAL 1 DAY) THEN streak_days + 1
           ELSE 1
         END,
         last_activity_date = CURDATE()
       WHERE id = ?`,
      [userId]
    );

    await conn.commit();
    return diagnosticId;
  } catch (error) {
    await conn.rollback();
    throw error;
  } finally {
    conn.release();
  }
};

import pool from '../config/database.js';
import { httpError, isDuplicateKeyError } from '../utils/activityValidation.js';

const asJson = (value) => (typeof value === 'string' ? JSON.parse(value) : value);

const normalizeQuestionRow = (q) => ({
  ...q,
  options: asJson(q.options),
  steps: asJson(q.steps),
  final_result: asJson(q.final_result),
});

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

export const toQuestionSnapshot = (question) => ({
  id: question.id,
  number: question.no_soal,
  category: question.category,
  topic: question.topik,
  questionText: question.pertanyaan,
  correctOption: question.jawaban_benar,
  stepsHeader: question.steps_header,
  stepsBadge: question.steps_badge,
  steps: question.steps,
  finalResult: question.final_result,
  hint: question.hint,
  hintTag: question.hint_tag,
});

export const findDiagnosticSubmission = async (userId, submissionId) => {
  const [rows] = await pool.query(
    'SELECT * FROM diagnostic_history WHERE user_id = ? AND submission_id = ? LIMIT 1',
    [userId, submissionId]
  );
  return rows[0] || null;
};

const findDiagnosticResult = async (connection, userId, submissionId) => {
  const [rows] = await connection.query(
    'SELECT * FROM diagnostic_history WHERE user_id = ? AND submission_id = ? LIMIT 1',
    [userId, submissionId]
  );
  return rows[0] || null;
};

const loadDiagnosticAnswers = async (connection, diagnosticId) => {
  const [answers] = await connection.query(
    `SELECT question_id, selected_option, is_correct, is_doubtful, question_snapshot
     FROM user_diagnostic_answers
     WHERE diagnostic_id = ?
     ORDER BY id ASC`,
    [diagnosticId]
  );

  const missingSnapshotIds = answers
    .filter((answer) => !answer.question_snapshot)
    .map((answer) => answer.question_id);
  const fallbackSnapshots = new Map();

  if (missingSnapshotIds.length > 0) {
    const [questions] = await connection.query(
      `SELECT id, no_soal, category, topik, pertanyaan, jawaban_benar,
              steps_header, steps_badge, steps, final_result, hint, hint_tag
       FROM diagnostic_questions
       WHERE id IN (${missingSnapshotIds.map(() => '?').join(',')})`,
      missingSnapshotIds
    );
    questions.map(normalizeQuestionRow).forEach((question) => {
      fallbackSnapshots.set(question.id, toQuestionSnapshot(question));
    });
  }

  return answers.map((answer) => ({
    questionId: Number(answer.question_id),
    selectedOption: answer.selected_option,
    isCorrect: Boolean(answer.is_correct),
    isDoubtful: Boolean(answer.is_doubtful),
    questionSnapshot: asJson(answer.question_snapshot) || fallbackSnapshots.get(answer.question_id) || null,
  }));
};

export const getDiagnosticResultDetails = async (result, database = pool) => {
  const answers = await loadDiagnosticAnswers(database, result.id);
  return { result, answers };
};

export const saveDiagnosticResult = async ({
  userId,
  submissionId,
  totalQuestions,
  answeredCount,
  correctCount,
  score,
  statusLevel,
  totalTimeSpentSeconds,
  answerRows,
}) => {
  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();

    const [users] = await connection.query('SELECT id FROM users WHERE id = ? LIMIT 1 FOR UPDATE', [userId]);
    if (users.length === 0) throw httpError(401, 'Sesi tidak valid. Silakan login kembali.');

    const existing = await findDiagnosticResult(connection, userId, submissionId);
    if (existing) {
      await connection.commit();
      return existing;
    }

    const [result] = await connection.query(
      `INSERT INTO diagnostic_history
         (user_id, submission_id, total_questions, answered_count, correct_count,
          score, status_level, total_time_spent_seconds)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
      [userId, submissionId, totalQuestions, answeredCount, correctCount,
        score, statusLevel, totalTimeSpentSeconds]
    );
    const diagnosticId = result.insertId;

    if (answerRows.length > 0) {
      await connection.query(
        `INSERT INTO user_diagnostic_answers
           (diagnostic_id, question_id, selected_option, is_correct, is_doubtful, question_snapshot)
         VALUES ?`,
        [answerRows.map((answer) => [
          diagnosticId,
          answer.questionId,
          answer.selectedOption,
          answer.isCorrect ? 1 : 0,
          answer.isDoubtful ? 1 : 0,
          JSON.stringify(answer.questionSnapshot),
        ])]
      );
    }

    await connection.query(
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

    const [savedRows] = await connection.query(
      'SELECT * FROM diagnostic_history WHERE id = ? LIMIT 1',
      [diagnosticId]
    );
    await connection.commit();
    return savedRows[0];
  } catch (error) {
    await connection.rollback();
    if (isDuplicateKeyError(error)) {
      const existing = await findDiagnosticResult(pool, userId, submissionId);
      if (existing) return existing;
    }
    throw error;
  } finally {
    connection.release();
  }
};

import pool from '../config/database.js';
import { httpError, isDuplicateKeyError, normalizeAnswers } from '../utils/activityValidation.js';

const asJson = (value) => {
  if (value === null || value === undefined) return null;
  return typeof value === 'string' ? JSON.parse(value) : value;
};

const findAttempt = async (connection, userId, submissionId) => {
  const [rows] = await connection.query(
    'SELECT * FROM user_quiz_attempts WHERE user_id = ? AND submission_id = ? LIMIT 1',
    [userId, submissionId]
  );
  return rows[0] || null;
};

const assertSameExercise = (attempt, exerciseId) => {
  if (attempt.exercise_id !== exerciseId) {
    throw httpError(409, 'submissionId sudah digunakan untuk latihan lain.');
  }
};

const toQuestionSnapshot = (question) => ({
  id: question.id,
  number: Number(question.question_no),
  text: question.text,
  points: Number(question.points),
  correctOption: question.correct_option,
});

const loadResult = async (connection, attempt) => {
  const [answers] = await connection.query(
    `SELECT question_id, selected_option, is_correct, is_doubtful, points_earned, question_snapshot
     FROM user_quiz_answers
     WHERE attempt_id = ?
     ORDER BY id ASC`,
    [attempt.id]
  );
  const missingSnapshotIds = answers
    .filter((answer) => !answer.question_snapshot)
    .map((answer) => answer.question_id);
  const fallbackSnapshots = new Map();

  if (missingSnapshotIds.length > 0) {
    const [questions] = await connection.query(
      `SELECT id, question_no, text, points, correct_option
       FROM quiz_questions
       WHERE id IN (${missingSnapshotIds.map(() => '?').join(',')})`,
      missingSnapshotIds
    );
    questions.forEach((question) => fallbackSnapshots.set(question.id, toQuestionSnapshot(question)));
  }

  return {
    attempt,
    answers: answers.map((answer) => ({
      questionId: answer.question_id,
      selectedOption: answer.selected_option,
      isCorrect: Boolean(answer.is_correct),
      isDoubtful: Boolean(answer.is_doubtful),
      pointsEarned: Number(answer.points_earned),
      questionSnapshot: asJson(answer.question_snapshot) || fallbackSnapshots.get(answer.question_id) || null,
    })),
  };
};

export const getExerciseQuiz = async (exerciseId) => {
  const [exercises] = await pool.query(
    `SELECT id, title, phase, duration_minutes, xp_reward, formula_title, formula_expression
     FROM exercises
     WHERE id = ? AND is_active = 1
     LIMIT 1`,
    [exerciseId]
  );
  const exercise = exercises[0];
  if (!exercise) return null;

  const [questions] = await pool.query(
    `SELECT id, difficulty, points, text, options, visual
     FROM quiz_questions
     WHERE exercise_id = ?
     ORDER BY question_no ASC`,
    [exerciseId]
  );
  if (questions.length === 0) return null;

  return {
    ...exercise,
    questions: questions.map((question) => ({
      ...question,
      options: asJson(question.options),
      visual: asJson(question.visual),
    })),
  };
};

export const submitExercise = async ({
  userId,
  exerciseId,
  submissionId,
  answers,
  timeSpentSeconds,
}) => {
  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();

    const [users] = await connection.query('SELECT id FROM users WHERE id = ? LIMIT 1 FOR UPDATE', [userId]);
    if (users.length === 0) throw httpError(401, 'Sesi tidak valid. Silakan login kembali.');

    const existing = await findAttempt(connection, userId, submissionId);
    if (existing) {
      assertSameExercise(existing, exerciseId);
      const result = await loadResult(connection, existing);
      await connection.commit();
      return result;
    }

    const [exercises] = await connection.query(
      `SELECT id, duration_minutes, xp_reward
       FROM exercises
       WHERE id = ? AND is_active = 1
       LIMIT 1`,
      [exerciseId]
    );
    const exercise = exercises[0];
    if (!exercise) throw httpError(404, 'Latihan tidak ditemukan atau belum tersedia.');

    const [questions] = await connection.query(
      `SELECT id, question_no, points, text, options, correct_option
       FROM quiz_questions
       WHERE exercise_id = ?
       ORDER BY question_no ASC`,
      [exerciseId]
    );
    if (questions.length === 0) throw httpError(404, 'Soal latihan belum tersedia.');

    const normalizedQuestions = questions.map((question) => ({
      ...question,
      options: asJson(question.options),
    }));
    const normalizedAnswers = normalizeAnswers(answers, normalizedQuestions);
    const totalQuestions = normalizedQuestions.length;
    const totalPoints = normalizedQuestions.reduce((sum, question) => sum + Number(question.points), 0);
    const answeredCount = normalizedAnswers.filter((answer) => answer.selectedOption !== null).length;

    const gradedAnswers = normalizedAnswers.map((answer) => {
      const isCorrect = answer.selectedOption !== null
        && answer.selectedOption === answer.question.correct_option;
      return {
        ...answer,
        isCorrect,
        pointsEarned: isCorrect ? Number(answer.question.points) : 0,
      };
    });
    const correctCount = gradedAnswers.filter((answer) => answer.isCorrect).length;
    const earnedPoints = gradedAnswers.reduce((sum, answer) => sum + answer.pointsEarned, 0);
    const accuracyPercent = Math.round((correctCount / totalQuestions) * 100);
    const xpEarned = Math.round(Number(exercise.xp_reward ?? 0) * correctCount / totalQuestions);
    const durationSeconds = Number(exercise.duration_minutes) * 60;
    const boundedTimeSpentSeconds = Math.min(timeSpentSeconds, durationSeconds);

    const [insertResult] = await connection.query(
      `INSERT INTO user_quiz_attempts
         (user_id, exercise_id, submission_id, status, total_questions, answered_count,
          correct_count, earned_points, total_points, accuracy_percent, xp_earned,
          time_spent_seconds, started_at, completed_at)
       VALUES (?, ?, ?, 'completed', ?, ?, ?, ?, ?, ?, ?, ?, NOW(), NOW())`,
      [userId, exerciseId, submissionId, totalQuestions, answeredCount, correctCount,
        earnedPoints, totalPoints, accuracyPercent, xpEarned, boundedTimeSpentSeconds]
    );
    const attemptId = insertResult.insertId;

    if (gradedAnswers.length > 0) {
      await connection.query(
        `INSERT INTO user_quiz_answers
           (attempt_id, question_id, selected_option, is_correct, is_doubtful, points_earned, question_snapshot)
         VALUES ?`,
        [gradedAnswers.map((answer) => [
          attemptId,
          answer.questionId,
          answer.selectedOption,
          answer.isCorrect ? 1 : 0,
          answer.isDoubtful ? 1 : 0,
          answer.pointsEarned,
          JSON.stringify(toQuestionSnapshot(answer.question)),
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

    const [attempts] = await connection.query(
      'SELECT * FROM user_quiz_attempts WHERE id = ? LIMIT 1',
      [attemptId]
    );
    const result = await loadResult(connection, attempts[0]);
    await connection.commit();
    return result;
  } catch (error) {
    await connection.rollback();
    if (isDuplicateKeyError(error)) {
      const existing = await findAttempt(pool, userId, submissionId);
      if (existing) {
        assertSameExercise(existing, exerciseId);
        return loadResult(pool, existing);
      }
    }
    throw error;
  } finally {
    connection.release();
  }
};

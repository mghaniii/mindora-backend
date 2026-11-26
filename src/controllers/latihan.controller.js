import { getExerciseQuiz, submitExercise } from '../models/exercise.model.js';
import { httpError, requireNonNegativeInteger, requireUuid } from '../utils/activityValidation.js';

const toQuizConfigDTO = (exercise) => ({
  id: exercise.id,
  title: exercise.title,
  phase: exercise.phase,
  durationSeconds: Number(exercise.duration_minutes) * 60,
  xpReward: exercise.xp_reward === null ? null : Number(exercise.xp_reward),
  formula: {
    title: exercise.formula_title,
    expression: exercise.formula_expression,
  },
  questions: exercise.questions.map((question) => ({
    id: question.id,
    difficulty: question.difficulty,
    points: Number(question.points),
    text: question.text,
    options: question.options,
    visual: question.visual,
  })),
});

const toQuizResultDTO = ({ attempt, answers }) => {
  return {
    attemptId: Number(attempt.id),
    submissionId: attempt.submission_id,
    exerciseId: attempt.exercise_id,
    totalQuestions: Number(attempt.total_questions),
    answeredCount: Number(attempt.answered_count),
    correctCount: Number(attempt.correct_count),
    earnedPoints: Number(attempt.earned_points),
    totalPoints: Number(attempt.total_points),
    accuracyPercent: Number(attempt.accuracy_percent),
    xpEarned: Number(attempt.xp_earned),
    timeSpentSeconds: Number(attempt.time_spent_seconds),
    completedAt: attempt.completed_at,
    review: answers.map((answer) => ({
      number: answer.questionSnapshot?.number ?? null,
      questionId: answer.questionId,
      text: answer.questionSnapshot?.text ?? null,
      points: answer.questionSnapshot?.points ?? 0,
      selectedOption: answer.selectedOption,
      correctOption: answer.questionSnapshot?.correctOption ?? null,
      isCorrect: answer.isCorrect,
      isDoubtful: answer.isDoubtful,
      pointsEarned: answer.pointsEarned,
    })),
  };
};

export const getLatihanQuiz = async (req, res, next) => {
  try {
    const exercise = await getExerciseQuiz(req.params.itemId);
    if (!exercise) throw httpError(404, 'Latihan tidak ditemukan atau belum tersedia.');
    return res.status(200).json({ success: true, data: toQuizConfigDTO(exercise) });
  } catch (error) {
    next(error);
  }
};

export const submitLatihanQuiz = async (req, res, next) => {
  try {
    const body = req.body || {};
    const submissionId = requireUuid(body.submissionId);
    const timeSpentSeconds = requireNonNegativeInteger(body.timeSpentSeconds, 'timeSpentSeconds');
    if (!Array.isArray(body.answers)) throw httpError(400, 'answers harus berupa array.');

    const result = await submitExercise({
      userId: req.user.id,
      exerciseId: req.params.itemId,
      submissionId,
      answers: body.answers,
      timeSpentSeconds,
    });
    return res.status(200).json({ success: true, data: toQuizResultDTO(result) });
  } catch (error) {
    next(error);
  }
};

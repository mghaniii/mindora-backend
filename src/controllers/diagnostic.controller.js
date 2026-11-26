import {
  findDiagnosticSubmission,
  getDiagnosticResultDetails,
  getQuestionsList,
  saveDiagnosticResult,
  toQuestionSnapshot,
} from '../models/question.model.js';
import {
  httpError,
  normalizeAnswers,
  requireNonNegativeInteger,
  requireUuid,
} from '../utils/activityValidation.js';

const MAX_DIAGNOSTIC_SECONDS = 600;

const toQuestionDTO = (question) => ({
  id: question.id,
  number: question.no_soal,
  category: question.category,
  topic: question.topik,
  questionText: question.pertanyaan,
  instruction: question.instruction,
  alertMessage: question.alert_message,
  options: question.options.map(({ id, label }) => ({ id, label })),
});

const toDiagnosticResultDTO = ({ result, answers }) => {
  const domainMap = new Map();
  const review = answers.map((answer) => {
    const snapshot = answer.questionSnapshot;
    if (snapshot) {
      const domain = domainMap.get(snapshot.category) || {
        name: snapshot.category,
        correct: 0,
        total: 0,
      };
      domain.total += 1;
      if (answer.isCorrect) domain.correct += 1;
      domainMap.set(snapshot.category, domain);
    }

    return {
      questionId: answer.questionId,
      number: snapshot?.number ?? null,
      category: snapshot?.category ?? null,
      questionText: snapshot?.questionText ?? null,
      selectedOption: answer.selectedOption,
      correctOption: snapshot?.correctOption ?? null,
      isCorrect: answer.isCorrect,
      isDoubtful: answer.isDoubtful,
      stepsHeader: snapshot?.stepsHeader ?? null,
      stepsBadge: snapshot?.stepsBadge ?? null,
      steps: snapshot?.steps ?? null,
      finalResult: snapshot?.finalResult ?? null,
      hint: snapshot?.hint ?? null,
      hintTag: snapshot?.hintTag ?? null,
    };
  });

  return {
    diagnosticId: Number(result.id),
    submissionId: result.submission_id,
    score: Number(result.score),
    statusLevel: result.status_level,
    totalCorrect: Number(result.correct_count),
    totalQuestions: Number(result.total_questions),
    answeredCount: Number(result.answered_count),
    totalTimeSpentSeconds: Number(result.total_time_spent_seconds),
    completedAt: result.created_at,
    domains: Array.from(domainMap.values()).map((domain) => ({
      ...domain,
      percent: Math.round((domain.correct / domain.total) * 100),
    })),
    review,
  };
};

const sendDiagnosticResult = async (res, result) => {
  const details = await getDiagnosticResultDetails(result);
  return res.status(200).json({
    success: true,
    message: 'Evaluasi diagnostik selesai!',
    data: toDiagnosticResultDTO(details),
  });
};

export const getDiagnosticQuestions = async (req, res, next) => {
  try {
    const questions = await getQuestionsList();
    return res.status(200).json({
      success: true,
      total: questions.length,
      data: questions.map(toQuestionDTO),
    });
  } catch (error) {
    next(error);
  }
};

const normalizeDiagnosticId = (value) => {
  if (typeof value === 'number' && Number.isSafeInteger(value) && value > 0) return value;
  if (typeof value === 'string' && /^[1-9]\d*$/.test(value)) {
    const numericValue = Number(value);
    if (Number.isSafeInteger(numericValue)) return numericValue;
  }
  throw httpError(400, 'questionId diagnostik tidak valid.');
};

export const submitDiagnostic = async (req, res, next) => {
  try {
    const body = req.body || {};
    const submissionId = requireUuid(body.submissionId);
    const existing = await findDiagnosticSubmission(req.user.id, submissionId);
    if (existing) return sendDiagnosticResult(res, existing);

    const requestedTime = requireNonNegativeInteger(
      body.totalTimeSpentSeconds,
      'totalTimeSpentSeconds'
    );
    const totalTimeSpentSeconds = Math.min(requestedTime, MAX_DIAGNOSTIC_SECONDS);

    const questions = await getQuestionsList();
    if (questions.length === 0) throw httpError(404, 'Soal diagnostik belum tersedia.');

    const normalizedAnswers = normalizeAnswers(body.answers, questions, normalizeDiagnosticId);
    const answeredCount = normalizedAnswers.filter((answer) => answer.selectedOption !== null).length;
    if (answeredCount === 0) throw httpError(400, 'Minimal satu soal harus dijawab.');

    const answerRows = normalizedAnswers.map((answer) => ({
      questionId: answer.questionId,
      selectedOption: answer.selectedOption,
      isCorrect: answer.selectedOption !== null
        && answer.selectedOption === answer.question.jawaban_benar,
      isDoubtful: answer.isDoubtful,
      questionSnapshot: toQuestionSnapshot(answer.question),
    }));
    const correctCount = answerRows.filter((answer) => answer.isCorrect).length;
    const score = Math.round((correctCount / questions.length) * 100);
    const statusLevel = score >= 80 ? 'Mandiri Mahir' : 'Perlu Pendampingan';

    const result = await saveDiagnosticResult({
      userId: req.user.id,
      submissionId,
      totalQuestions: questions.length,
      answeredCount,
      correctCount,
      score,
      statusLevel,
      totalTimeSpentSeconds,
      answerRows,
    });

    return sendDiagnosticResult(res, result);
  } catch (error) {
    next(error);
  }
};

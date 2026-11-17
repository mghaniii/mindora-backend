import { getQuestionsList, saveDiagnosticResult } from '../models/question.model.js';

// Bentuk soal mengikuti camelCase frontend (useDiagnosticLogic.js).
// id tetap numerik karena frontend mengirim questionId: Number(...).
const toQuestionDTO = (q) => ({
  id: q.id,
  number: q.no_soal,
  category: q.category,
  topic: q.topik,
  questionText: q.pertanyaan,
  instruction: q.instruction,
  alertMessage: q.alert_message,
  stepsHeader: q.steps_header,
  stepsBadge: q.steps_badge,
  steps: q.steps,
  finalResult: q.final_result,
  options: q.options,
  hint: q.hint,
  hintTag: q.hint_tag,
  correctOption: q.jawaban_benar,
});

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

export const submitDiagnostic = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { totalTimeSpentSeconds, answers } = req.body || {};

    if (!Array.isArray(answers) || answers.length === 0) {
      return res.status(400).json({ success: false, message: 'Payload jawaban tidak valid.' });
    }

    const questions = await getQuestionsList();
    if (questions.length === 0) {
      return res.status(404).json({ success: false, message: 'Soal diagnostik belum tersedia.' });
    }

    const correctMap = new Map(questions.map((q) => [q.id, q.jawaban_benar]));
    let correctCount = 0;

    const answerRows = answers.map((a) => {
      const questionId = Number(a.questionId);
      const correctOption = correctMap.get(questionId);
      const isCorrect = correctOption != null && a.selectedOption === correctOption;
      if (isCorrect) correctCount += 1;
      return {
        questionId,
        selectedOption: a.selectedOption || null,
        isCorrect,
        isDoubtful: Boolean(a.isDoubtful),
      };
    });

    const score = Math.round((correctCount / questions.length) * 100);
    const statusLevel = score >= 80 ? 'Mandiri Mahir' : 'Perlu Pendampingan';

    const diagnosticId = await saveDiagnosticResult({
      userId,
      totalQuestions: questions.length,
      answeredCount: answers.length,
      correctCount,
      score,
      statusLevel,
      totalTimeSpentSeconds: Number(totalTimeSpentSeconds || 0),
      answerRows,
    });

    return res.status(200).json({
      success: true,
      message: 'Evaluasi diagnostik selesai!',
      data: { diagnosticId, score, statusLevel, totalCorrect: correctCount },
    });
  } catch (error) {
    next(error);
  }
};

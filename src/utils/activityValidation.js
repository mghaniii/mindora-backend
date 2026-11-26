export const httpError = (status, message) => {
  const error = new Error(message);
  error.status = status;
  return error;
};

export const requireUuid = (value) => {
  if (typeof value !== 'string' || !/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(value)) {
    throw httpError(400, 'submissionId harus berupa UUID yang valid.');
  }
  return value.toLowerCase();
};

export const requireNonNegativeInteger = (value, field) => {
  if (typeof value !== 'number' || !Number.isSafeInteger(value) || value < 0) {
    throw httpError(400, `${field} harus berupa bilangan bulat nonnegatif.`);
  }
  return value;
};

export const normalizeDoubtful = (value) => {
  if (value === undefined || value === null || value === false || value === 0) return false;
  if (value === true || value === 1) return true;
  if (typeof value === 'string') {
    const normalized = value.trim().toLowerCase();
    if (['', '0', 'false', 'no', 'off'].includes(normalized)) return false;
    if (['1', 'true', 'yes', 'on'].includes(normalized)) return true;
  }
  throw httpError(400, 'isDoubtful harus bernilai boolean.');
};

export const normalizeStringId = (value) => {
  if (typeof value !== 'string' || value.length === 0) {
    throw httpError(400, 'questionId tidak valid.');
  }
  return value;
};

export const normalizeAnswers = (answers, questions, normalizeQuestionId = normalizeStringId) => {
  if (!Array.isArray(answers)) throw httpError(400, 'answers harus berupa array.');

  const questionMap = new Map(questions.map((question) => [normalizeQuestionId(question.id), question]));
  const seen = new Set();

  return answers.map((answer) => {
    if (!answer || typeof answer !== 'object' || Array.isArray(answer)) {
      throw httpError(400, 'Setiap jawaban harus berupa objek.');
    }

    const questionId = normalizeQuestionId(answer.questionId);
    const question = questionMap.get(questionId);
    if (!question) throw httpError(400, `questionId ${String(answer.questionId)} tidak dikenal.`);
    if (seen.has(questionId)) throw httpError(400, 'questionId tidak boleh duplikat.');
    seen.add(questionId);

    const selectedOption = answer.selectedOption;
    if (selectedOption !== null) {
      const validOption = Array.isArray(question.options)
        && question.options.some((option) => option?.id === selectedOption);
      if (!validOption) throw httpError(400, `Pilihan jawaban tidak valid untuk questionId ${String(answer.questionId)}.`);
    }

    return {
      questionId,
      question,
      selectedOption,
      isDoubtful: normalizeDoubtful(answer.isDoubtful),
    };
  });
};

export const isDuplicateKeyError = (error) =>
  error?.code === 'ER_DUPLICATE_ENTRY'
  || error?.code === 'ER_DUE_TO_ENTRY'
  || error?.code === 'ER_DUP_ENTRY';

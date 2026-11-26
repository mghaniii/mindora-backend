-- Non-destructive activity hardening migration for MariaDB 10.4 and MySQL 8.
-- Run with the target test/development database already selected.

SET @activity_hardening_sql = IF(
  (SELECT COUNT(*) FROM information_schema.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'user_quiz_answers'
     AND COLUMN_NAME = 'question_snapshot') = 0,
  'ALTER TABLE user_quiz_answers ADD COLUMN question_snapshot JSON NULL AFTER points_earned',
  'SELECT 1'
);
PREPARE activity_hardening_stmt FROM @activity_hardening_sql;
EXECUTE activity_hardening_stmt;
DEALLOCATE PREPARE activity_hardening_stmt;

SET @activity_hardening_sql = IF(
  (SELECT COUNT(*) FROM information_schema.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'user_diagnostic_answers'
     AND COLUMN_NAME = 'question_snapshot') = 0,
  'ALTER TABLE user_diagnostic_answers ADD COLUMN question_snapshot JSON NULL AFTER is_doubtful',
  'SELECT 1'
);
PREPARE activity_hardening_stmt FROM @activity_hardening_sql;
EXECUTE activity_hardening_stmt;
DEALLOCATE PREPARE activity_hardening_stmt;

SET @activity_hardening_sql = IF(
  (SELECT COUNT(*) FROM information_schema.TABLE_CONSTRAINTS
   WHERE CONSTRAINT_SCHEMA = DATABASE() AND TABLE_NAME = 'user_quiz_answers'
     AND CONSTRAINT_NAME = 'fk_uqa_question') = 0,
  'SELECT 1',
  'ALTER TABLE user_quiz_answers DROP FOREIGN KEY fk_uqa_question'
);
PREPARE activity_hardening_stmt FROM @activity_hardening_sql;
EXECUTE activity_hardening_stmt;
DEALLOCATE PREPARE activity_hardening_stmt;

SET @activity_hardening_sql = IF(
  (SELECT COUNT(*) FROM information_schema.TABLE_CONSTRAINTS
   WHERE CONSTRAINT_SCHEMA = DATABASE() AND TABLE_NAME = 'user_quiz_answers'
     AND CONSTRAINT_NAME = 'fk_uqa_question') = 0,
  'ALTER TABLE user_quiz_answers ADD CONSTRAINT fk_uqa_question FOREIGN KEY (question_id) REFERENCES quiz_questions (id) ON DELETE RESTRICT',
  'SELECT 1'
);
PREPARE activity_hardening_stmt FROM @activity_hardening_sql;
EXECUTE activity_hardening_stmt;
DEALLOCATE PREPARE activity_hardening_stmt;

SET @activity_hardening_sql = IF(
  (SELECT COUNT(*) FROM information_schema.TABLE_CONSTRAINTS
   WHERE CONSTRAINT_SCHEMA = DATABASE() AND TABLE_NAME = 'user_diagnostic_answers'
     AND CONSTRAINT_NAME = 'fk_uda_question') = 0,
  'SELECT 1',
  'ALTER TABLE user_diagnostic_answers DROP FOREIGN KEY fk_uda_question'
);
PREPARE activity_hardening_stmt FROM @activity_hardening_sql;
EXECUTE activity_hardening_stmt;
DEALLOCATE PREPARE activity_hardening_stmt;

SET @activity_hardening_sql = IF(
  (SELECT COUNT(*) FROM information_schema.TABLE_CONSTRAINTS
   WHERE CONSTRAINT_SCHEMA = DATABASE() AND TABLE_NAME = 'user_diagnostic_answers'
     AND CONSTRAINT_NAME = 'fk_uda_question') = 0,
  'ALTER TABLE user_diagnostic_answers ADD CONSTRAINT fk_uda_question FOREIGN KEY (question_id) REFERENCES diagnostic_questions (id) ON DELETE RESTRICT',
  'SELECT 1'
);
PREPARE activity_hardening_stmt FROM @activity_hardening_sql;
EXECUTE activity_hardening_stmt;
DEALLOCATE PREPARE activity_hardening_stmt;

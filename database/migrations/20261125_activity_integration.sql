-- Non-destructive migration for MariaDB 10.4 and MySQL 8.
-- Run with the target test/development database already selected.

SET @activity_migration_sql = IF(
  (SELECT COUNT(*) FROM information_schema.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'user_quiz_attempts'
     AND COLUMN_NAME = 'submission_id') = 0,
  'ALTER TABLE user_quiz_attempts ADD COLUMN submission_id VARCHAR(36) NULL AFTER exercise_id',
  'SELECT 1'
);
PREPARE activity_migration_stmt FROM @activity_migration_sql;
EXECUTE activity_migration_stmt;
DEALLOCATE PREPARE activity_migration_stmt;

SET @activity_migration_sql = IF(
  (SELECT COUNT(*) FROM information_schema.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'user_quiz_attempts'
     AND INDEX_NAME = 'uk_uqa_user_submission') = 0,
  'ALTER TABLE user_quiz_attempts ADD UNIQUE KEY uk_uqa_user_submission (user_id, submission_id)',
  'SELECT 1'
);
PREPARE activity_migration_stmt FROM @activity_migration_sql;
EXECUTE activity_migration_stmt;
DEALLOCATE PREPARE activity_migration_stmt;

SET @activity_migration_sql = IF(
  (SELECT COUNT(*) FROM information_schema.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'diagnostic_history'
     AND COLUMN_NAME = 'submission_id') = 0,
  'ALTER TABLE diagnostic_history ADD COLUMN submission_id VARCHAR(36) NULL AFTER user_id',
  'SELECT 1'
);
PREPARE activity_migration_stmt FROM @activity_migration_sql;
EXECUTE activity_migration_stmt;
DEALLOCATE PREPARE activity_migration_stmt;

SET @activity_migration_sql = IF(
  (SELECT COUNT(*) FROM information_schema.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'diagnostic_history'
     AND INDEX_NAME = 'uk_dh_user_submission') = 0,
  'ALTER TABLE diagnostic_history ADD UNIQUE KEY uk_dh_user_submission (user_id, submission_id)',
  'SELECT 1'
);
PREPARE activity_migration_stmt FROM @activity_migration_sql;
EXECUTE activity_migration_stmt;
DEALLOCATE PREPARE activity_migration_stmt;

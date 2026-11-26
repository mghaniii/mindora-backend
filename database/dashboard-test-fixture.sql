-- Fixture khusus database test dashboard; jangan dijalankan pada database produksi.
USE mindora_dashboard_test;

SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE user_diagnostic_answers;
TRUNCATE TABLE diagnostic_history;
TRUNCATE TABLE user_quiz_answers;
TRUNCATE TABLE user_quiz_attempts;
TRUNCATE TABLE user_material_progress;
TRUNCATE TABLE quiz_questions;
TRUNCATE TABLE exercises;
TRUNCATE TABLE materials;
TRUNCATE TABLE users;
SET FOREIGN_KEY_CHECKS = 1;

INSERT INTO users
  (id, name, email, password, kelas, streak_days, last_activity_date, daily_goal_target, daily_goal_minutes)
VALUES
  (1, 'Budi Pratama', 'budi@dashboard.test', 'test-hash', 'Kelas 2 SMA', 3, CURDATE(), 8, 20),
  (2, 'Budi Santoso', 'santoso@dashboard.test', 'test-hash', 'Kelas 2 SMA', 1, CURDATE(), 8, 20),
  (3, 'Dinda Ayu', 'dinda@dashboard.test', 'test-hash', 'Kelas 2 SMA', 2, CURDATE(), 8, 20),
  (4, 'Rina Larasati', 'rina@dashboard.test', 'test-hash', 'Kelas 3 SMA', 4, CURDATE(), 8, 20),
  (5, 'User Baru', 'baru@dashboard.test', 'test-hash', 'Kelas 2 SMA', 0, NULL, 8, 20);

INSERT INTO materials
  (id, title, category, category_filter, description, chapter, total_modules, sort_order)
VALUES
  ('mat-1', 'Bilangan Rasional', 'Bilangan Rasional', 'bilangan', 'Mengenal pecahan campuran.', 'Bab 4 • Bilangan Rasional', 6, 1),
  ('mat-2', 'Aljabar Dasar', 'Aljabar', 'aljabar', 'Mengenal variabel dan suku sejenis.', 'Bab 1 • Aljabar', 4, 2),
  ('mat-3', 'Geometri & Bangun Datar', 'Geometri', 'geometri', 'Menghitung luas dan keliling.', 'Bab 2 • Geometri', 5, 3),
  ('mat-4', 'Statistika & Data', 'Statistika', 'statistika', 'Membaca diagram dan rata-rata.', 'Bab 3 • Statistika', 4, 4);

INSERT INTO user_material_progress
  (user_id, material_id, status, progress_percentage, completed_subtopics, score, last_activity_at)
VALUES
  (1, 'mat-1', 'in_progress', 67, 4, NULL, NOW()),
  (1, 'mat-2', 'completed', 100, 4, 95, NOW() - INTERVAL 2 DAY),
  (2, 'mat-1', 'completed', 100, 6, 90, NOW() - INTERVAL 1 DAY),
  (2, 'mat-3', 'in_progress', 40, 2, NULL, NOW()),
  (4, 'mat-2', 'completed', 100, 4, 88, NOW() - INTERVAL 3 DAY);

INSERT INTO exercises
  (id, exercise_type, topic_slug, topic_label, title, questions_count, icon_type)
VALUES
  ('lat-1', 'latihan', 'pecahan', 'Pecahan Campuran', 'Latihan Pecahan', 4, 'book'),
  ('lat-2', 'latihan', 'aljabar', 'Aljabar Dasar', 'Latihan Aljabar', 4, 'book');

INSERT INTO user_quiz_attempts
  (user_id, exercise_id, status, total_questions, answered_count, correct_count,
   earned_points, total_points, accuracy_percent, xp_earned, time_spent_seconds,
   started_at, completed_at)
VALUES
  (1, 'lat-1', 'completed', 4, 4, 3, 30, 40, 75, 120, 600, NOW() - INTERVAL 12 MINUTE, NOW()),
  (1, 'lat-2', 'completed', 4, 4, 2, 20, 40, 50, 80, 300, NOW() - INTERVAL 1 DAY - INTERVAL 10 MINUTE, NOW() - INTERVAL 1 DAY),
  (1, 'lat-1', 'completed', 4, 4, 4, 40, 40, 100, 1000, 900, NOW() - INTERVAL 10 DAY, NOW() - INTERVAL 9 DAY),
  (2, 'lat-1', 'completed', 4, 4, 4, 40, 40, 100, 420, 480, NOW() - INTERVAL 15 MINUTE, NOW() - INTERVAL 10 MINUTE),
  (3, 'lat-2', 'completed', 4, 4, 3, 30, 40, 75, 300, 420, NOW() - INTERVAL 20 MINUTE, NOW() - INTERVAL 15 MINUTE),
  (4, 'lat-1', 'completed', 4, 4, 4, 40, 40, 100, 999, 600, NOW() - INTERVAL 30 MINUTE, NOW() - INTERVAL 25 MINUTE);

-- ============================================================
--  MINDORA — DATABASE SCHEMA (DDL)
--  Backend Mindora: Express.js + MySQL murni (mysql2/promise)
--
--  Cara pakai (XAMPP / phpMyAdmin):
--    1. Jalankan Apache & MySQL melalui XAMPP Control Panel
--    2. Buka phpMyAdmin -> tab Import -> pilih file ini, atau
--       jalankan lewat CLI:  mysql -u root -p < schema.sql
--
--  Catatan:
--    - Engine InnoDB (transaksi & foreign key), charset utf8mb4.
--    - Collation utf8mb4_unicode_ci agar kompatibel di XAMPP/MariaDB.
--      (MySQL 8 boleh diganti utf8mb4_0900_ai_ci)
--    - Semua nama tabel & kolom mengikuti kontrak Rencana backend.md,
--      kolom lain hanya-menambah (tidak mengubah yang sudah ada).
--    - File ini hanya DDL (struktur). Data demo ada di seed.sql.
-- ============================================================

CREATE DATABASE IF NOT EXISTS mindora_db
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE mindora_db;

SET FOREIGN_KEY_CHECKS = 0;

DROP VIEW IF EXISTS v_user_activities;
DROP TABLE IF EXISTS user_diagnostic_answers;
DROP TABLE IF EXISTS diagnostic_history;
DROP TABLE IF EXISTS diagnostic_questions;
DROP TABLE IF EXISTS user_quiz_answers;
DROP TABLE IF EXISTS user_quiz_attempts;
DROP TABLE IF EXISTS quiz_questions;
DROP TABLE IF EXISTS exercises;
DROP TABLE IF EXISTS user_material_progress;
DROP TABLE IF EXISTS materials;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS levels;

-- ============================================================
--  DOMAIN 1: AUTENTIKASI & PROFIL
-- ============================================================

-- Tabel lookup level (gamifikasi): menentukan level dari total XP siswa
CREATE TABLE levels (
  level   TINYINT UNSIGNED NOT NULL,                 -- 1, 2, 3, ...
  min_xp  INT UNSIGNED NOT NULL,                     -- XP minimum untuk level ini
  title   VARCHAR(60) NOT NULL,                      -- "Siswa Adaptif Mandiri"
  PRIMARY KEY (level)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabel users === KONTRAK Rencana backend.md ===
-- Kolom wajib: name, email, password, kelas, created_at
-- (avg bcrypt 60 char, VARCHAR(255) untuk antisipasi algoritma lain)
-- Catatan: kelas dibuat NULLABLE dengan default 'Kelas 2 SMA' karena
-- form Register frontend (saat ini) belum memiliki field kelas.
-- Saat INSERT, kolom kelas boleh DIHILANGKAN dari daftar kolom agar
-- defaultnya dipakai (INSERT eksplisit NULL akan menyimpan NULL).
CREATE TABLE users (
  id                 INT UNSIGNED NOT NULL AUTO_INCREMENT,
  name               VARCHAR(80) NOT NULL,
  email              VARCHAR(160) NOT NULL,
  password           VARCHAR(255) NOT NULL,          -- hash bcrypt
  kelas              VARCHAR(40) NULL DEFAULT 'Kelas 2 SMA',  -- sementara opsional: frontend belum punya field kelas
  avatar             VARCHAR(255) NULL,              -- URL foto profil (Header)
  streak_days        SMALLINT UNSIGNED NOT NULL DEFAULT 0,   -- streak belajar berurutan
  last_activity_date DATE NULL,                      -- tanggal aktivitas terakhir (perhitungan streak)
  daily_goal_target  TINYINT UNSIGNED NOT NULL DEFAULT 8,    -- target soal harian (LatihanDailyStats)
  daily_goal_minutes TINYINT UNSIGNED NOT NULL DEFAULT 20,   -- target menit belajar harian (WelcomeBanner)
  created_at         DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at         DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_users_email (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
--  DOMAIN 2: KONTEN PEMBELAJARAN (MATERI & LATIHAN)
-- ============================================================

-- Tabel materials === KONTRAK Rencana backend.md ===
-- Kolom wajib: id, title, category, total_modules
-- id berbentuk slug string ('mat-1') sesuai kebutuhan frontend
CREATE TABLE materials (
  id               VARCHAR(40) NOT NULL,             -- 'mat-1' ... 'mat-6'
  title            VARCHAR(120) NOT NULL,
  category         VARCHAR(60) NOT NULL,             -- label tampilan: "Bilangan Rasional"
  category_filter  ENUM('bilangan','aljabar','geometri','statistika') NOT NULL,
  description      TEXT NULL,
  chapter          VARCHAR(60) NULL,                 -- "Bab 4 • Bilangan Rasional" (continue-learning)
  total_modules    TINYINT UNSIGNED NOT NULL DEFAULT 4,   -- jumlah sub-bab
  exercises_count  SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  duration_minutes SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  xp_reward        SMALLINT UNSIGNED NOT NULL DEFAULT 0,  -- mis. 120 pada mat-3
  prerequisite_id  VARCHAR(40) NULL,                 -- materi prasyarat (self-referensi)
  required_level   TINYINT UNSIGNED NULL,            -- level minimum (status locked_level)
  sort_order       SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  created_at       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_materials_category_filter (category_filter),
  CONSTRAINT fk_materials_prereq
    FOREIGN KEY (prerequisite_id) REFERENCES materials (id)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabel user_material_progress === KONTRAK Rencana backend.md ===
-- Kolom wajib: user_id, material_id, progress_percentage, status DEFAULT 'ready'
CREATE TABLE user_material_progress (
  id                  INT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id             INT UNSIGNED NOT NULL,
  material_id         VARCHAR(40) NOT NULL,
  status              ENUM('ready','in_progress','completed','prerequisite_progress',
                           'locked_prerequisite','locked_level') NOT NULL DEFAULT 'ready',
  progress_percentage TINYINT UNSIGNED NOT NULL DEFAULT 0,   -- 0-100
  completed_subtopics TINYINT UNSIGNED NOT NULL DEFAULT 0,
  score               SMALLINT UNSIGNED NULL,        -- 95 -> tampilan "Skor: 95/100"
  last_activity_at    DATETIME NULL,
  created_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_ump_user_material (user_id, material_id),
  KEY idx_ump_user (user_id),
  CONSTRAINT fk_ump_user FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
  CONSTRAINT fk_ump_material FOREIGN KEY (material_id) REFERENCES materials (id) ON DELETE CASCADE,
  CONSTRAINT ck_ump_progress CHECK (progress_percentage BETWEEN 0 AND 100)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabel exercises: daftar latihan & kuis harian (halaman Latihan)
-- Topik disimpan langsung sebagai kolom (tidak pakai tabel topics)
-- agar query rekap penguasaan topik cukup GROUP BY topic_label
CREATE TABLE exercises (
  id                VARCHAR(40) NOT NULL,            -- 'lat-1'...'lat-4', 'kuis-harian'
  exercise_type     ENUM('latihan','kuis_harian') NOT NULL DEFAULT 'latihan',
  topic_slug        VARCHAR(40) NOT NULL,            -- 'matriks','komposisi','kalkulus','statistika'
  topic_label       VARCHAR(80) NOT NULL,            -- "Matriks & Sistem Persamaan Linier (SPLDV)"
  title             VARCHAR(140) NOT NULL,
  description       TEXT NULL,
  questions_count   SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  questions_label   VARCHAR(60) NULL,                -- "3 Soal Ulang" (kartu remediasi)
  duration_minutes  SMALLINT UNSIGNED NOT NULL DEFAULT 10,
  xp_reward         SMALLINT UNSIGNED NULL,          -- NULL = tanpa XP (kartu Remediasi)
  tag_label         VARCHAR(40) NULL,                -- "Remediasi"
  tag_variant       ENUM('danger','primary','secondary') NULL,
  icon_type         VARCHAR(40) NOT NULL DEFAULT 'matrix-grid',
  formula_title     VARCHAR(80) NULL,                -- "Rumus Determinan 2×2"
  formula_expression VARCHAR(120) NULL,              -- "det(M) = (a·d) - (b·c)"
  phase             VARCHAR(60) NOT NULL DEFAULT 'Fase F SMA • Matematika Wajib',
  is_active         TINYINT(1) NOT NULL DEFAULT 1,
  created_at        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_exercises_topic (topic_slug),
  KEY idx_exercises_type (exercise_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabel quiz_questions: bank soal untuk setiap exercises
-- options & visual bertipe JSON dengan key PERSIS bentuk frontend:
--   options: [{"id":"A","label":"2"}, ...]
--   visual : {"matrices":[{"label":"A","rows":[[2,3],[1,4]]}], "operator":"+"}
CREATE TABLE quiz_questions (
  id             VARCHAR(40) NOT NULL,               -- 'l1-1', 'kh-1' (unik di seluruh bank)
  exercise_id    VARCHAR(40) NOT NULL,
  question_no    SMALLINT UNSIGNED NOT NULL,         -- urutan soal di dalam exercise
  difficulty     ENUM('mudah','menengah','sulit') NOT NULL,
  points         SMALLINT UNSIGNED NOT NULL DEFAULT 5,  -- bobot 5 / 10 / 15
  text           TEXT NOT NULL,                      -- markup {x} ungu & ~x~ oranye dipertahankan
  options        JSON NOT NULL,
  correct_option CHAR(1) NOT NULL,                   -- 'A' - 'D'
  visual         JSON NULL,
  created_at     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_qq_exercise_no (exercise_id, question_no),
  KEY idx_qq_exercise (exercise_id),
  CONSTRAINT fk_qq_exercise
    FOREIGN KEY (exercise_id) REFERENCES exercises (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
--  DOMAIN 3: UPAHA & JAWABAN SISWA
-- ============================================================

-- Tabel user_quiz_attempts: satu baris = satu kali mengerjakan latihan/kuis
-- Sumber kebenaran untuk totalXp, leaderboard, akurasi, dan XP harian.
CREATE TABLE user_quiz_attempts (
  id               INT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id          INT UNSIGNED NOT NULL,
  exercise_id      VARCHAR(40) NOT NULL,
  status           ENUM('in_progress','completed') NOT NULL DEFAULT 'completed',
  total_questions  SMALLINT UNSIGNED NOT NULL,
  answered_count   SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  correct_count    SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  earned_points    SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  total_points     SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  accuracy_percent TINYINT UNSIGNED NOT NULL DEFAULT 0,   -- 0-100
  xp_earned        SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  time_spent_seconds INT UNSIGNED NOT NULL DEFAULT 0,
  started_at       DATETIME NULL,
  completed_at     DATETIME NULL,
  created_at       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_uqa_user_completed (user_id, completed_at),
  KEY idx_uqa_exercise (exercise_id, user_id),
  KEY idx_uqa_completed (completed_at),
  CONSTRAINT fk_uqa_user FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
  CONSTRAINT fk_uqa_exercise FOREIGN KEY (exercise_id) REFERENCES exercises (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabel user_quiz_answers: jawaban per soal dari sebuah attempt
-- (mendukung menu "Lihat Pembahasan" & perhitungan poin per soal)
CREATE TABLE user_quiz_answers (
  id              INT UNSIGNED NOT NULL AUTO_INCREMENT,
  attempt_id      INT UNSIGNED NOT NULL,
  question_id     VARCHAR(40) NOT NULL,
  selected_option CHAR(1) NULL,                      -- NULL = tidak dijawab
  is_correct      TINYINT(1) NOT NULL DEFAULT 0,
  is_doubtful     TINYINT(1) NOT NULL DEFAULT 0,     -- ditandai ragu-ragu
  points_earned   SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  UNIQUE KEY uk_uqa_attempt_question (attempt_id, question_id),
  KEY idx_uqa_question (question_id),
  CONSTRAINT fk_uqa_attempt
    FOREIGN KEY (attempt_id) REFERENCES user_quiz_attempts (id) ON DELETE CASCADE,
  CONSTRAINT fk_uqa_question
    FOREIGN KEY (question_id) REFERENCES quiz_questions (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
--  DOMAIN 4: TES DIAGNOSTIK
-- ============================================================

-- Tabel diagnostic_questions === KONTRAK Rencana backend.md ===
-- Kolom wajib: id, no_soal, topik, pertanyaan, options, jawaban_benar
-- id sengaja tetap NUMERIC (INT) karena frontend mengirim questionId: Number(...)
CREATE TABLE diagnostic_questions (
  id            INT UNSIGNED NOT NULL AUTO_INCREMENT,
  no_soal       SMALLINT UNSIGNED NOT NULL,          -- nomor urut soal ditampilkan ke siswa
  topik         VARCHAR(80) NOT NULL,                -- "ADAPTIF MATEMATIKA DASAR"
  category      VARCHAR(60) NOT NULL,                -- "PENJUMLAHAN"
  pertanyaan    TEXT NOT NULL,                       -- "27 + 35 = ...."
  options       JSON NOT NULL,                       -- [{"id":"A","label":"12","isCorrect":false}, ...]
  jawaban_benar CHAR(1) NOT NULL,                    -- 'A' - 'D'
  instruction   TEXT NULL,
  alert_message TEXT NULL,
  steps_header  VARCHAR(80) NULL,                    -- "CARA PENYELESAIAN BERSUSUN"
  steps_badge   VARCHAR(40) NULL,                    -- "Langkah demi Langkah"
  steps         JSON NULL,                           -- [{"step":1,"title":"...","formula":"...","description":"..."}]
  final_result  JSON NULL,                           -- {"equation":"27 + 35 = 62","correctOptionLabel":"..."}
  hint          TEXT NULL,
  hint_tag      VARCHAR(60) NULL,                    -- "Dekomposisi Nilai Tempat"
  is_active     TINYINT(1) NOT NULL DEFAULT 1,
  created_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_dq_no_soal (no_soal),
  KEY idx_dq_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabel diagnostic_history === KONTRAK Rencana backend.md ===
-- Kolom wajib: user_id, score, status_level, created_at
-- (INSERT di model: (user_id, score, status_level, created_at) VALUES (?, ?, ?, NOW()))
CREATE TABLE diagnostic_history (
  id                    INT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id               INT UNSIGNED NOT NULL,
  total_questions       SMALLINT UNSIGNED NOT NULL,
  answered_count        SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  correct_count         SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  score                 TINYINT UNSIGNED NOT NULL,   -- 0-100
  status_level          ENUM('Mandiri Mahir','Perlu Pendampingan') NOT NULL,
  total_time_spent_seconds INT UNSIGNED NOT NULL DEFAULT 0,
  created_at            DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_dh_user_created (user_id, created_at),
  CONSTRAINT fk_dh_user FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabel user_diagnostic_answers: jawaban tiap soal diagnostik dari sebuah tes
-- Bentuk mengikuti payload submit frontend: {questionId, selectedOption, isDoubtful}
CREATE TABLE user_diagnostic_answers (
  id             INT UNSIGNED NOT NULL AUTO_INCREMENT,
  diagnostic_id  INT UNSIGNED NOT NULL,              -- fk diagnostic_history
  question_id    INT UNSIGNED NOT NULL,
  selected_option CHAR(1) NULL,
  is_correct     TINYINT(1) NOT NULL DEFAULT 0,
  is_doubtful    TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  UNIQUE KEY uk_uda_diagnostic_question (diagnostic_id, question_id),
  KEY idx_uda_question (question_id),
  CONSTRAINT fk_uda_diagnostic
    FOREIGN KEY (diagnostic_id) REFERENCES diagnostic_history (id) ON DELETE CASCADE,
  CONSTRAINT fk_uda_question
    FOREIGN KEY (question_id) REFERENCES diagnostic_questions (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
--  VIEW: RIWAYAT AKTIVITAS (halaman Riwayat & Diagnostik)
-- ============================================================
--  Menggabungkan upaya latihan/kuis dengan riwayat tes diagnostik
--  menjadi satu daftar aktivitas terurut, sehingga endpoint
--  /diagnostic/activities cukup melakukan LIMIT/OFFSET tanpa
--  UNION di tiap pemanggilan.
--
--  Catatan: VIEW tidak memiliki index (berbeda dengan tabel),
--  namun data demo cukup kecil sehingga tetap cepat.
DROP VIEW IF EXISTS v_user_activities;
CREATE VIEW v_user_activities AS
SELECT
  a.id,
  a.user_id,
  CASE e.exercise_type
    WHEN 'kuis_harian'  THEN 'kuis-harian'
    WHEN 'latihan'      THEN 'latihan-mandiri'
  END AS icon_type,
  e.title,
  CONCAT(e.questions_count, ' Soal') AS subtitle,
  CASE e.exercise_type
    WHEN 'kuis_harian'  THEN 'Kuis Harian'
    WHEN 'latihan'      THEN 'Latihan Mandiri'
  END AS category,
  a.earned_points AS score_value,
  a.total_points  AS score_max,
  a.xp_earned,
  a.time_spent_seconds,
  a.completed_at AS finished_at,
  'quiz' AS source_type
FROM user_quiz_attempts a
JOIN exercises e ON e.id = a.exercise_id
WHERE a.status = 'completed'
UNION ALL
SELECT
  dh.id,
  dh.user_id,
  'tes-diagnostik' AS icon_type,
  'Tes Diagnostik Adaptif' AS title,
  CONCAT(dh.total_questions, ' Soal Pilihan Ganda') AS subtitle,
  'Tes Diagnostik' AS category,
  dh.score AS score_value,
  100 AS score_max,
  0 AS xp_earned,
  dh.total_time_spent_seconds,
  dh.created_at AS finished_at,
  'diagnostic' AS source_type
FROM diagnostic_history dh;

SET FOREIGN_KEY_CHECKS = 1;

-- ============================================================
--  RINGKASAN: 11 TABEL + 1 VIEW
--  levels, users, materials, user_material_progress, exercises,
--  quiz_questions, user_quiz_attempts, user_quiz_answers,
--  diagnostic_questions, diagnostic_history, user_diagnostic_answers,
--  v_user_activities (VIEW)
--
--  Langkah berikutnya (file terpisah):
--    seed.sql -> data demo (users, materi, soal, attempts)
-- ============================================================

# Rencana Database Mindora — Skema MySQL

Dokumen ini menjelaskan desain database backend Mindora yang diturunkan langsung dari kebutuhan data frontend. Database: **MySQL relasional** dengan driver `mysql2/promise` (raw SQL, tanpa ORM), sesuai [Rencana backend.md](../../Rencana%20backend.md). Struktur fisik diimplementasikan di [schema.sql](schema.sql); data demo menyusul di `seed.sql`.

---

## 1. Latar Belakang & Tujuan

Frontend sudah berjalan dengan **data contoh (mock)** di layer service (`src/features/*/services/*.js`). Agar backend bisa melayani semua endpoint **tanpa mengubah kode frontend**, skema database dirancang dengan memetakan setiap field mock data ke kolom, setiap endpoint ke query. Eksplorasi dilakukan pada: `services/api.js`, `dashboardService.js`, `diagnosticService.js`, `latihanService.js`, `materiService.js`, hook `useDiagnosticLogic.js` dan `useLatihanKuis.js`.

**Fakta kunci hasil eksplorasi:**

- Kontrak HTTP: base URL `http://localhost:8080/api`, otentikasi `Authorization: Bearer <token>`, **semua key respons camelCase**, **id konten berbentuk string** (`mat-1`, `lat-1`, `l1-1`).
- 8 endpoint GET sudah terkontrak (lihat §5). Dua payload submit sudah disiapkan frontend namun belum dikirim: **diagnostik** (`{completedAt, totalTimeSpentSeconds, totalQuestions, answers:[{questionId, selectedOption, isDoubtful}]}`) dan **kuis latihan** (hasil komputasi `useLatihanKuis`).
- Fitur auth & profil frontend belum dibuat (folder `features/auth` dan `features/profile` kosong), tetapi skema tetap menyediakan tabel `users` agar backend siap saat fitur itu dikerjakan.

---

## 2. Kontrak yang Wajib Dipertahankan

Dari Rencana backend.md (sudah diputuskan sebelumnya, skema ini **hanya menambah, bukan mengubah**):

| Tabel | Kolom wajib | Model query yang sudah ada |
|---|---|---|
| `users` | `name, email, password, kelas*, created_at` | `kelas` kini **opsional** (nullable + default) karena form register frontend belum ada field kelas — lihat [Rencana auth.md](../../Rencana%20auth.md) §2.4 |
| `materials` | `id, title, category, total_modules` | — |
| `user_material_progress` | `user_id, material_id, progress_percentage, status DEFAULT 'ready'` | `LEFT JOIN ... ON m.id = p.material_id AND p.user_id = ?` |
| `diagnostic_questions` | `id, no_soal, topik, pertanyaan, options, jawaban_benar` | `SELECT id, no_soal, topik, pertanyaan, options, jawaban_benar FROM diagnostic_questions ORDER BY no_soal ASC LIMIT 4` |
| `diagnostic_history` | `user_id, score, status_level, created_at` | `INSERT INTO diagnostic_history (user_id, score, status_level, created_at) VALUES (?, ?, ?, NOW())` |

Database name: `mindora_db`. Engine InnoDB, charset `utf8mb4`.

---

## 3. Keputusan Desain

### A. Primary Key: VARCHAR natural key untuk tabel konten

- `materials.id = 'mat-1'`, `exercises.id = 'lat-1' / 'kuis-harian'`, `quiz_questions.id = 'l1-1'` — **string langsung jadi PK**, cocok dengan bentuk id di frontend.
- **Pengecualian:** `diagnostic_questions.id` tetap **INT AUTO_INCREMENT** karena frontend mengirim `questionId: Number(...)` dan menerima id numerik.
- Tabel transaksional (`users`, `user_quiz_attempts`, dst.) memakai `INT AUTO_INCREMENT`.
- **Alasan:** seeding langsung `INSERT` dengan id eksplisit (jelas saat presentasi), tidak perlu lapisan translusi id, dan bentuk id identik dengan mock frontend.

### B. Penamaan: snake_case di database, camelCase di respons

- Kolom database memakai `snake_case` (konvensi SQL). Backend menyajikan `camelCase` agar sesuai kontrak frontend — dilakukan via `SELECT total_xp AS totalXp` atau util konversi di layer model (saat model ditulis).
- **Kolom JSON** (`options`, `visual`, `steps`, `final_result`) disimpan dengan **key persis bentuk frontend** (`id`, `label`, `rows`, `operator`, `isCorrect`) sehingga langsung pass-through tanpa konversi.

### C. Nilai Dihitung vs Disimpan

Prinsip: **upaya siswa (attempts & jawaban) adalah sumber kebenaran tunggal**; agregat dihitung ulang lewat query (`SUM`, `AVG`, `COUNT`) — sekaligus mendemonstrasikan fungsi agregat SQL pada presentasi.

| Nilai frontend | Sumber | Cara |
|---|---|---|
| `totalXp` (dashboard) | `user_quiz_attempts` | `SUM(xp_earned)` |
| Level & % menuju level berikutnya (Sidebar) | `levels` + total XP | `SELECT MAX(level) WHERE min_xp <= totalXp` |
| `completedModules` (dashboard) | `user_material_progress` | `SUM(completed_subtopics)` |
| Leaderboard `rank` + XP mingguan | `user_quiz_attempts` | `SUM(xp_earned)` filter `YEARWEEK(completed_at, 1)` + ranking |
| Daily stats (`targetCompleted`, `todayXp`) | `user_quiz_attempts` | `COUNT` / `SUM` attempt hari ini |
| Penguasaan topik (`topic-mastery`) | `user_quiz_attempts` ⋈ `exercises` | `AVG(accuracy_percent) GROUP BY topic_label` |
| Riwayat aktivitas (`activities`) | `v_user_activities` (VIEW) | `LIMIT/OFFSET` |
| `streakDays` | `users.streak_days` + `last_activity_date` | **disimpan**, diperbarui saat submit (logika hari-berurutan di backend) |
| `progress_percentage`, `status`, `completed_subtopics` materi | `user_material_progress` | **disimpan** (kontrak Rencana backend.md) |
| Target harian (`daily_goal_target`, `daily_goal_minutes`) | `users` | **disimpan** (per user, bisa diubah di pengaturan profil) |

### D. String Pre-Format Tetap di Frontend

Backend hanya mengirim nilai mentah (angka, `DATETIME`, enum). Frontend yang memformat tampilan:

| Frontend (format) | Backend (mentah) |
|---|---|
| `scoreLabel` `"90 / 100"` / `"8 dari 8 Soal"` | `earned_points`+`total_points` / `correct_count`+`total_questions` |
| `finishedAt` `"Kemarin, 14:20"` | `finished_at DATETIME` |
| `statusValue` `"75% (3/4 Sub-bab)"` | `progress_percentage`, `completed_subtopics`, `total_modules` |
| `initials`, `isCurrentUser`, `" (Kamu)"` | `name`, `id` |
| `categoryColor`, `tagColor`, `bannerBg`, `image` | `category_filter` (warna & gambar = aset lokal frontend) |
| `readiness` `"Sangat Siap"`, `phase` `"Fase F"` | `score` (mapping JS dari nilai) |
| `statusLabel` aktivitas (`Selesai`/`Tuntas`/`Sempurna`) | `correct_count`, `total_questions`, `score` (mapping JS) |

### E. VIEW untuk Riwayat Aktivitas

Daripada tabel log terpisah, `v_user_activities` menggabungkan (`UNION ALL`) `user_quiz_attempts` (status `completed`) dengan `diagnostic_history` menjadi satu daftar aktivitas dengan kolom `icon_type, title, subtitle, category, score_value, score_max, finished_at`. Endpoint cukup `ORDER BY finished_at DESC, id DESC LIMIT ? OFFSET ?`. Catatan trade-off: VIEW tidak memiliki index — data demo kecil, tetap cepat; jika volume membesar, ganti jadi tabel log + index komposit.

---

## 4. Struktur Tabel (11 tabel + 1 VIEW)

### Domain 1 — Autentikasi & Profil

**`levels`** — lookup level gamifikasi
| Kolom | Tipe | Keterangan |
|---|---|---|
| `level` | TINYINT UNSIGNED PK | 1, 2, 3, ... |
| `min_xp` | INT UNSIGNED | XP minimum |
| `title` | VARCHAR(60) | "Siswa Adaptif Mandiri" |

**`users`** — akun siswa (kontrak + kolom gamifikasi)
| Kolom | Tipe | Keterangan |
|---|---|---|
| `id` | INT AI PK | |
| `name`, `email` (UNIQUE), `password` (bcrypt) | VARCHAR | kontrak |
| `kelas` | VARCHAR(40) NULL, DEFAULT `'Kelas 2 SMA'` | sengaja longgar: form Register frontend belum punya field kelas (lihat [Rencana auth.md](../../Rencana%20auth.md) §2). Saat INSERT, kolom ini boleh dihilangkan agar defaultnya dipakai |
| `avatar` | VARCHAR(255) NULL | URL foto profil (Header) |
| `streak_days`, `last_activity_date` | SMALLINT / DATE | perhitungan streak berurutan |
| `daily_goal_target` (8), `daily_goal_minutes` (20) | TINYINT | target harian (WelcomeBanner & LatihanDailyStats) |
| `created_at`, `updated_at` | DATETIME | |

### Domain 2 — Konten Pembelajaran

**`materials`** — katalog materi (6 baris di frontend)
| Kolom | Tipe | Keterangan |
|---|---|---|
| `id` | VARCHAR(40) PK | 'mat-1' ... 'mat-6' |
| `title`, `category`, `total_modules` | | kontrak |
| `category_filter` | ENUM('bilangan','aljabar','geometri','statistika') | untuk tab filter |
| `description`, `chapter` | TEXT / VARCHAR(60) | chapter → "Bab 4 • Bilangan Rasional" |
| `exercises_count`, `duration_minutes`, `xp_reward` | SMALLINT | info kartu materi |
| `prerequisite_id` | VARCHAR(40) NULL, self-FK | materi prasyarat (locked_prerequisite) |
| `required_level` | TINYINT NULL | level minimum (locked_level) |
| `sort_order`, `created_at` | | urutan rekomendasi |

**`user_material_progress`** — progres materi per siswa
| Kolom | Tipe | Keterangan |
|---|---|---|
| `id` | INT AI PK | |
| `user_id` / `material_id` | FK | UNIQUE(user_id, material_id) |
| `status` | ENUM 6 nilai, DEFAULT 'ready' | 'in_progress','completed','prerequisite_progress','locked_prerequisite','locked_level' |
| `progress_percentage` | TINYINT 0–100 | CHECK 0–100 |
| `completed_subtopics`, `score`, `last_activity_at` | | |

**`exercises`** — daftar latihan & kuis harian
| Kolom | Tipe | Keterangan |
|---|---|---|
| `id` | VARCHAR(40) PK | 'lat-1'...'lat-4', 'kuis-harian' |
| `exercise_type` | ENUM('latihan','kuis_harian') | |
| `topic_slug`, `topic_label` | VARCHAR | topik sekaligus untuk GROUP BY penguasaan |
| `title`, `description`, `questions_count`, `questions_label` | | info kartu |
| `duration_minutes`, `xp_reward` (NULL) | | NULL = remedial tanpa XP |
| `tag_label`, `tag_variant` | | badge "Remediasi" |
| `icon_type`, `formula_title`, `formula_expression`, `phase`, `is_active` | | |

**`quiz_questions`** — bank soal latihan/kuis
| Kolom | Tipe | Keterangan |
|---|---|---|
| `id` | VARCHAR(40) PK | 'l1-1', 'kh-1' (unik lintas bank) |
| `exercise_id` | VARCHAR(40) FK | UNIQUE(exercise_id, question_no) |
| `difficulty` | ENUM('mudah','menengah','sulit') | |
| `points` | SMALLINT | bobot 5/10/15 |
| `text` | TEXT | markup `{x}` ungu & `~x~` oranye dipertahankan |
| `options` | JSON | `[{"id":"A","label":"2"}, ...]` |
| `correct_option` | CHAR(1) | 'A'–'D' |
| `visual` | JSON NULL | `{"matrices":[{"label":"A","rows":[[2,3],[1,4]]}],"operator":"+"}` |

### Domain 3 — Upaya & Jawaban Siswa

**`user_quiz_attempts`** — satu baris = satu kali mengerjakan latihan/kuis
| Kolom | Tipe | Keterangan |
|---|---|---|
| `id` | INT AI PK | |
| `user_id`, `exercise_id` | FK | |
| `status` | ENUM('in_progress','completed') | |
| `total_questions`, `answered_count`, `correct_count` | SMALLINT | |
| `earned_points`, `total_points`, `accuracy_percent`, `xp_earned` | | hasil komputasi submit |
| `time_spent_seconds`, `started_at`, `completed_at` | | |
| Index | | (user_id, completed_at), (exercise_id, user_id), (completed_at) |

**`user_quiz_answers`** — jawaban per soal (untuk menu pembahasan)
| Kolom | Tipe | Keterangan |
|---|---|---|
| `id` | INT AI PK | |
| `attempt_id`, `question_id` | FK | UNIQUE(attempt_id, question_id) |
| `selected_option` | CHAR(1) NULL | NULL = tidak dijawab |
| `is_correct`, `is_doubtful`, `points_earned` | | |

### Domain 4 — Tes Diagnostik

**`diagnostic_questions`** — soal diagnostik (id numerik)
| Kolom | Tipe | Keterangan |
|---|---|---|
| `id` | INT AI PK | numerik — frontend `Number(...)` |
| `no_soal` (UNIQUE), `topik`, `category`, `pertanyaan` | | kontrak + kategori soal |
| `options` | JSON | `[{"id":"A","label":"12","isCorrect":false}, ...]` |
| `jawaban_benar` | CHAR(1) | kontrak |
| `instruction`, `alert_message` | TEXT | teks panduan soal |
| `steps_header`, `steps_badge`, `steps` (JSON), `final_result` (JSON) | | tampilan "Cara Penyelesaian" |
| `hint`, `hint_tag`, `is_active` | | |

**`diagnostic_history`** — hasil tes diagnostik
| Kolom | Tipe | Keterangan |
|---|---|---|
| `id` | INT AI PK | |
| `user_id` | FK | |
| `total_questions`, `answered_count`, `correct_count` | SMALLINT | |
| `score` | TINYINT 0–100 | |
| `status_level` | ENUM('Mandiri Mahir','Perlu Pendampingan') | `score >= 80` → Mandiri Mahir |
| `total_time_spent_seconds`, `created_at` | | kontrak memakai `created_at` |

**`user_diagnostic_answers`** — jawaban tiap soal diagnostik
| Kolom | Tipe | Keterangan |
|---|---|---|
| `id` | INT AI PK | |
| `diagnostic_id`, `question_id` (INT) | FK | UNIQUE(diagnostic_id, question_id) |
| `selected_option`, `is_correct`, `is_doubtful` | | bentuk mengikuti payload submit frontend |

**`v_user_activities`** (VIEW) — lihat §3E.

### Diagram Relasi

```
users 1──N user_material_progress N──1 materials N──1 materials (prerequisite_id)
users 1──N user_quiz_attempts   N──1 exercises
user_quiz_attempts 1──N user_quiz_answers N──1 quiz_questions N──1 exercises
users 1──N diagnostic_history 1──N user_diagnostic_answers N──1 diagnostic_questions
levels (lookup level ← total XP users)
v_user_activities = user_quiz_attempts ∪ diagnostic_history
```

---

## 5. Pemetaan Endpoint → Tabel

| Endpoint | Sumber | Strategi query |
|---|---|---|
| `POST /auth/register`, `POST /auth/login` | `users` (register) + `diagnostic_history` (login) | sesuai Rencana backend.md (bcrypt, JWT `{id}` 1d). Detail kontrak respons yang disesuaikan dengan frontend ada di [Rencana auth.md](../../Rencana%20auth.md): register tanpa `kelas`, respons berisi `hasCompletedDiagnostic` dan `id` string |
| `GET /dashboard/summary` | `users` + subquery agregat | `name, streak_days, daily_goal_minutes AS totalTargetMinutes`, `spentMinutes` (SUM menit hari ini), `totalXp`, `completedModules`, `currentTopic` (materi `in_progress` terakhir). `targetPercentage` dihitung di backend |
| `GET /dashboard/continue-learning` | `user_material_progress` ⋈ `materials` | `WHERE status='in_progress' ORDER BY last_activity_at DESC LIMIT 1` → `chapter, title, completedSubtopics, totalSubtopics=total_modules, progressPercentage` |
| `GET /dashboard/recommendations` | `materials` LEFT JOIN progress | belum `completed`, `ORDER BY sort_order LIMIT 3` |
| `GET /dashboard/leaderboard` | `users` ⋈ `user_quiz_attempts` | `SUM(xp_earned)` filter `YEARWEEK(completed_at,1)`, `ROW_NUMBER() OVER (ORDER BY xp DESC)` (MySQL 8; alternatif 5.7: rank di JS) |
| `GET /diagnostic/questions` | `diagnostic_questions` | `WHERE is_active=1 ORDER BY no_soal LIMIT 4` (kontrak) |
| `POST /diagnostic/submit` | `diagnostic_history` + `user_diagnostic_answers` + `users` | hitung skor di controller (kontrak), INSERT history + jawaban, perbarui `streak_days`/`last_activity_date` |
| `GET /diagnostic/summary` | `diagnostic_history` + `AVG(accuracy_percent) GROUP BY topic_label` | attempt terbaru → `score, statusLevel, createdAt`; kekuatan/kelemahan = topik dengan rata-rata MAX/MIN; `readiness`/`phase` mapping JS |
| `GET /diagnostic/topic-mastery` | `user_quiz_attempts` ⋈ `exercises` | `AVG(accuracy_percent) GROUP BY topic_label`, `CASE WHEN >=90 THEN 'Tuntas Mahir' WHEN >=80 THEN 'Baik' ELSE 'Perlu Ditingkatkan' END`; `standard`/`semester`/`calibratedNote` konstanta backend |
| `GET /diagnostic/activities?page&category` | `v_user_activities` | filter `category`, `ORDER BY finished_at DESC, id DESC LIMIT 4 OFFSET ?`, `total` dari `COUNT(*)` |
| `GET /latihan/:itemId/kuis` | `exercises` ⋈ `quiz_questions` | rakit di JS: `{id: id, durationSeconds: duration_minutes*60, formula:{title,expression}, questions:[...]}` |
| `POST /latihan/:itemId/kuis/submit` *(mendatang)* | `user_quiz_attempts` + `user_quiz_answers` + `users` | mirror hasil `useLatihanKuis` (correctCount, earnedPoints, accuracyPercent, xpEarned); saat aktif, penilaian `correct_option` dipindahkan ke backend |
| `GET /materials` | `materials` LEFT JOIN progress | sesuai Rencana backend.md (`COALESCE(p.progress_percentage, 0) AS progress, COALESCE(p.status,'ready')`) |

**Catatan keamanan:** endpoint `GET /latihan/:itemId/kuis` sengaja mengikutkan `correct_option` karena frontend masih menilai client-side (desain `useLatihanKuis` saat ini). Saat endpoint submit aktif, penilaian dipindah ke backend.

---

## 6. Rencana Data Demo (`seed.sql`, menyusul)

Untuk demo presentasi, data dirancang **konsisten secara internal** (mock frontend sebenarnya saling bertabrakan — mock dashboard `totalXp 420` vs Sidebar `Level 3` vs leaderboard `1620/1450/1380`; seed memilih rangkaian yang rapi):

- **`levels`**: (1,0,'Pemula Penasaran'), (2,200,'Pelajar Konsisten'), (3,500,'Siswa Adaptif Mandiri'), (4,900,'Explorer Andal'), (5,1400,'Master Matematika').
- **`users`**: Budi Pratama (`budi@mindora.com`, 'Kelas 2 SMA') sebagai user utama + 4 teman kelas (Budi Santoso, Dinda Ayu, Eka Putra, Rizki Ramadhan).
- **`materials`** (6): persis `KATALOG_MATERI` — mat-1 `in_progress` 75% (3/4 sub-bab), mat-2 `completed` 100% skor 95, mat-3 `ready` (+120 XP), mat-4 `prerequisite_progress`, mat-5 `locked_prerequisite` (prerequisite mat-3), mat-6 `locked_level` 4.
- **`exercises`** (5): lat-1...lat-4 + `kuis-harian` dengan durasi, XP (NULL di lat-4 remedial), tag, formula, icon.
- **`quiz_questions`** (32): distribusi 6/8/5/3/10 soal; **total poin kuis harian = 100** agar `scoreLabel "90 / 100"` terbentuk natural dari `earned_points/total_points`.
- **`diagnostic_questions`** (4): soal mock lengkap (options dengan `isCorrect`, steps, final_result, hint).
- **`user_quiz_attempts`**: total XP Budi ≈ **760** → Level 3, (760−500)/(900−500) = **65% menuju Level 4** (cocok dengan Sidebar yang masih hardcode). XP minggu berjalan: Santoso 420 > Budi 350 > Dinda 300 → urutan leaderboard.
- **`diagnostic_history`**: Budi 92 (terbaru), 85, 78, 81, 65.
- Waktu memakai `NOW() - INTERVAL n DAY` agar label relatif frontend ("Kemarin", "2 hari lalu") selalu segar saat demo.

---

## 7. Poin-Poin untuk Presentasi

1. **Raw SQL terlihat langsung** — `LEFT JOIN`, `COALESCE`, `CASE`, `SUM/AVG/COUNT`, `YEARWEEK`, `LIMIT ... OFFSET` tertulis di file model, membuktikan penguasaan database relasional tanpa tertutup ORM.
2. **Normalisasi sebagai dasar** — tabel upaya & jawaban adalah sumber kebenaran; denormalisasi sengaja hanya pada `users.streak_days` dan `user_material_progress` dengan alasan kontrak/performa.
3. **JSON column** hanya untuk payload tampilan semi-terstruktur (soal matriks, langkah penyelesaian) — alternatif normalisasi (tabel anak `diagnostic_steps`) disebut sebagai pertimbangan.
4. **VIEW `v_user_activities`** mendemonstrasikan `UNION ALL` untuk menyatukan dua sumber aktivitas.
5. **Kontrak backend tetap** — semua nama tabel/kolom dari Rencana backend.md dipertahankan; skema murni ekstensi kolom.

---

## 8. Cara Import & Verifikasi

1. Jalankan MySQL (XAMPP Control Panel → Start MySQL).
2. Import [schema.sql](schema.sql): phpMyAdmin → tab **Import** → pilih file → **Go**; atau CLI `mysql -u root -p < schema.sql`.
3. Verifikasi struktur:
   ```sql
   USE mindora_db;
   SHOW FULL TABLES;                        -- 11 tabel + v_user_activities (VIEW)
   DESCRIBE quiz_questions;                 -- cek kolom options/visual bertipe JSON
   SELECT * FROM information_schema.KEY_COLUMN_USAGE
     WHERE TABLE_SCHEMA = 'mindora_db';    --cek semua FK terbentuk
   ```
4. Uji query per endpoint (tanpa backend), contoh:
   ```sql
   -- dashboard summary
   SELECT u.name, u.streak_days, u.daily_goal_minutes,
          COALESCE(SUM(a.xp_earned), 0) AS total_xp
   FROM users u LEFT JOIN user_quiz_attempts a ON a.user_id = u.id
   WHERE u.id = 1;
   -- topic mastery
   SELECT e.topic_label, ROUND(AVG(a.accuracy_percent)) AS mastery
   FROM user_quiz_attempts a JOIN exercises e ON e.id = a.exercise_id
   WHERE a.user_id = 1 AND a.status = 'completed'
   GROUP BY e.topic_label;
   -- riwayat aktivitas halaman 1
   SELECT * FROM v_user_activities WHERE user_id = 1
     ORDER BY finished_at DESC, id DESC LIMIT 4 OFFSET 0;
   ```
5. Setelah DDL divalidasi, lanjut: tulis `seed.sql` → baru implementasi `src/config/database.js`, model, controller, dan routes backend (menghapus fallback mock frontend setelah endpoint stabil).

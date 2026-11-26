-- ============================================================
--  MINDORA — DATA SEED (demo presentasi)
--
--  Cara pakai: mysql -u root mindora_db < seed.sql
--  atau phpMyAdmin -> Import. File ini aman dijalankan ulang
--  (data seed dihapus lalu disisihkan ulang). Tabel users
--  TIDAK disentuh, jadi akun yang sudah terdaftar tetap aman.
--
--  Isi:
--    - diagnostic_questions = 10 soal diagnostik terbaru
--      (kunci: B, C, C, C, C, C, B, C, C, C)
--    - materials = KATALOG_MATERI (materiService.js)
--    - exercises + quiz_questions = 5 latihan dan 32 soal latihanService.js
--
--  Catatan: riwayat diagnostik lama ikut di-reset karena soal
--  lama diganti total; akun demo kembali "belum mengerjakan".
-- ============================================================

USE mindora_db;

SET FOREIGN_KEY_CHECKS = 0;

DELETE FROM user_material_progress;
DELETE FROM materials;
DELETE FROM user_diagnostic_answers;
DELETE FROM diagnostic_history;
DELETE FROM diagnostic_questions;
DELETE FROM levels;

-- ------------------------------------------------------------
-- 1. LEVEL (tabel lookup gamifikasi)
-- ------------------------------------------------------------
INSERT INTO levels (level, min_xp, title) VALUES
  (1, 0,    'Pemula Penasaran'),
  (2, 200,  'Pelajar Konsisten'),
  (3, 500,  'Siswa Adaptif Mandiri'),
  (4, 900,  'Explorer Andal'),
  (5, 1400, 'Master Matematika');

-- ------------------------------------------------------------
-- 2. MATERIALS (katalog materi)
-- ------------------------------------------------------------
INSERT INTO materials
  (id, title, category, category_filter, description, chapter,
   total_modules, exercises_count, duration_minutes, xp_reward,
   prerequisite_id, required_level, sort_order)
VALUES
  ('mat-1', 'Operasi Pecahan Campuran', 'Bilangan Rasional', 'bilangan',
   'Menjumlahkan dan mengurangkan pecahan campuran dengan penyebut berbeda.',
   'Bab 4 • Bilangan Rasional', 4, 8, 25, 100, NULL, NULL, 1),
  ('mat-2', 'Bilangan Bulat & Garis Bilangan', 'Bilangan Bulat', 'bilangan',
   'Memahami nilai bilangan bulat dan posisinya pada garis bilangan.',
   'Bab 2 • Bilangan Bulat', 6, 6, 20, 80, NULL, NULL, 2),
  ('mat-3', 'Pengenalan Variabel & Bentuk Aljabar', 'Aljabar Dasar', 'aljabar',
   'Mengenal variabel, suku sejenis, dan model matematika sederhana.',
   'Bab 5 • Aljabar', 5, 10, 35, 120, NULL, NULL, 3),
  ('mat-4', 'Persamaan Linear Satu Variabel', 'Aljabar Lanjutan', 'aljabar',
   'Menyelesaikan persamaan linear satu variabel dengan operasi pada kedua ruas.',
   'Bab 6 • Aljabar', 6, 8, 30, 100, 'mat-3', NULL, 4),
  ('mat-5', 'Keliling & Luas Bangun Datar', 'Geometri Spasial', 'geometri',
   'Menghitung keliling dan luas bangun datar: persegi, persegi panjang, segitiga, dan lingkaran.',
   'Bab 8 • Geometri', 7, 12, 40, 120, 'mat-3', NULL, 5),
  ('mat-6', 'Penyajian Data & Diagram Batang', 'Statistika', 'statistika',
   'Membaca dan menyajikan data dalam diagram batang, garis, dan tabel.',
   'Bab 10 • Statistika', 5, 8, 30, 100, NULL, 4, 6);

-- ------------------------------------------------------------
-- 3. EXERCISES + QUIZ QUESTIONS (5 latihan, 32 soal)
--    INSERT idempoten agar bank soal lama diperbarui tanpa dihapus.
-- ------------------------------------------------------------
INSERT INTO exercises
  (id, exercise_type, topic_slug, topic_label, title, description,
   questions_count, questions_label, duration_minutes, xp_reward,
   tag_label, tag_variant, icon_type, formula_title, formula_expression,
   phase, is_active)
VALUES
  ('lat-1', 'latihan', 'matriks', 'Matriks & Sistem Persamaan Linier (SPLDV)',
   'Penjumlahan & Perkalian Skalar Matriks',
   'Pondasi ordo matriks, elemen seletak, serta sifat asosiatif dasar.',
   6, NULL, 8, 40, NULL, NULL, 'matrix-grid',
   'Sifat Perkalian Skalar', 'k·(A + B) = k·A + k·B',
   'Fase F SMA • Matematika Wajib', 1),
  ('lat-2', 'latihan', 'matriks', 'Matriks & Sistem Persamaan Linier (SPLDV)',
   'Determinan & Invers Matriks 2×2',
   'Perhitungan determinan, sifat matriks singular, dan rumus invers.',
   8, NULL, 12, 60, NULL, NULL, 'matrix-determinant',
   'Rumus Determinan 2×2', 'det(M) = (a·d) - (b·c)',
   'Fase F SMA • Matematika Wajib', 1),
  ('lat-3', 'latihan', 'matriks', 'Matriks & Sistem Persamaan Linier (SPLDV)',
   'Aplikasi Matriks dalam SPLDV & Ekonomi',
   'Pemodelan konteks toko belanja dan sistem persamaan dua variabel.',
   5, NULL, 15, 75, NULL, NULL, 'chart-trend',
   'Solusi SPLDV Matriks', 'AX = B  ⇒  X = A⁻¹·B',
   'Fase F SMA • Matematika Wajib', 1),
  ('lat-4', 'latihan', 'matriks', 'Matriks & Sistem Persamaan Linier (SPLDV)',
   'Evaluasi Kesalahan Tanda Negatif Invers',
   'Kaji ulang kesalahan peletakan tanda minus diagonal samping.',
   3, '3 Soal Ulang', 5, NULL, 'Remediasi', 'danger', 'warning-refresh',
   'Rumus Invers 2×2', 'A⁻¹ = (1/det)·[d -b; -c a]',
   'Fase F SMA • Matematika Wajib', 1),
  ('kuis-harian', 'kuis_harian', 'matriks', 'Matriks & Sistem Persamaan Linier (SPLDV)',
   'Kuis Harian: Matriks & Determinan 2×2',
   'Evaluasi pemahaman matriks dan determinan 2×2.',
   10, NULL, 15, 100, NULL, NULL, 'matrix-grid',
   'Rumus Determinan 2×2', 'det(M) = (a·d) - (b·c)',
   'Fase F SMA • Matematika Wajib', 1)
ON DUPLICATE KEY UPDATE
  exercise_type = VALUES(exercise_type),
  topic_slug = VALUES(topic_slug),
  topic_label = VALUES(topic_label),
  title = VALUES(title),
  description = VALUES(description),
  questions_count = VALUES(questions_count),
  questions_label = VALUES(questions_label),
  duration_minutes = VALUES(duration_minutes),
  xp_reward = VALUES(xp_reward),
  tag_label = VALUES(tag_label),
  tag_variant = VALUES(tag_variant),
  icon_type = VALUES(icon_type),
  formula_title = VALUES(formula_title),
  formula_expression = VALUES(formula_expression),
  phase = VALUES(phase),
  is_active = VALUES(is_active);

INSERT INTO quiz_questions
  (id, exercise_id, question_no, difficulty, points, text, options, correct_option, visual)
VALUES
  ('l1-1', 'lat-1', 1, 'mudah', 5,
   'Diketahui matriks {A} dan {B} seperti di bawah. Elemen baris ke-2 kolom ke-1 dari {A + B} adalah…',
   '[{"id":"A","label":"2"},{"id":"B","label":"3"},{"id":"C","label":"4"},{"id":"D","label":"9"}]', 'B',
   '{"matrices":[{"label":"A","rows":[[2,3],[1,4]]},{"label":"B","rows":[[1,0],[2,5]]}],"operator":"+"}'),
  ('l1-2', 'lat-1', 2, 'mudah', 5,
   'Hasil perkalian skalar {3A} memiliki elemen baris ke-1 kolom ke-2 sebesar…',
   '[{"id":"A","label":"-3"},{"id":"B","label":"3"},{"id":"C","label":"-1"},{"id":"D","label":"12"}]', 'A',
   '{"matrices":[{"label":"A","rows":[[2,-1],[0,4]]}]}'),
  ('l1-3', 'lat-1', 3, 'menengah', 10,
   'Jumlah elemen diagonal utama (trace) dari {A + B} adalah…',
   '[{"id":"A","label":"4"},{"id":"B","label":"5"},{"id":"C","label":"6"},{"id":"D","label":"10"}]', 'B',
   '{"matrices":[{"label":"A","rows":[[1,2],[3,4]]},{"label":"B","rows":[[0,1],[1,0]]}],"operator":"+"}'),
  ('l1-4', 'lat-1', 4, 'menengah', 10,
   'Elemen baris ke-2 kolom ke-2 dari {2A − B} adalah…',
   '[{"id":"A","label":"3"},{"id":"B","label":"2"},{"id":"C","label":"4"},{"id":"D","label":"5"}]', 'A',
   '{"matrices":[{"label":"A","rows":[[3,1],[2,2]]},{"label":"B","rows":[[1,0],[1,1]]}],"operator":"−"}'),
  ('l1-5', 'lat-1', 5, 'menengah', 10,
   'Sifat {(A + B) + C = A + (B + C)} pada penjumlahan matriks disebut sifat…',
   '[{"id":"A","label":"Komutatif"},{"id":"B","label":"Asosiatif"},{"id":"C","label":"Distributif"},{"id":"D","label":"Identitas"}]', 'B', NULL),
  ('l1-6', 'lat-1', 6, 'sulit', 15,
   'Jika {A = B}, maka nilai {x + y} adalah…',
   '[{"id":"A","label":"3"},{"id":"B","label":"4"},{"id":"C","label":"5"},{"id":"D","label":"6"}]', 'C',
   '{"matrices":[{"label":"A","rows":[["x",2],[3,4]]},{"label":"B","rows":[[1,2],[3,"y"]]}],"operator":"="}'),

  ('l2-1', 'lat-2', 1, 'mudah', 5,
   'Determinan dari matriks {M} adalah…',
   '[{"id":"A","label":"5"},{"id":"B","label":"6"},{"id":"C","label":"11"},{"id":"D","label":"-5"}]', 'A',
   '{"matrices":[{"label":"M","rows":[[2,1],[3,4]]}]}'),
  ('l2-2', 'lat-2', 2, 'mudah', 5,
   'Matriks {M} disebut singular karena determinannya bernilai…',
   '[{"id":"A","label":"0"},{"id":"B","label":"1"},{"id":"C","label":"20"},{"id":"D","label":"40"}]', 'A',
   '{"matrices":[{"label":"M","rows":[[5,2],[10,4]]}]}'),
  ('l2-3', 'lat-2', 3, 'menengah', 10,
   'Diketahui matriks {P} dan matriks {Q} di bawah ini. Jika determinan dari matriks hasil penjumlahan (P + Q) adalah ~k~, berapakah nilai dari {2k}?',
   '[{"id":"A","label":"30"},{"id":"B","label":"60"},{"id":"C","label":"54"},{"id":"D","label":"72"}]', 'B',
   '{"matrices":[{"label":"P","rows":[[4,-2],[3,1]]},{"label":"Q","rows":[[1,2],[0,5]]}],"operator":"+"}'),
  ('l2-4', 'lat-2', 4, 'menengah', 10,
   'Elemen baris ke-1 kolom ke-2 dari {M⁻¹} adalah…',
   '[{"id":"A","label":"1"},{"id":"B","label":"-1"},{"id":"C","label":"2"},{"id":"D","label":"-2"}]', 'A',
   '{"matrices":[{"label":"M","rows":[[4,2],[3,1]]}]}'),
  ('l2-5', 'lat-2', 5, 'menengah', 10,
   'Determinan dari matriks {M} adalah…',
   '[{"id":"A","label":"10"},{"id":"B","label":"12"},{"id":"C","label":"14"},{"id":"D","label":"16"}]', 'C',
   '{"matrices":[{"label":"M","rows":[[3,-2],[1,4]]}]}'),
  ('l2-6', 'lat-2', 6, 'sulit', 15,
   'Jika {det(A) = 3} dan {det(B) = 4}, maka {det(AB)} sama dengan…',
   '[{"id":"A","label":"7"},{"id":"B","label":"12"},{"id":"C","label":"1"},{"id":"D","label":"81"}]', 'B', NULL),
  ('l2-7', 'lat-2', 7, 'sulit', 15,
   'Matriks {M} tidak memiliki invers (singular). Nilai {x} yang memenuhi adalah…',
   '[{"id":"A","label":"1"},{"id":"B","label":"2"},{"id":"C","label":"3"},{"id":"D","label":"6"}]', 'A',
   '{"matrices":[{"label":"M","rows":[["2x",3],[4,6]]}]}'),
  ('l2-8', 'lat-2', 8, 'sulit', 15,
   'Elemen baris ke-2 kolom ke-1 dari {M⁻¹} adalah…',
   '[{"id":"A","label":"2"},{"id":"B","label":"-2"},{"id":"C","label":"5"},{"id":"D","label":"-5"}]', 'B',
   '{"matrices":[{"label":"M","rows":[[1,2],[2,5]]}]}'),

  ('l3-1', 'lat-3', 1, 'menengah', 10,
   'Harga {2 buku + 1 pensil} adalah Rp8.000, sedangkan {1 buku + 2 pensil} Rp7.000. Jika dimodelkan sebagai {AX = B}, harga satu buku adalah…',
   '[{"id":"A","label":"Rp2.000"},{"id":"B","label":"Rp3.000"},{"id":"C","label":"Rp4.000"},{"id":"D","label":"Rp5.000"}]', 'B', NULL),
  ('l3-2', 'lat-3', 2, 'menengah', 10,
   'Determinan matriks koefisien dari sistem {2x + y = 8.000} dan {x + 2y = 7.000} adalah…',
   '[{"id":"A","label":"1"},{"id":"B","label":"2"},{"id":"C","label":"3"},{"id":"D","label":"5"}]', 'C', NULL),
  ('l3-3', 'lat-3', 3, 'sulit', 15,
   'Toko roti menjual paket {3 roti + 2 susu} seharga Rp24.000 dan {1 roti + 3 susu} seharga Rp22.000. Harga satu susu adalah…',
   '[{"id":"A","label":"Rp4.000"},{"id":"B","label":"Rp5.000"},{"id":"C","label":"Rp6.000"},{"id":"D","label":"Rp7.000"}]', 'C', NULL),
  ('l3-4', 'lat-3', 4, 'sulit', 15,
   'Sistem {AX = B} dengan matriks {A} di bawah dan {B} = [5; 1] memiliki solusi {x} dan {y}. Nilai {x · y} adalah…',
   '[{"id":"A","label":"5"},{"id":"B","label":"6"},{"id":"C","label":"8"},{"id":"D","label":"9"}]', 'B',
   '{"matrices":[{"label":"A","rows":[[1,1],[2,-1]]}]}'),
  ('l3-5', 'lat-3', 5, 'menengah', 10,
   'Sistem persamaan linear {AX = B} memiliki solusi tunggal jika dan hanya jika…',
   '[{"id":"A","label":"det(A) = 0"},{"id":"B","label":"det(A) ≠ 0"},{"id":"C","label":"A matriks nol"},{"id":"D","label":"B matriks nol"}]', 'B', NULL),

  ('l4-1', 'lat-4', 1, 'mudah', 5,
   'Pada invers matriks {M}, elemen baris ke-1 kolom ke-2 bernilai…',
   '[{"id":"A","label":"-3/5"},{"id":"B","label":"3/5"},{"id":"C","label":"-1/5"},{"id":"D","label":"4/5"}]', 'A',
   '{"matrices":[{"label":"M","rows":[[2,3],[1,4]]}]}'),
  ('l4-2', 'lat-4', 2, 'menengah', 10,
   'Rumus invers {A⁻¹ = (1/det(A))·adj(A)}. Untuk {A} = [a b; c d], elemen diagonal samping pada adj(A) bertanda…',
   '[{"id":"A","label":"Positif keduanya"},{"id":"B","label":"Negatif keduanya"},{"id":"C","label":"a positif, d negatif"},{"id":"D","label":"b positif, c negatif"}]', 'B', NULL),
  ('l4-3', 'lat-4', 3, 'menengah', 10,
   'Elemen baris ke-1 kolom ke-2 dari {M⁻¹} adalah…',
   '[{"id":"A","label":"3"},{"id":"B","label":"-3"},{"id":"C","label":"7"},{"id":"D","label":"-2"}]', 'B',
   '{"matrices":[{"label":"M","rows":[[1,3],[2,7]]}]}'),

  ('kh-1', 'kuis-harian', 1, 'mudah', 5,
   'Ordo dari matriks {M} di bawah adalah…',
   '[{"id":"A","label":"2×2"},{"id":"B","label":"2×3"},{"id":"C","label":"3×2"},{"id":"D","label":"3×3"}]', 'B',
   '{"matrices":[{"label":"M","rows":[[2,3,1],[4,0,5]]}]}'),
  ('kh-2', 'kuis-harian', 2, 'mudah', 5,
   'Determinan dari matriks {M} adalah…',
   '[{"id":"A","label":"10"},{"id":"B","label":"12"},{"id":"C","label":"14"},{"id":"D","label":"2"}]', 'A',
   '{"matrices":[{"label":"M","rows":[[3,1],[2,4]]}]}'),
  ('kh-3', 'kuis-harian', 3, 'menengah', 10,
   'Diketahui matriks {P} dan matriks {Q} di bawah ini. Jika determinan dari matriks hasil penjumlahan (P + Q) adalah ~k~, berapakah nilai dari {2k}?',
   '[{"id":"A","label":"30"},{"id":"B","label":"60"},{"id":"C","label":"54"},{"id":"D","label":"72"}]', 'B',
   '{"matrices":[{"label":"P","rows":[[4,-2],[3,1]]},{"label":"Q","rows":[[1,2],[0,5]]}],"operator":"+"}'),
  ('kh-4', 'kuis-harian', 4, 'menengah', 10,
   'Jumlah elemen diagonal utama (trace) dari {A + B} adalah…',
   '[{"id":"A","label":"4"},{"id":"B","label":"5"},{"id":"C","label":"6"},{"id":"D","label":"10"}]', 'B',
   '{"matrices":[{"label":"A","rows":[[1,2],[3,4]]},{"label":"B","rows":[[0,1],[1,0]]}],"operator":"+"}'),
  ('kh-5', 'kuis-harian', 5, 'menengah', 10,
   'Elemen baris ke-1 kolom ke-2 dari {M⁻¹} adalah…',
   '[{"id":"A","label":"1"},{"id":"B","label":"-1"},{"id":"C","label":"2"},{"id":"D","label":"-2"}]', 'A',
   '{"matrices":[{"label":"M","rows":[[4,2],[3,1]]}]}'),
  ('kh-6', 'kuis-harian', 6, 'sulit', 15,
   'Matriks {M} tidak memiliki invers (singular). Nilai {x} yang memenuhi adalah…',
   '[{"id":"A","label":"1"},{"id":"B","label":"2"},{"id":"C","label":"3"},{"id":"D","label":"6"}]', 'A',
   '{"matrices":[{"label":"M","rows":[["2x",3],[4,6]]}]}'),
  ('kh-7', 'kuis-harian', 7, 'menengah', 10,
   'Harga {2 buku + 1 pensil} adalah Rp8.000, sedangkan {1 buku + 2 pensil} Rp7.000. Jika dimodelkan sebagai {AX = B}, harga satu buku adalah…',
   '[{"id":"A","label":"Rp2.000"},{"id":"B","label":"Rp3.000"},{"id":"C","label":"Rp4.000"},{"id":"D","label":"Rp5.000"}]', 'B', NULL),
  ('kh-8', 'kuis-harian', 8, 'mudah', 5,
   'Hasil perkalian skalar {3A} memiliki elemen baris ke-1 kolom ke-2 sebesar…',
   '[{"id":"A","label":"-3"},{"id":"B","label":"3"},{"id":"C","label":"-1"},{"id":"D","label":"12"}]', 'A',
   '{"matrices":[{"label":"A","rows":[[2,-1],[0,4]]}]}'),
  ('kh-9', 'kuis-harian', 9, 'sulit', 15,
   'Jika {det(A) = 3} dan {det(B) = 4}, maka {det(AB)} sama dengan…',
   '[{"id":"A","label":"7"},{"id":"B","label":"12"},{"id":"C","label":"1"},{"id":"D","label":"81"}]', 'B', NULL),
  ('kh-10', 'kuis-harian', 10, 'menengah', 10,
   'Elemen baris ke-1 kolom ke-2 dari {M⁻¹} adalah…',
   '[{"id":"A","label":"3"},{"id":"B","label":"-3"},{"id":"C","label":"7"},{"id":"D","label":"-2"}]', 'B',
   '{"matrices":[{"label":"M","rows":[[1,3],[2,7]]}]}')
ON DUPLICATE KEY UPDATE
  exercise_id = VALUES(exercise_id),
  question_no = VALUES(question_no),
  difficulty = VALUES(difficulty),
  points = VALUES(points),
  text = VALUES(text),
  options = VALUES(options),
  correct_option = VALUES(correct_option),
  visual = VALUES(visual);

-- ------------------------------------------------------------
-- 4. PROGRES MATERI user id=1 (akun demo)
--    mat-3 sengaja TIDAK diberi baris: LEFT JOIN menghasilkan
--    default (status 'ready', progress 0).
-- ------------------------------------------------------------
INSERT INTO user_material_progress
  (user_id, material_id, status, progress_percentage, completed_subtopics, score, last_activity_at)
VALUES
  (1, 'mat-1', 'in_progress', 75, 3, NULL, NOW()),
  (1, 'mat-2', 'completed', 100, 6, 95, DATE_SUB(NOW(), INTERVAL 2 DAY)),
  (1, 'mat-4', 'prerequisite_progress', 0, 0, NULL, NULL),
  (1, 'mat-5', 'locked_prerequisite', 0, 0, NULL, NULL),
  (1, 'mat-6', 'locked_level', 0, 0, NULL, NULL);

-- ------------------------------------------------------------
-- 5. SOAL DIAGNOSTIK (10 soal terbaru)
--    id dibuat eksplisit (1-10) supaya import ulang tidak
--    menggeser id — frontend mengirim questionId numerik yang
--    harus cocok dengan id ini.
--    Kunci jawaban: B, C, C, C, C, C, B, C, C, C
-- ------------------------------------------------------------
INSERT INTO diagnostic_questions
  (id, no_soal, topik, category, pertanyaan, options, jawaban_benar,
   instruction, alert_message, steps_header, steps_badge, steps, final_result, hint, hint_tag)
VALUES
  (1, 1, 'Penjumlahan', 'PENJUMLAHAN', 'Hasil dari 25 + 35 adalah ...',
   JSON_ARRAY(
     JSON_OBJECT('id', 'A', 'label', '50', 'isCorrect', FALSE),
     JSON_OBJECT('id', 'B', 'label', '60', 'isCorrect', TRUE),
     JSON_OBJECT('id', 'C', 'label', '65', 'isCorrect', FALSE),
     JSON_OBJECT('id', 'D', 'label', '70', 'isCorrect', FALSE)),
   'B',
   'Pilih satu jawaban yang paling tepat untuk operasi penjumlahan di atas.',
   'Jumlahkan digit satuan terlebih dahulu, lalu puluhan beserta simpanannya.',
   'CARA PENYELESAIAN BERSUSUN', 'Langkah demi Langkah',
   JSON_ARRAY(
     JSON_OBJECT('step', 1, 'title', 'Kolom Satuan', 'formula', '5 + 5',
       'description', 'Hitung digit satuan: 5 + 5 = 10. Tulis 0 pada kolom satuan, simpan 1 di kolom puluhan.'),
     JSON_OBJECT('step', 2, 'title', 'Kolom Puluhan Bersama Simpanan', 'formula', '1 + 2 + 3',
       'description', 'Jumlahkan simpanan bersama digit puluhan: 1 + 2 + 3 = 6. Tulis 6 pada kolom puluhan.'),
     JSON_OBJECT('step', 3, 'title', 'Gabungkan Hasil', 'formula', '60 + 0',
       'description', 'Gabungkan nilai puluhan dan satuan: 60 + 0 = 60.')),
   JSON_OBJECT('equation', '25 + 35 = 60', 'correctOptionLabel', 'Jawaban Benar: Opsi B'),
   'Pisahkan nilai tempat: (20 + 30) + (5 + 5) = 50 + 10 = 60.',
   'Dekomposisi Nilai Tempat'),

  (2, 2, 'Pengurangan', 'PENGURANGAN', 'Hasil dari 100 − 45 adalah ...',
   JSON_ARRAY(
     JSON_OBJECT('id', 'A', 'label', '45', 'isCorrect', FALSE),
     JSON_OBJECT('id', 'B', 'label', '50', 'isCorrect', FALSE),
     JSON_OBJECT('id', 'C', 'label', '55', 'isCorrect', TRUE),
     JSON_OBJECT('id', 'D', 'label', '65', 'isCorrect', FALSE)),
   'C',
   'Tentukan hasil pengurangan bilangan di atas dengan teliti.',
   'Perhatikan teknik meminjam saat digit satuan lebih kecil dari pengurang.',
   'CARA PENYELESAIAN BERSUSUN', 'Langkah demi Langkah',
   JSON_ARRAY(
     JSON_OBJECT('step', 1, 'title', 'Kurangkan Satuan dengan Pinjaman', 'formula', '10 − 5',
       'description', 'Satuan 0 tidak dapat dikurangi 5, pinjam 1 puluhan: 10 − 5 = 5.'),
     JSON_OBJECT('step', 2, 'title', 'Kurangkan Puluhan Setelah Dipinjam', 'formula', '9 − 4',
       'description', 'Puluhan 10 berkurang 1 menjadi 9: 9 − 4 = 5.'),
     JSON_OBJECT('step', 3, 'title', 'Periksa Ratusan', 'formula', '1 − 1 = 0',
       'description', 'Ratusan 1 habis dipinjam sehingga menjadi 0. Hasil akhir 55.')),
   JSON_OBJECT('equation', '100 − 45 = 55', 'correctOptionLabel', 'Jawaban Benar: Opsi C'),
   '100 − 45 = 100 − 40 − 5 = 60 − 5 = 55.',
   'Pengurangan Bertahap'),

  (3, 3, 'Perkalian', 'PERKALIAN', 'Jika satu barang berharga Rp5.000, berapa harga 4 barang?',
   JSON_ARRAY(
     JSON_OBJECT('id', 'A', 'label', 'Rp10.000', 'isCorrect', FALSE),
     JSON_OBJECT('id', 'B', 'label', 'Rp15.000', 'isCorrect', FALSE),
     JSON_OBJECT('id', 'C', 'label', 'Rp20.000', 'isCorrect', TRUE),
     JSON_OBJECT('id', 'D', 'label', 'Rp25.000', 'isCorrect', FALSE)),
   'C',
   'Hitung total harga dengan mengalikan harga satuan dan jumlah barang.',
   'Total harga = harga satu barang × banyak barang.',
   'CARA PENYELESAIAN BERSUSUN', 'Langkah demi Langkah',
   JSON_ARRAY(
     JSON_OBJECT('step', 1, 'title', 'Identifikasi Harga Satuan', 'formula', 'Rp5.000',
       'description', 'Harga satu barang adalah Rp5.000.'),
     JSON_OBJECT('step', 2, 'title', 'Kalikan dengan Jumlah Barang', 'formula', '5.000 × 4',
       'description', 'Total harga = harga satuan × jumlah barang: 5.000 × 4 = 20.000.')),
   JSON_OBJECT('equation', '5.000 × 4 = 20.000', 'correctOptionLabel', 'Jawaban Benar: Opsi C'),
   '5.000 × 4 = 5 × 4 ribu = 20 ribu.',
   'Perkalian Ribuan'),

  (4, 4, 'Perkalian', 'PERKALIAN', 'Hasil dari 12 × 8 adalah ...',
   JSON_ARRAY(
     JSON_OBJECT('id', 'A', 'label', '86', 'isCorrect', FALSE),
     JSON_OBJECT('id', 'B', 'label', '92', 'isCorrect', FALSE),
     JSON_OBJECT('id', 'C', 'label', '96', 'isCorrect', TRUE),
     JSON_OBJECT('id', 'D', 'label', '108', 'isCorrect', FALSE)),
   'C',
   'Hitunglah hasil perkalian bilangan di atas.',
   'Uraikan 12 menjadi 10 + 2 sebelum mengalikan.',
   'CARA PENYELESAIAN BERSUSUN', 'Langkah demi Langkah',
   JSON_ARRAY(
     JSON_OBJECT('step', 1, 'title', 'Kalikan Nilai Puluhan', 'formula', '10 × 8',
       'description', 'Kalikan digit puluhan dengan pengali: 10 × 8 = 80.'),
     JSON_OBJECT('step', 2, 'title', 'Kalikan Nilai Satuan', 'formula', '2 × 8',
       'description', 'Kalikan digit satuan dengan pengali: 2 × 8 = 16.'),
     JSON_OBJECT('step', 3, 'title', 'Jumlahkan Kedua Hasil', 'formula', '80 + 16',
       'description', 'Jumlahkan hasil perkalian puluhan dan satuan: 80 + 16 = 96.')),
   JSON_OBJECT('equation', '12 × 8 = 96', 'correctOptionLabel', 'Jawaban Benar: Opsi C'),
   '(10 × 8) + (2 × 8) = 80 + 16 = 96.',
   'Distributif Perkalian'),

  (5, 5, 'Pembagian', 'PEMBAGIAN', 'Hasil dari 144 ÷ 12 adalah ...',
   JSON_ARRAY(
     JSON_OBJECT('id', 'A', 'label', '10', 'isCorrect', FALSE),
     JSON_OBJECT('id', 'B', 'label', '11', 'isCorrect', FALSE),
     JSON_OBJECT('id', 'C', 'label', '12', 'isCorrect', TRUE),
     JSON_OBJECT('id', 'D', 'label', '14', 'isCorrect', FALSE)),
   'C',
   'Tentukan hasil pembagian di atas.',
   'Gunakan hubungan kebalikan antara perkalian dan pembagian.',
   'CARA PENYELESAIAN BERSUSUN', 'Langkah demi Langkah',
   JSON_ARRAY(
     JSON_OBJECT('step', 1, 'title', 'Cari Faktor Pengali', 'formula', '12 × ? = 144',
       'description', 'Pembagian adalah kebalikan perkalian: cari angka yang jika dikali 12 menghasilkan 144.'),
     JSON_OBJECT('step', 2, 'title', 'Uji Perkalian', 'formula', '12 × 12',
       'description', '12 × 12 = 144, maka 144 ÷ 12 = 12.')),
   JSON_OBJECT('equation', '144 ÷ 12 = 12', 'correctOptionLabel', 'Jawaban Benar: Opsi C'),
   'Ingat kuadrat: 12 × 12 = 144.',
   'Kebalikan Perkalian'),

  (6, 6, 'Pengurangan', 'PENGURANGAN', 'Jika terdapat 50 data dan 20 data dihapus, berapa data yang tersisa?',
   JSON_ARRAY(
     JSON_OBJECT('id', 'A', 'label', '20', 'isCorrect', FALSE),
     JSON_OBJECT('id', 'B', 'label', '25', 'isCorrect', FALSE),
     JSON_OBJECT('id', 'C', 'label', '30', 'isCorrect', TRUE),
     JSON_OBJECT('id', 'D', 'label', '35', 'isCorrect', FALSE)),
   'C',
   'Terjemahkan cerita menjadi operasi pengurangan lalu hitung hasilnya.',
   'Data yang dihapus mengurangi jumlah data awal.',
   'CARA PENYELESAIAN BERSUSUN', 'Langkah demi Langkah',
   JSON_ARRAY(
     JSON_OBJECT('step', 1, 'title', 'Model Matematika', 'formula', '50 − 20',
       'description', 'Data tersisa = data awal − data yang dihapus.'),
     JSON_OBJECT('step', 2, 'title', 'Hitung Selisih', 'formula', '50 − 20 = 30',
       'description', '50 − 20 = 30, jadi data yang tersisa 30.')),
   JSON_OBJECT('equation', '50 − 20 = 30', 'correctOptionLabel', 'Jawaban Benar: Opsi C'),
   'Kurangi puluhan: 5 puluh − 2 puluh = 3 puluh.',
   'Pengurangan Puluhan'),

  (7, 7, 'Penjumlahan Pecahan', 'PECAHAN', 'Berapa hasil dari ¾ + ¼?',
   JSON_ARRAY(
     JSON_OBJECT('id', 'A', 'label', '½', 'isCorrect', FALSE),
     JSON_OBJECT('id', 'B', 'label', '1', 'isCorrect', TRUE),
     JSON_OBJECT('id', 'C', 'label', '1½', 'isCorrect', FALSE),
     JSON_OBJECT('id', 'D', 'label', '2', 'isCorrect', FALSE)),
   'B',
   'Jumlahkan kedua pecahan di atas.',
   'Jika penyebut sudah sama, jumlahkan pembilangnya saja.',
   'CARA PENYELESAIAN BERSUSUN', 'Langkah demi Langkah',
   JSON_ARRAY(
     JSON_OBJECT('step', 1, 'title', 'Periksa Penyebut', 'formula', '3/4 + 1/4',
       'description', 'Kedua pecahan sudah berpenyebut sama (4), sehingga pembilang dapat langsung dijumlahkan.'),
     JSON_OBJECT('step', 2, 'title', 'Jumlahkan Pembilang', 'formula', '(3 + 1)/4',
       'description', '3 + 1 = 4, sehingga hasilnya 4/4.'),
     JSON_OBJECT('step', 3, 'title', 'Sederhanakan', 'formula', '4/4 = 1',
       'description', 'Pecahan dengan pembilang dan penyebut sama bernilai 1.')),
   JSON_OBJECT('equation', '¾ + ¼ = 1', 'correctOptionLabel', 'Jawaban Benar: Opsi B'),
   'Penyebut sama: jumlahkan pembilang saja, (3 + 1)/4 = 4/4 = 1.',
   'Penyebut Sama'),

  (8, 8, 'Rata-rata', 'STATISTIKA', 'Jika nilai 70, 80, dan 90 dijumlahkan lalu dibagi 3, berapa rata-ratanya?',
   JSON_ARRAY(
     JSON_OBJECT('id', 'A', 'label', '70', 'isCorrect', FALSE),
     JSON_OBJECT('id', 'B', 'label', '75', 'isCorrect', FALSE),
     JSON_OBJECT('id', 'C', 'label', '80', 'isCorrect', TRUE),
     JSON_OBJECT('id', 'D', 'label', '85', 'isCorrect', FALSE)),
   'C',
   'Hitung rata-rata dengan menjumlahkan nilai lalu membaginya dengan banyak data.',
   'Rata-rata = total nilai ÷ jumlah data.',
   'CARA PENYELESAIAN BERSUSUN', 'Langkah demi Langkah',
   JSON_ARRAY(
     JSON_OBJECT('step', 1, 'title', 'Jumlahkan Semua Nilai', 'formula', '70 + 80 + 90',
       'description', '70 + 80 + 90 = 240.'),
     JSON_OBJECT('step', 2, 'title', 'Bagi dengan Banyak Data', 'formula', '240 ÷ 3',
       'description', '240 ÷ 3 = 80, jadi rata-ratanya 80.')),
   JSON_OBJECT('equation', '(70 + 80 + 90) ÷ 3 = 80', 'correctOptionLabel', 'Jawaban Benar: Opsi C'),
   'Rata-rata = jumlah nilai ÷ banyak data = 240 ÷ 3 = 80.',
   'Rumus Rata-rata'),

  (9, 9, 'Persentase', 'PERSENTASE', 'Sebuah database menyimpan 200 data mahasiswa. Jika 25% merupakan mahasiswa semester 4, berapa jumlahnya?',
   JSON_ARRAY(
     JSON_OBJECT('id', 'A', 'label', '25', 'isCorrect', FALSE),
     JSON_OBJECT('id', 'B', 'label', '40', 'isCorrect', FALSE),
     JSON_OBJECT('id', 'C', 'label', '50', 'isCorrect', TRUE),
     JSON_OBJECT('id', 'D', 'label', '75', 'isCorrect', FALSE)),
   'C',
   'Hitung 25% dari 200 data mahasiswa.',
   'Persen berarti per seratus: 25% = 25/100.',
   'CARA PENYELESAIAN BERSUSUN', 'Langkah demi Langkah',
   JSON_ARRAY(
     JSON_OBJECT('step', 1, 'title', 'Ubah Persen Menjadi Pecahan', 'formula', '25% = 25/100',
       'description', '25% = 25/100 = 1/4.'),
     JSON_OBJECT('step', 2, 'title', 'Kalikan dengan Total Data', 'formula', '1/4 × 200',
       'description', '1/4 × 200 = 50, jadi mahasiswa semester 4 sebanyak 50.')),
   JSON_OBJECT('equation', '25% × 200 = 50', 'correctOptionLabel', 'Jawaban Benar: Opsi C'),
   '25% itu seperempat: 200 ÷ 4 = 50.',
   'Persen ke Pecahan'),

  (10, 10, 'Perkalian', 'PERKALIAN', 'Jika terdapat 5 kelompok dan setiap kelompok memiliki 12 anggota, berapa total anggotanya?',
   JSON_ARRAY(
     JSON_OBJECT('id', 'A', 'label', '50', 'isCorrect', FALSE),
     JSON_OBJECT('id', 'B', 'label', '55', 'isCorrect', FALSE),
     JSON_OBJECT('id', 'C', 'label', '60', 'isCorrect', TRUE),
     JSON_OBJECT('id', 'D', 'label', '65', 'isCorrect', FALSE)),
   'C',
   'Hitung total anggota dengan mengalikan banyak kelompok dan anggota tiap kelompok.',
   'Total = banyak kelompok × anggota per kelompok.',
   'CARA PENYELESAIAN BERSUSUN', 'Langkah demi Langkah',
   JSON_ARRAY(
     JSON_OBJECT('step', 1, 'title', 'Model Perkalian', 'formula', '5 × 12',
       'description', 'Total anggota = banyak kelompok × anggota per kelompok.'),
     JSON_OBJECT('step', 2, 'title', 'Hitung Hasil', 'formula', '5 × 12 = 60',
       'description', '5 × 12 = 60, jadi total anggota 60.')),
   JSON_OBJECT('equation', '5 × 12 = 60', 'correctOptionLabel', 'Jawaban Benar: Opsi C'),
   '5 × 12 = 5 × 10 + 5 × 2 = 50 + 10 = 60.',
   'Distributif Perkalian');

SET FOREIGN_KEY_CHECKS = 1;
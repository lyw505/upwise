-- =====================================================
-- ADD YOUTUBE_VIDEOS FIELD TO DAILY_LEARNING_TASKS
-- =====================================================
-- Migration untuk menambahkan field youtube_videos ke tabel daily_learning_tasks
-- Jalankan di Supabase SQL Editor

-- Tambahkan kolom youtube_videos sebagai JSONB
ALTER TABLE daily_learning_tasks 
ADD COLUMN IF NOT EXISTS youtube_videos JSONB DEFAULT '[]'::jsonb;

-- Tambahkan index untuk performa query
CREATE INDEX IF NOT EXISTS idx_daily_learning_tasks_youtube_videos 
ON daily_learning_tasks USING gin(youtube_videos);

-- Tambahkan comment untuk dokumentasi
COMMENT ON COLUMN daily_learning_tasks.youtube_videos IS 'Array of YouTube video recommendations in JSON format';

-- Verifikasi struktur tabel
SELECT column_name, data_type, is_nullable, column_default 
FROM information_schema.columns 
WHERE table_name = 'daily_learning_tasks' 
AND column_name = 'youtube_videos';
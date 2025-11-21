# YouTube Videos Setup Instructions

## 🎥 Masalah: Video YouTube Tidak Muncul

Jika Anda sudah mencentang "Recommend YouTube Videos" tapi video tidak muncul, kemungkinan database belum memiliki field `youtube_videos`.

## 🔧 Solusi: Jalankan Migration Database

### Langkah 1: Buka Supabase Dashboard
1. Buka [Supabase Dashboard](https://app.supabase.com)
2. Pilih project Upwise Anda
3. Klik "SQL Editor" di sidebar kiri

### Langkah 2: Jalankan Migration SQL
Copy dan paste SQL berikut ke SQL Editor, lalu klik "Run":

```sql
-- Tambahkan kolom youtube_videos ke tabel daily_learning_tasks
ALTER TABLE daily_learning_tasks 
ADD COLUMN IF NOT EXISTS youtube_videos JSONB DEFAULT '[]'::jsonb;

-- Tambahkan index untuk performa
CREATE INDEX IF NOT EXISTS idx_daily_learning_tasks_youtube_videos 
ON daily_learning_tasks USING gin(youtube_videos);

-- Verifikasi kolom berhasil ditambahkan
SELECT column_name, data_type, is_nullable, column_default 
FROM information_schema.columns 
WHERE table_name = 'daily_learning_tasks' 
AND column_name = 'youtube_videos';
```

### Langkah 3: Verifikasi
Setelah menjalankan SQL di atas, Anda harus melihat output seperti ini:
```
column_name    | data_type | is_nullable | column_default
youtube_videos | jsonb     | YES         | '[]'::jsonb
```

### Langkah 4: Test Aplikasi
1. Restart aplikasi Flutter
2. Buat learning path baru dengan "Recommend YouTube Videos" dicentang
3. Buka learning path → Tab "Videos"
4. Video seharusnya muncul sekarang

## 🐛 Debug Mode
Untuk melihat log debug, buka browser console (F12) saat menggunakan aplikasi. Anda akan melihat log seperti:
- `🎥 Finding YouTube videos for: [topic]`
- `✅ Found X videos from AI for: [topic]`
- `YouTube videos count: X`

## ⚠️ Troubleshooting

### Jika masih tidak ada video:
1. **Cek Gemini API Key**: Pastikan `GEMINI_API_KEY` sudah diset di `.env`
2. **Cek Internet**: Pastikan koneksi internet stabil
3. **Cek Console**: Lihat error di browser console (F12)
4. **Fallback Videos**: Meskipun AI gagal, seharusnya ada fallback videos

### Jika error "column does not exist":
- Jalankan ulang migration SQL di atas
- Pastikan Anda menjalankannya di project Supabase yang benar

### Jika video muncul tapi tidak bisa dibuka:
- Pastikan `url_launcher` dependency sudah terinstall
- Cek apakah browser memblokir popup

## 📞 Support
Jika masih ada masalah, cek:
1. Browser console untuk error messages
2. Supabase logs di dashboard
3. Pastikan semua dependencies sudah terinstall dengan `flutter pub get`
-- =====================================================
-- AI SUMMARIZER DATABASE SCHEMA - SIMPLE VERSION
-- =====================================================
-- Schema sederhana untuk menggantikan local storage
-- Copy dan paste ke Supabase SQL Editor

-- =====================================================
-- 1. CONTENT SUMMARIES - Tabel Utama
-- =====================================================
CREATE TABLE IF NOT EXISTS content_summaries (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    learning_path_id UUID REFERENCES learning_paths(id) ON DELETE SET NULL,
    
    -- Content Info
    title TEXT NOT NULL,
    original_content TEXT NOT NULL,
    content_type TEXT NOT NULL CHECK (content_type IN ('text', 'url', 'file')),
    content_source TEXT, -- URL atau file path
    
    -- AI Generated
    summary TEXT NOT NULL,
    key_points JSONB DEFAULT '[]'::jsonb,
    tags JSONB DEFAULT '[]'::jsonb,
    
    -- Metadata
    word_count INTEGER,
    estimated_read_time INTEGER, -- dalam menit
    difficulty_level TEXT CHECK (difficulty_level IN ('beginner', 'intermediate', 'advanced')),
    
    -- User Actions
    is_favorite BOOLEAN DEFAULT FALSE,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

-- =====================================================
-- 2. SUMMARY CATEGORIES - Organisasi
-- =====================================================
CREATE TABLE IF NOT EXISTS summary_categories (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    name TEXT NOT NULL,
    color TEXT DEFAULT '#2563EB',
    icon TEXT DEFAULT 'folder',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    UNIQUE(user_id, name)
);

-- =====================================================
-- 3. SUMMARY-CATEGORY RELATIONS
-- =====================================================
CREATE TABLE IF NOT EXISTS summary_category_relations (
    summary_id UUID REFERENCES content_summaries(id) ON DELETE CASCADE NOT NULL,
    category_id UUID REFERENCES summary_categories(id) ON DELETE CASCADE NOT NULL,
    PRIMARY KEY (summary_id, category_id)
);

-- =====================================================
-- 4. ROW LEVEL SECURITY
-- =====================================================
ALTER TABLE content_summaries ENABLE ROW LEVEL SECURITY;
ALTER TABLE summary_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE summary_category_relations ENABLE ROW LEVEL SECURITY;

-- Content Summaries Policies
CREATE POLICY "Users can view own summaries" ON content_summaries
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own summaries" ON content_summaries
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own summaries" ON content_summaries
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own summaries" ON content_summaries
    FOR DELETE USING (auth.uid() = user_id);

-- Categories Policies
CREATE POLICY "Users can manage own categories" ON summary_categories
    FOR ALL USING (auth.uid() = user_id);

-- Relations Policies
CREATE POLICY "Users can manage own relations" ON summary_category_relations
    FOR ALL USING (
        auth.uid() IN (
            SELECT user_id FROM content_summaries WHERE id = summary_id
        )
    );

-- =====================================================
-- 5. INDEXES UNTUK PERFORMANCE
-- =====================================================
CREATE INDEX idx_content_summaries_user_id ON content_summaries(user_id);
CREATE INDEX idx_content_summaries_created_at ON content_summaries(created_at DESC);
CREATE INDEX idx_content_summaries_is_favorite ON content_summaries(is_favorite);
CREATE INDEX idx_content_summaries_title_search ON content_summaries USING gin(to_tsvector('english', title));
CREATE INDEX idx_content_summaries_summary_search ON content_summaries USING gin(to_tsvector('english', summary));
CREATE INDEX idx_content_summaries_tags ON content_summaries USING gin(tags);

CREATE INDEX idx_summary_categories_user_id ON summary_categories(user_id);
CREATE INDEX idx_summary_category_relations_summary_id ON summary_category_relations(summary_id);

-- =====================================================
-- 6. TRIGGERS UNTUK AUTO UPDATE
-- =====================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_content_summaries_updated_at 
    BEFORE UPDATE ON content_summaries
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- 7. DEFAULT CATEGORIES UNTUK USER BARU
-- =====================================================
CREATE OR REPLACE FUNCTION create_default_categories_for_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO summary_categories (user_id, name, color, icon) VALUES
    (NEW.id, 'General', '#6B7280', 'folder'),
    (NEW.id, 'Work', '#3B82F6', 'briefcase'),
    (NEW.id, 'Study', '#10B981', 'book'),
    (NEW.id, 'Personal', '#F59E0B', 'user');
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Note: Trigger ini akan ditambahkan ke profiles table jika diperlukan
-- CREATE TRIGGER create_user_categories AFTER INSERT ON profiles
--     FOR EACH ROW EXECUTE FUNCTION create_default_categories_for_user();

-- =====================================================
-- 8. VIEW UNTUK QUERY MUDAH
-- =====================================================
CREATE OR REPLACE VIEW summaries_with_categories AS
SELECT 
    cs.*,
    COALESCE(
        json_agg(
            json_build_object(
                'id', sc.id,
                'name', sc.name,
                'color', sc.color,
                'icon', sc.icon
            )
        ) FILTER (WHERE sc.id IS NOT NULL),
        '[]'::json
    ) as categories
FROM content_summaries cs
LEFT JOIN summary_category_relations scr ON cs.id = scr.summary_id
LEFT JOIN summary_categories sc ON scr.category_id = sc.id
GROUP BY cs.id;

-- =====================================================
-- SETUP SELESAI!
-- =====================================================
-- Setelah run schema ini:
-- 1. Data AI Summarizer akan tersimpan di cloud
-- 2. Sync otomatis antar device
-- 3. Search functionality tersedia
-- 4. Kategorisasi untuk organisasi
-- 5. Security dengan RLS policies

-- Test query:
-- SELECT * FROM content_summaries WHERE user_id = auth.uid();
-- SELECT * FROM summaries_with_categories WHERE user_id = auth.uid();
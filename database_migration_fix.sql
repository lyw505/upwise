-- =====================================================
-- DATABASE MIGRATION FIX - Add Missing Column
-- =====================================================
-- Run this in your Supabase SQL editor to fix the missing column error

-- Add learning_path_id column to content_summaries table
ALTER TABLE content_summaries 
ADD COLUMN IF NOT EXISTS learning_path_id UUID REFERENCES learning_paths(id) ON DELETE SET NULL;

-- Add index for performance
CREATE INDEX IF NOT EXISTS idx_content_summaries_learning_path_id ON content_summaries(learning_path_id);

-- Update the view to include the new column
DROP VIEW IF EXISTS summaries_with_categories;

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

-- Verify the fix
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'content_summaries' 
AND column_name = 'learning_path_id';

-- Should return:
-- learning_path_id | uuid | YES
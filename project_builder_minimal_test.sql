-- =====================================================
-- PROJECT BUILDER MINIMAL TEST SCHEMA
-- =====================================================
-- Script untuk testing Project Builder dengan minimal setup

-- 1. Check if tables exist
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('project_templates', 'user_projects', 'project_step_completions');

-- 2. Create minimal project_templates table if not exists
CREATE TABLE IF NOT EXISTS project_templates (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    category TEXT NOT NULL DEFAULT 'web',
    difficulty_level TEXT NOT NULL DEFAULT 'beginner',
    estimated_hours INTEGER DEFAULT 10,
    tech_stack JSONB DEFAULT '[]'::jsonb,
    prerequisites JSONB DEFAULT '[]'::jsonb,
    learning_objectives JSONB DEFAULT '[]'::jsonb,
    project_steps JSONB NOT NULL DEFAULT '{"steps": []}'::jsonb,
    resources JSONB DEFAULT '[]'::jsonb,
    tags JSONB DEFAULT '[]'::jsonb,
    is_featured BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::TEXT, NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE
);

-- 3. Create minimal user_projects table if not exists
CREATE TABLE IF NOT EXISTS user_projects (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL,
    template_id UUID REFERENCES project_templates(id) ON DELETE SET NULL,
    learning_path_id UUID,
    title TEXT NOT NULL,
    description TEXT,
    status TEXT NOT NULL DEFAULT 'not_started',
    current_step INTEGER DEFAULT 0,
    total_steps INTEGER NOT NULL DEFAULT 1,
    progress_percentage DECIMAL(5,2) DEFAULT 0.00,
    estimated_hours INTEGER,
    actual_hours_spent DECIMAL(5,2) DEFAULT 0.00,
    project_data JSONB DEFAULT '{}'::jsonb,
    completed_steps JSONB DEFAULT '[]'::jsonb,
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    due_date TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::TEXT, NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE
);

-- 4. Create minimal project_step_completions table if not exists
CREATE TABLE IF NOT EXISTS project_step_completions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_project_id UUID REFERENCES user_projects(id) ON DELETE CASCADE NOT NULL,
    step_number INTEGER NOT NULL,
    step_title TEXT NOT NULL,
    is_completed BOOLEAN DEFAULT FALSE,
    completion_notes TEXT,
    time_spent_minutes INTEGER DEFAULT 0,
    attachments JSONB DEFAULT '[]'::jsonb,
    completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::TEXT, NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE,
    UNIQUE(user_project_id, step_number)
);

-- 5. Insert minimal test data
INSERT INTO project_templates (title, description, category, difficulty_level, estimated_hours, project_steps, tech_stack, tags) 
VALUES (
    'Test Portfolio Website',
    'A simple portfolio website to test Project Builder functionality',
    'web',
    'beginner',
    10,
    '{"steps": [
        {"id": 1, "title": "Setup Project", "description": "Create project structure", "estimatedHours": 2},
        {"id": 2, "title": "Build HTML", "description": "Create HTML structure", "estimatedHours": 3},
        {"id": 3, "title": "Add CSS", "description": "Style the website", "estimatedHours": 3},
        {"id": 4, "title": "Deploy", "description": "Deploy to web", "estimatedHours": 2}
    ]}'::jsonb,
    '["HTML", "CSS", "JavaScript"]'::jsonb,
    '["portfolio", "web", "beginner"]'::jsonb
) ON CONFLICT (id) DO NOTHING;

-- 6. Enable RLS (Row Level Security)
ALTER TABLE project_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE project_step_completions ENABLE ROW LEVEL SECURITY;

-- 7. Create basic RLS policies
DROP POLICY IF EXISTS "project_templates_select_policy" ON project_templates;
CREATE POLICY "project_templates_select_policy" ON project_templates
    FOR SELECT USING (is_active = true);

DROP POLICY IF EXISTS "user_projects_policy" ON user_projects;
CREATE POLICY "user_projects_policy" ON user_projects
    FOR ALL USING (auth.uid()::text = user_id::text);

DROP POLICY IF EXISTS "project_step_completions_policy" ON project_step_completions;
CREATE POLICY "project_step_completions_policy" ON project_step_completions
    FOR ALL USING (
        auth.uid()::text IN (
            SELECT user_id::text FROM user_projects WHERE id = user_project_id
        )
    );

-- 8. Check final status
SELECT 
    'project_templates' as table_name,
    COUNT(*) as record_count
FROM project_templates
WHERE is_active = true

UNION ALL

SELECT 
    'user_projects' as table_name,
    COUNT(*) as record_count
FROM user_projects

UNION ALL

SELECT 
    'project_step_completions' as table_name,
    COUNT(*) as record_count
FROM project_step_completions;

-- =====================================================
-- TESTING COMPLETE
-- =====================================================
-- Jika script ini berhasil dijalankan:
-- 1. Tables akan dibuat jika belum ada
-- 2. Minimal test data akan diinsert
-- 3. RLS policies akan aktif
-- 4. Project Builder seharusnya bisa berfungsi
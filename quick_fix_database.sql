-- QUICK FIX: Create minimal tables for Project Builder testing

-- 1. Create project_templates table
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
    project_steps JSONB NOT NULL DEFAULT '{"steps": [{"id": 1, "title": "Setup", "description": "Setup project", "estimatedHours": 2}]}'::jsonb,
    resources JSONB DEFAULT '[]'::jsonb,
    tags JSONB DEFAULT '[]'::jsonb,
    is_featured BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE
);

-- 2. Create user_projects table
CREATE TABLE IF NOT EXISTS user_projects (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL,
    template_id UUID REFERENCES project_templates(id),
    learning_path_id UUID,
    title TEXT NOT NULL,
    description TEXT,
    status TEXT DEFAULT 'not_started',
    current_step INTEGER DEFAULT 0,
    total_steps INTEGER DEFAULT 1,
    progress_percentage DECIMAL(5,2) DEFAULT 0.00,
    estimated_hours INTEGER,
    actual_hours_spent DECIMAL(5,2) DEFAULT 0.00,
    project_data JSONB DEFAULT '{}'::jsonb,
    completed_steps JSONB DEFAULT '[]'::jsonb,
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    due_date TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE
);

-- 3. Create project_step_completions table
CREATE TABLE IF NOT EXISTS project_step_completions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_project_id UUID REFERENCES user_projects(id) ON DELETE CASCADE,
    step_number INTEGER NOT NULL,
    step_title TEXT NOT NULL,
    is_completed BOOLEAN DEFAULT FALSE,
    completion_notes TEXT,
    time_spent_minutes INTEGER DEFAULT 0,
    attachments JSONB DEFAULT '[]'::jsonb,
    completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE
);

-- 4. Insert test template
INSERT INTO project_templates (title, description, category, difficulty_level, estimated_hours, project_steps, tech_stack, tags) 
VALUES (
    'Test Portfolio Website',
    'A simple portfolio website to test Project Builder',
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
    '["portfolio", "web", "test"]'::jsonb
) ON CONFLICT DO NOTHING;

-- 5. Enable RLS
ALTER TABLE project_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE project_step_completions ENABLE ROW LEVEL SECURITY;

-- 6. Create RLS policies
CREATE POLICY IF NOT EXISTS "project_templates_select" ON project_templates FOR SELECT USING (is_active = true);
CREATE POLICY IF NOT EXISTS "user_projects_all" ON user_projects FOR ALL USING (auth.uid()::text = user_id::text);
CREATE POLICY IF NOT EXISTS "project_step_completions_all" ON project_step_completions FOR ALL USING (
    auth.uid()::text IN (SELECT user_id::text FROM user_projects WHERE id = user_project_id)
);

-- 7. Check results
SELECT 'Tables created successfully' as status;
SELECT COUNT(*) as template_count FROM project_templates WHERE is_active = true;
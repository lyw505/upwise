-- =====================================================
-- PROJECT BUILDER SCHEMA - FULLY COMPATIBLE VERSION
-- =====================================================
-- Schema yang 100% kompatibel dengan database existing
-- Menggunakan naming convention dan struktur yang sama
-- Tidak akan merusak atau bertabrakan dengan data yang ada

-- =====================================================
-- 1. PROJECT TEMPLATES - Template Project yang Tersedia
-- =====================================================
CREATE TABLE IF NOT EXISTS project_templates (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    
    -- Basic Info
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    category TEXT NOT NULL, -- 'web', 'mobile', 'data', 'ai', 'game'
    difficulty_level TEXT NOT NULL CHECK (difficulty_level IN ('beginner', 'intermediate', 'advanced')),
    
    -- Project Details
    estimated_hours INTEGER,
    tech_stack JSONB DEFAULT '[]'::jsonb, -- ['React', 'Node.js', 'MongoDB']
    prerequisites JSONB DEFAULT '[]'::jsonb, -- skill yang dibutuhkan
    learning_objectives JSONB DEFAULT '[]'::jsonb, -- apa yang akan dipelajari
    
    -- Project Structure
    project_steps JSONB NOT NULL, -- step-by-step instructions
    resources JSONB DEFAULT '[]'::jsonb, -- links, tutorials, docs
    
    -- Metadata
    tags JSONB DEFAULT '[]'::jsonb,
    is_featured BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    
    -- Timestamps (consistent dengan existing schema)
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::TEXT, NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE
);

-- =====================================================
-- 2. USER PROJECTS - Project yang Dikerjakan User
-- =====================================================
CREATE TABLE IF NOT EXISTS user_projects (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL, -- menggunakan profiles, bukan auth.users
    template_id UUID REFERENCES project_templates(id) ON DELETE SET NULL,
    learning_path_id UUID REFERENCES learning_paths(id) ON DELETE SET NULL, -- optional link
    
    -- Project Info
    title TEXT NOT NULL,
    description TEXT,
    status TEXT NOT NULL DEFAULT 'not_started' CHECK (status IN ('not_started', 'in_progress', 'completed', 'paused', 'cancelled')),
    
    -- Progress Tracking
    current_step INTEGER DEFAULT 0,
    total_steps INTEGER NOT NULL,
    progress_percentage DECIMAL(5,2) DEFAULT 0.00,
    
    -- Time Tracking
    estimated_hours INTEGER,
    actual_hours_spent DECIMAL(5,2) DEFAULT 0.00,
    
    -- Project Data
    project_data JSONB DEFAULT '{}'::jsonb, -- custom data, notes, configurations
    completed_steps JSONB DEFAULT '[]'::jsonb, -- array of completed step IDs
    
    -- Dates
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    due_date TIMESTAMP WITH TIME ZONE,
    
    -- Timestamps (consistent dengan existing schema)
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::TEXT, NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE
);

-- =====================================================
-- 3. PROJECT STEP COMPLETIONS - Detail Progress per Step
-- =====================================================
CREATE TABLE IF NOT EXISTS project_step_completions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_project_id UUID REFERENCES user_projects(id) ON DELETE CASCADE NOT NULL,
    
    -- Step Info
    step_number INTEGER NOT NULL,
    step_title TEXT NOT NULL,
    
    -- Completion Data
    is_completed BOOLEAN DEFAULT FALSE,
    completion_notes TEXT,
    time_spent_minutes INTEGER DEFAULT 0,
    
    -- Files/Links
    attachments JSONB DEFAULT '[]'::jsonb, -- screenshots, files, links
    
    -- Timestamps
    completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::TEXT, NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE,
    
    UNIQUE(user_project_id, step_number)
);

-- =====================================================
-- 4. PROJECT BUILDER RECOMMENDATIONS - Enhanced Recommendations
-- =====================================================
-- Note: Tidak mengganti table project_recommendations yang sudah ada
-- Membuat table baru dengan nama berbeda untuk menghindari konflik
CREATE TABLE IF NOT EXISTS project_builder_recommendations (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    learning_path_id UUID REFERENCES learning_paths(id) ON DELETE CASCADE,
    
    -- Recommendation Data
    recommended_projects JSONB NOT NULL, -- array of project template IDs with scores
    recommendation_reason TEXT,
    
    -- Metadata
    is_viewed BOOLEAN DEFAULT FALSE,
    is_dismissed BOOLEAN DEFAULT FALSE,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::TEXT, NOW()) NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE DEFAULT (TIMEZONE('utc'::TEXT, NOW()) + INTERVAL '30 days') NOT NULL
);

-- =====================================================
-- 5. PROJECT PORTFOLIOS - Showcase Completed Projects
-- =====================================================
CREATE TABLE IF NOT EXISTS project_portfolios (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    user_project_id UUID REFERENCES user_projects(id) ON DELETE CASCADE NOT NULL,
    
    -- Portfolio Data
    title TEXT NOT NULL,
    description TEXT,
    demo_url TEXT,
    github_url TEXT,
    screenshots JSONB DEFAULT '[]'::jsonb,
    
    -- Showcase Settings
    is_public BOOLEAN DEFAULT FALSE,
    is_featured BOOLEAN DEFAULT FALSE,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::TEXT, NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE
);

-- =====================================================
-- 6. ROW LEVEL SECURITY
-- =====================================================
ALTER TABLE project_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE project_step_completions ENABLE ROW LEVEL SECURITY;
ALTER TABLE project_builder_recommendations ENABLE ROW LEVEL SECURITY;
ALTER TABLE project_portfolios ENABLE ROW LEVEL SECURITY;

-- Project Templates - Public Read (semua user bisa lihat template aktif)
DROP POLICY IF EXISTS "project_templates_select_policy" ON project_templates;
CREATE POLICY "project_templates_select_policy" ON project_templates
    FOR SELECT USING (is_active = true);

-- User Projects Policies
DROP POLICY IF EXISTS "user_projects_select_policy" ON user_projects;
CREATE POLICY "user_projects_select_policy" ON user_projects
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "user_projects_insert_policy" ON user_projects;
CREATE POLICY "user_projects_insert_policy" ON user_projects
    FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "user_projects_update_policy" ON user_projects;
CREATE POLICY "user_projects_update_policy" ON user_projects
    FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "user_projects_delete_policy" ON user_projects;
CREATE POLICY "user_projects_delete_policy" ON user_projects
    FOR DELETE USING (auth.uid() = user_id);

-- Step Completions Policies
DROP POLICY IF EXISTS "project_step_completions_policy" ON project_step_completions;
CREATE POLICY "project_step_completions_policy" ON project_step_completions
    FOR ALL USING (
        auth.uid() IN (
            SELECT user_id FROM user_projects WHERE id = user_project_id
        )
    );

-- Builder Recommendations Policies
DROP POLICY IF EXISTS "project_builder_recommendations_select_policy" ON project_builder_recommendations;
CREATE POLICY "project_builder_recommendations_select_policy" ON project_builder_recommendations
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "project_builder_recommendations_update_policy" ON project_builder_recommendations;
CREATE POLICY "project_builder_recommendations_update_policy" ON project_builder_recommendations
    FOR UPDATE USING (auth.uid() = user_id);

-- Portfolio Policies
DROP POLICY IF EXISTS "project_portfolios_manage_policy" ON project_portfolios;
CREATE POLICY "project_portfolios_manage_policy" ON project_portfolios
    FOR ALL USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "project_portfolios_public_select_policy" ON project_portfolios;
CREATE POLICY "project_portfolios_public_select_policy" ON project_portfolios
    FOR SELECT USING (is_public = true);

-- =====================================================
-- 7. INDEXES UNTUK PERFORMANCE (dengan nama unik)
-- =====================================================

-- Project Templates
CREATE INDEX IF NOT EXISTS idx_project_templates_category_pb ON project_templates(category);
CREATE INDEX IF NOT EXISTS idx_project_templates_difficulty_pb ON project_templates(difficulty_level);
CREATE INDEX IF NOT EXISTS idx_project_templates_featured_pb ON project_templates(is_featured);
CREATE INDEX IF NOT EXISTS idx_project_templates_active_pb ON project_templates(is_active);
CREATE INDEX IF NOT EXISTS idx_project_templates_tags_pb ON project_templates USING gin(tags);

-- User Projects
CREATE INDEX IF NOT EXISTS idx_user_projects_user_id_pb ON user_projects(user_id);
CREATE INDEX IF NOT EXISTS idx_user_projects_status_pb ON user_projects(status);
CREATE INDEX IF NOT EXISTS idx_user_projects_template_id_pb ON user_projects(template_id);
CREATE INDEX IF NOT EXISTS idx_user_projects_learning_path_id_pb ON user_projects(learning_path_id);
CREATE INDEX IF NOT EXISTS idx_user_projects_created_at_pb ON user_projects(created_at DESC);

-- Step Completions
CREATE INDEX IF NOT EXISTS idx_project_step_completions_project_id_pb ON project_step_completions(user_project_id);
CREATE INDEX IF NOT EXISTS idx_project_step_completions_completed_pb ON project_step_completions(is_completed);

-- Builder Recommendations
CREATE INDEX IF NOT EXISTS idx_project_builder_recommendations_user_id_pb ON project_builder_recommendations(user_id);
CREATE INDEX IF NOT EXISTS idx_project_builder_recommendations_learning_path_pb ON project_builder_recommendations(learning_path_id);
CREATE INDEX IF NOT EXISTS idx_project_builder_recommendations_expires_at_pb ON project_builder_recommendations(expires_at);

-- Portfolios
CREATE INDEX IF NOT EXISTS idx_project_portfolios_user_id_pb ON project_portfolios(user_id);
CREATE INDEX IF NOT EXISTS idx_project_portfolios_public_pb ON project_portfolios(is_public);
CREATE INDEX IF NOT EXISTS idx_project_portfolios_featured_pb ON project_portfolios(is_featured);

-- =====================================================
-- 8. TRIGGERS UNTUK AUTO UPDATE (menggunakan function existing)
-- =====================================================

-- Menggunakan function handle_updated_at() yang sudah ada
-- Tidak perlu membuat function baru

-- Auto-update timestamps untuk project builder tables
DROP TRIGGER IF EXISTS project_templates_updated_at ON project_templates;
CREATE TRIGGER project_templates_updated_at 
    BEFORE UPDATE ON project_templates
    FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

DROP TRIGGER IF EXISTS user_projects_updated_at ON user_projects;
CREATE TRIGGER user_projects_updated_at 
    BEFORE UPDATE ON user_projects
    FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

DROP TRIGGER IF EXISTS project_step_completions_updated_at ON project_step_completions;
CREATE TRIGGER project_step_completions_updated_at 
    BEFORE UPDATE ON project_step_completions
    FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

DROP TRIGGER IF EXISTS project_portfolios_updated_at ON project_portfolios;
CREATE TRIGGER project_portfolios_updated_at 
    BEFORE UPDATE ON project_portfolios
    FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

-- =====================================================
-- 9. FUNCTION UNTUK AUTO UPDATE PROGRESS
-- =====================================================

-- Function untuk update progress project secara otomatis
CREATE OR REPLACE FUNCTION public.update_project_progress()
RETURNS TRIGGER AS $$
BEGIN
    -- Update progress percentage when step completion changes
    UPDATE user_projects 
    SET 
        progress_percentage = (
            SELECT COALESCE(
                (COUNT(*) FILTER (WHERE is_completed = true) * 100.0 / NULLIF(COUNT(*), 0)),
                0
            )
            FROM project_step_completions 
            WHERE user_project_id = NEW.user_project_id
        ),
        current_step = (
            SELECT COALESCE(MAX(step_number), 0)
            FROM project_step_completions 
            WHERE user_project_id = NEW.user_project_id AND is_completed = true
        ),
        updated_at = TIMEZONE('utc'::TEXT, NOW())
    WHERE id = NEW.user_project_id;
    
    -- Auto-complete project if all steps done
    UPDATE user_projects 
    SET 
        status = 'completed',
        completed_at = TIMEZONE('utc'::TEXT, NOW())
    WHERE id = NEW.user_project_id 
        AND status != 'completed'
        AND progress_percentage >= 100;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger untuk auto-update progress
DROP TRIGGER IF EXISTS update_project_progress_trigger ON project_step_completions;
CREATE TRIGGER update_project_progress_trigger
    AFTER INSERT OR UPDATE ON project_step_completions
    FOR EACH ROW EXECUTE FUNCTION public.update_project_progress();

-- =====================================================
-- 10. VIEWS UNTUK QUERY MUDAH
-- =====================================================

CREATE OR REPLACE VIEW user_projects_with_progress AS
SELECT 
    up.*,
    pt.title as template_title,
    pt.category as template_category,
    pt.difficulty_level,
    pt.tech_stack,
    (
        SELECT COUNT(*) 
        FROM project_step_completions psc 
        WHERE psc.user_project_id = up.id AND psc.is_completed = true
    ) as completed_steps_count,
    (
        SELECT SUM(time_spent_minutes) 
        FROM project_step_completions psc 
        WHERE psc.user_project_id = up.id
    ) as total_time_spent_minutes
FROM user_projects up
LEFT JOIN project_templates pt ON up.template_id = pt.id;

CREATE OR REPLACE VIEW project_analytics AS
SELECT 
    user_id,
    COUNT(*) as total_projects,
    COUNT(*) FILTER (WHERE status = 'completed') as completed_projects,
    COUNT(*) FILTER (WHERE status = 'in_progress') as active_projects,
    AVG(progress_percentage) as avg_progress,
    SUM(actual_hours_spent) as total_hours_spent
FROM user_projects
GROUP BY user_id;

-- =====================================================
-- 11. SAMPLE PROJECT TEMPLATES
-- =====================================================

-- Insert sample project templates (hanya jika belum ada)
INSERT INTO project_templates (title, description, category, difficulty_level, estimated_hours, tech_stack, prerequisites, learning_objectives, project_steps, resources, tags) 
SELECT * FROM (VALUES 
    -- Personal Portfolio Website
    ('Personal Portfolio Website', 'Create a responsive personal portfolio website to showcase your skills and projects', 'web', 'beginner', 15, 
     '["HTML", "CSS", "JavaScript"]'::jsonb,
     '["Basic HTML/CSS knowledge", "Understanding of responsive design"]'::jsonb,
     '["HTML5 semantic elements", "CSS Grid and Flexbox", "JavaScript DOM manipulation", "Responsive design principles"]'::jsonb,
     '{"steps": [{"id": 1, "title": "Project Setup", "description": "Set up project structure and files", "estimatedHours": 1}, {"id": 2, "title": "HTML Structure", "description": "Create semantic HTML structure", "estimatedHours": 2}, {"id": 3, "title": "CSS Styling", "description": "Add styles and layout", "estimatedHours": 4}, {"id": 4, "title": "JavaScript Interactivity", "description": "Add interactive elements", "estimatedHours": 3}, {"id": 5, "title": "Responsive Design", "description": "Make it mobile-friendly", "estimatedHours": 3}, {"id": 6, "title": "Testing & Deployment", "description": "Test and deploy the website", "estimatedHours": 2}]}'::jsonb,
     '[{"title": "HTML5 Semantic Elements Guide", "url": "https://developer.mozilla.org/en-US/docs/Web/HTML/Element"}, {"title": "CSS Grid Complete Guide", "url": "https://css-tricks.com/snippets/css/complete-guide-grid/"}]'::jsonb,
     '["portfolio", "html", "css", "javascript", "responsive"]'::jsonb),

    -- Todo List App
    ('Todo List App', 'Build a functional todo list application with local storage', 'web', 'beginner', 12,
     '["HTML", "CSS", "JavaScript", "Local Storage"]'::jsonb,
     '["Basic JavaScript knowledge", "Understanding of DOM manipulation"]'::jsonb,
     '["JavaScript event handling", "Local storage API", "CRUD operations", "Array methods"]'::jsonb,
     '{"steps": [{"id": 1, "title": "HTML Structure", "description": "Create the basic HTML layout", "estimatedHours": 1}, {"id": 2, "title": "CSS Styling", "description": "Style the todo list interface", "estimatedHours": 2}, {"id": 3, "title": "Add Todo Functionality", "description": "Implement adding new todos", "estimatedHours": 2}, {"id": 4, "title": "Complete/Delete Todos", "description": "Add complete and delete features", "estimatedHours": 2}, {"id": 5, "title": "Local Storage", "description": "Persist todos in local storage", "estimatedHours": 3}, {"id": 6, "title": "Filter & Search", "description": "Add filtering and search capabilities", "estimatedHours": 2}]}'::jsonb,
     '[{"title": "JavaScript Local Storage", "url": "https://developer.mozilla.org/en-US/docs/Web/API/Window/localStorage"}]'::jsonb,
     '["todo", "javascript", "localstorage", "crud"]'::jsonb),

    -- Weather Dashboard
    ('Weather Dashboard', 'Create a weather dashboard using external APIs', 'web', 'intermediate', 20,
     '["HTML", "CSS", "JavaScript", "API Integration", "Chart.js"]'::jsonb,
     '["JavaScript fundamentals", "Understanding of APIs", "Async/await concepts"]'::jsonb,
     '["API integration", "Async JavaScript", "Data visualization", "Error handling"]'::jsonb,
     '{"steps": [{"id": 1, "title": "Project Setup", "description": "Set up project and get API keys", "estimatedHours": 2}, {"id": 2, "title": "Basic Layout", "description": "Create the dashboard layout", "estimatedHours": 3}, {"id": 3, "title": "Weather API Integration", "description": "Fetch weather data from API", "estimatedHours": 4}, {"id": 4, "title": "Display Current Weather", "description": "Show current weather information", "estimatedHours": 3}, {"id": 5, "title": "5-Day Forecast", "description": "Add 5-day weather forecast", "estimatedHours": 4}, {"id": 6, "title": "Charts & Visualization", "description": "Add weather charts using Chart.js", "estimatedHours": 4}]}'::jsonb,
     '[{"title": "OpenWeatherMap API", "url": "https://openweathermap.org/api"}, {"title": "Chart.js Documentation", "url": "https://www.chartjs.org/docs/"}]'::jsonb,
     '["weather", "api", "dashboard", "charts"]'::jsonb),

    -- Personal Finance Dashboard
    ('Personal Finance Dashboard', 'Build a comprehensive personal finance dashboard in Excel/Google Sheets', 'data', 'beginner', 18,
     '["Excel", "Google Sheets", "Data Analysis", "Charts"]'::jsonb,
     '["Basic spreadsheet knowledge", "Understanding of formulas"]'::jsonb,
     '["Advanced Excel formulas", "Data visualization", "Financial analysis", "Dashboard design"]'::jsonb,
     '{"steps": [{"id": 1, "title": "Data Structure Setup", "description": "Create data input sheets", "estimatedHours": 2}, {"id": 2, "title": "Income Tracking", "description": "Build income tracking system", "estimatedHours": 3}, {"id": 3, "title": "Expense Categories", "description": "Create expense categorization", "estimatedHours": 3}, {"id": 4, "title": "Budget vs Actual", "description": "Compare budget with actual spending", "estimatedHours": 4}, {"id": 5, "title": "Charts & Visualizations", "description": "Create visual dashboards", "estimatedHours": 4}, {"id": 6, "title": "Automated Reports", "description": "Set up automated monthly reports", "estimatedHours": 2}]}'::jsonb,
     '[{"title": "Excel Dashboard Tutorial", "url": "https://www.excel-easy.com/examples/dashboard.html"}]'::jsonb,
     '["finance", "excel", "dashboard", "data-analysis"]'::jsonb),

    -- Expense Tracker Mobile App
    ('Expense Tracker Mobile App', 'Develop a cross-platform mobile app for tracking expenses', 'mobile', 'intermediate', 35,
     '["Flutter", "Dart", "SQLite", "Charts"]'::jsonb,
     '["Basic programming knowledge", "Understanding of mobile development concepts"]'::jsonb,
     '["Flutter framework", "State management", "Local database", "Mobile UI/UX"]'::jsonb,
     '{"steps": [{"id": 1, "title": "Flutter Setup", "description": "Set up Flutter development environment", "estimatedHours": 3}, {"id": 2, "title": "App Structure", "description": "Create basic app structure and navigation", "estimatedHours": 4}, {"id": 3, "title": "Database Setup", "description": "Set up SQLite database", "estimatedHours": 4}, {"id": 4, "title": "Add Expense Feature", "description": "Implement add expense functionality", "estimatedHours": 6}, {"id": 5, "title": "Expense List & Categories", "description": "Show expenses with categories", "estimatedHours": 6}, {"id": 6, "title": "Charts & Analytics", "description": "Add expense analytics and charts", "estimatedHours": 6}, {"id": 7, "title": "Export & Backup", "description": "Add data export and backup features", "estimatedHours": 4}, {"id": 8, "title": "Testing & Polish", "description": "Test app and polish UI", "estimatedHours": 2}]}'::jsonb,
     '[{"title": "Flutter Documentation", "url": "https://flutter.dev/docs"}, {"title": "SQLite in Flutter", "url": "https://pub.dev/packages/sqflite"}]'::jsonb,
     '["mobile", "flutter", "expense-tracker", "sqlite"]'::jsonb)
) AS new_templates(title, description, category, difficulty_level, estimated_hours, tech_stack, prerequisites, learning_objectives, project_steps, resources, tags)
WHERE NOT EXISTS (
    SELECT 1 FROM project_templates WHERE title = new_templates.title
);

-- =====================================================
-- SETUP COMPLETE!
-- =====================================================
-- Schema project builder telah berhasil dibuat dengan:
-- ✅ Kompatibilitas penuh dengan database existing
-- ✅ Tidak ada konflik naming atau struktur
-- ✅ Menggunakan profiles(id) bukan auth.users(id)
-- ✅ Consistent timestamp format dengan existing schema
-- ✅ Unique index names dengan suffix _pb
-- ✅ Unique policy names untuk menghindari konflik
-- ✅ Menggunakan function handle_updated_at() yang sudah ada
-- ✅ Sample data yang tidak duplikat

-- Test queries:
-- SELECT * FROM project_templates WHERE difficulty_level = 'beginner';
-- SELECT * FROM user_projects_with_progress WHERE user_id = auth.uid();
-- SELECT * FROM project_analytics WHERE user_id = auth.uid();
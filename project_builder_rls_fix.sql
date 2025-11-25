-- =====================================================
-- PROJECT BUILDER RLS POLICIES FIX
-- =====================================================
-- Script untuk memperbaiki RLS policies yang mungkin menyebabkan masalah

-- 1. Drop existing policies
DROP POLICY IF EXISTS "project_templates_select_policy" ON project_templates;
DROP POLICY IF EXISTS "user_projects_policy" ON user_projects;
DROP POLICY IF EXISTS "project_step_completions_policy" ON project_step_completions;

-- 2. Create more permissive policies for testing

-- Project Templates - Allow all authenticated users to read
CREATE POLICY "project_templates_select_policy" ON project_templates
    FOR SELECT 
    USING (auth.role() = 'authenticated' AND is_active = true);

-- User Projects - Allow users to manage their own projects
CREATE POLICY "user_projects_select_policy" ON user_projects
    FOR SELECT 
    USING (auth.uid()::text = user_id::text);

CREATE POLICY "user_projects_insert_policy" ON user_projects
    FOR INSERT 
    WITH CHECK (auth.uid()::text = user_id::text);

CREATE POLICY "user_projects_update_policy" ON user_projects
    FOR UPDATE 
    USING (auth.uid()::text = user_id::text)
    WITH CHECK (auth.uid()::text = user_id::text);

CREATE POLICY "user_projects_delete_policy" ON user_projects
    FOR DELETE 
    USING (auth.uid()::text = user_id::text);

-- Project Step Completions - Allow users to manage steps for their projects
CREATE POLICY "project_step_completions_select_policy" ON project_step_completions
    FOR SELECT 
    USING (
        auth.uid()::text IN (
            SELECT user_id::text FROM user_projects WHERE id = user_project_id
        )
    );

CREATE POLICY "project_step_completions_insert_policy" ON project_step_completions
    FOR INSERT 
    WITH CHECK (
        auth.uid()::text IN (
            SELECT user_id::text FROM user_projects WHERE id = user_project_id
        )
    );

CREATE POLICY "project_step_completions_update_policy" ON project_step_completions
    FOR UPDATE 
    USING (
        auth.uid()::text IN (
            SELECT user_id::text FROM user_projects WHERE id = user_project_id
        )
    )
    WITH CHECK (
        auth.uid()::text IN (
            SELECT user_id::text FROM user_projects WHERE id = user_project_id
        )
    );

CREATE POLICY "project_step_completions_delete_policy" ON project_step_completions
    FOR DELETE 
    USING (
        auth.uid()::text IN (
            SELECT user_id::text FROM user_projects WHERE id = user_project_id
        )
    );

-- 3. Test the policies
SELECT 'RLS Policies Updated Successfully' as status;

-- 4. Check current user and test data access
SELECT 
    'Current User: ' || COALESCE(auth.uid()::text, 'Not authenticated') as auth_status;

-- Test template access
SELECT 
    'Templates accessible: ' || COUNT(*)::text as template_test
FROM project_templates 
WHERE is_active = true;

-- Test user projects access (will show 0 if no projects for current user)
SELECT 
    'User projects accessible: ' || COUNT(*)::text as user_projects_test
FROM user_projects 
WHERE user_id = auth.uid();

-- =====================================================
-- TROUBLESHOOTING NOTES
-- =====================================================
-- If you still have issues:
-- 1. Make sure you're authenticated in Supabase
-- 2. Check that auth.uid() returns your user ID
-- 3. Verify that user_id in user_projects matches auth.uid()
-- 4. Consider temporarily disabling RLS for testing:
--    ALTER TABLE user_projects DISABLE ROW LEVEL SECURITY;
--    (Remember to re-enable it later!)
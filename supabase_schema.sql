-- =====================================================
-- Upwise App - Supabase Database Schema
-- =====================================================
-- This file contains the complete database schema for the Upwise app
-- Run this in your Supabase SQL editor after creating your project

-- Enable Row Level Security
ALTER DEFAULT PRIVILEGES REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC;

-- =====================================================
-- 1. PROFILES TABLE (User Management)
-- =====================================================
CREATE TABLE IF NOT EXISTS profiles (
    id UUID REFERENCES auth.users(id) PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    name TEXT,
    avatar_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::TEXT, NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE,
    current_streak INTEGER DEFAULT 0,
    longest_streak INTEGER DEFAULT 0,
    last_active_date TIMESTAMP WITH TIME ZONE
);

-- Enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- RLS Policies for profiles
CREATE POLICY "Users can view own profile" ON profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON profiles
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

-- =====================================================
-- 2. LEARNING PATHS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS learning_paths (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    topic TEXT NOT NULL,
    description TEXT NOT NULL,
    duration_days INTEGER NOT NULL,
    daily_time_minutes INTEGER NOT NULL,
    experience_level TEXT NOT NULL CHECK (experience_level IN ('beginner', 'intermediate', 'advanced')),
    learning_style TEXT NOT NULL CHECK (learning_style IN ('visual', 'auditory', 'kinesthetic', 'readingWriting')),
    output_goal TEXT NOT NULL,
    include_projects BOOLEAN DEFAULT FALSE,
    include_exercises BOOLEAN DEFAULT FALSE,
    notes TEXT,
    status TEXT DEFAULT 'notStarted' CHECK (status IN ('notStarted', 'inProgress', 'completed', 'paused')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::TEXT, NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE,
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE
);

-- Enable RLS
ALTER TABLE learning_paths ENABLE ROW LEVEL SECURITY;

-- RLS Policies for learning_paths
CREATE POLICY "Users can view own learning paths" ON learning_paths
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own learning paths" ON learning_paths
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own learning paths" ON learning_paths
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own learning paths" ON learning_paths
    FOR DELETE USING (auth.uid() = user_id);

-- =====================================================
-- 3. DAILY LEARNING TASKS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS daily_learning_tasks (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    learning_path_id UUID REFERENCES learning_paths(id) ON DELETE CASCADE NOT NULL,
    day_number INTEGER NOT NULL,
    main_topic TEXT NOT NULL,
    sub_topic TEXT NOT NULL,
    material_url TEXT,
    material_title TEXT,
    exercise TEXT,
    status TEXT DEFAULT 'notStarted' CHECK (status IN ('notStarted', 'inProgress', 'completed', 'skipped')),
    completed_at TIMESTAMP WITH TIME ZONE,
    time_spent_minutes INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::TEXT, NOW()) NOT NULL,
    UNIQUE(learning_path_id, day_number)
);

-- Enable RLS
ALTER TABLE daily_learning_tasks ENABLE ROW LEVEL SECURITY;

-- RLS Policies for daily_learning_tasks
CREATE POLICY "Users can view own tasks" ON daily_learning_tasks
    FOR SELECT USING (
        auth.uid() IN (
            SELECT user_id FROM learning_paths WHERE id = learning_path_id
        )
    );

CREATE POLICY "Users can insert own tasks" ON daily_learning_tasks
    FOR INSERT WITH CHECK (
        auth.uid() IN (
            SELECT user_id FROM learning_paths WHERE id = learning_path_id
        )
    );

CREATE POLICY "Users can update own tasks" ON daily_learning_tasks
    FOR UPDATE USING (
        auth.uid() IN (
            SELECT user_id FROM learning_paths WHERE id = learning_path_id
        )
    );

CREATE POLICY "Users can delete own tasks" ON daily_learning_tasks
    FOR DELETE USING (
        auth.uid() IN (
            SELECT user_id FROM learning_paths WHERE id = learning_path_id
        )
    );

-- =====================================================
-- 4. PROJECT RECOMMENDATIONS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS project_recommendations (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    learning_path_id UUID REFERENCES learning_paths(id) ON DELETE CASCADE NOT NULL,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    url TEXT,
    difficulty TEXT,
    estimated_hours INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::TEXT, NOW()) NOT NULL
);

-- Enable RLS
ALTER TABLE project_recommendations ENABLE ROW LEVEL SECURITY;

-- RLS Policies for project_recommendations
CREATE POLICY "Users can view own project recommendations" ON project_recommendations
    FOR SELECT USING (
        auth.uid() IN (
            SELECT user_id FROM learning_paths WHERE id = learning_path_id
        )
    );

CREATE POLICY "Users can insert own project recommendations" ON project_recommendations
    FOR INSERT WITH CHECK (
        auth.uid() IN (
            SELECT user_id FROM learning_paths WHERE id = learning_path_id
        )
    );

CREATE POLICY "Users can update own project recommendations" ON project_recommendations
    FOR UPDATE USING (
        auth.uid() IN (
            SELECT user_id FROM learning_paths WHERE id = learning_path_id
        )
    );

CREATE POLICY "Users can delete own project recommendations" ON project_recommendations
    FOR DELETE USING (
        auth.uid() IN (
            SELECT user_id FROM learning_paths WHERE id = learning_path_id
        )
    );

-- =====================================================
-- 5. INDEXES FOR PERFORMANCE
-- =====================================================
CREATE INDEX IF NOT EXISTS idx_learning_paths_user_id ON learning_paths(user_id);
CREATE INDEX IF NOT EXISTS idx_learning_paths_status ON learning_paths(status);
CREATE INDEX IF NOT EXISTS idx_learning_paths_created_at ON learning_paths(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_daily_tasks_learning_path_id ON daily_learning_tasks(learning_path_id);
CREATE INDEX IF NOT EXISTS idx_daily_tasks_day_number ON daily_learning_tasks(day_number);
CREATE INDEX IF NOT EXISTS idx_daily_tasks_status ON daily_learning_tasks(status);

CREATE INDEX IF NOT EXISTS idx_project_recommendations_learning_path_id ON project_recommendations(learning_path_id);

CREATE INDEX IF NOT EXISTS idx_profiles_last_active_date ON profiles(last_active_date DESC);

-- =====================================================
-- 6. FUNCTIONS AND TRIGGERS
-- =====================================================

-- Function to automatically create profile when user signs up
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, email, name, created_at)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'name', ''),
        NOW()
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to run the function
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = TIMEZONE('utc'::TEXT, NOW());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers for updated_at
CREATE TRIGGER profiles_updated_at BEFORE UPDATE ON profiles
    FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

CREATE TRIGGER learning_paths_updated_at BEFORE UPDATE ON learning_paths
    FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

-- Function to update streak when task is completed
CREATE OR REPLACE FUNCTION public.update_user_streak()
RETURNS TRIGGER AS $$
BEGIN
    -- Only update streak when task status changes to completed
    IF NEW.status = 'completed' AND (OLD.status IS NULL OR OLD.status != 'completed') THEN
        UPDATE profiles 
        SET 
            last_active_date = CURRENT_DATE,
            current_streak = CASE 
                WHEN last_active_date = CURRENT_DATE - INTERVAL '1 day' OR last_active_date IS NULL 
                THEN current_streak + 1
                WHEN last_active_date = CURRENT_DATE 
                THEN current_streak
                ELSE 1
            END,
            longest_streak = GREATEST(
                longest_streak, 
                CASE 
                    WHEN last_active_date = CURRENT_DATE - INTERVAL '1 day' OR last_active_date IS NULL 
                    THEN current_streak + 1
                    WHEN last_active_date = CURRENT_DATE 
                    THEN current_streak
                    ELSE 1
                END
            )
        WHERE id = (
            SELECT user_id FROM learning_paths 
            WHERE id = NEW.learning_path_id
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger for streak updates
CREATE TRIGGER daily_task_completed AFTER UPDATE ON daily_learning_tasks
    FOR EACH ROW EXECUTE PROCEDURE public.update_user_streak();

-- =====================================================
-- 7. SAMPLE DATA (Optional - for testing)
-- =====================================================
-- Uncomment below to insert sample data for testing

/*
-- Sample learning path data
INSERT INTO learning_paths (
    id, user_id, topic, description, duration_days, daily_time_minutes,
    experience_level, learning_style, output_goal, include_projects, include_exercises
) VALUES (
    gen_random_uuid(),
    '00000000-0000-0000-0000-000000000000', -- Replace with actual user ID
    'Python Programming',
    'Complete beginner course in Python programming',
    30,
    60,
    'beginner',
    'visual',
    'Build a web application using Python',
    true,
    true
);
*/

-- =====================================================
-- SETUP COMPLETE
-- =====================================================
-- After running this schema:
-- 1. Your database tables will be created
-- 2. Row Level Security will be enabled
-- 3. Automatic profile creation will be set up
-- 4. Streak tracking will be automated
-- 5. All necessary indexes will be created

-- Next steps:
-- 1. Get your Supabase URL and anon key from Project Settings > API
-- 2. Update your .env file with these credentials
-- 3. Test the connection with your Flutter app
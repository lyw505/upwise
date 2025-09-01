# Supabase Setup Guide for Upwise

This guide will help you set up Supabase backend for the Upwise application.

## 1. Create Supabase Project

1. Go to [supabase.com](https://supabase.com)
2. Sign up or log in to your account
3. Click "New Project"
4. Fill in the project details:
   - Name: `upwise`
   - Database Password: Choose a strong password
   - Region: Choose the closest region to your users
5. Click "Create new project"

## 2. Database Schema

Once your project is created, go to the SQL Editor and run the following SQL commands:

### Create Profiles Table

```sql
-- Create a table for user profiles
CREATE TABLE profiles (
  id UUID REFERENCES auth.users NOT NULL PRIMARY KEY,
  email TEXT NOT NULL,
  name TEXT,
  avatar_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  current_streak INTEGER DEFAULT 0,
  longest_streak INTEGER DEFAULT 0,
  last_active_date TIMESTAMP WITH TIME ZONE
);

-- Set up Row Level Security (RLS)
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Public profiles are viewable by everyone." 
ON profiles FOR SELECT 
USING (true);

CREATE POLICY "Users can insert their own profile." 
ON profiles FOR INSERT 
WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update own profile." 
ON profiles FOR UPDATE 
USING (auth.uid() = id);
```

### Create Learning Paths Table

```sql
-- Create learning paths table
CREATE TABLE learning_paths (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users NOT NULL,
  topic TEXT NOT NULL,
  description TEXT,
  duration_days INTEGER NOT NULL,
  daily_time_minutes INTEGER NOT NULL,
  experience_level TEXT NOT NULL CHECK (experience_level IN ('beginner', 'intermediate', 'advanced')),
  learning_style TEXT NOT NULL CHECK (learning_style IN ('visual', 'auditory', 'kinesthetic', 'readingWriting')),
  output_goal TEXT NOT NULL,
  include_projects BOOLEAN DEFAULT FALSE,
  include_exercises BOOLEAN DEFAULT FALSE,
  notes TEXT,
  status TEXT DEFAULT 'notStarted' CHECK (status IN ('notStarted', 'inProgress', 'completed', 'paused')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  started_at TIMESTAMP WITH TIME ZONE,
  completed_at TIMESTAMP WITH TIME ZONE
);

-- Set up RLS
ALTER TABLE learning_paths ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can view own learning paths." 
ON learning_paths FOR SELECT 
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own learning paths." 
ON learning_paths FOR INSERT 
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own learning paths." 
ON learning_paths FOR UPDATE 
USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own learning paths." 
ON learning_paths FOR DELETE 
USING (auth.uid() = user_id);
```

### Create Daily Tasks Table

```sql
-- Create daily tasks table
CREATE TABLE daily_tasks (
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
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Set up RLS
ALTER TABLE daily_tasks ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can view tasks from own learning paths." 
ON daily_tasks FOR SELECT 
USING (
  learning_path_id IN (
    SELECT id FROM learning_paths WHERE user_id = auth.uid()
  )
);

CREATE POLICY "Users can insert tasks for own learning paths." 
ON daily_tasks FOR INSERT 
WITH CHECK (
  learning_path_id IN (
    SELECT id FROM learning_paths WHERE user_id = auth.uid()
  )
);

CREATE POLICY "Users can update tasks from own learning paths." 
ON daily_tasks FOR UPDATE 
USING (
  learning_path_id IN (
    SELECT id FROM learning_paths WHERE user_id = auth.uid()
  )
);

CREATE POLICY "Users can delete tasks from own learning paths." 
ON daily_tasks FOR DELETE 
USING (
  learning_path_id IN (
    SELECT id FROM learning_paths WHERE user_id = auth.uid()
  )
);
```

### Create Project Recommendations Table

```sql
-- Create project recommendations table
CREATE TABLE project_recommendations (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  learning_path_id UUID REFERENCES learning_paths(id) ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  url TEXT,
  difficulty TEXT CHECK (difficulty IN ('beginner', 'intermediate', 'advanced')),
  estimated_hours INTEGER,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Set up RLS
ALTER TABLE project_recommendations ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can view project recommendations from own learning paths." 
ON project_recommendations FOR SELECT 
USING (
  learning_path_id IN (
    SELECT id FROM learning_paths WHERE user_id = auth.uid()
  )
);

CREATE POLICY "Users can insert project recommendations for own learning paths." 
ON project_recommendations FOR INSERT 
WITH CHECK (
  learning_path_id IN (
    SELECT id FROM learning_paths WHERE user_id = auth.uid()
  )
);

CREATE POLICY "Users can update project recommendations from own learning paths." 
ON project_recommendations FOR UPDATE 
USING (
  learning_path_id IN (
    SELECT id FROM learning_paths WHERE user_id = auth.uid()
  )
);

CREATE POLICY "Users can delete project recommendations from own learning paths." 
ON project_recommendations FOR DELETE 
USING (
  learning_path_id IN (
    SELECT id FROM learning_paths WHERE user_id = auth.uid()
  )
);
```

## 3. Get API Keys

1. Go to Settings > API in your Supabase dashboard
2. Copy the following values:
   - Project URL
   - Anon public key

## 4. Configure Flutter App

1. Open `lib/main.dart`
2. Replace the placeholder values:
   ```dart
   await Supabase.initialize(
     url: 'YOUR_SUPABASE_URL', // Replace with your Project URL
     anonKey: 'YOUR_SUPABASE_ANON_KEY', // Replace with your Anon public key
   );
   ```

## 5. Set up Google Gemini API (Optional)

1. Go to [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Create a new API key
3. Open `lib/services/gemini_service.dart`
4. Replace the placeholder:
   ```dart
   static const String _apiKey = 'YOUR_GEMINI_API_KEY'; // Replace with your API key
   ```

## 6. Authentication Setup

The authentication is already configured to work with Supabase Auth. Users can:
- Sign up with email and password
- Sign in with email and password
- Reset password (feature to be implemented)

## 7. Testing the Setup

1. Run the Flutter app
2. Try creating a new account
3. Check your Supabase dashboard to see if the user was created in the Authentication section
4. Check if a profile was created in the profiles table

## Troubleshooting

### Common Issues:

1. **RLS Policies**: Make sure all RLS policies are correctly set up
2. **API Keys**: Ensure you're using the correct Project URL and Anon key
3. **Network**: Check if your network allows connections to Supabase

### Useful Supabase Commands:

```sql
-- Check if user profiles are being created
SELECT * FROM profiles;

-- Check learning paths
SELECT * FROM learning_paths;

-- Check daily tasks
SELECT * FROM daily_tasks;

-- Check project recommendations
SELECT * FROM project_recommendations;
```

# Supabase Project Configuration

## Project Details

- **Project Name**: upwise
- **Project ID**: wecizrgxuibhxledozpq
- **Region**: ap-southeast-1 (Southeast Asia - Singapore)
- **Status**: ACTIVE_HEALTHY
- **Database Version**: PostgreSQL 17.4.1.069

## API Configuration

- **Project URL**: `https://wecizrgxuibhxledozpq.supabase.co`
- **Anon Key**: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndlY2l6cmd4dWliaHhsZWRvenBxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQ5NzExMjYsImV4cCI6MjA3MDU0NzEyNn0.6uIMc70gVSPsY_h9NZR284J3n3PQByYvfl0vzmp0bXc`

## Database Schema

### Tables Created:

#### 1. profiles
- **Purpose**: User profile information with streak tracking
- **Columns**:
  - `id` (UUID, PRIMARY KEY) - References auth.users
  - `email` (TEXT, NOT NULL)
  - `name` (TEXT, NULLABLE)
  - `avatar_url` (TEXT, NULLABLE)
  - `created_at` (TIMESTAMP WITH TIME ZONE)
  - `updated_at` (TIMESTAMP WITH TIME ZONE)
  - `current_streak` (INTEGER, DEFAULT 0)
  - `longest_streak` (INTEGER, DEFAULT 0)
  - `last_active_date` (TIMESTAMP WITH TIME ZONE)

#### 2. learning_paths
- **Purpose**: AI-generated learning paths
- **Columns**:
  - `id` (UUID, PRIMARY KEY)
  - `user_id` (UUID, NOT NULL) - References auth.users
  - `topic` (TEXT, NOT NULL)
  - `description` (TEXT)
  - `duration_days` (INTEGER, NOT NULL)
  - `daily_time_minutes` (INTEGER, NOT NULL)
  - `experience_level` (TEXT, CHECK: beginner/intermediate/advanced)
  - `learning_style` (TEXT, CHECK: visual/auditory/kinesthetic/readingWriting)
  - `output_goal` (TEXT, NOT NULL)
  - `include_projects` (BOOLEAN, DEFAULT FALSE)
  - `include_exercises` (BOOLEAN, DEFAULT FALSE)
  - `notes` (TEXT)
  - `status` (TEXT, CHECK: notStarted/inProgress/completed/paused)
  - `created_at`, `updated_at`, `started_at`, `completed_at` (TIMESTAMPS)

#### 3. daily_tasks
- **Purpose**: Daily learning tasks for each learning path
- **Columns**:
  - `id` (UUID, PRIMARY KEY)
  - `learning_path_id` (UUID, NOT NULL) - References learning_paths(id)
  - `day_number` (INTEGER, NOT NULL)
  - `main_topic` (TEXT, NOT NULL)
  - `sub_topic` (TEXT, NOT NULL)
  - `material_url` (TEXT)
  - `material_title` (TEXT)
  - `exercise` (TEXT)
  - `status` (TEXT, CHECK: notStarted/inProgress/completed/skipped)
  - `completed_at` (TIMESTAMP WITH TIME ZONE)
  - `time_spent_minutes` (INTEGER)
  - `created_at` (TIMESTAMP WITH TIME ZONE)

#### 4. project_recommendations
- **Purpose**: Project recommendations for learning paths
- **Columns**:
  - `id` (UUID, PRIMARY KEY)
  - `learning_path_id` (UUID, NOT NULL) - References learning_paths(id)
  - `title` (TEXT, NOT NULL)
  - `description` (TEXT, NOT NULL)
  - `url` (TEXT)
  - `difficulty` (TEXT, CHECK: beginner/intermediate/advanced)
  - `estimated_hours` (INTEGER)
  - `created_at` (TIMESTAMP WITH TIME ZONE)

## Row Level Security (RLS)

All tables have RLS enabled with appropriate policies:

### profiles
- Public read access
- Users can insert/update their own profile

### learning_paths
- Users can only access their own learning paths
- Full CRUD operations for own data

### daily_tasks
- Users can only access tasks from their own learning paths
- Full CRUD operations for own data

### project_recommendations
- Users can only access recommendations from their own learning paths
- Full CRUD operations for own data

## Authentication Configuration

- **Email/Password**: Enabled
- **Email Confirmations**: Disabled (for development)
- **Site URL**: http://localhost:8080 (development)

## Integration Status

✅ **Database Schema**: All tables created with proper constraints and RLS
✅ **API Keys**: Configured in Flutter app
✅ **Connection**: Tested and working
✅ **Authentication**: Ready for user registration/login
✅ **Security**: RLS policies implemented

## Next Steps

The Supabase backend is now fully configured and ready for:
1. User registration and authentication
2. Learning path creation and management
3. Daily task tracking
4. Progress analytics
5. Project recommendations

All Flutter providers are configured to work with this database schema.

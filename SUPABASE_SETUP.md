# 🚀 Upwise Supabase Backend Setup Guide

## Step 1: Create Supabase Project

1. **Go to Supabase Dashboard**
   - Visit: https://app.supabase.com
   - Sign in with your account

2. **Create New Project**
   - Click "New Project"
   - Name: `upwise-first` (or your preferred name)
   - Choose a region close to your users
   - Generate a strong database password
   - Click "Create new project"

3. **Wait for Setup**
   - Project creation takes ~2 minutes
   - Wait until status shows "Active"

## Step 2: Get Project Credentials

1. **Navigate to Project Settings**
   - Click on your project
   - Go to `Settings` → `API`

2. **Copy Project URL and Keys**
   ```
   Project URL: https://your-project-ref.supabase.co
   anon public key: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
   ```

## Step 3: Configure Environment Variables

1. **Update `.env` file**
   Replace the placeholders in your `.env` file:
   ```env
   # Supabase Configuration
   SUPABASE_URL=https://your-project-ref.supabase.co
   SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
   
   # Google Gemini AI Configuration
   GEMINI_API_KEY=AIzaSyAB7DAlcP6M9LH7lJWquEPIXHOnQ_ibxME
   ```

## Step 4: Set Up Database Schema

1. **Open SQL Editor**
   - In your Supabase dashboard
   - Go to `SQL Editor`

2. **Run Schema Script**
   - Copy the entire content of `supabase_schema.sql`
   - Paste it into the SQL Editor
   - Click "Run" to execute

3. **Verify Tables Created**
   - Go to `Table Editor`
   - You should see these tables:
     - `profiles`
     - `learning_paths`
     - `daily_learning_tasks`
     - `project_recommendations`

## Step 5: Configure Authentication

1. **Enable Email Authentication**
   - Go to `Authentication` → `Settings`
   - Ensure "Enable email confirmations" is configured as needed
   - For development, you can disable email confirmations

2. **Set Up Auth Policies**
   - The schema includes Row Level Security (RLS)
   - Users can only access their own data
   - Policies are automatically created by the schema

## Step 6: Test the Connection

1. **Run Flutter App**
   ```bash
   flutter pub get
   flutter run
   ```

2. **Test Registration**
   - Open the app
   - Try creating a new account
   - Check if profile is created in Supabase

3. **Test Learning Path Creation**
   - Create a new learning path
   - Verify data appears in `learning_paths` table

## Step 7: Verify Database Functions

The schema includes several automated features:

### ✅ Automatic Profile Creation
- When user signs up, profile is auto-created
- Check `profiles` table after registration

### ✅ Streak Tracking
- Completing tasks updates user streaks
- Test by marking tasks as complete

### ✅ Timestamp Management
- `updated_at` fields are automatically maintained
- No manual intervention needed

## Troubleshooting

### Common Issues

#### ❌ "Invalid API credentials"
**Solution**: Double-check your SUPABASE_URL and SUPABASE_ANON_KEY in `.env`

#### ❌ "Row Level Security policy violation"
**Solution**: Ensure you're signed in when testing, RLS blocks unauthorized access

#### ❌ "Table does not exist"
**Solution**: Re-run the schema script in SQL Editor

#### ❌ "Authentication not working"
**Solution**: Check Authentication settings in Supabase dashboard

### Debug Steps

1. **Check Environment Loading**
   ```dart
   // Add to your app for debugging
   print('Supabase URL: ${EnvConfig.supabaseUrl}');
   print('Supabase Key: ${EnvConfig.supabaseAnonKey.substring(0, 20)}...');
   ```

2. **Verify Database Connection**
   ```dart
   // Test in your app
   final response = await Supabase.instance.client
       .from('profiles')
       .select()
       .limit(1);
   print('Database connected: ${response.length}');
   ```

3. **Check RLS Policies**
   - Go to `Authentication` → `Users`
   - Verify users are being created
   - Check `profiles` table for corresponding entries

## Production Considerations

### Security
- ✅ RLS is enabled on all tables
- ✅ Users can only access their own data
- ✅ API keys are environment-specific

### Performance
- ✅ Indexes are created for common queries
- ✅ Foreign key constraints maintain data integrity
- ✅ Automatic cleanup on user deletion

### Backup
- Supabase automatically backs up your database
- Consider exporting schema for version control

## Next Steps

After successful setup:

1. **Test All Features**
   - User registration/login
   - Learning path creation
   - Daily task management
   - Streak tracking

2. **Deploy to Production**
   - Use environment-specific Supabase projects
   - Configure production authentication settings
   - Set up monitoring and alerts

3. **Monitor Usage**
   - Check Supabase dashboard for API usage
   - Monitor database performance
   - Set up error tracking

## Support

- **Supabase Docs**: https://supabase.com/docs
- **Flutter Integration**: https://supabase.com/docs/reference/dart
- **Project Repository**: Check README.md for additional setup instructions

---

🎉 **Your Upwise backend is now ready!** The app should work exactly as it did before with full Supabase integration.
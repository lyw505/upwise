# Upwise App - Setup Guide

## 🚨 Critical Issues Fixed

### Security Issues Resolved
- ✅ Removed hardcoded API keys from source code
- ✅ Updated environment configuration to require proper .env file
- ✅ Enhanced validation logic for missing credentials

## 📋 Required Setup Steps

### 1. Create Environment File
Create a `.env` file in the project root with your actual credentials:

```env
# Supabase Configuration
SUPABASE_URL=your_actual_supabase_project_url_here
SUPABASE_ANON_KEY=your_actual_supabase_anon_key_here

# Google Gemini AI Configuration
GEMINI_API_KEY=your_actual_gemini_api_key_here

# Optional Configuration
APP_ENV=development
DEBUG_MODE=true
API_TIMEOUT=30000
MAX_RETRIES=3
ENABLE_ANALYTICS=true
ENABLE_NOTIFICATIONS=true
ENABLE_OFFLINE_MODE=false
```

### 2. Get Your API Keys

#### Supabase Setup
1. Go to [Supabase Dashboard](https://app.supabase.com)
2. Create a new project or select existing one
3. Go to Settings → API
4. Copy your Project URL and anon/public key
5. Run the SQL schema from `supabase_schema.sql`

#### Google Gemini API Setup
1. Go to [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Create a new API key
3. Copy the key to your .env file

### 3. Install Dependencies
```bash
flutter pub get
```

### 4. Run the App
```bash
flutter run
```

### 5. Verify Setup
- Open app → Dashboard → Menu → "Config Status"
- Ensure all configurations show ✅
- Test authentication and AI features

## 🔧 What Was Fixed

### Security Improvements
- **Before**: API keys were hardcoded in `env_config.dart`
- **After**: App requires proper .env file with actual credentials
- **Impact**: No more exposed credentials in source code

### Configuration Validation
- Enhanced validation logic to check for empty credentials
- Better error messages for missing configuration
- Improved development experience with clear setup instructions

### Error Handling
- App will now properly fail if credentials are missing
- Clear error messages guide users to setup requirements
- Development vs production environment handling

## 🏗️ Architecture Overview

Your app has excellent architecture with:
- ✅ Clean Provider pattern for state management
- ✅ Proper Go Router navigation setup
- ✅ Well-structured folder organization
- ✅ Comprehensive error handling and fallbacks
- ✅ Modern Material Design 3 theming
- ✅ Proper separation of concerns

## 🚀 Next Steps

1. **Create your .env file** with actual credentials
2. **Test the authentication flow** with Supabase
3. **Verify AI features** work with Gemini API
4. **Run the app** and check Config Status screen
5. **Deploy** following the deployment guides in the docs folder

## 📚 Additional Resources

- [Supabase Setup Guide](SUPABASE_SETUP.md)
- [API Setup Guide](README_API_SETUP.md)
- [Main README](README.md)

## ⚠️ Important Notes

- Never commit the `.env` file to version control
- The `.env` file is already in `.gitignore`
- Use different credentials for development and production
- Test all features after setup to ensure everything works

---

**Status**: ✅ Security issues resolved, app ready for proper configuration

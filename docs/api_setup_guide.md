# API Setup Guide - Upwise

## Overview

This guide will help you configure the real API keys for Upwise application to enable full AI-powered learning path generation.

## Required API Keys

### 1. Google Gemini API Key

**Purpose**: AI-powered learning path generation
**Service**: Google Gemini (Gemma 3)
**Cost**: Free tier available with generous limits

#### How to Get Gemini API Key:

1. **Visit Google AI Studio**
   - Go to: https://makersuite.google.com/app/apikey
   - Sign in with your Google account

2. **Create API Key**
   - Click "Create API Key"
   - Choose your Google Cloud project (or create new one)
   - Copy the generated API key

3. **Configure in Upwise**
   - Open `.env` file in project root
   - Replace `your_gemini_api_key_here` with your actual API key:
   ```
   GEMINI_API_KEY=your_actual_api_key_here
   ```

#### API Limits (Free Tier):
- **Requests**: 60 requests per minute
- **Tokens**: 1 million tokens per month
- **Rate Limit**: 1 request per second

### 2. Supabase Configuration (Optional)

**Purpose**: Database and authentication
**Current Status**: Already configured with default project
**When to Update**: If you want to use your own Supabase project

#### How to Setup Your Own Supabase:

1. **Create Supabase Project**
   - Go to: https://supabase.com
   - Create new project
   - Wait for setup to complete

2. **Get Project Credentials**
   - Go to Project Settings > API
   - Copy Project URL and anon public key

3. **Configure in Upwise**
   ```
   SUPABASE_URL=your_supabase_project_url
   SUPABASE_ANON_KEY=your_supabase_anon_key
   ```

4. **Setup Database Schema**
   - Run the SQL scripts from `docs/database_schema.sql`
   - Configure Row Level Security (RLS) policies

## Environment Configuration

### File Structure
```
upwise/
├── .env                 # Your actual API keys (DO NOT COMMIT)
├── .env.example         # Template file (safe to commit)
└── lib/core/config/
    └── env_config.dart  # Environment configuration class
```

### Configuration Options

```bash
# Google Gemini API Configuration
GEMINI_API_KEY=your_actual_gemini_api_key_here

# Supabase Configuration (optional)
SUPABASE_URL=your_supabase_project_url_here
SUPABASE_ANON_KEY=your_supabase_anon_key_here

# App Configuration
APP_ENV=development
DEBUG_MODE=true

# API Configuration
API_TIMEOUT=30000
MAX_RETRIES=3

# Feature Flags
ENABLE_ANALYTICS=true
ENABLE_NOTIFICATIONS=true
ENABLE_OFFLINE_MODE=false
```

## Setup Instructions

### Step 1: Copy Environment File
```bash
cp .env.example .env
```

### Step 2: Configure API Keys
Edit `.env` file and replace placeholder values:
- Get Gemini API key from Google AI Studio
- (Optional) Configure your own Supabase project

### Step 3: Install Dependencies
```bash
flutter pub get
```

### Step 4: Test Configuration
```bash
flutter run
```

The app will automatically detect if API keys are configured and use real AI generation or fallback to mock data.

## Verification

### Check Configuration Status
The app will show configuration status in debug mode:
- ✅ **Real AI**: Gemini API key configured
- ⚠️ **Fallback**: Using mock data (API key not configured)

### Test AI Generation
1. Create a new learning path
2. Fill in the form with your learning topic
3. Submit and verify:
   - **Real AI**: Unique, contextual learning plan
   - **Fallback**: Generic template-based plan

## Troubleshooting

### Common Issues

#### 1. "API key not configured" Message
**Problem**: Gemini API key not set or invalid
**Solution**: 
- Check `.env` file exists
- Verify API key is correct
- Ensure no extra spaces or quotes

#### 2. "Failed to load .env file"
**Problem**: Environment file not found
**Solution**:
- Create `.env` file from `.env.example`
- Ensure file is in project root directory

#### 3. API Rate Limit Exceeded
**Problem**: Too many requests to Gemini API
**Solution**:
- Wait for rate limit to reset (1 minute)
- Consider upgrading to paid tier for higher limits

#### 4. Invalid API Response
**Problem**: Malformed response from Gemini API
**Solution**:
- Check API key permissions
- Verify internet connection
- App will automatically fallback to mock data

### Debug Mode

Enable debug logging by setting:
```bash
DEBUG_MODE=true
```

This will show:
- API request/response details
- Configuration validation results
- Fallback activation reasons

## Security Best Practices

### API Key Security
- ✅ **DO**: Keep API keys in `.env` file
- ✅ **DO**: Add `.env` to `.gitignore`
- ❌ **DON'T**: Commit API keys to version control
- ❌ **DON'T**: Share API keys in public channels

### Production Deployment
- Use environment variables in deployment platform
- Rotate API keys regularly
- Monitor API usage and costs
- Set up alerts for unusual activity

## Cost Management

### Gemini API Costs
- **Free Tier**: 1M tokens/month (sufficient for most users)
- **Paid Tier**: $0.00025 per 1K characters
- **Monitoring**: Check usage in Google Cloud Console

### Optimization Tips
- Cache generated learning paths
- Implement request deduplication
- Use appropriate model size (gemini-pro vs gemini-pro-vision)
- Monitor token usage patterns

## Support

### Getting Help
- **Documentation**: Check this guide first
- **Issues**: Create GitHub issue with error details
- **API Docs**: https://ai.google.dev/docs
- **Supabase Docs**: https://supabase.com/docs

### Useful Commands
```bash
# Check environment configuration
flutter run --debug

# Analyze code for issues
flutter analyze

# Run tests
flutter test

# Build for production
flutter build apk --release
```

## Next Steps

After configuring API keys:
1. ✅ Test learning path generation
2. ✅ Verify all features work correctly
3. ✅ Run comprehensive testing
4. ✅ Deploy to production environment
5. ✅ Monitor API usage and performance

Your Upwise app is now ready for production use with real AI-powered learning path generation! 🚀

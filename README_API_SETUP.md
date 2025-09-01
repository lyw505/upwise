# 🚀 Upwise - Real API Configuration Setup

## Quick Start Guide

### 1. 📋 Prerequisites
- Flutter SDK installed
- Google account for Gemini API
- Text editor for configuration

### 2. 🔑 Get Your Gemini API Key

1. **Visit Google AI Studio**
   ```
   https://makersuite.google.com/app/apikey
   ```

2. **Create API Key**
   - Sign in with Google account
   - Click "Create API Key"
   - Choose or create Google Cloud project
   - Copy the generated API key

### 3. ⚙️ Configure Environment

1. **Copy Environment Template**
   ```bash
   cp .env.example .env
   ```

2. **Edit .env File**
   ```bash
   # Replace with your actual API key
   GEMINI_API_KEY=your_actual_gemini_api_key_here
   
   # Optional: Use your own Supabase project
   SUPABASE_URL=your_supabase_project_url_here
   SUPABASE_ANON_KEY=your_supabase_anon_key_here
   ```

### 4. 🏃‍♂️ Run the App

```bash
# Install dependencies
flutter pub get

# Run the app
flutter run
```

## 🔍 Verify Configuration

### Method 1: Check Dashboard Menu
1. Open the app
2. Go to Dashboard
3. Tap menu (⋮) → "Config Status"
4. Verify all configurations are ✅

### Method 2: Test AI Generation
1. Create new learning path
2. Fill in topic (e.g., "Python Programming")
3. Submit form
4. Check if you get unique, contextual content (not generic template)

## 📊 Configuration Status

### ✅ Properly Configured
- **Real AI Generation**: Unique learning paths based on your input
- **Contextual Content**: Relevant materials and exercises
- **Fast Response**: < 5 seconds generation time

### ⚠️ Fallback Mode (API Key Missing)
- **Template-based**: Generic learning path structure
- **Limited Customization**: Basic topic substitution only
- **Instant Response**: No API calls made

## 🛠️ Troubleshooting

### Common Issues

#### "API key not configured"
**Solution**: Check `.env` file exists and contains valid API key

#### "Failed to load .env file"
**Solution**: Ensure `.env` file is in project root directory

#### "API rate limit exceeded"
**Solution**: Wait 1 minute or upgrade to paid tier

#### "Invalid API response"
**Solution**: Verify API key permissions and internet connection

### Debug Mode

Enable detailed logging:
```bash
# In .env file
DEBUG_MODE=true
```

## 💰 API Costs

### Free Tier Limits
- **1M tokens/month** (sufficient for most users)
- **60 requests/minute**
- **1 request/second**

### Typical Usage
- **Learning Path Generation**: ~500-1000 tokens
- **Monthly Estimate**: 50-100 learning paths = ~50K tokens
- **Cost**: FREE for typical usage

## 🔒 Security

### Best Practices
- ✅ Keep API keys in `.env` file
- ✅ Add `.env` to `.gitignore`
- ❌ Never commit API keys to version control
- ❌ Don't share API keys publicly

### Production Deployment
- Use environment variables in hosting platform
- Rotate API keys regularly
- Monitor usage and set alerts

## 📱 Features Enabled with Real API

### AI-Powered Learning Paths
- **Personalized Content**: Based on experience level and learning style
- **Contextual Materials**: Relevant resources and links
- **Custom Exercises**: Tailored practice activities
- **Project Recommendations**: Real-world application projects

### Smart Customization
- **Duration Optimization**: Realistic daily time allocation
- **Difficulty Progression**: Gradual skill building
- **Learning Style Adaptation**: Visual, auditory, kinesthetic approaches
- **Goal-Oriented Planning**: Aligned with your output objectives

## 🎯 Next Steps

After successful configuration:

1. **Test All Features**
   - Create multiple learning paths
   - Try different topics and settings
   - Verify AI responses are unique

2. **Optimize Settings**
   - Adjust API timeout if needed
   - Configure feature flags
   - Set up monitoring

3. **Deploy to Production**
   - Configure production environment
   - Set up CI/CD pipeline
   - Monitor API usage

## 📞 Support

### Need Help?
- **Documentation**: Check `docs/api_setup_guide.md`
- **Issues**: Create GitHub issue with error details
- **API Docs**: https://ai.google.dev/docs

### Useful Commands
```bash
# Check configuration status
flutter run --debug

# Analyze code
flutter analyze

# Run tests
flutter test

# Build for production
flutter build apk --release
```

---

**🎉 Congratulations!** Your Upwise app is now powered by real AI and ready for production use!

For detailed technical documentation, see `docs/api_setup_guide.md`.

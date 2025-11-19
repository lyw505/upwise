# 🔧 AI Summarizer Troubleshooting Guide

## 🚨 Problem: "Failed Generate Summary"

Jika Anda mengalami error "failed generate summary", ikuti panduan troubleshooting ini untuk mengidentifikasi dan mengatasi masalahnya.

## 🔍 Debug Tools Added

### ✅ **Debug Button**
- **Location**: Header AI Summarizer (bug icon)
- **Function**: Menampilkan informasi konfigurasi dan status
- **Usage**: Klik icon bug untuk melihat debug info

### ✅ **Enhanced Error Dialog**
- **Detailed error messages** dengan possible causes
- **Retry functionality** langsung dari dialog
- **Technical error details** untuk debugging

### ✅ **Enhanced Logging**
- **Provider logging**: Detailed logs di SummarizerProvider
- **Service logging**: API call logs di SummarizerService
- **Authentication checks**: User authentication status

## 🔧 Troubleshooting Steps

### Step 1: Check Debug Information

1. **Open AI Summarizer**
2. **Click bug icon** (🐛) di header
3. **Review debug info**:

```
✅ Authentication: Logged in
✅ User ID: [user-id]
✅ User Email: [email]
✅ Gemini API Key: Configured
✅ Supabase URL: Configured
✅ Supabase Key: Configured
```

### Step 2: Common Issues & Solutions

#### ❌ **Issue: "User not authenticated"**
**Symptoms:**
- Debug shows "Authentication: Not logged in"
- Error: "User not authenticated. Please login first."

**Solution:**
```dart
1. Logout dari aplikasi
2. Login kembali
3. Coba generate summary lagi
```

#### ❌ **Issue: "Gemini API Key Missing"**
**Symptoms:**
- Debug shows "Gemini API Key: Missing"
- Using fallback summary generation

**Solution:**
```env
# Check .env file
GEMINI_API_KEY=your_api_key_here
```

#### ❌ **Issue: "Supabase Configuration Missing"**
**Symptoms:**
- Debug shows "Supabase URL: Missing" or "Supabase Key: Missing"
- Database connection errors

**Solution:**
```env
# Check .env file
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_key
```

#### ❌ **Issue: "API Service Temporarily Unavailable"**
**Symptoms:**
- API Response status: 429, 500, 503
- Network timeout errors

**Solution:**
```dart
1. Wait a few minutes and retry
2. Check internet connection
3. Use "Test AI" button to verify API
```

### Step 3: Test AI Generation

1. **Click "Test AI" button** in debug dialog
2. **Wait for test result**:
   - ✅ Success: "AI generation test successful!"
   - ❌ Failure: Shows specific error message

### Step 4: Check Browser Console

1. **Open browser developer tools** (F12)
2. **Go to Console tab**
3. **Look for error messages**:

```javascript
// Look for these patterns:
SummarizerProvider: Error generating summary
SummarizerService: Gemini API error
SummarizerService: Error calling Gemini API
```

## 🔍 Detailed Error Analysis

### **Authentication Errors**
```dart
// Error Pattern
"User not authenticated. Please login first."

// Debug Steps
1. Check if user is logged in
2. Verify Supabase connection
3. Check auth token validity
```

### **API Configuration Errors**
```dart
// Error Pattern
"AI service returned null. Check API configuration."

// Debug Steps
1. Verify GEMINI_API_KEY in .env
2. Check API key validity
3. Test API connection
```

### **Database Errors**
```dart
// Error Pattern
"Failed to save summary: [database error]"

// Debug Steps
1. Check Supabase configuration
2. Verify database schema
3. Check RLS policies
```

### **Network Errors**
```dart
// Error Pattern
"Error calling Gemini API: [network error]"

// Debug Steps
1. Check internet connection
2. Verify API endpoint accessibility
3. Check for firewall/proxy issues
```

## 🛠️ Advanced Debugging

### **Enable Detailed Logging**
```dart
// In browser console, enable verbose logging
localStorage.setItem('flutter.inspector.structuredErrors', 'true');
```

### **Check Network Requests**
1. **Open Network tab** in developer tools
2. **Try generate summary**
3. **Look for failed requests**:
   - Supabase API calls
   - Gemini API calls
   - Authentication requests

### **Verify Environment Configuration**
```dart
// Check if .env file is loaded properly
print('Gemini API Key: ${EnvConfig.geminiApiKey}');
print('Supabase URL: ${EnvConfig.supabaseUrl}');
```

## 🔄 Quick Fixes

### **Fix 1: Restart Application**
```bash
# Stop current session
Ctrl+C

# Restart Flutter
flutter run -d chrome --hot
```

### **Fix 2: Clear Browser Cache**
```bash
# Clear browser data
1. Open browser settings
2. Clear browsing data
3. Restart browser
4. Try again
```

### **Fix 3: Verify API Keys**
```bash
# Test Gemini API key manually
curl -X POST \
  'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=YOUR_API_KEY' \
  -H 'Content-Type: application/json' \
  -d '{"contents":[{"parts":[{"text":"Hello"}]}]}'
```

### **Fix 4: Database Connection Test**
```dart
// Test Supabase connection
final response = await Supabase.instance.client
    .from('profiles')
    .select('count')
    .count(CountOption.exact);
```

## 📊 Error Codes Reference

| Error Code | Description | Solution |
|------------|-------------|----------|
| AUTH_001 | User not authenticated | Login again |
| API_001 | Gemini API key missing | Check .env file |
| API_002 | API rate limit exceeded | Wait and retry |
| API_003 | API service unavailable | Check service status |
| DB_001 | Database connection failed | Check Supabase config |
| DB_002 | RLS policy violation | Check user permissions |
| NET_001 | Network timeout | Check internet connection |
| NET_002 | CORS error | Check browser settings |

## 🎯 Prevention Tips

### **Regular Maintenance**
1. **Monitor API usage** to avoid rate limits
2. **Keep API keys secure** and rotate regularly
3. **Update dependencies** regularly
4. **Monitor error logs** for patterns

### **Best Practices**
1. **Always test** after configuration changes
2. **Use debug tools** before reporting issues
3. **Keep backups** of working configurations
4. **Document custom changes**

## 🆘 Still Having Issues?

### **Collect Debug Information**
1. **Screenshot of debug dialog**
2. **Browser console errors**
3. **Network tab failures**
4. **Steps to reproduce**

### **Common Solutions Summary**
- ✅ **Login issues**: Logout and login again
- ✅ **API issues**: Check .env configuration
- ✅ **Database issues**: Verify Supabase setup
- ✅ **Network issues**: Check internet connection
- ✅ **Browser issues**: Clear cache and restart

**With these debugging tools and steps, you should be able to identify and resolve most AI Summarizer issues!** 🚀
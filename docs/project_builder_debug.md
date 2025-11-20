# Project Builder Debug Guide

## 🐛 **Error yang Dilaporkan**
- **Error**: 400 (Bad Request) ketika start project
- **URL**: `https://emelocetgqlirzuqvyegd.supabase.co/rest/v1/user_projects?id=eq.501...`
- **Symptom**: Tidak terjadi apa-apa di web, error di console

## 🔍 **Possible Causes**

### 1. **Authentication Issues**
- User belum login (`authProvider.currentUser` null)
- User ID tidak valid
- Session expired

### 2. **Database Issues**
- Table `user_projects` tidak ada
- RLS policies tidak mengizinkan insert
- View `user_projects_with_progress` tidak ada
- Foreign key constraints error

### 3. **Data Issues**
- Template ID tidak valid
- Required fields missing
- Data type mismatch

## 🔧 **Debug Steps Applied**

### 1. **Added Debug Logging**
```dart
// In ProjectProvider.startProject()
print('Starting project for userId: $userId, templateId: $templateId');
print('Template response: $templateResponse');
print('Project data to insert: $projectData');

// In ProjectProvider.loadUserProjects()
print('Loading user projects for userId: $userId');
print('User projects response: $response');
print('Loaded ${_userProjects.length} user projects');

// In ProjectBuilderScreen._startProject()
print('_startProject called for template: ${template.title}');
print('Current user: ${authProvider.currentUser?.id}');
print('startProject result: $success');
```

### 2. **Fixed Database Query**
```dart
// Changed from problematic view to direct table query
// OLD (causing 400 error):
.from('user_projects_with_progress')

// NEW (should work):
.from('user_projects')
.select('*, project_templates(title, category, difficulty_level, tech_stack)')
```

### 3. **Enhanced Error Handling**
```dart
// Added user authentication check
if (authProvider.currentUser == null) {
  SnackbarUtils.showError(context, 'Please log in to start a project');
  return;
}

// Better error messages
SnackbarUtils.showError(context, projectProvider.error ?? 'Failed to start project');
```

## 🧪 **Testing Instructions**

### 1. **Check Console Output**
Setelah menjalankan aplikasi dan mencoba start project, periksa console untuk:
```
_startProject called for template: [Template Name]
Current user: [User ID or null]
Starting project for userId: [User ID]
Template response: [Template Data]
Project data to insert: [Project Data]
```

### 2. **Check Authentication**
- Pastikan user sudah login
- Periksa `authProvider.currentUser?.id` tidak null
- Verify session masih valid

### 3. **Check Database**
- Pastikan table `user_projects` ada di Supabase
- Verify RLS policies mengizinkan insert untuk authenticated users
- Check foreign key constraints (template_id, user_id)

## 🎯 **Expected Debug Output**

### **Success Case:**
```
_startProject called for template: Personal Portfolio Website
Current user: 12345678-1234-1234-1234-123456789012
Starting project for userId: 12345678-1234-1234-1234-123456789012, templateId: template-uuid
Template response: {id: template-uuid, title: Personal Portfolio Website, ...}
Project data to insert: {user_id: 12345678-1234-1234-1234-123456789012, template_id: template-uuid, ...}
Loading user projects for userId: 12345678-1234-1234-1234-123456789012
User projects response: [{id: project-uuid, title: Personal Portfolio Website, ...}]
Loaded 1 user projects
startProject result: true
```

### **Failure Cases:**

#### **Not Logged In:**
```
_startProject called for template: Personal Portfolio Website
Current user: null
No current user, returning
```

#### **Database Error:**
```
_startProject called for template: Personal Portfolio Website
Current user: 12345678-1234-1234-1234-123456789012
Starting project for userId: 12345678-1234-1234-1234-123456789012, templateId: template-uuid
Error loading user projects: [Error Details]
startProject result: false
projectProvider.error: Failed to load user projects: [Error Details]
```

## 🚀 **Next Steps**

1. **Run the app** dengan debug logging
2. **Try to start a project** dan monitor console
3. **Identify the exact failure point** dari debug output
4. **Fix the specific issue** berdasarkan error yang ditemukan

**Debug logging will help identify the exact cause of the 400 error! 🔍**
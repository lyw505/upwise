# Upwise - AI Learning Path Generator

## 1. User Flow (Developer & AI IDE Friendly)

```markdown
# 1. WelcomeScreen
- Type: Stateless Widget
- Layout:
  - Logo / App name (Top center)
  - Description text (middle)
  - CTA Button "Get Started"
- Navigation:
  - On press → LoginScreen or RegisterScreen

# 2. RegisterScreen
- Type: Form Widget
- Fields:
  - TextField: Name
  - TextField: Email
  - PasswordField: Password
- Button: "Create Account"
- Layout:
  - Column layout with spacing
- Action:
  - OnSubmit → POST /api/auth/register
  - OnSuccess → Navigate to DashboardScreen

# 3. LoginScreen
- Type: Form Widget
- Fields:
  - TextField: Email
  - PasswordField: Password
- Button: "Login"
- Layout:
  - Column layout with spacing
- Action:
  - OnSubmit → POST /api/auth/login
  - OnSuccess → Navigate to DashboardScreen

# 4. DashboardScreen
- Type: Stateful Widget
- Layout:
  - Top bar: Greeting & Streak counter 🔥
  - Button: "+ Create Learning Path" → CreatePathScreen
  - ListView: Existing learning paths (clickable cards)
- Data:
  - GET /api/learning-paths

# 5. CreatePathScreen
- Type: Form + Stateful Widget
- Fields:
  - Topic (TextField)
  - Duration (Dropdown: days/weeks)
  - Daily Time (NumberInput)
  - Experience Level (Dropdown)
  - Learning Style (Dropdown)
  - Output Goal (TextField)
  - Checkbox: Include project
  - Checkbox: Include exercise
  - Notes (Multiline TextField)
- Layout:
  - Scrollable Column Form
- Action:
  - Submit → POST /api/generate-learning-path
  - OnSuccess → ViewPathScreen

# 6. ViewPathScreen
- Type: Stateful Widget with Tabs
- Tabs:
  - "Learning Table"
  - "Project Recommendations"
- Learning Table: DataTable
  - Columns:
    - Day
    - Topic
    - Subtopic
    - Link
    - Exercise
    - Status (Dropdown/Chip)
  - Action:
    - PATCH /api/learning-paths/:id/status
- Projects Section:
  - ListView of cards (Title, Description, Link)

# 7. DailyTodayScreen
- Type: Widget
- Content:
  - Card layout:
    - Title (Today’s Topic)
    - Subtopic
    - Material link button
    - Exercise (if any)
    - Status toggle buttons:
      - Complete
      - Skip
      - In Progress
- Data:
  - GET today’s learning task from /api/learning-paths/:id/today

# 8. AnalyticsScreen
- Type: Stateless Widget with Charts
- Layout:
  - Progress bar (total %)
  - Streak days counter
  - Total time learned
  - Topics completed
- Data:
  - GET /api/analytics

# 9. SettingsScreen
- Type: Form Widget
- Fields:
  - Name (TextField)
  - Password (secure input)
- Actions:
  - Save changes → PATCH /api/user/profile
  - Logout Button

# 10. Navigation Flow Summary
WelcomeScreen → [Login/Register] → DashboardScreen → [CreatePathScreen → ViewPathScreen → DailyTodayScreen → AnalyticsScreen → SettingsScreen]
```

## Notes

* Learning path stored in Supabase with progress tracking and streak logic
* Mobile-first, gamified experience for lifelong learners

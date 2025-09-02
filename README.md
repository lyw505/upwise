# Upwise - AI-Powered Learning Path Generator

Upwise is a Flutter mobile application that helps users generate detailed and personalized learning paths using AI, track progress daily, and stay motivated through gamification features like streaks and badges.

## Features

- **AI-Generated Learning Paths**: Create personalized learning plans using Google Gemini AI
- **Daily Progress Tracking**: Track your learning progress with daily tasks
- **Streak System**: Stay motivated with daily streaks and achievements
- **Analytics Dashboard**: Monitor your learning journey with detailed statistics
- **User Authentication**: Secure sign-up and sign-in with Supabase Auth
- **Responsive Design**: Beautiful UI with blue primary theme and Poppins font

## Tech Stack

- **Frontend**: Flutter (Dart)
- **Backend**: Supabase (Database, Auth, API)
- **AI**: Google Gemini API
- **State Management**: Provider
- **Navigation**: Go Router
- **UI**: Material Design 3 with custom theme

## Getting Started

### Prerequisites

- Flutter SDK (>=3.7.2)
- Dart SDK (>=2.17.0)
- A Supabase account
- A Google Gemini API key (optional, for AI features)

### Quick Setup

⚠️ **Important**: This app requires a Supabase backend. Follow these steps:

1. **Set up Supabase Project**
   - Create project at [Supabase Dashboard](https://app.supabase.com)
   - Name it `upwise-first` or your preferred name
   - Run the SQL schema from `supabase_schema.sql`
   - Get your Project URL and anon key

2. **Configure Environment**
   - Update `.env` file with your Supabase credentials:
   ```env
   SUPABASE_URL=https://your-project-ref.supabase.co
   SUPABASE_ANON_KEY=your-anon-key-here
   GEMINI_API_KEY=your-gemini-key-here
   ```

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd upwise
   flutter pub get
   ```

2. **Complete Backend Setup**
   Follow the detailed guide in `SUPABASE_SETUP.md` for:
   - Creating Supabase project
   - Setting up database schema
   - Configuring environment variables
   - Testing the connection

3. **Run the app**
   ```bash
   flutter run
   ```

4. **Verify Setup**
   - Open app → Dashboard → Menu → "Config Status"
   - Test Supabase connection
   - Ensure all configurations show ✅

## Project Structure

```
lib/
├── core/
│   ├── constants/          # App colors, text styles, constants
│   └── theme/             # App theme configuration
├── models/                # Data models (User, LearningPath, etc.)
├── providers/             # State management (Auth, User, LearningPath)
├── screens/               # UI screens
│   ├── auth/             # Authentication screens
│   └── ...               # Other screens
├── services/             # External services (Gemini AI)
└── main.dart             # App entry point
```

## Current Implementation Status

### ✅ Completed Features
- [x] Project setup with dependencies
- [x] Custom theme with blue primary color and Poppins font
- [x] Data models for User, LearningPath, DailyTask, etc.
- [x] State management with Provider
- [x] Supabase integration and database schema
- [x] Complete authentication system
- [x] Authentication screens (Welcome, Login, Register)
- [x] Basic Dashboard screen
- [x] Gemini AI service setup
- [x] Environment configuration and validation
- [x] Connection testing and debugging tools

### 🚧 In Progress
- [ ] Supabase database schema setup
- [ ] Complete authentication flow
- [ ] Navigation system with Go Router

### 📋 Planned Features
- [ ] Create Learning Path screen with AI integration
- [ ] View Learning Path screen with progress tracking
- [ ] Daily Task tracker
- [ ] Analytics screen with charts
- [ ] Settings screen
- [ ] Complete testing suite

## Documentation

- [**Supabase Setup Guide**](SUPABASE_SETUP.md) - Complete backend setup instructions
- [**API Setup Guide**](README_API_SETUP.md) - Gemini AI configuration
- [User Flow](docs/userflow.md) - Complete user flow documentation
- [Product Requirements](docs/prd.md) - Detailed product requirements document
- [Database Schema](supabase_schema.sql) - Complete SQL schema for Supabase

## Testing

Run the test suite:
```bash
flutter test
```

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

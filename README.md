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

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd upwise
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Set up Supabase**
   - Follow the detailed guide in `docs/supabase_setup.md`
   - Create a new Supabase project
   - Set up the database schema
   - Get your API keys

4. **Configure the app**
   - Open `lib/main.dart`
   - Replace the Supabase URL and anon key with your actual values:
   ```dart
   await Supabase.initialize(
     url: 'YOUR_SUPABASE_URL',
     anonKey: 'YOUR_SUPABASE_ANON_KEY',
   );
   ```

5. **Configure Gemini AI (Optional)**
   - Open `lib/services/gemini_service.dart`
   - Replace the API key with your actual Gemini API key:
   ```dart
   static const String _apiKey = 'YOUR_GEMINI_API_KEY';
   ```

6. **Run the app**
   ```bash
   flutter run
   ```

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
- [x] Supabase integration setup
- [x] Authentication screens (Welcome, Login, Register)
- [x] Basic Dashboard screen
- [x] Gemini AI service setup

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

- [Supabase Setup Guide](docs/supabase_setup.md) - Detailed guide for setting up the backend
- [User Flow](docs/userflow.md) - Complete user flow documentation
- [Product Requirements](docs/prd.md) - Detailed product requirements document

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

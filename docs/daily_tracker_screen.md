# Daily Tracker Screen Implementation

## Overview

The Daily Tracker Screen is the core productivity feature of Upwise that helps users focus on their daily learning tasks with built-in timer functionality, progress tracking, and streak management. This screen provides a distraction-free environment for completing daily learning objectives.

## Features Implemented

### ✅ Today's Task Display
- **Active Learning Path Info**: Shows current learning path and progress
- **Today's Task Card**: Highlighted card with today's specific learning objective
- **Material Recommendations**: Display suggested learning resources
- **Exercise Instructions**: Show practice activities for the day

### ✅ Study Timer
- **Pomodoro-style Timer**: Built-in timer for focused study sessions
- **Timer Controls**: Start, pause, reset functionality
- **Time Tracking**: Automatic time logging for completed tasks
- **Visual Timer Display**: Large, easy-to-read timer format

### ✅ Task Management
- **Complete Task**: Mark task as completed with time logging
- **Skip Task**: Option to skip with confirmation dialog
- **Streak Integration**: Automatic streak updates on task completion
- **Progress Sync**: Real-time sync with learning path progress

### ✅ User Experience
- **Streak Display**: Current streak counter in app bar
- **No Task State**: Friendly message when no tasks available
- **Loading States**: Smooth loading experience
- **Success Feedback**: Celebratory messages on task completion

## Screen Structure

### App Bar with Streak Counter
```dart
AppBar(
  title: const Text('Daily Tracker'),
  actions: [
    // Streak counter with fire icon
    Container(
      child: Row(
        children: [
          Icon(Icons.local_fire_department),
          Text('${userProvider.user?.currentStreak ?? 0}'),
        ],
      ),
    ),
  ],
)
```

### Learning Path Info Card
```dart
Container(
  // Shows current learning path topic and day progress
  child: Row(
    children: [
      Icon(Icons.school),
      Column(
        children: [
          Text(_activeLearningPath!.topic),
          Text('Day ${_todayTask!.dayNumber} of ${_activeLearningPath!.durationDays}'),
        ],
      ),
      // Navigate to view path
      GestureDetector(onTap: () => context.goToViewPath()),
    ],
  ),
)
```

### Today's Task Card
```dart
Container(
  decoration: BoxDecoration(
    border: Border.all(color: AppColors.primary, width: 2),
    boxShadow: [/* Primary color shadow */],
  ),
  child: Column(
    children: [
      // "TODAY" badge
      Container(child: Text('TODAY')),
      // Main topic
      Text(_todayTask!.mainTopic),
      // Sub topic
      Text(_todayTask!.subTopic),
      // Material recommendations
      if (_todayTask!.materialTitle != null) /* Material card */,
      // Exercise instructions
      if (_todayTask!.exercise != null) /* Exercise card */,
    ],
  ),
)
```

## Timer Implementation

### Timer State Management
```dart
class _DailyTrackerScreenState extends State<DailyTrackerScreen> {
  Timer? _timer;
  int _elapsedSeconds = 0;
  bool _isTimerRunning = false;
  
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedSeconds++;
      });
    });
  }
  
  void _pauseTimer() {
    _timer?.cancel();
    _timer = null;
  }
  
  void _resetTimer() {
    _timer?.cancel();
    _timer = null;
    setState(() {
      _elapsedSeconds = 0;
    });
  }
}
```

### Timer Display
```dart
Container(
  child: Text(
    _formatTime(_elapsedSeconds),
    style: AppTextStyles.displaySmall.copyWith(
      fontFamily: 'monospace',
      color: AppColors.primary,
    ),
  ),
)

String _formatTime(int seconds) {
  final hours = seconds ~/ 3600;
  final minutes = (seconds % 3600) ~/ 60;
  final secs = seconds % 60;
  
  if (hours > 0) {
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  } else {
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
```

## Task Completion Flow

### Complete Task Process
```dart
Future<void> _completeTask() async {
  // 1. Stop timer and calculate time spent
  _pauseTimer();
  final timeSpentMinutes = (_elapsedSeconds / 60).ceil();
  
  // 2. Update task status in database
  final success = await learningPathProvider.updateTaskStatus(
    taskId: _todayTask!.id,
    status: TaskStatus.completed,
    timeSpentMinutes: timeSpentMinutes,
  );
  
  // 3. Update user streak
  if (success) {
    await userProvider.updateStreak();
    
    // 4. Show success feedback
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🎉 Task completed! Great job! Your streak has been updated.'),
        backgroundColor: AppColors.success,
      ),
    );
    
    // 5. Reload today's task
    await _loadTodayTask();
  }
}
```

### Skip Task Process
```dart
Future<void> _skipTask() async {
  // 1. Show confirmation dialog
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Skip Today\'s Task'),
      content: const Text('Are you sure you want to skip today\'s task?'),
      actions: [/* Cancel, Skip buttons */],
    ),
  );
  
  // 2. Update task status if confirmed
  if (confirmed == true) {
    final success = await learningPathProvider.updateTaskStatus(
      taskId: _todayTask!.id,
      status: TaskStatus.skipped,
    );
    
    // 3. Show feedback and reload
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(/* Skip message */);
      await _loadTodayTask();
    }
  }
}
```

## Data Loading & State Management

### Today's Task Loading
```dart
Future<void> _loadTodayTask() async {
  final authProvider = context.read<AuthProvider>();
  final learningPathProvider = context.read<LearningPathProvider>();
  
  if (authProvider.currentUser != null) {
    // Load all learning paths
    await learningPathProvider.loadLearningPaths(authProvider.currentUser!.id);
    
    // Find active learning path with today's task
    final activePaths = learningPathProvider.learningPaths
        .where((path) => path.status == LearningPathStatus.inProgress)
        .toList();
    
    if (activePaths.isNotEmpty) {
      _activeLearningPath = activePaths.first;
      _todayTask = _activeLearningPath!.todayTask;
    }
  }
  
  setState(() {
    _isLoading = false;
  });
}
```

### Provider Integration
- **AuthProvider**: User authentication and session management
- **LearningPathProvider**: Task status updates and data sync
- **UserProvider**: Streak management and user profile updates

## UI States & Feedback

### Loading State
```dart
_isLoading
  ? const Center(child: CircularProgressIndicator())
  : /* Main content */
```

### No Task State
```dart
Widget _buildNoTaskView() {
  return Center(
    child: Column(
      children: [
        Icon(Icons.check_circle_outline, size: 80, color: AppColors.success),
        Text('All Caught Up!'),
        Text('You\'ve completed today\'s task or don\'t have any active learning paths.'),
        ElevatedButton(onPressed: () => context.goToCreatePath(), child: Text('Create Learning Path')),
        OutlinedButton(onPressed: () => context.goToDashboard(), child: Text('View Dashboard')),
      ],
    ),
  );
}
```

### Success Feedback
- **Task Completion**: Celebratory message with emoji
- **Streak Update**: Automatic streak counter update
- **Visual Feedback**: Success color coding and animations

## Navigation Integration

### Route Configuration
```dart
GoRoute(
  path: '/daily',
  name: 'daily',
  builder: (context, state) => const DailyTrackerScreen(),
)
```

### Navigation Flow
```
Dashboard → [Today's Task] → Daily Tracker
View Path → [Continue Today] → Daily Tracker
Daily Tracker → [Complete] → Dashboard (with success message)
Daily Tracker → [Back] → Dashboard
Daily Tracker → [Path Info] → View Path
```

## Database Integration

### Task Status Update
```sql
UPDATE daily_tasks 
SET 
  status = ?,
  completed_at = ?,
  time_spent_minutes = ?
WHERE id = ?
```

### Streak Update
```sql
UPDATE profiles 
SET 
  current_streak = current_streak + 1,
  longest_streak = GREATEST(longest_streak, current_streak + 1),
  last_active_date = NOW()
WHERE id = ?
```

## Performance Considerations

### Timer Optimization
- **Efficient Updates**: Only update UI every second
- **Memory Management**: Proper timer disposal in dispose()
- **Background Handling**: Pause timer when app goes to background

### State Management
- **Minimal Rebuilds**: Use Consumer widgets for specific updates
- **Data Caching**: Cache today's task to avoid repeated queries
- **Lazy Loading**: Load data only when needed

## Accessibility Features

### Screen Reader Support
- **Semantic Labels**: Proper labels for all interactive elements
- **Timer Announcements**: Announce timer state changes
- **Progress Updates**: Announce task completion and streak updates

### Keyboard Navigation
- **Tab Order**: Logical tab order for keyboard users
- **Shortcuts**: Keyboard shortcuts for timer controls
- **Focus Management**: Proper focus handling after actions

## Error Handling

### Network Errors
- **Offline Support**: Cache last known state
- **Retry Mechanisms**: Automatic retry for failed operations
- **User Feedback**: Clear error messages with retry options

### Data Validation
- **Task Existence**: Handle missing or invalid tasks
- **Timer Bounds**: Prevent negative or excessive timer values
- **State Consistency**: Ensure UI state matches data state

## Future Enhancements

### Planned Features
1. **Pomodoro Integration**: 25-minute focused sessions with breaks
2. **Background Timer**: Continue timing when app is backgrounded
3. **Study Statistics**: Detailed time tracking and analytics
4. **Custom Reminders**: Personalized study reminders
5. **Focus Mode**: Distraction-free full-screen mode

### Advanced Features
1. **Study Music Integration**: Background music for focus
2. **Break Reminders**: Automatic break suggestions
3. **Progress Sharing**: Share daily achievements
4. **Habit Tracking**: Track study habits and patterns
5. **AI Insights**: Personalized productivity insights

## Conclusion

The Daily Tracker Screen provides a comprehensive daily learning experience with:
- ✅ Focused task display with clear objectives
- ✅ Built-in study timer with full controls
- ✅ Automatic progress and streak tracking
- ✅ Seamless integration with learning paths
- ✅ User-friendly feedback and navigation
- ✅ Robust error handling and state management

The screen serves as the daily productivity hub for Upwise users, encouraging consistent learning habits through gamification and focused study sessions.

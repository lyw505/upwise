import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
import '../core/constants/app_dimensions.dart';
import '../core/router/app_router.dart';
import '../core/utils/snackbar_utils.dart';
import '../providers/auth_provider.dart';
import '../providers/learning_path_provider.dart';
import '../models/learning_path_model.dart';

class CreatePathScreen extends StatefulWidget {
  const CreatePathScreen({super.key});

  @override
  State<CreatePathScreen> createState() => _CreatePathScreenState();
}

class _CreatePathScreenState extends State<CreatePathScreen> {
  final _formKey = GlobalKey<FormState>();
  final _topicController = TextEditingController();
  final _outputGoalController = TextEditingController();
  final _notesController = TextEditingController();
  
  int _durationDays = 7;
  int _dailyTimeMinutes = 30;
  ExperienceLevel _experienceLevel = ExperienceLevel.beginner;
  LearningStyle _learningStyle = LearningStyle.visual;
  bool _includeProjects = false;
  bool _includeExercises = true;

  @override
  void dispose() {
    _topicController.dispose();
    _outputGoalController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _generateLearningPath() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final learningPathProvider = context.read<LearningPathProvider>();

    if (authProvider.currentUser == null) {
      SnackbarUtils.showError(context, 'Please log in to create a learning path');
      return;
    }

    final learningPath = await learningPathProvider.generateLearningPath(
      userId: authProvider.currentUser!.id,
      topic: _topicController.text.trim(),
      durationDays: _durationDays,
      dailyTimeMinutes: _dailyTimeMinutes,
      experienceLevel: _experienceLevel,
      learningStyle: _learningStyle,
      outputGoal: _outputGoalController.text.trim(),
      includeProjects: _includeProjects,
      includeExercises: _includeExercises,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    if (learningPath != null && mounted) {
      SnackbarUtils.showSuccess(context, 'Learning path generated successfully!');
      context.goToViewPath(learningPath.id);
    } else if (mounted) {
      SnackbarUtils.showError(context, 'Failed to generate learning path. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Create Learning Path',
                        style: AppTextStyles.headlineMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Let AI create a personalized learning journey for you',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Topic Field
                _buildSectionTitle('What do you want to learn?'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _topicController,
                  decoration: const InputDecoration(
                    hintText: 'e.g., Flutter Development, Machine Learning, Spanish Language',
                    prefixIcon: Icon(Icons.school),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a topic';
                    }
                    if (value.trim().length < 3) {
                      return 'Topic must be at least 3 characters';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 24),
                
                // Duration and Time
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle('Duration'),
                          const SizedBox(height: 8),
                          _buildDurationSelector(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle('Daily Time'),
                          const SizedBox(height: 8),
                          _buildTimeSelector(),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Experience Level
                _buildSectionTitle('Your Experience Level'),
                const SizedBox(height: 16),
                _buildExperienceLevelSelector(),
                
                const SizedBox(height: 24),
                
                // Output Goal
                _buildSectionTitle('What do you want to achieve?'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _outputGoalController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'e.g., Build a mobile app, Get certified, Start a career, Complete a project',
                    prefixIcon: Icon(Icons.flag),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please describe your goal';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 24),
                
                
                // Notes (Optional)
                _buildSectionTitle('Additional Notes (Optional)'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Any specific requirements, preferences, or constraints...',
                    prefixIcon: Icon(Icons.note),
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Generate Button
                Consumer<LearningPathProvider>(
                  builder: (context, provider, child) {
                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: provider.isGenerating ? null : _generateLearningPath,
                        icon: provider.isGenerating
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(Icons.auto_awesome, color: Colors.white),
                        label: Text(
                          provider.isGenerating ? 'Generating...' : 'Generate Learning Path',
                          style: AppTextStyles.buttonLarge.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.titleSmall.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildDurationSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _durationDays,
          isExpanded: true,
          items: [7, 14, 21, 30, 60, 90].map((days) {
            return DropdownMenuItem(
              value: days,
              child: Text('$days days'),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _durationDays = value!;
            });
          },
        ),
      ),
    );
  }

  Widget _buildTimeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _dailyTimeMinutes,
          isExpanded: true,
          items: [15, 30, 45, 60, 90, 120].map((minutes) {
            return DropdownMenuItem(
              value: minutes,
              child: Text('${minutes}min'),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _dailyTimeMinutes = value!;
            });
          },
        ),
      ),
    );
  }

  Widget _buildExperienceLevelSelector() {
    return Row(
      children: ExperienceLevel.values.map((level) {
        final isSelected = _experienceLevel == level;
        final index = ExperienceLevel.values.indexOf(level);
        
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: index < ExperienceLevel.values.length - 1 ? 8.0 : 0.0,
            ),
            child: FilterChip(
              label: Text(
                _getExperienceLevelLabel(level),
                textAlign: TextAlign.center,
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _experienceLevel = level;
                });
              },
              backgroundColor: AppColors.surfaceVariant,
              selectedColor: AppColors.primary,
              labelStyle: AppTextStyles.labelMedium.copyWith(
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? AppColors.primary : AppColors.border,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLearningStyleSelector() {
    return Wrap(
      spacing: 8,
      children: LearningStyle.values.map((style) {
        final isSelected = _learningStyle == style;
        return FilterChip(
          label: Text(_getLearningStyleLabel(style)),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              _learningStyle = style;
            });
          },
          backgroundColor: AppColors.surfaceVariant,
          selectedColor: AppColors.primary,
          labelStyle: AppTextStyles.labelMedium.copyWith(
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildOptionsSection() {
    return Column(
      children: [
        CheckboxListTile(
          title: Text(
            'Include Project Recommendations',
            style: AppTextStyles.bodyMedium,
          ),
          subtitle: Text(
            'Get suggestions for hands-on projects',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          value: _includeProjects,
          onChanged: (value) {
            setState(() {
              _includeProjects = value!;
            });
          },
          activeColor: AppColors.primary,
          contentPadding: EdgeInsets.zero,
        ),
        CheckboxListTile(
          title: Text(
            'Include Daily Exercises',
            style: AppTextStyles.bodyMedium,
          ),
          subtitle: Text(
            'Get practice exercises for each day',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          value: _includeExercises,
          onChanged: (value) {
            setState(() {
              _includeExercises = value!;
            });
          },
          activeColor: AppColors.primary,
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  String _getExperienceLevelLabel(ExperienceLevel level) {
    switch (level) {
      case ExperienceLevel.beginner:
        return 'Beginner';
      case ExperienceLevel.intermediate:
        return 'Intermediate';
      case ExperienceLevel.advanced:
        return 'Advanced';
    }
  }

  String _getLearningStyleLabel(LearningStyle style) {
    switch (style) {
      case LearningStyle.visual:
        return 'Visual';
      case LearningStyle.auditory:
        return 'Auditory';
      case LearningStyle.kinesthetic:
        return 'Hands-on';
      case LearningStyle.readingWriting:
        return 'Reading/Writing';
    }
  }
}

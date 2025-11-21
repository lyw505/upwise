import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
import '../services/gemini_test_service.dart';
import '../models/learning_path_model.dart';
import '../services/gemini_service.dart';

class AiEnhancementDemoScreen extends StatefulWidget {
  const AiEnhancementDemoScreen({super.key});

  @override
  State<AiEnhancementDemoScreen> createState() => _AiEnhancementDemoScreenState();
}

class _AiEnhancementDemoScreenState extends State<AiEnhancementDemoScreen> {
  final GeminiService _geminiService = GeminiService();
  bool _isGenerating = false;
  Map<String, dynamic>? _generatedContent;
  String _selectedTopic = 'Flutter Development';
  ExperienceLevel _selectedLevel = ExperienceLevel.beginner;
  LearningStyle _selectedStyle = LearningStyle.visual;
  int _selectedDuration = 7;
  
  final List<String> _topics = [
    'Flutter Development',
    'Python Programming',
    'JavaScript Fundamentals',
    'React Development',
    'Node.js Backend',
    'Machine Learning',
    'Data Science',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('AI Enhancement Demo'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildConfigurationSection(),
            const SizedBox(height: 24),
            _buildGenerateButton(),
            const SizedBox(height: 24),
            if (_generatedContent != null) _buildResultSection(),
            const SizedBox(height: 24),
            _buildTestingSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Enhanced AI Learning Path Generator',
                  style: AppTextStyles.titleLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Test the enhanced Gemini AI with improved prompts, content quality validation, and intelligent fallbacks.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigurationSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Configuration',
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          
          // Topic Selection
          _buildDropdown(
            'Topic',
            _selectedTopic,
            _topics,
            (value) => setState(() => _selectedTopic = value!),
          ),
          const 
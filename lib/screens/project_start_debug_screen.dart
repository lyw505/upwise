import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
import '../core/constants/app_dimensions.dart';
import '../core/router/app_router.dart';
import '../core/utils/snackbar_utils.dart';
import '../providers/auth_provider.dart';
import '../providers/project_provider.dart';
import '../models/project_model.dart';

class ProjectStartDebugScreen extends StatefulWidget {
  const ProjectStartDebugScreen({super.key});

  @override
  State<ProjectStartDebugScreen> createState() => _ProjectStartDebugScreenState();
}

class _ProjectStartDebugScreenState extends State<ProjectStartDebugScreen> {
  String? _selectedTemplateId;
  bool _isStarting = false;
  String? _lastError;
  String? _lastSuccess;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Project Start Debug'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAuthSection(),
            const SizedBox(height: 24),
            _buildTemplateSelection(),
            const SizedBox(height: 24),
            _buildStartSection(),
            const SizedBox(height: 24),
            _buildResultSection(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: 3, // Highlight "Projects" since we're debugging projects
        onTap: (index) {
          switch (index) {
            case 0:
              context.goToDashboard();
              break;
            case 1:
              context.goToLearningPaths();
              break;
            case 2:
              context.goToCreatePath();
              break;
            case 3:
              context.goToProjects();
              break;
            case 4:
              context.goToSummarizer();
              break;
            case 5:
              context.goToAnalytics();
              break;
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey[500],
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.normal,
          fontSize: 12,
        ),
        elevation: 0,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined, size: AppDimensions.bottomNavIconSize),
            activeIcon: Icon(Icons.home, size: AppDimensions.bottomNavIconSize),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school_outlined, size: AppDimensions.bottomNavIconSize),
            activeIcon: Icon(Icons.school, size: AppDimensions.bottomNavIconSize),
            label: 'Paths',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline, size: AppDimensions.bottomNavIconSize),
            activeIcon: Icon(Icons.add_circle, size: AppDimensions.bottomNavIconSize),
            label: 'Create',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.build_outlined, size: AppDimensions.bottomNavIconSize),
            activeIcon: Icon(Icons.build, size: AppDimensions.bottomNavIconSize),
            label: 'Projects',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.article_outlined, size: AppDimensions.bottomNavIconSize),
            activeIcon: Icon(Icons.article, size: AppDimensions.bottomNavIconSize),
            label: 'Summary',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_outlined, size: AppDimensions.bottomNavIconSize),
            activeIcon: Icon(Icons.analytics, size: AppDimensions.bottomNavIconSize),
            label: 'Analytics',
          ),
        ],
      ),
    );
  }

  Widget _buildAuthSection() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Authentication Status',
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildInfoRow('Authenticated', authProvider.isAuthenticated.toString()),
              _buildInfoRow('User ID', authProvider.currentUser?.id ?? 'null'),
              _buildInfoRow('User Email', authProvider.currentUser?.email ?? 'null'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTemplateSelection() {
    return Consumer<ProjectProvider>(
      builder: (context, projectProvider, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Template Selection',
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildInfoRow('Templates Loaded', projectProvider.projectTemplates.length.toString()),
              const SizedBox(height: 16),
              
              if (projectProvider.projectTemplates.isNotEmpty) ...[
                Text(
                  'Select Template:',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedTemplateId,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: projectProvider.projectTemplates.map((template) {
                    return DropdownMenuItem(
                      value: template.id,
                      child: Text(
                        template.title,
                        style: AppTextStyles.bodyMedium,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedTemplateId = value;
                    });
                  },
                ),
                
                if (_selectedTemplateId != null) ...[
                  const SizedBox(height: 16),
                  _buildSelectedTemplateInfo(),
                ],
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'No templates available. Make sure templates are loaded.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.warning,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSelectedTemplateInfo() {
    return Consumer<ProjectProvider>(
      builder: (context, projectProvider, child) {
        final template = projectProvider.projectTemplates
            .where((t) => t.id == _selectedTemplateId)
            .firstOrNull;
        
        if (template == null) return const SizedBox.shrink();
        
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Selected Template Info:',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              _buildInfoRow('Title', template.title),
              _buildInfoRow('Category', template.category),
              _buildInfoRow('Difficulty', template.difficultyText),
              _buildInfoRow('Estimated Hours', '${template.estimatedHours ?? 0}h'),
              _buildInfoRow('Steps Count', '${(template.projectSteps['steps'] as List? ?? []).length}'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStartSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Start Project Test',
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _selectedTemplateId != null && !_isStarting ? _testStartProject : null,
              icon: _isStarting 
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.play_arrow),
              label: Text(_isStarting ? 'Starting...' : 'Test Start Project'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Test Results',
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          if (_lastSuccess != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: AppColors.success,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Success',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _lastSuccess!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          
          if (_lastError != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.error,
                        color: AppColors.error,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Error',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _lastError!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          
          if (_lastSuccess == null && _lastError == null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.textTertiary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'No test results yet. Select a template and click "Test Start Project".',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _testStartProject() async {
    if (_selectedTemplateId == null) return;
    
    setState(() {
      _isStarting = true;
      _lastError = null;
      _lastSuccess = null;
    });

    final authProvider = context.read<AuthProvider>();
    final projectProvider = context.read<ProjectProvider>();
    
    try {
      print('🧪 Testing project start...');
      print('👤 User ID: ${authProvider.currentUser?.id}');
      print('📋 Template ID: $_selectedTemplateId');
      
      if (authProvider.currentUser == null) {
        throw Exception('User not authenticated');
      }

      final success = await projectProvider.startProject(
        userId: authProvider.currentUser!.id,
        templateId: _selectedTemplateId!,
      );

      if (success) {
        setState(() {
          _lastSuccess = 'Project started successfully! Check the "My Projects" tab to see your new project.';
        });
        SnackbarUtils.showSuccess(context, 'Project started successfully!');
      } else {
        setState(() {
          _lastError = projectProvider.error ?? 'Unknown error occurred';
        });
        SnackbarUtils.showError(context, projectProvider.error ?? 'Failed to start project');
      }
    } catch (e) {
      setState(() {
        _lastError = 'Exception: $e';
      });
      SnackbarUtils.showError(context, 'Error: $e');
    } finally {
      setState(() {
        _isStarting = false;
      });
    }
  }
}

extension IterableExtension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
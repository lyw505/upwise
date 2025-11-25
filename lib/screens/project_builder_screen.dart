import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
import '../core/constants/app_dimensions.dart';
import '../core/router/app_router.dart';
import '../core/utils/snackbar_utils.dart';
import '../providers/auth_provider.dart';
import '../providers/project_provider.dart';
import '../providers/learning_path_provider.dart';
import '../models/project_model.dart';
import '../models/learning_path_model.dart' as learning_path;

class ProjectBuilderScreen extends StatefulWidget {
  const ProjectBuilderScreen({super.key});

  @override
  State<ProjectBuilderScreen> createState() => _ProjectBuilderScreenState();
}

class _ProjectBuilderScreenState extends State<ProjectBuilderScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCategory = 'all';
  String _selectedDifficulty = 'all';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final projectProvider = context.read<ProjectProvider>();
    final learningPathProvider = context.read<LearningPathProvider>();
    final authProvider = context.read<AuthProvider>();
    
    if (authProvider.currentUser != null) {
      // Load learning paths first to get active learning path projects
      await learningPathProvider.loadLearningPaths(authProvider.currentUser!.id);
      
      await Future.wait([
        projectProvider.loadProjectTemplates(),
        projectProvider.loadUserProjects(authProvider.currentUser!.id),
        projectProvider.loadProjectAnalytics(authProvider.currentUser!.id),
        projectProvider.loadProjectRecommendations(authProvider.currentUser!.id),
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildLearningPathProjectsTab(),
                  _buildMyProjectsTab(),
                  _buildCompletedTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Projects',
                      style: AppTextStyles.headlineSmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Build portfolio projects with step-by-step guidance',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Debug button
                  IconButton(
                    onPressed: () => context.go('/project-debug'),
                    icon: const Icon(Icons.bug_report_outlined),
                    tooltip: 'Debug Project Builder',
                    iconSize: 20,
                  ),
                  // Start Debug button
                  IconButton(
                    onPressed: () => context.go('/project-start-debug'),
                    icon: const Icon(Icons.play_circle_outlined),
                    tooltip: 'Debug Project Start',
                    iconSize: 20,
                  ),
                  const SizedBox(width: 8),
                  Consumer<ProjectProvider>(
                    builder: (context, projectProvider, child) {
                      final analytics = projectProvider.analytics;
                      if (analytics == null) return const SizedBox.shrink();
                      
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: AppColors.primary,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${analytics.completedProjects}',
                              style: AppTextStyles.labelMedium.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildAIProjectBuilder(),
        ],
      ),
    );
  }

  Widget _buildAIProjectBuilder() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI-Powered Project Builder',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Build portfolio projects with step-by-step guidance',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppColors.surface,
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.primary,
        tabs: const [
          Tab(text: 'From Learning Path'),
          Tab(text: 'My Projects'),
          Tab(text: 'Completed'),
        ],
      ),
    );
  }

  Widget _buildLearningPathProjectsTab() {
    return Consumer2<LearningPathProvider, ProjectProvider>(
      builder: (context, learningPathProvider, projectProvider, child) {
        if (learningPathProvider.isLoading || projectProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // Get active learning paths
        final activeLearningPaths = learningPathProvider.learningPaths
            .where((path) => path.status == learning_path.LearningPathStatus.inProgress)
            .toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLearningPathProjectsHeader(),
              const SizedBox(height: 24),
              if (activeLearningPaths.isEmpty)
                _buildNoActiveLearningPathsMessage()
              else
                _buildActiveLearningPathProjects(activeLearningPaths),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLearningPathProjectsHeader() {
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
          Row(
            children: [
              Icon(
                Icons.school,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Learning Path Projects',
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildFeatureItem(
            'Projects are automatically generated based on your active learning paths.',
          ),
          _buildFeatureItem(
            'Complete projects to reinforce your learning and build your portfolio.',
          ),
          _buildFeatureItem(
            'Track your progress and showcase your completed work.',
          ),
        ],
      ),
    );
  }

  Widget _buildNoActiveLearningPathsMessage() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          Icon(
            Icons.school_outlined,
            size: 80,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            'No Active Learning Paths',
            style: AppTextStyles.headlineSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a learning path to see project recommendations here.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _tabController.animateTo(1), // Go to Learning Paths
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'Browse Learning Paths',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveLearningPathProjects(List<learning_path.LearningPathModel> activePaths) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: activePaths.map((path) => _buildLearningPathSection(path)).toList(),
    );
  }

  Widget _buildLearningPathSection(learning_path.LearningPathModel learningPath) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Learning Path Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary.withValues(alpha: 0.1), AppColors.primary.withValues(alpha: 0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.school,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        learningPath.topic,
                        style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${learningPath.progressPercentage.toStringAsFixed(0)}% Complete • ${learningPath.durationDays} days',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'ACTIVE',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Projects from this learning path
          if (learningPath.projectRecommendations.isEmpty)
            _buildNoProjectsForPath()
          else
            ...learningPath.projectRecommendations.map((project) => 
              _buildLearningPathProjectCard(project, learningPath)),
        ],
      ),
    );
  }

  Widget _buildNoProjectsForPath() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: AppColors.textTertiary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'No projects available for this learning path yet.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLearningPathProjectCard(learning_path.ProjectRecommendation project, learning_path.LearningPathModel learningPath) {
    Color difficultyColor;
    switch (project.difficulty?.toLowerCase()) {
      case 'beginner':
        difficultyColor = AppColors.success;
        break;
      case 'intermediate':
        difficultyColor = AppColors.warning;
        break;
      case 'advanced':
        difficultyColor = AppColors.error;
        break;
      default:
        difficultyColor = AppColors.textTertiary;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.build,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            project.title,
                            style: AppTextStyles.titleMedium.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              if (project.difficulty != null) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: difficultyColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: difficultyColor.withValues(alpha: 0.3)),
                                  ),
                                  child: Text(
                                    project.difficulty!.toUpperCase(),
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: difficultyColor,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              if (project.estimatedHours != null) ...[
                                Icon(
                                  Icons.access_time,
                                  size: 14,
                                  color: AppColors.textTertiary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${project.estimatedHours}h',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  project.description,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _startProjectFromLearningPath(project, learningPath),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Start Project',
                  style: AppTextStyles.buttonMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textSecondary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Row(
      children: [
        Expanded(
          child: _buildFilterDropdown(
            'Category',
            _selectedCategory,
            ['all', 'web', 'mobile', 'data', 'ai', 'game'],
            (value) => setState(() => _selectedCategory = value!),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildFilterDropdown(
            'Difficulty',
            _selectedDifficulty,
            ['all', 'beginner', 'intermediate', 'advanced'],
            (value) => setState(() => _selectedDifficulty = value!),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterDropdown(
    String label,
    String value,
    List<String> options,
    ValueChanged<String?> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          onChanged: onChanged,
          isExpanded: true,
          items: options.map((option) {
            return DropdownMenuItem(
              value: option,
              child: Text(
                option == 'all' ? 'All ${label}s' : option.capitalize(),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: 'Search projects...',
          hintStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textTertiary,
          ),
          border: InputBorder.none,
          icon: Icon(
            Icons.search,
            color: AppColors.textTertiary,
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendedProjects() {
    return Consumer<ProjectProvider>(
      builder: (context, projectProvider, child) {
        var templates = projectProvider.projectTemplates;

        // Apply filters
        if (_selectedCategory != 'all') {
          templates = templates.where((t) => t.category == _selectedCategory).toList();
        }
        if (_selectedDifficulty != 'all') {
          templates = templates.where((t) => t.difficultyLevel.toString().split('.').last == _selectedDifficulty).toList();
        }
        if (_searchQuery.isNotEmpty) {
          templates = projectProvider.searchTemplates(_searchQuery);
        }

        if (templates.isEmpty) {
          return Center(
            child: Column(
              children: [
                Icon(
                  Icons.search_off,
                  size: 64,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(height: 16),
                Text(
                  'No Projects Found',
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Try adjusting your filters or search terms.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recommended Projects',
              style: AppTextStyles.titleLarge.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...templates.map((template) => _buildProjectCard(template)),
          ],
        );
      },
    );
  }

  Widget _buildProjectCard(ProjectTemplate template) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getCategoryIcon(template.category),
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            template.title,
                            style: AppTextStyles.titleMedium.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              _buildDifficultyChip(template.difficultyLevel),
                              const SizedBox(width: 8),
                              if (template.estimatedHours != null) ...[
                                Icon(
                                  Icons.access_time,
                                  size: 14,
                                  color: AppColors.textTertiary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${template.estimatedHours}h',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  template.description,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                if (template.techStack.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: template.techStack.take(4).map((tech) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.textTertiary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          tech,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _startProject(template),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Start Project',
                  style: AppTextStyles.buttonMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultyChip(ProjectDifficulty difficulty) {
    Color color;
    switch (difficulty) {
      case ProjectDifficulty.beginner:
        color = AppColors.success;
        break;
      case ProjectDifficulty.intermediate:
        color = AppColors.warning;
        break;
      case ProjectDifficulty.advanced:
        color = AppColors.error;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        difficulty.toString().split('.').last.toUpperCase(),
        style: AppTextStyles.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'web':
        return Icons.web;
      case 'mobile':
        return Icons.phone_android;
      case 'data':
        return Icons.analytics;
      case 'ai':
        return Icons.psychology;
      case 'game':
        return Icons.games;
      default:
        return Icons.code;
    }
  }

  Widget _buildMyProjectsTab() {
    return Consumer<ProjectProvider>(
      builder: (context, projectProvider, child) {
        final activeProjects = projectProvider.getProjectsByStatus(ProjectStatus.inProgress);
        final notStartedProjects = projectProvider.getProjectsByStatus(ProjectStatus.notStarted);
        final allActiveProjects = [...notStartedProjects, ...activeProjects];

        if (allActiveProjects.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.work_outline,
                  size: 64,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(height: 16),
                Text(
                  'No Active Projects',
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start a project from the Recommended tab to begin building your portfolio.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textTertiary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => _tabController.animateTo(0),
                  child: const Text('Browse Projects'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: allActiveProjects.length,
          itemBuilder: (context, index) {
            return _buildUserProjectCard(allActiveProjects[index]);
          },
        );
      },
    );
  }

  Widget _buildCompletedTab() {
    return Consumer<ProjectProvider>(
      builder: (context, projectProvider, child) {
        final completedProjects = projectProvider.getProjectsByStatus(ProjectStatus.completed);

        if (completedProjects.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.emoji_events_outlined,
                  size: 64,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(height: 16),
                Text(
                  'No Completed Projects',
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Complete projects to build your portfolio and showcase your skills.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textTertiary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: completedProjects.length,
          itemBuilder: (context, index) {
            return _buildUserProjectCard(completedProjects[index]);
          },
        );
      },
    );
  }

  Widget _buildUserProjectCard(UserProject project) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project.title,
                        style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (project.description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          project.description!,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                _buildStatusChip(project.status),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Progress',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: project.progressPercentage / 100,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${project.progressPercentage.toStringAsFixed(0)}% • ${project.currentStep}/${project.totalSteps} steps',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                if (project.estimatedHours != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Time',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${project.actualHoursSpent.toStringAsFixed(1)}h',
                        style: AppTextStyles.titleSmall.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'of ${project.estimatedHours}h',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _viewProjectDetails(project),
                    child: const Text('View Details'),
                  ),
                ),
                if (project.status == ProjectStatus.notStarted) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _startExistingProject(project),
                      child: const Text('Start'),
                    ),
                  ),
                ] else if (project.status == ProjectStatus.inProgress) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _continueProject(project),
                      child: const Text('Continue'),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(ProjectStatus status) {
    Color color;
    String text;
    
    switch (status) {
      case ProjectStatus.notStarted:
        color = AppColors.textTertiary;
        text = 'Not Started';
        break;
      case ProjectStatus.inProgress:
        color = AppColors.primary;
        text = 'In Progress';
        break;
      case ProjectStatus.completed:
        color = AppColors.success;
        text = 'Completed';
        break;
      case ProjectStatus.paused:
        color = AppColors.warning;
        text = 'Paused';
        break;
      case ProjectStatus.cancelled:
        color = AppColors.error;
        text = 'Cancelled';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: AppTextStyles.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }



  Future<void> _startProject(ProjectTemplate template) async {
    final authProvider = context.read<AuthProvider>();
    final projectProvider = context.read<ProjectProvider>();
    
    print('🎯 _startProject called for template: ${template.title}');
    print('👤 Current user: ${authProvider.currentUser?.id}');
    
    if (authProvider.currentUser == null) {
      print('❌ No current user, showing error');
      SnackbarUtils.showError(context, 'Please log in to start a project');
      return;
    }

    print('🔄 Calling projectProvider.startProject...');
    final success = await projectProvider.startProject(
      userId: authProvider.currentUser!.id,
      templateId: template.id,
    );

    print('📊 startProject result: $success');
    print('🔍 projectProvider.error: ${projectProvider.error}');

    if (success && mounted) {
      SnackbarUtils.showSuccess(context, 'Project started successfully!');
      _tabController.animateTo(1); // Switch to My Projects tab
    } else if (mounted) {
      SnackbarUtils.showError(context, projectProvider.error ?? 'Failed to start project');
    }
  }

  Future<void> _startProjectFromLearningPath(learning_path.ProjectRecommendation project, learning_path.LearningPathModel learningPath) async {
    final authProvider = context.read<AuthProvider>();
    final projectProvider = context.read<ProjectProvider>();
    
    if (authProvider.currentUser == null) {
      SnackbarUtils.showError(context, 'Please log in to start a project');
      return;
    }

    // Create a project from learning path recommendation
    final success = await projectProvider.startProjectFromLearningPath(
      userId: authProvider.currentUser!.id,
      learningPathId: learningPath.id,
      projectRecommendation: project,
    );

    if (success && mounted) {
      SnackbarUtils.showSuccess(context, 'Project "${project.title}" started successfully!');
      _tabController.animateTo(1); // Switch to My Projects tab
    } else if (mounted) {
      SnackbarUtils.showError(context, projectProvider.error ?? 'Failed to start project');
    }
  }

  Future<void> _startExistingProject(UserProject project) async {
    final projectProvider = context.read<ProjectProvider>();
    
    final success = await projectProvider.updateProjectStatus(
      project.id,
      ProjectStatus.inProgress,
    );

    if (success && mounted) {
      SnackbarUtils.showSuccess(context, 'Project started!');
    }
  }

  void _continueProject(UserProject project) {
    // Navigate to project detail screen
    context.goToProjectDetail(project.id);
  }

  void _viewProjectDetails(UserProject project) {
    // Navigate to project detail screen
    context.goToProjectDetail(project.id);
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
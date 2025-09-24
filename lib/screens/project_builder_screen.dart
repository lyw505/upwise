import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
import '../widgets/consistent_header.dart';
import '../models/project_blueprint_model.dart';
import 'project_detail_screen.dart';

class ProjectBuilderScreen extends StatefulWidget {
  const ProjectBuilderScreen({super.key});

  @override
  State<ProjectBuilderScreen> createState() => _ProjectBuilderScreenState();
}

class _ProjectBuilderScreenState extends State<ProjectBuilderScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Beginner', 'Intermediate', 'Advanced'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          ConsistentHeader(
            title: 'Project Scoper',
            onProfileTap: () {
              // TODO: Implement profile tap
            },
          ),
          // Search and Filter Row
          Container(
            color: AppColors.background,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                // Search Box
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!, width: 1),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search projects...',
                        hintStyle: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: Colors.grey[500],
                          size: 20,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.clear,
                                  color: Colors.grey[500],
                                  size: 20,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Filter Button
                PopupMenuButton<String>(
                  initialValue: _selectedFilter,
                  onSelected: (String value) {
                    setState(() {
                      _selectedFilter = value;
                    });
                  },
                  itemBuilder: (BuildContext context) {
                    return _filters.map((String value) {
                      return PopupMenuItem<String>(
                        value: value,
                        child: Row(
                          children: [
                            Icon(
                              Icons.filter_list,
                              color: _selectedFilter == value 
                                  ? AppColors.primary 
                                  : Colors.grey[600],
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(value),
                          ],
                        ),
                      );
                    }).toList();
                  },
                  child: Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary,
                        width: 1.5
                      ),
                    ),
                    child: Icon(
                      Icons.filter_list,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildProjectBlueprints(),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildProjectBlueprints() {
    final allBlueprints = _getDummyProjectBlueprints();
    final filteredBlueprints = _getFilteredBlueprints(allBlueprints);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Project Scoper - Your Learning Projects',
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'AI-generated project blueprints tailored to your learning goals',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          
          if (filteredBlueprints.isEmpty && (_searchQuery.isNotEmpty || _selectedFilter != 'All'))
            _buildEmptySearchState()
          else
            ...filteredBlueprints.map((blueprint) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildProjectBlueprintCard(blueprint),
            )),
        ],
      ),
    );
  }

  Widget _buildEmptySearchState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          Icon(
            Icons.search_off,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No projects found',
            style: AppTextStyles.titleMedium.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filter',
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  List<ProjectBlueprint> _getFilteredBlueprints(List<ProjectBlueprint> blueprints) {
    var filtered = blueprints;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((blueprint) {
        return blueprint.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               blueprint.goalStatement.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               blueprint.category.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               blueprint.requiredSkills.any((skill) => skill.toLowerCase().contains(_searchQuery.toLowerCase()));
      }).toList();
    }

    // Apply difficulty filter
    if (_selectedFilter != 'All') {
      filtered = filtered.where((blueprint) {
        return blueprint.difficulty.toLowerCase() == _selectedFilter.toLowerCase();
      }).toList();
    }

    return filtered;
  }

  Widget _buildProjectBlueprintCard(ProjectBlueprint blueprint) {
    return GestureDetector(
      onTap: () => _navigateToProjectDetail(blueprint),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and category
            Row(
              children: [
                Expanded(
                  child: Text(
                    blueprint.title,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    blueprint.category,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Short description
            Text(
              blueprint.goalStatement,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            
            // Tags and info
            Row(
              children: [
                // Difficulty tag
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getDifficultyColor(blueprint.difficulty).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    blueprint.difficulty.toUpperCase(),
                    style: AppTextStyles.labelSmall.copyWith(
                      color: _getDifficultyColor(blueprint.difficulty),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Duration
                Icon(
                  Icons.schedule,
                  size: 14,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 4),
                Text(
                  '${blueprint.estimatedDuration} days',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const Spacer(),
                // Progress indicator if started
                if (blueprint.isStarted) ...[
                  Icon(
                    Icons.play_circle_filled,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'In Progress',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ] else ...[
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Colors.grey[400],
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return Colors.green;
      case 'intermediate':
        return Colors.orange;
      case 'advanced':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  List<ProjectBlueprint> _getDummyProjectBlueprints() {
    final now = DateTime.now();
    return [
      ProjectBlueprint(
        id: 'blueprint_1',
        userId: 'dummy_user',
        title: 'Flutter E-Commerce Mobile App',
        goalStatement: 'Build a complete e-commerce mobile application with user authentication, product catalog, shopping cart, and payment integration to master Flutter development and state management.',
        requiredSkills: ['Flutter', 'Dart', 'State Management', 'REST APIs', 'Firebase'],
        requiredTools: ['Flutter SDK', 'VS Code', 'Firebase', 'Stripe API', 'Git'],
        milestones: [
          ProjectMilestone(
            id: 'milestone_1',
            title: 'Setup & Authentication',
            description: 'Project setup, user registration, login, and profile management',
            tasks: ['Create Flutter project', 'Setup Firebase', 'Implement authentication', 'Design login/signup UI'],
            estimatedDays: 5,
          ),
          ProjectMilestone(
            id: 'milestone_2',
            title: 'Product Catalog & UI',
            description: 'Build product listing, search, and detail screens',
            tasks: ['Design product cards', 'Implement search', 'Create product details', 'Add favorites'],
            estimatedDays: 7,
          ),
          ProjectMilestone(
            id: 'milestone_3',
            title: 'Shopping Cart & Checkout',
            description: 'Implement cart functionality and payment flow',
            tasks: ['Build cart screen', 'Implement quantity controls', 'Add checkout flow', 'Integrate payment'],
            estimatedDays: 6,
          ),
          ProjectMilestone(
            id: 'milestone_4',
            title: 'Testing & Deployment',
            description: 'Test the app thoroughly and deploy to app stores',
            tasks: ['Write unit tests', 'UI testing', 'Performance optimization', 'Deploy to stores'],
            estimatedDays: 4,
          ),
        ],
        estimatedDuration: 22,
        dailyStudyHours: 2,
        difficulty: 'intermediate',
        category: 'Mobile Development',
        createdAt: now.subtract(const Duration(hours: 1)),
        isStarted: true,
      ),
      ProjectBlueprint(
        id: 'blueprint_2',
        userId: 'dummy_user',
        title: 'React Task Management Dashboard',
        goalStatement: 'Create a comprehensive task management web application with real-time updates, team collaboration features, and advanced filtering to master React and modern web development.',
        requiredSkills: ['React', 'JavaScript', 'Node.js', 'MongoDB', 'Socket.io'],
        requiredTools: ['VS Code', 'Node.js', 'MongoDB', 'React DevTools', 'Postman'],
        milestones: [
          ProjectMilestone(
            id: 'milestone_1',
            title: 'Frontend Foundation',
            description: 'Setup React app with routing and basic components',
            tasks: ['Create React app', 'Setup routing', 'Design layout', 'Create reusable components'],
            estimatedDays: 4,
          ),
          ProjectMilestone(
            id: 'milestone_2',
            title: 'Backend API',
            description: 'Build REST API with authentication and task management',
            tasks: ['Setup Express server', 'Create database models', 'Implement auth', 'Build task APIs'],
            estimatedDays: 6,
          ),
          ProjectMilestone(
            id: 'milestone_3',
            title: 'Real-time Features',
            description: 'Add real-time updates and collaboration features',
            tasks: ['Integrate Socket.io', 'Real-time notifications', 'Team collaboration', 'Live updates'],
            estimatedDays: 5,
          ),
        ],
        estimatedDuration: 15,
        dailyStudyHours: 3,
        difficulty: 'advanced',
        category: 'Web Development',
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      ProjectBlueprint(
        id: 'blueprint_3',
        userId: 'dummy_user',
        title: 'Python Data Analysis Portfolio',
        goalStatement: 'Build a comprehensive data analysis portfolio showcasing skills in data cleaning, visualization, and machine learning using real-world datasets.',
        requiredSkills: ['Python', 'Pandas', 'NumPy', 'Matplotlib', 'Scikit-learn'],
        requiredTools: ['Jupyter Notebook', 'Python', 'Git', 'Kaggle', 'GitHub Pages'],
        milestones: [
          ProjectMilestone(
            id: 'milestone_1',
            title: 'Data Collection & Cleaning',
            description: 'Gather datasets and perform comprehensive data cleaning',
            tasks: ['Find datasets', 'Data exploration', 'Handle missing values', 'Data preprocessing'],
            estimatedDays: 3,
          ),
          ProjectMilestone(
            id: 'milestone_2',
            title: 'Exploratory Analysis',
            description: 'Perform statistical analysis and create visualizations',
            tasks: ['Statistical analysis', 'Create charts', 'Find patterns', 'Generate insights'],
            estimatedDays: 4,
          ),
          ProjectMilestone(
            id: 'milestone_3',
            title: 'Portfolio Website',
            description: 'Create and deploy portfolio website showcasing projects',
            tasks: ['Build website', 'Write case studies', 'Deploy online', 'Add documentation'],
            estimatedDays: 3,
          ),
        ],
        estimatedDuration: 10,
        dailyStudyHours: 2,
        difficulty: 'beginner',
        category: 'Data Science',
        createdAt: now.subtract(const Duration(days: 5)),
      ),
    ];
  }

  void _showCreateProjectDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Project'),
        content: const Text('Project creation feature coming soon!\n\nThis will allow you to input your learning goals and generate custom project blueprints.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _navigateToProjectDetail(ProjectBlueprint blueprint) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProjectDetailScreen(blueprint: blueprint),
      ),
    );
  }

  void _startProject(ProjectBlueprint blueprint) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${blueprint.isStarted ? 'Continuing' : 'Starting'} project: ${blueprint.title}'),
        backgroundColor: AppColors.primary,
        action: SnackBarAction(
          label: 'View Details',
          textColor: Colors.white,
          onPressed: () => _navigateToProjectDetail(blueprint),
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.of(context).pushNamed('/create-project');
          },
          borderRadius: BorderRadius.circular(12),
          child: const Center(
            child: Icon(
              Icons.add,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
import '../core/constants/app_dimensions.dart';
import '../core/router/app_router.dart';
import '../widgets/consistent_header.dart';
import '../providers/learning_path_provider.dart';
import '../models/learning_path_model.dart';

class LearningPathsScreen extends StatefulWidget {
  const LearningPathsScreen({super.key});

  @override
  State<LearningPathsScreen> createState() => _LearningPathsScreenState();
}

class _LearningPathsScreenState extends State<LearningPathsScreen> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Active', 'Completed', 'Not Started'];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showProfileMenu() {
    context.goToProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: _buildFloatingActionButton(),
      body: Column(
        children: [
          ConsistentHeader(
            title: 'Learning Paths',
            onProfileTap: _showProfileMenu,
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
                        hintText: 'Search learning paths...',
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
          
          const SizedBox(height: 20),

          // Learning Paths List
          Expanded(
            child: Consumer<LearningPathProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final filteredPaths = _getFilteredPaths(provider.learningPaths);

                if (filteredPaths.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  itemCount: filteredPaths.length,
                  itemBuilder: (context, index) {
                    return _buildLearningPathCard(filteredPaths[index]);
                  },
                );
              },
            ),
          ),
          ],
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
          onTap: () => context.goToCreatePath(),
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

  List<LearningPathModel> _getFilteredPaths(List<LearningPathModel> paths) {
    var filteredPaths = paths;
    
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filteredPaths = filteredPaths.where((path) {
        return path.topic.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               path.description.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }
    
    // Apply status filter
    if (_selectedFilter != 'All') {
      filteredPaths = filteredPaths.where((path) {
        switch (_selectedFilter) {
          case 'Active':
            return path.status == LearningPathStatus.inProgress;
          case 'Completed':
            return path.status == LearningPathStatus.completed;
          case 'Not Started':
            return path.progressPercentage == 0.0;
          default:
            return true;
        }
      }).toList();
    }
    
    return filteredPaths;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.school_outlined,
            size: AppDimensions.iconXXLarge + 16, // 80px
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No learning paths yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first learning path to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLearningPathCard(LearningPathModel path) {
    Color statusColor;
    String statusText;

    switch (path.status) {
      case LearningPathStatus.notStarted:
        statusColor = AppColors.textSecondary;
        statusText = 'Not Started';
        break;
      case LearningPathStatus.inProgress:
        statusColor = AppColors.primary;
        statusText = 'In Progress';
        break;
      case LearningPathStatus.completed:
        statusColor = Colors.green;
        statusText = 'Completed';
        break;
      case LearningPathStatus.paused:
        statusColor = Colors.orange;
        statusText = 'Paused';
        break;
    }

    return GestureDetector(
      onTap: () => context.goToViewPath(path.id),
      child: Container(
        margin: EdgeInsets.only(bottom: AppDimensions.spaceMedium),
        padding: EdgeInsets.all(AppDimensions.cardPaddingLarge),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: AppDimensions.shadowBlurRadius,
              offset: Offset(0, AppDimensions.shadowOffset),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    path.topic,
                    style: AppTextStyles.titleLarge.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusText,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: AppDimensions.iconXSmall,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(width: 4),
                Text(
                  '${path.durationDays} days',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.access_time,
                  size: AppDimensions.iconXSmall,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(width: 4),
                Text(
                  '${path.dailyTimeMinutes} min/day',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Progress Bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progress',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${path.progressPercentage.toStringAsFixed(0)}%',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  height: AppDimensions.progressBarHeightThick,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(AppDimensions.progressBarHeightThick / 2),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: path.progressPercentage / 100,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(AppDimensions.progressBarHeightThick / 2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${path.completedOrSkippedTasksCount}/${path.dailyTasks.length} tasks completed',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
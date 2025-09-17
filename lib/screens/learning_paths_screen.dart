import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
import '../core/router/app_router.dart';
import '../providers/learning_path_provider.dart';
import '../models/learning_path_model.dart';

class LearningPathsScreen extends StatefulWidget {
  const LearningPathsScreen({super.key});

  @override
  State<LearningPathsScreen> createState() => _LearningPathsScreenState();
}

class _LearningPathsScreenState extends State<LearningPathsScreen> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Active', 'Completed', 'Paused', 'Not Started'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Learning Paths',
                    style: AppTextStyles.headlineLarge.copyWith(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedFilter,
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedFilter = newValue;
                            });
                          }
                        },
                        icon: const Icon(
                          Icons.keyboard_arrow_down,
                          color: AppColors.primary,
                        ),
                        isDense: true,
                        items: _filters.map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.filter_list,
                                    color: _selectedFilter == value 
                                        ? AppColors.primary 
                                        : Colors.grey[600],
                                    size: 18,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    value,
                                    style: TextStyle(
                                      color: _selectedFilter == value 
                                          ? AppColors.primary 
                                          : Colors.black,
                                      fontWeight: _selectedFilter == value 
                                          ? FontWeight.w600 
                                          : FontWeight.normal,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
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
      ),
    );
  }


  List<LearningPathModel> _getFilteredPaths(List<LearningPathModel> paths) {
    if (_selectedFilter == 'All') return paths;
    
    return paths.where((path) {
      switch (_selectedFilter) {
        case 'Active':
          return path.status == LearningPathStatus.inProgress;
        case 'Completed':
          return path.status == LearningPathStatus.completed;
        case 'Paused':
          return path.status == LearningPathStatus.paused;
        case 'Not Started':
          return path.status == LearningPathStatus.notStarted;
        default:
          return true;
      }
    }).toList();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.school_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Learning Paths Found',
            style: AppTextStyles.titleLarge.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first learning path to get started!',
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.goToCreatePath(),
            icon: const Icon(Icons.add),
            label: const Text('Create Learning Path'),
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
        statusColor = Colors.grey[600]!;
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
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[300]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
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
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
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
            const SizedBox(height: 8),
            if (path.description.isNotEmpty)
              Text(
                path.description,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 16,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 4),
                Text(
                  '${path.durationDays} days',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 4),
                Text(
                  '${path.dailyTimeMinutes} min/day',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.grey[600],
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
                        color: Colors.grey[700],
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
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: path.progressPercentage / 100,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${path.completedOrSkippedTasksCount}/${path.dailyTasks.length} tasks completed',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.grey[500],
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
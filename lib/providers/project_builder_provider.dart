import 'package:flutter/material.dart';
import '../models/project_model.dart';
import '../core/constants/app_colors.dart';

class ProjectBuilderProvider with ChangeNotifier {
  List<ProjectModel> _recommendedProjects = [];
  List<ProjectModel> _myProjects = [];
  List<ProjectModel> _completedProjects = [];
  bool _isLoading = false;
  String? _error;

  List<ProjectModel> get recommendedProjects => _recommendedProjects;
  List<ProjectModel> get myProjects => _myProjects;
  List<ProjectModel> get completedProjects => _completedProjects;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadProjects() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Simulate API call delay
      await Future.delayed(const Duration(seconds: 1));

      // Mock recommended projects data
      _recommendedProjects = [
        ProjectModel(
          id: '1',
          title: 'Build a Personal Finance Dashboard in Excel',
          description: 'Create a comprehensive personal finance dashboard with automated calculations, charts, and expense tracking features.',
          category: 'Business',
          categoryColor: AppColors.primaryDark,
          categoryIcon: Icons.business,
          difficulty: 'Beginner',
          estimatedDays: 7,
          totalSteps: 12,
          portfolioValue: 8.5,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          steps: [
            ProjectStep(
              id: '1-1',
              title: 'Set up Excel workbook structure',
              description: 'Create worksheets for income, expenses, categories, and dashboard',
              order: 1,
              resources: ['Excel templates', 'Tutorial videos'],
              checklist: ['Create Income sheet', 'Create Expenses sheet', 'Create Categories sheet', 'Create Dashboard sheet'],
            ),
            ProjectStep(
              id: '1-2',
              title: 'Design income tracking system',
              description: 'Build automated income calculation with multiple sources',
              order: 2,
              resources: ['Excel formulas guide', 'Sample data'],
              checklist: ['Add income categories', 'Create monthly totals', 'Add validation rules'],
            ),
          ],
          resources: [
            'Excel Advanced Functions Guide',
            'Dashboard Design Best Practices',
            'Financial Planning Templates',
            'Data Visualization in Excel'
          ],
          technologies: ['Microsoft Excel', 'VBA (optional)', 'Data Analysis'],
        ),
        ProjectModel(
          id: '2',
          title: 'Create a Task Management Web App',
          description: 'Build a full-stack task management application with user authentication, real-time updates, and team collaboration features.',
          category: 'Web Development',
          categoryColor: AppColors.primary,
          categoryIcon: Icons.web,
          difficulty: 'Intermediate',
          estimatedDays: 21,
          totalSteps: 18,
          portfolioValue: 9.2,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          resources: [
            'React.js Documentation',
            'Node.js Best Practices',
            'MongoDB Tutorial',
            'Authentication Guide'
          ],
          technologies: ['React.js', 'Node.js', 'MongoDB', 'Express.js', 'JWT'],
        ),
        ProjectModel(
          id: '3',
          title: 'Mobile Expense Tracker App',
          description: 'Develop a cross-platform mobile app for tracking daily expenses with categories, budgets, and spending analytics.',
          category: 'Mobile Development',
          categoryColor: AppColors.success,
          categoryIcon: Icons.phone_android,
          difficulty: 'Intermediate',
          estimatedDays: 14,
          totalSteps: 15,
          portfolioValue: 8.8,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          resources: [
            'Flutter Documentation',
            'Firebase Setup Guide',
            'Mobile UI/UX Patterns',
            'App Store Guidelines'
          ],
          technologies: ['Flutter', 'Dart', 'Firebase', 'SQLite'],
        ),
        ProjectModel(
          id: '4',
          title: 'Data Analysis Dashboard with Python',
          description: 'Create an interactive data analysis dashboard using Python, Pandas, and Plotly to visualize business metrics.',
          category: 'Data Science',
          categoryColor: const Color(0xFF8B5CF6),
          categoryIcon: Icons.analytics,
          difficulty: 'Advanced',
          estimatedDays: 10,
          totalSteps: 14,
          portfolioValue: 9.5,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          resources: [
            'Pandas Documentation',
            'Plotly Tutorial',
            'Data Visualization Guide',
            'Python Best Practices'
          ],
          technologies: ['Python', 'Pandas', 'Plotly', 'Streamlit', 'NumPy'],
        ),
        ProjectModel(
          id: '5',
          title: 'E-commerce Website Design',
          description: 'Design a modern, responsive e-commerce website with user-friendly interface and optimized checkout flow.',
          category: 'Design',
          categoryColor: AppColors.error,
          categoryIcon: Icons.design_services,
          difficulty: 'Beginner',
          estimatedDays: 12,
          totalSteps: 10,
          portfolioValue: 7.8,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          resources: [
            'Figma Design System',
            'UI/UX Best Practices',
            'E-commerce Design Patterns',
            'Accessibility Guidelines'
          ],
          technologies: ['Figma', 'Adobe XD', 'Sketch', 'Prototyping'],
        ),
      ];

      // Mock my projects data (in progress)
      _myProjects = [
        ProjectModel(
          id: 'my-1',
          title: 'Personal Portfolio Website',
          description: 'Building a responsive portfolio website to showcase my projects and skills.',
          category: 'Web Development',
          categoryColor: AppColors.primary,
          categoryIcon: Icons.web,
          difficulty: 'Beginner',
          estimatedDays: 5,
          totalSteps: 8,
          completedSteps: 3,
          portfolioValue: 7.5,
          status: 'In Progress',
          progressPercentage: 37.5,
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
          updatedAt: DateTime.now(),
        ),
        ProjectModel(
          id: 'my-2',
          title: 'Budget Tracker Mobile App',
          description: 'Developing a mobile app for personal budget tracking with expense categorization.',
          category: 'Mobile Development',
          categoryColor: AppColors.success,
          categoryIcon: Icons.phone_android,
          difficulty: 'Intermediate',
          estimatedDays: 14,
          totalSteps: 12,
          completedSteps: 7,
          portfolioValue: 8.2,
          status: 'In Progress',
          progressPercentage: 58.3,
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
          updatedAt: DateTime.now(),
        ),
      ];

      // Mock completed projects data
      _completedProjects = [
        ProjectModel(
          id: 'completed-1',
          title: 'Weather App with API Integration',
          description: 'A weather application that fetches real-time weather data from external APIs.',
          category: 'Web Development',
          categoryColor: AppColors.primary,
          categoryIcon: Icons.web,
          difficulty: 'Beginner',
          estimatedDays: 3,
          totalSteps: 6,
          completedSteps: 6,
          portfolioValue: 6.8,
          status: 'Completed',
          progressPercentage: 100.0,
          completedDate: '2024-01-15',
          createdAt: DateTime.now().subtract(const Duration(days: 20)),
          updatedAt: DateTime.now().subtract(const Duration(days: 5)),
        ),
      ];

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> startProject(ProjectModel project) async {
    try {
      // Create a copy of the project with "In Progress" status
      final newProject = project.copyWith(
        status: 'In Progress',
        progressPercentage: 0.0,
        completedSteps: 0,
      );

      // Add to my projects
      _myProjects.add(newProject);
      
      // Remove from recommended projects
      _recommendedProjects.removeWhere((p) => p.id == project.id);
      
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateProjectProgress(String projectId, int completedSteps) async {
    try {
      final projectIndex = _myProjects.indexWhere((p) => p.id == projectId);
      if (projectIndex != -1) {
        final project = _myProjects[projectIndex];
        final progressPercentage = (completedSteps / project.totalSteps) * 100;
        
        final updatedProject = project.copyWith(
          completedSteps: completedSteps,
          progressPercentage: progressPercentage,
          status: progressPercentage == 100 ? 'Completed' : 'In Progress',
          updatedAt: DateTime.now(),
        );

        _myProjects[projectIndex] = updatedProject;

        // If completed, move to completed projects
        if (progressPercentage == 100) {
          _completedProjects.add(updatedProject.copyWith(
            completedDate: DateTime.now().toString().split(' ')[0],
          ));
          _myProjects.removeAt(projectIndex);
        }

        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> pauseProject(String projectId) async {
    try {
      final projectIndex = _myProjects.indexWhere((p) => p.id == projectId);
      if (projectIndex != -1) {
        final project = _myProjects[projectIndex];
        final updatedProject = project.copyWith(
          status: 'Paused',
          updatedAt: DateTime.now(),
        );
        _myProjects[projectIndex] = updatedProject;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> resumeProject(String projectId) async {
    try {
      final projectIndex = _myProjects.indexWhere((p) => p.id == projectId);
      if (projectIndex != -1) {
        final project = _myProjects[projectIndex];
        final updatedProject = project.copyWith(
          status: 'In Progress',
          updatedAt: DateTime.now(),
        );
        _myProjects[projectIndex] = updatedProject;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
import '../core/config/env_config.dart';
import '../providers/auth_provider.dart';
import '../providers/project_provider.dart';
import '../providers/learning_path_provider.dart';

class ProjectDebugScreen extends StatefulWidget {
  const ProjectDebugScreen({super.key});

  @override
  State<ProjectDebugScreen> createState() => _ProjectDebugScreenState();
}

class _ProjectDebugScreenState extends State<ProjectDebugScreen> {
  Map<String, dynamic> _debugInfo = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDebugInfo();
  }

  Future<void> _loadDebugInfo() async {
    setState(() {
      _isLoading = true;
    });

    final authProvider = context.read<AuthProvider>();
    final projectProvider = context.read<ProjectProvider>();
    final learningPathProvider = context.read<LearningPathProvider>();

    Map<String, dynamic> debugInfo = {
      'timestamp': DateTime.now().toIso8601String(),
      'authentication': {
        'isAuthenticated': authProvider.isAuthenticated,
        'currentUser': authProvider.currentUser?.id,
        'userEmail': authProvider.currentUser?.email,
      },
      'environment': {
        'supabaseUrl': EnvConfig.supabaseUrl,
        'hasSupabaseKey': EnvConfig.supabaseAnonKey.isNotEmpty,
        'hasGeminiKey': EnvConfig.hasGeminiApiKey,
        'appEnv': EnvConfig.appEnv,
      },
      'projectProvider': {
        'isLoading': projectProvider.isLoading,
        'error': projectProvider.error,
        'templatesCount': projectProvider.projectTemplates.length,
        'userProjectsCount': projectProvider.userProjects.length,
      },
      'learningPathProvider': {
        'isLoading': learningPathProvider.isLoading,
        'errorMessage': learningPathProvider.errorMessage,
        'pathsCount': learningPathProvider.learningPaths.length,
      },
    };

    // Test database connections
    try {
      if (authProvider.currentUser != null) {
        await projectProvider.loadProjectTemplates();
        await projectProvider.loadUserProjects(authProvider.currentUser!.id);
        await learningPathProvider.loadLearningPaths(authProvider.currentUser!.id);
        
        debugInfo['databaseTest'] = {
          'templatesLoaded': projectProvider.projectTemplates.length,
          'userProjectsLoaded': projectProvider.userProjects.length,
          'learningPathsLoaded': learningPathProvider.learningPaths.length,
          'projectProviderError': projectProvider.error,
          'learningPathProviderError': learningPathProvider.errorMessage,
          'hasProjectTemplates': projectProvider.projectTemplates.isNotEmpty,
          'canCreateProjects': projectProvider.projectTemplates.isNotEmpty && authProvider.currentUser != null,
        };
      } else {
        debugInfo['databaseTest'] = {
          'error': 'User not authenticated - Please login first',
          'canCreateProjects': false,
        };
      }
    } catch (e) {
      debugInfo['databaseTest'] = {
        'error': e.toString(),
        'canCreateProjects': false,
      };
    }

    setState(() {
      _debugInfo = debugInfo;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Builder Debug'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadDebugInfo,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDebugSection('Authentication', _debugInfo['authentication']),
                  const SizedBox(height: 16),
                  _buildDebugSection('Environment', _debugInfo['environment']),
                  const SizedBox(height: 16),
                  _buildDebugSection('Project Provider', _debugInfo['projectProvider']),
                  const SizedBox(height: 16),
                  _buildDebugSection('Learning Path Provider', _debugInfo['learningPathProvider']),
                  const SizedBox(height: 16),
                  _buildDebugSection('Database Test', _debugInfo['databaseTest']),
                  const SizedBox(height: 24),
                  _buildActionButtons(),
                ],
              ),
            ),
    );
  }

  Widget _buildDebugSection(String title, dynamic data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (data != null)
              ...data.entries.map<Widget>((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 120,
                        child: Text(
                          '${entry.key}:',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          entry.value?.toString() ?? 'null',
                          style: TextStyle(
                            color: _getValueColor(entry.value),
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList()
            else
              const Text('No data available'),
          ],
        ),
      ),
    );
  }

  Color _getValueColor(dynamic value) {
    if (value == null || value == false || value == 0) {
      return Colors.red[600]!;
    } else if (value == true || (value is num && value > 0)) {
      return Colors.green[600]!;
    } else if (value.toString().toLowerCase().contains('error')) {
      return Colors.red[600]!;
    }
    return Colors.black87;
  }

  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: _testProjectTemplates,
          icon: const Icon(Icons.build),
          label: const Text('Test Load Project Templates'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: _testUserProjects,
          icon: const Icon(Icons.work),
          label: const Text('Test Load User Projects'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: _testCreateProject,
          icon: const Icon(Icons.add),
          label: const Text('Test Create Sample Project'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: _checkDatabaseTables,
          icon: const Icon(Icons.storage),
          label: const Text('Check Database Tables'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple,
            foregroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 8),
        Text(
          'Database Setup',
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[600], size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Database Schema Required',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[800],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'If you see "table does not exist" errors, you need to deploy the database schema:',
                style: TextStyle(color: Colors.blue[700]),
              ),
              const SizedBox(height: 8),
              Text(
                '1. Copy content from project_builder_minimal_test.sql\n'
                '2. Paste in Supabase SQL Editor\n'
                '3. Run the script\n'
                '4. Refresh this debug screen',
                style: TextStyle(
                  color: Colors.blue[700],
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _testProjectTemplates() async {
    final projectProvider = context.read<ProjectProvider>();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Testing project templates...')),
    );

    try {
      await projectProvider.loadProjectTemplates();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Loaded ${projectProvider.projectTemplates.length} templates'),
            backgroundColor: Colors.green,
          ),
        );
        _loadDebugInfo();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _testUserProjects() async {
    final authProvider = context.read<AuthProvider>();
    final projectProvider = context.read<ProjectProvider>();
    
    if (authProvider.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ User not authenticated'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Testing user projects...')),
    );

    try {
      await projectProvider.loadUserProjects(authProvider.currentUser!.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Loaded ${projectProvider.userProjects.length} user projects'),
            backgroundColor: Colors.green,
          ),
        );
        _loadDebugInfo();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _testCreateProject() async {
    final authProvider = context.read<AuthProvider>();
    final projectProvider = context.read<ProjectProvider>();
    
    if (authProvider.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ User not authenticated'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Testing create project...')),
    );

    // First load templates to get a template ID
    try {
      await projectProvider.loadProjectTemplates();
      
      if (projectProvider.projectTemplates.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ No project templates available'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final template = projectProvider.projectTemplates.first;
      final success = await projectProvider.startProject(
        userId: authProvider.currentUser!.id,
        templateId: template.id,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? '✅ Project created successfully!' : '❌ Failed to create project'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
        if (success) {
          _loadDebugInfo();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _checkDatabaseTables() async {
    final authProvider = context.read<AuthProvider>();
    
    if (authProvider.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ User not authenticated'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Checking database tables...')),
    );

    try {
      // Try to query each table to see if it exists
      final supabase = Supabase.instance.client;
      
      Map<String, bool> tableStatus = {};
      
      // Check project_templates
      try {
        await supabase.from('project_templates').select('id').limit(1);
        tableStatus['project_templates'] = true;
      } catch (e) {
        tableStatus['project_templates'] = false;
      }
      
      // Check user_projects
      try {
        await supabase.from('user_projects').select('id').limit(1);
        tableStatus['user_projects'] = true;
      } catch (e) {
        tableStatus['user_projects'] = false;
      }
      
      // Check project_step_completions
      try {
        await supabase.from('project_step_completions').select('id').limit(1);
        tableStatus['project_step_completions'] = true;
      } catch (e) {
        tableStatus['project_step_completions'] = false;
      }

      if (mounted) {
        final allTablesExist = tableStatus.values.every((exists) => exists);
        final missingTables = tableStatus.entries
            .where((entry) => !entry.value)
            .map((entry) => entry.key)
            .toList();

        if (allTablesExist) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ All database tables exist!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Missing tables: ${missingTables.join(', ')}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
        
        _loadDebugInfo();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Database check failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
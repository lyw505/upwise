import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
import '../core/config/env_config.dart';
import '../widgets/consistent_header.dart';
import '../models/content_summary_model.dart';
import '../providers/summarizer_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/learning_path_provider.dart';

// Custom clipper for wave effect
class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 30);
    
    var firstControlPoint = Offset(size.width * 0.25, size.height);
    var firstEndPoint = Offset(size.width * 0.5, size.height - 15);
    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );
    
    var secondControlPoint = Offset(size.width * 0.75, size.height - 30);
    var secondEndPoint = Offset(size.width, size.height - 5);
    path.quadraticBezierTo(
      secondControlPoint.dx,
      secondControlPoint.dy,
      secondEndPoint.dx,
      secondEndPoint.dy,
    );
    
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }
  
  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class SummarizerScreen extends StatefulWidget {
  const SummarizerScreen({super.key});

  @override
  State<SummarizerScreen> createState() => _SummarizerScreenState();
}

class _SummarizerScreenState extends State<SummarizerScreen> {
  final _contentController = TextEditingController();
  final _urlController = TextEditingController();
  final _titleController = TextEditingController();
  final _tagsController = TextEditingController();
  final _searchController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  ContentType _selectedContentType = ContentType.text;
  DifficultyLevel? _targetDifficulty;
  bool _includeKeyPoints = true;
  String? _selectedLearningPathId;
  bool _showCreateForm = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _contentController.dispose();
    _urlController.dispose();
    _titleController.dispose();
    _tagsController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _loadData() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final summarizerProvider = context.read<SummarizerProvider>();
      final learningPathProvider = context.read<LearningPathProvider>();
      final authProvider = context.read<AuthProvider>();
      
      // Check if user is authenticated for database access
      if (authProvider.currentUser != null) {
        // Initialize default categories for new users
        await summarizerProvider.initializeDefaultCategories();
        
        // Load summaries and categories from Supabase database
        summarizerProvider.loadSummaries();
        summarizerProvider.loadCategories();
        
        // Load learning paths for integration
        learningPathProvider.loadLearningPaths(authProvider.currentUser!.id);
      } else {
        // Redirect to login if not authenticated
        if (mounted) {
          context.go('/login');
        }
      }
    });
  }

  Widget _buildModernAppBar() {
    return Container(
      color: AppColors.background,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  if (_showCreateForm)
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios),
                      onPressed: () {
                        setState(() {
                          _showCreateForm = false;
                        });
                      },
                    ),
                  Icon(
                    Icons.auto_awesome,
                    color: AppColors.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'AI Summarizer',
                          style: AppTextStyles.headlineSmall.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Transform content into insights',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!_showCreateForm) ...[
                    IconButton(
                      icon: const Icon(Icons.category_outlined),
                      onPressed: _showCategoriesDialog,
                      tooltip: 'Manage Categories',
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: _showCreateCategoryDialog,
                      tooltip: 'Create Category',
                    ),
                    IconButton(
                      icon: const Icon(Icons.bug_report_outlined),
                      onPressed: _showDebugInfo,
                      tooltip: 'Debug Info',
                    ),
                  ],
                ],
              ),
              if (!_showCreateForm) ...[
                const SizedBox(height: 16),
                Container(
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
                      hintText: 'Search summaries...',
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
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          ConsistentHeader(
            title: 'AI Summarizer',
            showProfile: false,
          ),
          Expanded(
            child: _showCreateForm ? _buildCreateTab() : _buildLibraryTab(),
          ),
        ],
      ),
      floatingActionButton: _showCreateForm ? null : _buildFloatingActionButton(),
    );
  }

  Widget _buildCreateTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildModernContentTypeSelector(),
            const SizedBox(height: 28),
            _buildModernContentInput(),
            const SizedBox(height: 28),
            _buildModernSummaryOptions(),
            const SizedBox(height: 40),
            _buildGenerateButton(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }



  Widget _buildModernContentTypeSelector() {
    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.category_outlined, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Select Content Type',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _buildContentTypeOption(
                  ContentType.text,
                  'Text',
                  Icons.text_fields,
                  'Paste or type your content',
                ),
                const SizedBox(width: 12),
                _buildContentTypeOption(
                  ContentType.url,
                  'URL',
                  Icons.link,
                  'Web articles, YouTube videos',
                ),
                const SizedBox(width: 12),
                _buildContentTypeOption(
                  ContentType.file,
                  'File',
                  Icons.description,
                  'PDF, documents',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentTypeOption(ContentType type, String label, IconData icon, String description) {
    final isSelected = _selectedContentType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedContentType = type;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.grey[50],
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? AppColors.primary : Colors.grey[600],
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isSelected ? AppColors.primary : Colors.grey[800],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.primary),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildModernTextArea({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: TextFormField(
        controller: controller,
        validator: validator,
        maxLines: 8,
        decoration: InputDecoration(
          hintText: label,
          hintStyle: TextStyle(
            color: Colors.grey[500],
            fontSize: 16,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(20),
        ),
        style: const TextStyle(
          fontSize: 16,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.titleMedium.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildContentInput() {
    if (_selectedContentType == ContentType.url) {
      return TextFormField(
        controller: _urlController,
        decoration: const InputDecoration(
          hintText: 'https://example.com/article',
          prefixIcon: Icon(Icons.link),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please enter a URL';
          }
          final uri = Uri.tryParse(value);
          if (uri == null || !uri.hasAbsolutePath) {
            return 'Please enter a valid URL';
          }
          return null;
        },
      );
    } else {
      return TextFormField(
        controller: _contentController,
        maxLines: 6,
        decoration: const InputDecoration(
          hintText: 'Paste or type your content here...',
          prefixIcon: Icon(Icons.text_fields),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please enter content to summarize';
          }
          return null;
        },
      );
    }
  }

  Widget _buildLearningPathIntegration() {
    return Consumer<LearningPathProvider>(
      builder: (context, provider, child) {
        final learningPaths = provider.learningPaths;
        if (learningPaths.isEmpty) {
          return const SizedBox.shrink();
        }
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Link to Learning Path (Optional)'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedLearningPathId,
              decoration: const InputDecoration(
                hintText: 'Select a learning path',
                prefixIcon: Icon(Icons.school),
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('None'),
                ),
                ...learningPaths.map((path) => DropdownMenuItem<String>(
                  value: path.id,
                  child: Text(path.topic),
                )),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedLearningPathId = value;
                });
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildModernContentInput() {
    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.edit_outlined, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Content Input',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            if (_selectedContentType == ContentType.url) ...[
              _buildModernTextField(
                controller: _urlController,
                label: 'Enter URL',
                hint: 'https://example.com/article or https://youtube.com/watch?v=...',
                icon: Icons.link_rounded,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter a URL';
                  }
                  final uri = Uri.tryParse(value!);
                  if (uri == null || !uri.hasAbsolutePath) {
                    return 'Please enter a valid URL';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Text(
                'Additional Notes (Optional)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
            ],
            
            _buildModernTextArea(
              controller: _contentController,
              label: _selectedContentType == ContentType.url 
                  ? 'Add context or specific instructions...'
                  : 'Paste or type your content here...',
              hint: _getContentHint(),
              validator: _selectedContentType == ContentType.url 
                  ? null 
                  : (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Please enter content to summarize';
                      }
                      return null;
                    },
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildModernSummaryOptions() {
    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tune_rounded, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Customization Options',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            _buildModernTextField(
              controller: _titleController,
              label: 'Custom Title',
              hint: 'Give your summary a memorable title',
              icon: Icons.title_rounded,
            ),
            const SizedBox(height: 16),
            
            _buildModernDropdown(),
            const SizedBox(height: 16),
            
            _buildModernTextField(
              controller: _tagsController,
              label: 'Tags',
              hint: 'programming, tutorial, flutter',
              icon: Icons.tag_rounded,
            ),
            const SizedBox(height: 16),
            
            _buildLearningPathDropdown(),
            const SizedBox(height: 20),
            
            _buildModernSwitchTile(),
          ],
        ),
      ),
    );
  }

  Widget _buildModernDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonFormField<DifficultyLevel>(
        value: _targetDifficulty,
        decoration: InputDecoration(
          labelText: 'Target Difficulty',
          prefixIcon: Icon(Icons.school_rounded, color: AppColors.primary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
        items: DifficultyLevel.values.map((level) {
          return DropdownMenuItem(
            value: level,
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _getDifficultyColor(level),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  level.value.toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _targetDifficulty = value;
          });
        },
      ),
    );
  }

  Color _getDifficultyColor(DifficultyLevel level) {
    switch (level) {
      case DifficultyLevel.beginner:
        return Colors.green;
      case DifficultyLevel.intermediate:
        return Colors.orange;
      case DifficultyLevel.advanced:
        return Colors.red;
    }
  }

  Widget _buildModernSwitchTile() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _includeKeyPoints ? AppColors.primary.withValues(alpha: 0.1) : Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.key_rounded,
              color: _includeKeyPoints ? AppColors.primary : Colors.grey[600],
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Extract Key Points',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                Text(
                  'Highlight the most important insights',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _includeKeyPoints,
            onChanged: (value) {
              setState(() {
                _includeKeyPoints = value;
              });
            },
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildLearningPathDropdown() {
    return Consumer<LearningPathProvider>(
      builder: (context, learningPathProvider, child) {
        final learningPaths = learningPathProvider.learningPaths;
        
        return DropdownButtonFormField<String>(
          value: _selectedLearningPathId,
          decoration: const InputDecoration(
            labelText: 'Link to Learning Path (Optional)',
            prefixIcon: Icon(Icons.school),
          ),
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text('None'),
            ),
            ...learningPaths.map((path) {
              return DropdownMenuItem<String>(
                value: path.id,
                child: Text(
                  path.topic,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }),
          ],
          onChanged: (value) {
            setState(() {
              _selectedLearningPathId = value;
            });
          },
        );
      },
    );
  }

  Widget _buildGenerateButton() {
    return Consumer<SummarizerProvider>(
      builder: (context, summarizerProvider, child) {
        return Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: summarizerProvider.isGenerating 
                  ? [Colors.grey[400]!, Colors.grey[500]!]
                  : [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: summarizerProvider.isGenerating 
                ? []
                : [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: summarizerProvider.isGenerating ? null : _generateSummary,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (summarizerProvider.isGenerating) ...[
                      const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Generating Summary...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ] else ...[
                      const Icon(
                        Icons.auto_awesome,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Generate Summary',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }



  List<ContentSummaryModel> _getFilteredSummaries(List<ContentSummaryModel> summaries) {
    if (_searchQuery.isEmpty) {
      return summaries;
    }
    
    // For now, use local filtering. Database search can be implemented separately
    return summaries.where((summary) {
      return summary.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             summary.summary.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             summary.tags.any((tag) => tag.toLowerCase().contains(_searchQuery.toLowerCase()));
    }).toList();
  }

  /// Perform database search (can be called separately)
  Future<void> _performDatabaseSearch() async {
    if (_searchQuery.isEmpty) return;
    
    final summarizerProvider = context.read<SummarizerProvider>();
    final searchResults = await summarizerProvider.searchSummaries(_searchQuery);
    
    // You can handle search results here if needed
    // For example, show in a separate dialog or update the UI
  }

  /// Show categories management dialog
  void _showCategoriesDialog() {
    showDialog(
      context: context,
      builder: (context) => _CategoriesDialog(),
    );
  }

  /// Show category creation dialog
  void _showCreateCategoryDialog() {
    final nameController = TextEditingController();
    final colorController = TextEditingController(text: '#3B82F6');
    final iconController = TextEditingController(text: 'folder');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Category Name',
                hintText: 'Enter category name',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: colorController,
              decoration: const InputDecoration(
                labelText: 'Color (Hex)',
                hintText: '#3B82F6',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: iconController,
              decoration: const InputDecoration(
                labelText: 'Icon Name',
                hintText: 'folder',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isNotEmpty) {
                final summarizerProvider = context.read<SummarizerProvider>();
                final success = await summarizerProvider.createCategory(
                  name: nameController.text.trim(),
                  color: colorController.text.trim(),
                  icon: iconController.text.trim(),
                );
                
                if (success && mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Category created successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  /// Show debug information dialog
  void _showDebugInfo() {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.currentUser;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Debug Information'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDebugItem('Authentication', user != null ? 'Logged in' : 'Not logged in'),
              _buildDebugItem('User ID', user?.id ?? 'N/A'),
              _buildDebugItem('User Email', user?.email ?? 'N/A'),
              const Divider(),
              _buildDebugItem('Gemini API Key', EnvConfig.hasGeminiApiKey ? 'Configured' : 'Missing'),
              _buildDebugItem('Supabase URL', EnvConfig.supabaseUrl.isNotEmpty ? 'Configured' : 'Missing'),
              _buildDebugItem('Supabase Key', EnvConfig.supabaseAnonKey.isNotEmpty ? 'Configured' : 'Missing'),
              const Divider(),
              _buildDebugItem('Environment', EnvConfig.appEnv),
              _buildDebugItem('Debug Mode', EnvConfig.isDebugMode.toString()),
              _buildDebugItem('API Timeout', '${EnvConfig.apiTimeout}ms'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (EnvConfig.hasGeminiApiKey && user != null)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _testAIGeneration();
              },
              child: const Text('Test AI'),
            ),
        ],
      ),
    );
  }

  Widget _buildDebugItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: value.contains('Missing') || value.contains('Not logged') 
                    ? Colors.red[600] 
                    : Colors.green[600],
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Test AI generation with simple content
  Future<void> _testAIGeneration() async {
    try {
      final summarizerProvider = context.read<SummarizerProvider>();
      
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Testing AI generation...'),
            ],
          ),
        ),
      );

      final testRequest = SummaryRequestModel(
        content: 'This is a test content for AI summarization. Flutter is a UI toolkit for building natively compiled applications.',
        contentType: ContentType.text,
        title: 'Test Summary',
      );

      final result = await summarizerProvider.generateSummary(
        request: testRequest,
        autoSave: false,
      );

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      if (result != null) {
        // Show success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ AI generation test successful!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Show failure
        final error = summarizerProvider.error ?? 'Unknown error';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ AI generation test failed: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted) Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Test error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
            setState(() {
              _showCreateForm = true;
            });
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

  Widget _buildLibraryTab() {
    return Stack(
      children: [
        Consumer<SummarizerProvider>(
          builder: (context, summarizerProvider, child) {
            if (summarizerProvider.isLoading) {
              return Center(
                child: LoadingAnimationWidget.twistingDots(
                  leftDotColor: AppColors.primary,
                  rightDotColor: AppColors.secondary,
                  size: 50,
                ),
              );
            }

            // Show error if there's a database error
            if (summarizerProvider.error != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 80,
                      color: Colors.red[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Database Error',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.red[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      summarizerProvider.error!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.red[500],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _loadData(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            final allSummaries = summarizerProvider.summaries;
            final summaries = _getFilteredSummaries(allSummaries);

            if (allSummaries.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.library_books_outlined,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No summaries yet',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create your first AI summary',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: summaries.length,
              itemBuilder: (context, index) {
                final summary = summaries[index];
                return _buildSummaryCard(summary);
              },
            );
          },
        ),
        if (_showCreateForm)
          Container(
            color: Colors.black54,
            child: Center(
              child: Container(
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Text(
                            'Create AI Summary',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _showCreateForm = false;
                              });
                            },
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _buildCreateTab(),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }



  Widget _buildSummaryCard(ContentSummaryModel summary) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          // Check if this is a chat conversation
          if (summary.tags.contains('conversation') && summary.tags.contains('ai-chat')) {
            // Navigate to conversation viewer
            context.pushNamed('conversation-viewer', extra: summary);
          } else {
            // Show summary details in a dialog
            _showSummaryDetailsDialog(summary);
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _getContentTypeIcon(summary.contentType),
                    size: 20,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      summary.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Consumer<SummarizerProvider>(
                    builder: (context, provider, child) {
                      return IconButton(
                        onPressed: () => provider.toggleFavorite(summary.id),
                        icon: Icon(
                          summary.isFavorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: summary.isFavorite
                              ? Colors.red
                              : Colors.grey[400],
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                summary.summary,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              if (summary.tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: summary.tags.take(3).map((tag) {
                    return Chip(
                      label: Text(
                        tag,
                        style: const TextStyle(fontSize: 12),
                      ),
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      side: BorderSide.none,
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${summary.estimatedReadTime ?? 0} min read',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatDate(summary.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildStatsCard(String title, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }


  Future<void> _generateSummary() async {
    if (!_formKey.currentState!.validate()) return;

    // Prepare content and source based on type
    String content;
    String? contentSource;
    
    if (_selectedContentType == ContentType.url) {
      contentSource = _urlController.text.trim();
      // Use additional notes if provided, otherwise use URL
      content = _contentController.text.trim().isEmpty 
          ? contentSource 
          : _contentController.text.trim();
    } else {
      content = _contentController.text.trim();
      contentSource = null;
    }

    // Parse tags from the tags controller
    List<String> tags = [];
    if (_tagsController.text.trim().isNotEmpty) {
      tags = _tagsController.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();
    }

    // Create summary request
    final request = SummaryRequestModel(
      content: content,
      contentType: _selectedContentType,
      contentSource: contentSource,
      title: _titleController.text.trim().isEmpty 
          ? null 
          : _titleController.text.trim(),
      targetDifficulty: _targetDifficulty,
      tags: tags,
      includeKeyPoints: _includeKeyPoints,
      learningPathId: _selectedLearningPathId,
    );

    try {
      // Generate summary directly
      final summarizerProvider = context.read<SummarizerProvider>();
      final summary = await summarizerProvider.generateSummary(
        request: request,
        autoSave: true,
      );

      if (summary != null && mounted) {
        // Show summary result dialog
        _showSummaryResultDialog(summary);
        
        // Clear form after successful generation
        _clearForm();
      } else if (mounted) {
        // Show error if generation failed
        final summarizerProvider = context.read<SummarizerProvider>();
        final errorMessage = summarizerProvider.error ?? 'Failed to generate summary. Please try again.';
        
        _showErrorDialog(errorMessage);
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Error: $e');
      }
    }
  }

  void _clearForm() {
    _contentController.clear();
    _urlController.clear();
    _titleController.clear();
    _tagsController.clear();
    setState(() {
      _selectedContentType = ContentType.text;
      _targetDifficulty = null;
      _selectedLearningPathId = null;
      _includeKeyPoints = true;
    });
  }

  /// Show summary result in a beautiful dialog
  void _showSummaryResultDialog(ContentSummaryModel summary) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SummaryResultDialog(summary: summary),
    );
  }

  /// Show error dialog with detailed information
  void _showErrorDialog(String errorMessage) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red[600]),
            const SizedBox(width: 12),
            const Text('Generation Failed'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Unable to generate summary. This could be due to:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            const Text('• Network connection issues'),
            const Text('• API service temporarily unavailable'),
            const Text('• Content format not supported'),
            const Text('• Authentication problems'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Text(
                'Error Details:\n$errorMessage',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red[700],
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Retry generation
              _generateSummary();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _showSummaryDetailsDialog(ContentSummaryModel summary) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          summary.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Summary info
              Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    '${summary.contentTypeDisplay} • ${summary.estimatedReadTime ?? 0} min read',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Summary content
              Text(
                'Summary',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(summary.summary),
              
              if (summary.keyPoints.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Key Points',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...summary.keyPoints.asMap().entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${entry.key + 1}. ', 
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                        Expanded(child: Text(entry.value)),
                      ],
                    ),
                  );
                }),
              ],
              
              if (summary.tags.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Tags',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: summary.tags.map((tag) {
                    return Chip(
                      label: Text(tag, style: const TextStyle(fontSize: 12)),
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }


  String _getContentHint() {
    switch (_selectedContentType) {
      case ContentType.text:
        return 'Paste your text content here...';
      case ContentType.url:
        return 'Additional context or specific points to focus on...';
      case ContentType.file:
        return 'Paste file content here...';
    }
  }


  IconData _getContentTypeIcon(ContentType type) {
    switch (type) {
      case ContentType.text:
        return Icons.text_fields;
      case ContentType.url:
        return Icons.link;
      case ContentType.file:
        return Icons.description;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

class SummaryDetailsScreen extends StatelessWidget {
  final ContentSummaryModel summary;

  const SummaryDetailsScreen({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(summary.title),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          Consumer<SummarizerProvider>(
            builder: (context, provider, child) {
              return IconButton(
                onPressed: () => provider.toggleFavorite(summary.id),
                icon: Icon(
                  summary.isFavorite ? Icons.favorite : Icons.favorite_border,
                ),
              );
            },
          ),
          IconButton(
            onPressed: () => _showShareDialog(context),
            icon: const Icon(Icons.share),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(context),
            const SizedBox(height: 16),
            _buildSummaryCard(context),
            if (summary.keyPoints.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildKeyPointsCard(context),
            ],
            if (summary.tags.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildTagsCard(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Summary Info',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(context, 'Content Type', summary.contentTypeDisplay),
            _buildInfoRow(context, 'Word Count', '${summary.wordCount ?? 0}'),
            _buildInfoRow(context, 'Reading Time', '${summary.estimatedReadTime ?? 0} min'),
            _buildInfoRow(context, 'Difficulty', summary.difficultyLevelDisplay),
            _buildInfoRow(context, 'Created', _formatDate(summary.createdAt)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.summarize, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Summary',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              summary.summary,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyPointsCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.list_alt, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Key Points',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...summary.keyPoints.asMap().entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${entry.key + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTagsCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tag, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Tags',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: summary.tags.map((tag) {
                return Chip(
                  label: Text(tag),
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  side: BorderSide.none,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _showShareDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share Summary'),
        content: const Text('Share functionality will be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

/// Categories management dialog
class _CategoriesDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 400,
        height: 500,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                const Text(
                  'Manage Categories',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Consumer<SummarizerProvider>(
                builder: (context, provider, child) {
                  if (provider.categories.isEmpty) {
                    return const Center(
                      child: Text('No categories yet'),
                    );
                  }

                  return ListView.builder(
                    itemCount: provider.categories.length,
                    itemBuilder: (context, index) {
                      final category = provider.categories[index];
                      return ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Color(int.parse(category.color.replaceFirst('#', '0xFF'))),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.folder,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        title: Text(category.name),
                        subtitle: category.description != null 
                            ? Text(category.description!)
                            : null,
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete Category'),
                                content: Text('Are you sure you want to delete "${category.name}"?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );

                            if (confirmed == true) {
                              await provider.deleteCategory(category.id);
                            }
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.add),
                label: const Text('Create New Category'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
/// Beautiful dialog to show summary results
class SummaryResultDialog extends StatefulWidget {
  final ContentSummaryModel summary;

  const SummaryResultDialog({
    super.key,
    required this.summary,
  });

  @override
  State<SummaryResultDialog> createState() => _SummaryResultDialogState();
}

class _SummaryResultDialogState extends State<SummaryResultDialog>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                height: MediaQuery.of(context).size.height * 0.8,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildHeader(),
                    Expanded(
                      child: _buildContent(),
                    ),
                    _buildActions(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
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
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Summary Generated!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'AI has analyzed your content',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.close,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          _buildSectionTitle('Title'),
          const SizedBox(height: 8),
          _buildContentCard(
            child: Text(
              widget.summary.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Summary
          _buildSectionTitle('Summary'),
          const SizedBox(height: 8),
          _buildContentCard(
            child: Text(
              widget.summary.summary,
              style: const TextStyle(
                fontSize: 16,
                height: 1.6,
                color: Colors.black87,
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Key Points
          if (widget.summary.keyPoints.isNotEmpty) ...[
            _buildSectionTitle('Key Points'),
            const SizedBox(height: 8),
            _buildContentCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: widget.summary.keyPoints.map((point) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 6),
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            point,
                            style: const TextStyle(
                              fontSize: 15,
                              height: 1.5,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
          ],
          
          // Tags
          if (widget.summary.tags.isNotEmpty) ...[
            _buildSectionTitle('Tags'),
            const SizedBox(height: 8),
            _buildContentCard(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.summary.tags.map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
          ],
          
          // Metadata
          _buildMetadata(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildContentCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
        ),
      ),
      child: child,
    );
  }

  Widget _buildMetadata() {
    return _buildContentCard(
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.schedule,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Text(
                'Reading Time: ${widget.summary.estimatedReadTime ?? 0} min',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.text_fields,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Text(
                'Words: ${widget.summary.wordCount ?? 0}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
          if (widget.summary.difficultyLevel != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.signal_cellular_alt,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Text(
                  'Level: ${widget.summary.difficultyLevelDisplay}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.category,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Text(
                  'Type: ${widget.summary.contentTypeDisplay}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          // Chat Button (Optional)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                // Navigate to chat with this summary
                context.pushNamed('ai-chat', extra: {
                  'content': widget.summary.originalContent,
                  'url': widget.summary.contentSource,
                  'contentType': widget.summary.contentType,
                  'title': widget.summary.title,
                  'summary': widget.summary,
                });
              },
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('Chat About This'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // View Details Button
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                // Navigate to summary details
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SummaryDetailsScreen(summary: widget.summary),
                  ),
                );
              },
              icon: const Icon(Icons.visibility),
              label: const Text('View Details'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
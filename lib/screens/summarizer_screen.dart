import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
import '../core/router/app_router.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final summarizerProvider = context.read<SummarizerProvider>();
      final learningPathProvider = context.read<LearningPathProvider>();
      final authProvider = context.read<AuthProvider>();
      
      // Load summaries from local storage (no auth required)
      summarizerProvider.loadSummaries();
      summarizerProvider.loadCategories();
      
      // Still load learning paths if user is authenticated for integration
      if (authProvider.currentUser != null) {
        learningPathProvider.loadLearningPaths(authProvider.currentUser!.id);
      }
    });
  }


  void _showProfileMenu() {
    context.goToProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          ConsistentHeader(
            title: 'AI Summarizer',
            onProfileTap: _showProfileMenu,
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
                        'Generating...',
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
                        'Generate AI Summary',
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
    
    return summaries.where((summary) {
      return summary.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             summary.summary.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             summary.tags.any((tag) => tag.toLowerCase().contains(_searchQuery.toLowerCase()));
    }).toList();
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
    return Column(
      children: [
        // Search Bar
        Container(
          color: AppColors.background,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
        ),
        
        // Content
        Expanded(
          child: Consumer<SummarizerProvider>(
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

              if (summaries.isEmpty && _searchQuery.isNotEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No summaries found',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Try adjusting your search terms',
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
        ),
      ],
    );
  }



  Widget _buildSummaryCard(ContentSummaryModel summary) {
    return GestureDetector(
      onTap: () {
        // Navigate to summary detail screen
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => SummaryDetailsScreen(summary: summary),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary, width: 1),
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
            Row(
              children: [
                Expanded(
                  child: Text(
                    summary.title,
                    style: AppTextStyles.titleLarge.copyWith(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getContentTypeText(summary.contentType),
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.primary,
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
                  size: 16,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 4),
                Text(
                  _formatDate(summary.createdAt),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const Spacer(),
                Consumer<SummarizerProvider>(
                  builder: (context, provider, child) {
                    return GestureDetector(
                      onTap: () => provider.toggleFavorite(summary.id),
                      child: Icon(
                        summary.isFavorite
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: summary.isFavorite
                            ? Colors.red
                            : Colors.grey[400],
                        size: 20,
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
      );  
  }

  String _getContentTypeText(ContentType contentType) {
    switch (contentType) {
      case ContentType.text:
        return 'Text';
      case ContentType.url:
        return 'URL';
      case ContentType.file:
        return 'File';
    }
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Future<void> _generateSummary() async {
    if (!_formKey.currentState!.validate()) return;

    // Show dummy summary instead of navigating to AI chat
    _showDummySummary();
  }

  void _showDummySummary() {
    final String title = _titleController.text.trim().isEmpty 
        ? 'AI Generated Summary' 
        : _titleController.text.trim();
    
    // Create dummy summary object
    final dummySummary = ContentSummaryModel(
      id: 'dummy_${DateTime.now().millisecondsSinceEpoch}',
      userId: 'dummy_user',
      title: title,
      originalContent: _selectedContentType == ContentType.url 
          ? _urlController.text.trim()
          : _contentController.text.trim(),
      summary: 'This is a comprehensive summary of the provided content. The key concepts have been extracted and organized in a clear, digestible format suitable for learning and review.\n\n'
          'Key Points:\n'
          '• Main concept 1: Core principles and fundamentals\n'
          '• Main concept 2: Practical applications and examples\n'
          '• Main concept 3: Advanced techniques and best practices\n'
          '• Main concept 4: Common pitfalls and how to avoid them\n\n'
          'This summary provides a structured overview that can be used for quick reference and deeper study.',
      contentType: _selectedContentType,
      difficultyLevel: _targetDifficulty ?? DifficultyLevel.intermediate,
      keyPoints: [
        'Core principles and fundamentals',
        'Practical applications and examples', 
        'Advanced techniques and best practices',
        'Common pitfalls and how to avoid them'
      ],
      tags: ['ai-generated', 'dummy', _selectedContentType.name],
      wordCount: 150,
      estimatedReadTime: 3,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Navigate to detail screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SummaryDetailsScreen(summary: dummySummary),
      ),
    );

    // Clear form and show success message
    _clearForm();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Summary generated successfully!'),
        backgroundColor: AppColors.primary,
      ),
    );
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


}

class SummaryDetailsScreen extends StatelessWidget {
  final ContentSummaryModel summary;

  const SummaryDetailsScreen({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(summary.title),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCard(context),
            if (summary.keyPoints.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildKeyPointsCard(context),
            ],
            if (summary.tags.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildTagsCard(context),
            ],
            const SizedBox(height: 16),
            _buildInfoCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(0),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary, width: 1),
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
    );
  }

  Widget _buildKeyPointsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary, width: 1),
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
                  Text(
                    '${entry.key + 1}. ',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
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
    );
  }

  Widget _buildTagsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary, width: 1),
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
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

// Extension untuk ContentSummaryModel
extension ContentSummaryModelExtension on ContentSummaryModel {
  String get contentTypeDisplay {
    switch (contentType) {
      case ContentType.text:
        return 'Text';
      case ContentType.url:
        return 'Web Article';
      case ContentType.file:
        return 'File';
    }
  }

  String get difficultyLevelDisplay {
    return difficultyLevel?.name.capitalize() ?? 'Not specified';
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

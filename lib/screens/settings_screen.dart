import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
import '../core/router/app_router.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _nameController = TextEditingController();
  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final authProvider = context.read<AuthProvider>();
    final userProvider = context.read<UserProvider>();
    
    if (authProvider.currentUser != null) {
      await userProvider.loadUser(authProvider.currentUser!.id);
      _nameController.text = userProvider.user?.name ?? '';
    }
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Name cannot be empty'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final userProvider = context.read<UserProvider>();
    final success = await userProvider.updateProfile(
      name: _nameController.text.trim(),
    );

    setState(() {
      _isLoading = false;
      _isEditing = false;
    });

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update profile. Please try again.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final authProvider = context.read<AuthProvider>();
      await authProvider.signOut();
      
      if (mounted) {
        context.goToWelcome();
      }
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone and all your learning progress will be lost.',
        ),
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
      // Show second confirmation
      final doubleConfirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Final Confirmation'),
          content: const Text(
            'This will permanently delete your account and all data. Type "DELETE" to confirm.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
                child: const Text('Confirm Delete'),
            ),
          ],
        ),
      );

      if (doubleConfirmed == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account deletion feature coming soon!'),
            backgroundColor: AppColors.info,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.goToDashboard(),
        ),
        actions: [
          if (_isEditing)
            TextButton(
              onPressed: _isLoading ? null : _saveProfile,
              child: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      'Save',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Section
            _buildProfileSection(),
            
            const SizedBox(height: 32),
            
            // App Settings Section
            _buildAppSettingsSection(),
            
            const SizedBox(height: 32),
            
            // About Section
            _buildAboutSection(),
            
            const SizedBox(height: 32),
            
            // Account Actions Section
            _buildAccountActionsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return Consumer2<AuthProvider, UserProvider>(
      builder: (context, authProvider, userProvider, child) {
        final user = authProvider.currentUser;
        final profile = userProvider.user;
        
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Profile',
                    style: AppTextStyles.titleLarge.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  if (!_isEditing)
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _isEditing = true;
                        });
                      },
                      icon: const Icon(Icons.edit),
                      color: AppColors.primary,
                    ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Avatar
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Icon(
                    Icons.person,
                    size: 40,
                    color: AppColors.primary,
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Name Field
              Text(
                'Name',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              if (_isEditing)
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    hintText: 'Enter your name',
                  ),
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textPrimary,
                  ),
                )
              else
                Text(
                  profile?.name ?? 'No name set',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              
              const SizedBox(height: 16),
              
              // Email Field (Read-only)
              Text(
                'Email',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                user?.email ?? 'No email',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Stats
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'Current Streak',
                      '${profile?.currentStreak ?? 0} days',
                      Icons.local_fire_department,
                      AppColors.warning,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatItem(
                      'Longest Streak',
                      '${profile?.longestStreak ?? 0} days',
                      Icons.emoji_events,
                      AppColors.success,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.titleSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAppSettingsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'App Settings',
            style: AppTextStyles.titleLarge.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          
          const SizedBox(height: 16),
          
          _buildSettingItem(
            'Notifications',
            'Manage your notification preferences',
            Icons.notifications,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notification settings coming soon!')),
              );
            },
          ),
          
          const Divider(),
          
          _buildSettingItem(
            'Theme',
            'Choose your preferred theme',
            Icons.palette,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Theme settings coming soon!')),
              );
            },
          ),
          
          const Divider(),
          
          _buildSettingItem(
            'Language',
            'Select your language',
            Icons.language,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Language settings coming soon!')),
              );
            },
          ),
          
          const Divider(),
          
          _buildSettingItem(
            'Data & Privacy',
            'Manage your data and privacy settings',
            Icons.privacy_tip,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Privacy settings coming soon!')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About',
            style: AppTextStyles.titleLarge.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          
          const SizedBox(height: 16),
          
          _buildSettingItem(
            'Help & Support',
            'Get help and contact support',
            Icons.help,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Help & Support coming soon!')),
              );
            },
          ),
          
          const Divider(),
          
          _buildSettingItem(
            'Terms of Service',
            'Read our terms of service',
            Icons.description,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Terms of Service coming soon!')),
              );
            },
          ),
          
          const Divider(),
          
          _buildSettingItem(
            'Privacy Policy',
            'Read our privacy policy',
            Icons.policy,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Privacy Policy coming soon!')),
              );
            },
          ),
          
          const Divider(),
          
          _buildSettingItem(
            'App Version',
            'Version 1.0.0',
            Icons.info,
            showArrow: false,
          ),
        ],
      ),
    );
  }

  Widget _buildAccountActionsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account Actions',
            style: AppTextStyles.titleLarge.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          
          const SizedBox(height: 16),
          
          _buildSettingItem(
            'Logout',
            'Sign out of your account',
            Icons.logout,
            onTap: _logout,
            textColor: AppColors.warning,
          ),
          
          const Divider(),
          
          _buildSettingItem(
            'Delete Account',
            'Permanently delete your account',
            Icons.delete_forever,
            onTap: _deleteAccount,
            textColor: AppColors.error,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(
    String title,
    String subtitle,
    IconData icon, {
    VoidCallback? onTap,
    bool showArrow = true,
    Color? textColor,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (textColor ?? AppColors.primary).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: textColor ?? AppColors.primary,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: AppTextStyles.titleMedium.copyWith(
          color: textColor ?? AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
      trailing: showArrow
          ? Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.textTertiary,
            )
          : null,
      onTap: onTap,
    );
  }
}

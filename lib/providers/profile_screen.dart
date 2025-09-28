import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../providers/user_provider.dart';
import '../../services/file_upload_service.dart';
import '../../widgets/sidebar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  ProfileScreenState createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  final FileUploadService _fileUploadService = FileUploadService();
  final _formKey = GlobalKey<FormState>();
  late UserModel _currentUser;
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  void _loadUserProfile() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.user == null) {
      userProvider.loadUserProfile();
    } else {
      _currentUser = userProvider.user!.copyWith(); // Create a copy for editing
    }
  }

  void _toggleEditing() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        // Reset to original data when canceling edit
        _loadUserProfile();
      }
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    _formKey.currentState!.save();
    setState(() => _isSaving = true);

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.updateProfile(_currentUser);
      
      if (mounted) {
        if (userProvider.error == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Profile updated successfully'),
              backgroundColor: Colors.green.shade600,
              behavior: SnackBarBehavior.floating,
            ),
          );
          _toggleEditing();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${userProvider.error}'),
              backgroundColor: Colors.red.shade600,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _uploadProfileImage() async {
    final file = await _fileUploadService.pickImage();
    if (!mounted || file == null) return;

    setState(() => _isSaving = true);
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.uploadProfileImage(file.path);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              userProvider.error == null 
                ? 'Profile image updated' 
                : 'Error: ${userProvider.error}'
            ),
            backgroundColor: userProvider.error == null 
              ? Colors.green.shade600 
              : Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _uploadResume() async {
    final file = await _fileUploadService.pickDocument();
    if (!mounted || file == null) return;

    setState(() => _isSaving = true);
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.uploadResume(file.path);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              userProvider.error == null 
                ? 'Resume updated successfully' 
                : 'Error: ${userProvider.error}'
            ),
            backgroundColor: userProvider.error == null 
              ? Colors.green.shade600 
              : Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _viewResume() {
    if (_currentUser.resumeUrl != null) {
      // Implement resume viewing logic
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Resume'),
          content: Text('Resume URL: ${_currentUser.resumeUrl}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    if (userProvider.isLoading && userProvider.user == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(colors.primary)),
              const SizedBox(height: 16),
              Text(
                'Loading your profile...',
                style: theme.textTheme.bodyLarge?.copyWith(color: colors.onSurface.withValues(alpha: 0.7)),
              ),
            ],
          ),
        ),
      );
    }

    if (userProvider.error != null && userProvider.user == null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: colors.error),
                const SizedBox(height: 16),
                Text(
                  'Unable to load profile',
                  style: theme.textTheme.headlineSmall?.copyWith(color: colors.error),
                ),
                const SizedBox(height: 8),
                Text(
                  userProvider.error!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurface.withValues(alpha: 0.7)),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => userProvider.loadUserProfile(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    _currentUser = userProvider.user!;

    return Scaffold(
      drawer: const Sidebar(),
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        actions: [
          if (!_isEditing && !_isSaving)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: _toggleEditing,
              tooltip: 'Edit Profile',
            ),
          if (_isEditing) ...[
            IconButton(
              icon: _isSaving 
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(colors.onPrimary),
                      ),
                    )
                  : const Icon(Icons.save_outlined),
              onPressed: _isSaving ? null : _saveProfile,
              tooltip: 'Save Changes',
            ),
            IconButton(
              icon: const Icon(Icons.close_outlined),
              onPressed: _isSaving ? null : _toggleEditing,
              tooltip: 'Cancel',
            ),
          ],
        ],
      ),
      body: _isSaving && !_isEditing
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Image Section
                    Center(
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: colors.primary.withValues(alpha: 0.2),
                                width: 3,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 70,
                              backgroundColor: colors.surfaceContainerHighest,
                              backgroundImage: _currentUser.profileImage != null
                                  ? NetworkImage(_currentUser.profileImage!)
                                  : const AssetImage('assets/default_avatar.png') as ImageProvider,
                              child: _currentUser.profileImage == null
                                  ? Icon(Icons.person, size: 70, color: colors.onSurfaceVariant)
                                  : null,
                            ),
                          ),
                          if (_isEditing)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: colors.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: colors.surface, width: 3),
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.camera_alt, color: Colors.white),
                                  onPressed: _uploadProfileImage,
                                  tooltip: 'Change Photo',
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Personal Details Card
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.person_outline, color: colors.primary),
                                const SizedBox(width: 8),
                                Text(
                                  'Personal Details',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: colors.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildEditableField(
                              label: 'Full Name',
                              value: _currentUser.fullName,
                              icon: Icons.badge_outlined,
                              isEditing: _isEditing,
                              onSaved: (value) => _currentUser = _currentUser.copyWith(fullName: value),
                            ),
                            const SizedBox(height: 12),
                            _buildEditableField(
                              label: 'Email',
                              value: _currentUser.email,
                              icon: Icons.email_outlined,
                              isEditing: _isEditing,
                              onSaved: (value) => _currentUser = _currentUser.copyWith(email: value),
                            ),
                            const SizedBox(height: 12),
                            _buildEditableField(
                              label: 'Phone',
                              value: _currentUser.phone ?? '',
                              icon: Icons.phone_outlined,
                              isEditing: _isEditing,
                              onSaved: (value) => _currentUser = _currentUser.copyWith(phone: value.isEmpty ? null : value),
                              validator: (value) => null,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Resume Card
                    Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(top: 20),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.description_outlined, color: colors.primary),
                                const SizedBox(width: 8),
                                Text(
                                  'Resume',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: colors.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (_currentUser.resumeUrl != null) ...[
                              ListTile(
                                leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                                title: const Text('Current Resume'),
                                subtitle: Text(
                                  _currentUser.resumeUrl!.split('/').last,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.visibility_outlined),
                                      onPressed: _viewResume,
                                      tooltip: 'View Resume',
                                    ),
                                    if (_isEditing)
                                      IconButton(
                                        icon: const Icon(Icons.upload_outlined),
                                        onPressed: _uploadResume,
                                        tooltip: 'Update Resume',
                                      ),
                                  ],
                                ),
                              ),
                            ] else
                              ListTile(
                                leading: const Icon(Icons.upload_outlined),
                                title: const Text('No resume uploaded'),
                                subtitle: const Text('Upload your resume to complete your profile'),
                                trailing: _isEditing
                                    ? FilledButton.icon(
                                        onPressed: _uploadResume,
                                        icon: const Icon(Icons.upload),
                                        label: const Text('Upload Resume'),
                                      )
                                    : null,
                              ),
                          ],
                        ),
                      ),
                    ),

                    // Education Card
                    _buildSectionCard(
                      icon: Icons.school_outlined,
                      title: 'Education',
                      child: _buildEducationSection(),
                    ),

                    // Experience Card
                    _buildSectionCard(
                      icon: Icons.work_outline,
                      title: 'Work Experience',
                      child: _buildExperienceSection(),
                    ),

                    // Skills Card
                    _buildSectionCard(
                      icon: Icons.build_outlined,
                      title: 'Skills',
                      child: _buildSkillsSection(),
                    ),

                    // Career Preferences Card
                    _buildSectionCard(
                      icon: Icons.track_changes_outlined,
                      title: 'Career Preferences',
                      child: _buildCareerPreferencesSection(),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionCard({required IconData icon, required String title, required Widget child}) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(top: 20),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildEditableField({
    required String label,
    required String value,
    required IconData icon,
    required bool isEditing,
    required Function(String) onSaved,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
        filled: !isEditing,
        fillColor: !isEditing ? Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3) : null,
      ),
      enabled: isEditing,
      validator: validator ?? (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $label';
        }
        if (label.toLowerCase().contains('email') && !value.contains('@')) {
          return 'Please enter a valid email';
        }
        return null;
      },
      onSaved: (value) => onSaved(value!),
    );
  }

  Widget _buildEducationSection() {
    if (_currentUser.education.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          'No education information added',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      );
    }

    return Column(
      children: _currentUser.education.map((edu) => ListTile(
        leading: const Icon(Icons.school, color: Colors.blue),
        title: Text(edu.degree, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(edu.institution),
            if (edu.field.isNotEmpty) Text(edu.field),
            Text(_formatDateRange(edu.startDate, edu.endDate, edu.isCurrent)),
          ],
        ),
        trailing: _isEditing ? IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () => _showDeleteDialog('education', edu.degree, () {
            // Implement delete education
          }),
        ) : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      )).toList(),
    );
  }

  Widget _buildExperienceSection() {
    if (_currentUser.experience.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          'No work experience added',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      );
    }

    return Column(
      children: _currentUser.experience.map((exp) => ListTile(
        leading: const Icon(Icons.work, color: Colors.green),
        title: Text(exp.position, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(exp.company),
            if (exp.description.isNotEmpty) Text(exp.description),
            Text(_formatDateRange(exp.startDate, exp.endDate, exp.isCurrent)),
          ],
        ),
        trailing: _isEditing ? IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () => _showDeleteDialog('experience', exp.position, () {
            // Implement delete experience
          }),
        ) : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      )).toList(),
    );
  }

  Widget _buildSkillsSection() {
    if (_currentUser.skills.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          'No skills added',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _currentUser.skills.map((skill) => Chip(
        label: Text(skill),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        deleteIcon: const Icon(Icons.close, size: 16),
        onDeleted: _isEditing ? () => _showDeleteDialog('skill', skill, () {
          // Implement delete skill
        }) : null,
      )).toList(),
    );
  }

  Widget _buildCareerPreferencesSection() {
    return Column(
      children: [
        _buildEditableField(
          label: 'Desired Job Type',
          value: _currentUser.preferences.jobType,
          icon: Icons.work_outline,
          isEditing: _isEditing,
          onSaved: (value) => _currentUser = _currentUser.copyWith(
            preferences: _currentUser.preferences.copyWith(jobType: value),
          ),
        ),
        const SizedBox(height: 12),
        _buildEditableField(
          label: 'Preferred Location',
          value: _currentUser.preferences.preferredLocation,
          icon: Icons.location_on_outlined,
          isEditing: _isEditing,
          onSaved: (value) => _currentUser = _currentUser.copyWith(
            preferences: _currentUser.preferences.copyWith(preferredLocation: value),
          ),
        ),
        // Add more preference fields as needed
      ],
    );
  }

  void _showDeleteDialog(String type, String name, VoidCallback onDelete) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete $type?'),
        content: Text('Are you sure you want to delete "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              onDelete();
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _formatDateRange(DateTime start, DateTime? end, bool isCurrent) {
    final formatter = DateFormat('MMM yyyy');
    if (isCurrent) {
      return '${formatter.format(start)} - Present';
    } else if (end != null) {
      return '${formatter.format(start)} - ${formatter.format(end)}';
    } else {
      return formatter.format(start);
    }
  }
}
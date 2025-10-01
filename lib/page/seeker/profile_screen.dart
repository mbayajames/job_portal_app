import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../models/user_model.dart';
import '../../providers/user_provider.dart';
import 'cloudinary_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final _formKey = GlobalKey<FormState>();
  late UserModel _currentUser;
  bool _isEditing = false;
  bool _isInitialized = false;
  bool isUploading = false;
  
  // Controllers for adding new items
  final TextEditingController _educationDegreeController = TextEditingController();
  final TextEditingController _educationInstitutionController = TextEditingController();
  final TextEditingController _educationFieldController = TextEditingController();
  final TextEditingController _educationStartDateController = TextEditingController();
  final TextEditingController _educationEndDateController = TextEditingController();
  bool _educationIsCurrent = false;
  final TextEditingController _experiencePositionController = TextEditingController();
  final TextEditingController _experienceCompanyController = TextEditingController();
  final TextEditingController _experienceDescriptionController = TextEditingController();
  final TextEditingController _experienceStartDateController = TextEditingController();
  final TextEditingController _experienceEndDateController = TextEditingController();
  bool _experienceIsCurrent = false;
  final TextEditingController _skillController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _loadUserProfile();
      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    _educationDegreeController.dispose();
    _educationInstitutionController.dispose();
    _educationFieldController.dispose();
    _educationStartDateController.dispose();
    _educationEndDateController.dispose();
    _experiencePositionController.dispose();
    _experienceCompanyController.dispose();
    _experienceDescriptionController.dispose();
    _experienceStartDateController.dispose();
    _experienceEndDateController.dispose();
    _skillController.dispose();
    super.dispose();
  }

  void _loadUserProfile() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.user == null) {
      userProvider.loadUserProfile();
    } else {
      _currentUser = userProvider.user!;
    }
  }

  void _toggleEditing() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        // Clear controllers when exiting edit mode
        _clearControllers();
      }
    });
  }

  void _clearControllers() {
    _educationDegreeController.clear();
    _educationInstitutionController.clear();
    _educationFieldController.clear();
    _educationStartDateController.clear();
    _educationEndDateController.clear();
    _educationIsCurrent = false;
    _experiencePositionController.clear();
    _experienceCompanyController.clear();
    _experienceDescriptionController.clear();
    _experienceStartDateController.clear();
    _experienceEndDateController.clear();
    _experienceIsCurrent = false;
    _skillController.clear();
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.updateProfile(_currentUser);
      if (mounted) {
        if (userProvider.error == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Profile updated successfully'),
              backgroundColor: Colors.blue.shade700,
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
    }
  }

  /// Upload profile image to Cloudinary
  Future<void> _uploadProfileImage() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    try {
      setState(() => isUploading = true);
      
      // Pick image
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) {
        setState(() => isUploading = false);
        return;
      }

      final File imageFile = File(image.path);
      
      // Check file size (max 5MB)
      final int fileSize = await imageFile.length();
      if (fileSize > 5 * 1024 * 1024) {
        throw Exception('Image size must be less than 5MB');
      }

      // Delete old image if exists (optional - only if you have API secret)
      if (_currentUser.profileImage != null && _currentUser.profileImage!.isNotEmpty) {
        final oldPublicId = _cloudinaryService.getPublicIdFromUrl(
          _currentUser.profileImage!
        );
        if (oldPublicId != null) {
          await _cloudinaryService.deleteImage(oldPublicId);
        }
      }

      // Upload to Cloudinary
      final String? imageUrl = await _cloudinaryService.uploadImage(
        imageFile: imageFile,
        folder: 'seekers',
        publicId: '${_currentUser.id}_profile',
      );

      if (imageUrl == null) {
        throw Exception('Failed to upload image to Cloudinary');
      }

      // Update user model and save to backend
      _currentUser = _currentUser.copyWith(profileImage: imageUrl);
      await userProvider.updateProfile(_currentUser);

      if (mounted) {
        setState(() => isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile image updated successfully'),
            backgroundColor: Colors.blue.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error uploading profile image: $e');
      if (mounted) {
        setState(() => isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Upload resume to Cloudinary
  Future<void> _uploadResume() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    try {
      setState(() => isUploading = true);
      
      // Pick document (using image picker for simplicity - you can use file_picker for better document selection)
      final ImagePicker picker = ImagePicker();
      final XFile? file = await picker.pickImage(source: ImageSource.gallery);

      if (file == null) {
        if (mounted) {
          setState(() => isUploading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('No document selected'),
              backgroundColor: Colors.orange.shade600,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      final File documentFile = File(file.path);

      // Check file size (max 10MB)
      final int fileSize = await documentFile.length();
      if (fileSize > 10 * 1024 * 1024) {
        throw Exception('Document size must be less than 10MB');
      }

      // Delete old resume if exists (optional - only if you have API secret)
      if (_currentUser.resumeUrl != null && _currentUser.resumeUrl!.isNotEmpty) {
        final oldPublicId = _cloudinaryService.getPublicIdFromUrl(
          _currentUser.resumeUrl!
        );
        if (oldPublicId != null) {
          await _cloudinaryService.deleteDocument(oldPublicId);
        }
      }

      // Upload resume to Cloudinary
      final String? resumeUrl = await _cloudinaryService.uploadDocument(
        documentFile: documentFile,
        folder: 'resumes',
        publicId: '${_currentUser.id}_resume',
      );

      if (resumeUrl == null) {
        throw Exception('Failed to upload resume to Cloudinary');
      }

      // Update user model and save to backend
      _currentUser = _currentUser.copyWith(resumeUrl: resumeUrl);
      await userProvider.updateProfile(_currentUser);

      if (mounted) {
        setState(() => isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Resume updated successfully'),
            backgroundColor: Colors.blue.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error uploading resume: $e');
      if (mounted) {
        setState(() => isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _downloadResume() {
    if (_currentUser.resumeUrl != null && _currentUser.resumeUrl!.isNotEmpty) {
      // Implement resume download functionality
      // This would typically use a package like flutter_downloader or open the URL in a browser
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Downloading resume...'),
          backgroundColor: Colors.blue.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      // Example: Launch URL
      // launchUrl(Uri.parse(_currentUser.resumeUrl!));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No resume available to download'),
          backgroundColor: Colors.orange.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _addEducation() {
    if (_educationDegreeController.text.isNotEmpty &&
        _educationInstitutionController.text.isNotEmpty &&
        _educationStartDateController.text.isNotEmpty) {
      DateTime startDate = DateTime.parse(_educationStartDateController.text);
      DateTime? endDate = _educationEndDateController.text.isNotEmpty ? DateTime.parse(_educationEndDateController.text) : null;
      setState(() {
        _currentUser.education.add(Education(
          degree: _educationDegreeController.text,
          institution: _educationInstitutionController.text,
          field: _educationFieldController.text,
          startDate: startDate,
          endDate: endDate,
          isCurrent: _educationIsCurrent,
        ));
      });
      _educationDegreeController.clear();
      _educationInstitutionController.clear();
      _educationFieldController.clear();
      _educationStartDateController.clear();
      _educationEndDateController.clear();
      _educationIsCurrent = false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Education added successfully'),
          backgroundColor: Colors.blue.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please fill all required fields'),
          backgroundColor: Colors.orange.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _removeEducation(int index) {
    setState(() {
      _currentUser.education.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Education removed'),
        backgroundColor: Colors.orange.shade600,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _addExperience() {
    if (_experiencePositionController.text.isNotEmpty &&
        _experienceCompanyController.text.isNotEmpty &&
        _experienceStartDateController.text.isNotEmpty) {
      DateTime startDate = DateTime.parse(_experienceStartDateController.text);
      DateTime? endDate = _experienceEndDateController.text.isNotEmpty ? DateTime.parse(_experienceEndDateController.text) : null;
      setState(() {
        _currentUser.experience.add(WorkExperience(
          position: _experiencePositionController.text,
          company: _experienceCompanyController.text,
          description: _experienceDescriptionController.text,
          startDate: startDate,
          endDate: endDate,
          isCurrent: _experienceIsCurrent,
        ));
      });
      _experiencePositionController.clear();
      _experienceCompanyController.clear();
      _experienceDescriptionController.clear();
      _experienceStartDateController.clear();
      _experienceEndDateController.clear();
      _experienceIsCurrent = false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Experience added successfully'),
          backgroundColor: Colors.blue.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please fill all required fields'),
          backgroundColor: Colors.orange.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _removeExperience(int index) {
    setState(() {
      _currentUser.experience.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Experience removed'),
        backgroundColor: Colors.orange.shade600,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _addSkill() {
    if (_skillController.text.isNotEmpty) {
      setState(() {
        _currentUser.skills.add(_skillController.text);
      });
      _skillController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Skill added successfully'),
          backgroundColor: Colors.blue.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a skill'),
          backgroundColor: Colors.orange.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _removeSkill(int index) {
    setState(() {
      _currentUser.skills.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Skill removed'),
        backgroundColor: Colors.orange.shade600,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildProfileAvatar() {
    return Stack(
      children: [
        CircleAvatar(
          radius: 60,
          backgroundColor: Colors.grey.shade200,
          backgroundImage: _currentUser.profileImage != null &&
                  _currentUser.profileImage!.isNotEmpty
              ? NetworkImage(_currentUser.profileImage!)
              : null,
          child: _currentUser.profileImage == null || _currentUser.profileImage!.isEmpty
              ? Icon(Icons.person, size: 50, color: Colors.grey.shade400)
              : null,
        ),
        if (isUploading)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
          ),
        if (_isEditing)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.blue.shade700,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: IconButton(
                icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                onPressed: isUploading ? null : _uploadProfileImage,
                tooltip: 'Change Profile Photo',
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final theme = Theme.of(context);

    if (userProvider.isLoading && userProvider.user == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Colors.blue.shade700)),
              const SizedBox(height: 16),
              Text('Loading profile...', style: theme.textTheme.bodyLarge?.copyWith(color: Colors.black)),
            ],
          ),
        ),
      );
    }

    if (userProvider.error != null && userProvider.user == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.blue.shade700),
                const SizedBox(height: 16),
                Text('Error loading profile', style: theme.textTheme.headlineSmall?.copyWith(color: Colors.black)),
                const SizedBox(height: 8),
                Text('${userProvider.error}', 
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black54), textAlign: TextAlign.center),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => userProvider.loadUserProfile(),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (userProvider.user == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_off, size: 64, color: Colors.blue.shade700),
              const SizedBox(height: 16),
              Text('User data not available', style: theme.textTheme.headlineSmall?.copyWith(color: Colors.black)),
            ],
          ),
        ),
      );
    }

    _currentUser = userProvider.user!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 2,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: _toggleEditing,
              tooltip: 'Edit Profile',
            ),
          if (_isEditing) ...[
            IconButton(
              icon: const Icon(Icons.save, color: Colors.white),
              onPressed: _saveProfile,
              tooltip: 'Save Changes',
            ),
            IconButton(
              icon: const Icon(Icons.cancel, color: Colors.white),
              onPressed: () {
                setState(() {
                  _isEditing = false;
                  _clearControllers();
                  _loadUserProfile();
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Changes discarded'),
                    backgroundColor: Colors.orange.shade600,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              tooltip: 'Cancel Editing',
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Image Section
              Center(
                child: _buildProfileAvatar(),
              ),
              const SizedBox(height: 24),

              // Personal Details Card
              Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 20),
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.blue.shade100, width: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.person_outline, color: Colors.blue.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'Personal Details',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildEditableField(
                        label: 'Full Name',
                        value: _currentUser.fullName,
                        isEditing: _isEditing,
                        icon: Icons.person,
                        onSaved: (value) => _currentUser = _currentUser.copyWith(fullName: value),
                      ),
                      const SizedBox(height: 12),
                      _buildEditableField(
                        label: 'Email',
                        value: _currentUser.email,
                        isEditing: _isEditing,
                        icon: Icons.email,
                        onSaved: (value) => _currentUser = _currentUser.copyWith(email: value),
                      ),
                      const SizedBox(height: 12),
                      _buildEditableField(
                        label: 'Phone',
                        value: _currentUser.phone ?? '',
                        isEditing: _isEditing,
                        icon: Icons.phone,
                        onSaved: (value) => _currentUser = _currentUser.copyWith(phone: value),
                      ),
                    ],
                  ),
                ),
              ),

              // Resume Section Card
              Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 20),
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.blue.shade100, width: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.description_outlined, color: Colors.blue.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'Resume',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_currentUser.resumeUrl != null && _currentUser.resumeUrl!.isNotEmpty)
                        ListTile(
                          leading: Icon(Icons.insert_drive_file, color: Colors.blue.shade700),
                          title: Text('Current Resume', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black)),
                          subtitle: Text(_currentUser.resumeUrl!.split('/').last,
                              style: theme.textTheme.bodySmall?.copyWith(color: Colors.black54)),
                          trailing: IconButton(
                            icon: Icon(Icons.download, color: Colors.blue.shade700),
                            onPressed: _downloadResume,
                          ),
                          onTap: _downloadResume,
                        ),
                      if (_isEditing)
                        FilledButton.icon(
                          onPressed: isUploading ? null : _uploadResume,
                          icon: isUploading 
                              ? SizedBox(height: 16, width: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.upload),
                          label: Text(isUploading ? 'Uploading...' : 'Upload Resume'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            foregroundColor: Colors.white,
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Education Section
              _buildEducationSection(),

              // Experience Section
              _buildExperienceSection(),

              // Skills Section
              _buildSkillsSection(),

              // Career Preferences
              _buildCareerPreferencesSection(),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditableField({
    required String label,
    required String value,
    required bool isEditing,
    required Function(String) onSaved,
    IconData? icon,
  }) {
    return TextFormField(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.black54),
        prefixIcon: icon != null ? Icon(icon, color: Colors.blue.shade700) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.blue.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.blue.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.blue.shade700),
        ),
        filled: !isEditing,
        fillColor: !isEditing ? Colors.grey.shade50 : Colors.white,
      ),
      style: TextStyle(color: Colors.black),
      enabled: isEditing,
      validator: (value) {
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
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 20),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.blue.shade100, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.school_outlined, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  'Education',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._currentUser.education.asMap().entries.map((entry) => ListTile(
              leading: Icon(Icons.arrow_right, color: Colors.blue.shade700),
              title: Text(entry.value.degree, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${entry.value.institution} • ${entry.value.field}', style: TextStyle(color: Colors.black54)),
                  Text('${entry.value.startDate.year} - ${entry.value.isCurrent ? 'Present' : entry.value.endDate?.year ?? 'N/A'}', 
                      style: TextStyle(color: Colors.black54, fontSize: 12)),
                ],
              ),
              trailing: _isEditing
                  ? IconButton(
                      icon: Icon(Icons.delete, color: Colors.red.shade600),
                      onPressed: () => _removeEducation(entry.key),
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 0),
            )),
            if (_isEditing) ...[
              const SizedBox(height: 16),
              const Divider(color: Colors.grey),
              const SizedBox(height: 12),
              Text('Add New Education', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.black)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _educationDegreeController,
                decoration: InputDecoration(
                  labelText: 'Degree*',
                  labelStyle: TextStyle(color: Colors.black54),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.blue.shade300),
                  ),
                ),
                style: TextStyle(color: Colors.black),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _educationInstitutionController,
                decoration: InputDecoration(
                  labelText: 'Institution*',
                  labelStyle: TextStyle(color: Colors.black54),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.blue.shade300),
                  ),
                ),
                style: TextStyle(color: Colors.black),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _educationFieldController,
                decoration: InputDecoration(
                  labelText: 'Field of Study',
                  labelStyle: TextStyle(color: Colors.black54),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.blue.shade300),
                  ),
                ),
                style: TextStyle(color: Colors.black),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _educationStartDateController,
                decoration: InputDecoration(
                  labelText: 'Start Date (YYYY-MM-DD)*',
                  labelStyle: TextStyle(color: Colors.black54),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.blue.shade300),
                  ),
                ),
                style: TextStyle(color: Colors.black),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _educationEndDateController,
                decoration: InputDecoration(
                  labelText: 'End Date (YYYY-MM-DD)',
                  labelStyle: TextStyle(color: Colors.black54),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.blue.shade300),
                  ),
                ),
                style: TextStyle(color: Colors.black),
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                title: Text('Currently Studying', style: TextStyle(color: Colors.black)),
                value: _educationIsCurrent,
                activeColor: Colors.blue.shade700,
                onChanged: (value) => setState(() => _educationIsCurrent = value ?? false),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _addEducation,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Add Education'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildExperienceSection() {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 20),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.blue.shade100, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.work_outline, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  'Work Experience',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._currentUser.experience.asMap().entries.map((entry) => ListTile(
              leading: Icon(Icons.arrow_right, color: Colors.blue.shade700),
              title: Text(entry.value.position, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.value.company, style: TextStyle(color: Colors.black54)),
                  if (entry.value.description.isNotEmpty)
                    Text(entry.value.description, style: TextStyle(color: Colors.black54, fontSize: 12)),
                  Text('${entry.value.startDate.year} - ${entry.value.isCurrent ? 'Present' : entry.value.endDate?.year ?? 'N/A'}', 
                      style: TextStyle(color: Colors.black54, fontSize: 12)),
                ],
              ),
              trailing: _isEditing
                  ? IconButton(
                      icon: Icon(Icons.delete, color: Colors.red.shade600),
                      onPressed: () => _removeExperience(entry.key),
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 0),
            )),
            if (_isEditing) ...[
              const SizedBox(height: 16),
              const Divider(color: Colors.grey),
              const SizedBox(height: 12),
              Text('Add New Experience', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.black)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _experiencePositionController,
                decoration: InputDecoration(
                  labelText: 'Position*',
                  labelStyle: TextStyle(color: Colors.black54),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.blue.shade300),
                  ),
                ),
                style: TextStyle(color: Colors.black),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _experienceCompanyController,
                decoration: InputDecoration(
                  labelText: 'Company*',
                  labelStyle: TextStyle(color: Colors.black54),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.blue.shade300),
                  ),
                ),
                style: TextStyle(color: Colors.black),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _experienceDescriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  labelStyle: TextStyle(color: Colors.black54),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.blue.shade300),
                  ),
                ),
                style: TextStyle(color: Colors.black),
                maxLines: 2,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _experienceStartDateController,
                decoration: InputDecoration(
                  labelText: 'Start Date (YYYY-MM-DD)*',
                  labelStyle: TextStyle(color: Colors.black54),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.blue.shade300),
                  ),
                ),
                style: TextStyle(color: Colors.black),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _experienceEndDateController,
                decoration: InputDecoration(
                  labelText: 'End Date (YYYY-MM-DD)',
                  labelStyle: TextStyle(color: Colors.black54),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.blue.shade300),
                  ),
                ),
                style: TextStyle(color: Colors.black),
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                title: Text('Currently Working', style: TextStyle(color: Colors.black)),
                value: _experienceIsCurrent,
                activeColor: Colors.blue.shade700,
                onChanged: (value) => setState(() => _experienceIsCurrent = value ?? false),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _addExperience,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Add Experience'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSkillsSection() {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 20),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.blue.shade100, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.star_outline, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  'Skills',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _currentUser.skills.asMap().entries.map((entry) => Chip(
                label: Text(entry.value, style: TextStyle(color: Colors.white)),
                backgroundColor: Colors.blue.shade700,
                deleteIcon: _isEditing ? const Icon(Icons.close, size: 18, color: Colors.white) : null,
                onDeleted: _isEditing ? () => _removeSkill(entry.key) : null,
              )).toList(),
            ),
            if (_isEditing) ...[
              const SizedBox(height: 16),
              const Divider(color: Colors.grey),
              const SizedBox(height: 12),
              Text('Add New Skill', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.black)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _skillController,
                      decoration: InputDecoration(
                        labelText: 'Skill',
                        labelStyle: TextStyle(color: Colors.black54),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.blue.shade300),
                        ),
                      ),
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: _addSkill,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Add'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCareerPreferencesSection() {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 20),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.blue.shade100, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings_suggest_outlined, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  'Career Preferences',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildEditableField(
              label: 'Job Type',
              value: _currentUser.preferences.jobType,
              isEditing: _isEditing,
              icon: Icons.work,
              onSaved: (value) => _currentUser = _currentUser.copyWith(
                preferences: _currentUser.preferences.copyWith(jobType: value),
              ),
            ),
            const SizedBox(height: 12),
            _buildEditableField(
              label: 'Preferred Location',
              value: _currentUser.preferences.preferredLocation,
              isEditing: _isEditing,
              icon: Icons.location_on,
              onSaved: (value) => _currentUser = _currentUser.copyWith(
                preferences: _currentUser.preferences.copyWith(preferredLocation: value),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
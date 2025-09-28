import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> with TickerProviderStateMixin {
  final user = FirebaseAuth.instance.currentUser!;
  final _formKey = GlobalKey<FormState>();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Controllers
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _industryController = TextEditingController();
  final TextEditingController _companySizeController = TextEditingController();
  final TextEditingController _aboutController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();

  File? _profileImage;
  File? _companyLogo;
  String? _currentProfileImageUrl;
  String? _currentCompanyLogoUrl;
  bool isLoading = false;
  bool isImageUploading = false;
  String? _imageUploadProgress;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _loadUserData();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _companyNameController.dispose();
    _industryController.dispose();
    _companySizeController.dispose();
    _aboutController.dispose();
    _websiteController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => isLoading = true);
    
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      final data = doc.data();
      if (data != null) {
        _fullNameController.text = data['fullName'] ?? '';
        _emailController.text = data['email'] ?? '';
        _phoneController.text = data['phoneNumber'] ?? '';
        _companyNameController.text = data['companyName'] ?? '';
        _industryController.text = data['industry'] ?? '';
        _companySizeController.text = data['companySize'] ?? '';
        _aboutController.text = data['about'] ?? '';
        _websiteController.text = data['website'] ?? '';
        _addressController.text = data['address'] ?? '';
        _cityController.text = data['city'] ?? '';
        _currentProfileImageUrl = data['profilePicture'];
        _currentCompanyLogoUrl = data['companyLogo'];
      }
    } catch (e) {
      _showSnackbar('Error loading profile data: $e', isError: true);
    }
    
    setState(() => isLoading = false);
  }

  Future<void> _pickImage(bool isProfile) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery, 
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      
      if (pickedFile != null) {
        setState(() {
          if (isProfile) {
            _profileImage = File(pickedFile.path);
          } else {
            _companyLogo = File(pickedFile.path);
          }
        });
        
        // Show immediate visual feedback
        _showSnackbar(
          isProfile ? 'Profile picture selected' : 'Company logo selected', 
          isError: false,
        );
      }
    } catch (e) {
      _showSnackbar('Error selecting image: $e', isError: true);
    }
  }

  Future<void> _showImageSourceDialog(bool isProfile) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            isProfile ? 'Update Profile Picture' : 'Update Company Logo',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1a73e8).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.photo_library, color: Color(0xFF1a73e8)),
                ),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(isProfile);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1a73e8).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt, color: Color(0xFF1a73e8)),
                ),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.of(context).pop();
                  _takePhoto(isProfile);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _takePhoto(bool isProfile) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      
      if (pickedFile != null) {
        setState(() {
          if (isProfile) {
            _profileImage = File(pickedFile.path);
          } else {
            _companyLogo = File(pickedFile.path);
          }
        });
        
        _showSnackbar(
          isProfile ? 'Photo captured' : 'Company logo captured', 
          isError: false,
        );
      }
    } catch (e) {
      _showSnackbar('Error taking photo: $e', isError: true);
    }
  }

  Future<String?> _uploadFile(File file, String path) async {
    try {
      setState(() {
        isImageUploading = true;
        _imageUploadProgress = 'Uploading image...';
      });

      final ref = FirebaseStorage.instance.ref().child(path);
      final uploadTask = ref.putFile(file);

      uploadTask.snapshotEvents.listen((event) {
        final progress = (event.bytesTransferred / event.totalBytes * 100).toStringAsFixed(0);
        setState(() {
          _imageUploadProgress = 'Uploading... $progress%';
        });
      });

      await uploadTask;
      final url = await ref.getDownloadURL();
      
      setState(() {
        isImageUploading = false;
        _imageUploadProgress = null;
      });
      
      return url;
    } catch (e) {
      setState(() {
        isImageUploading = false;
        _imageUploadProgress = null;
      });
      _showSnackbar('Upload failed: $e', isError: true);
      return null;
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    String? profileUrl;
    String? logoUrl;

    try {
      // Upload images if selected
      if (_profileImage != null) {
        profileUrl = await _uploadFile(
          _profileImage!, 
          'users/${user.uid}/profile_picture_${DateTime.now().millisecondsSinceEpoch}.jpg'
        );
      }
      
      if (_companyLogo != null) {
        logoUrl = await _uploadFile(
          _companyLogo!, 
          'users/${user.uid}/company_logo_${DateTime.now().millisecondsSinceEpoch}.jpg'
        );
      }

      // Update user data
      final updateData = {
        'fullName': _fullNameController.text.trim(),
        'email': _emailController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'companyName': _companyNameController.text.trim(),
        'industry': _industryController.text.trim(),
        'companySize': _companySizeController.text.trim(),
        'about': _aboutController.text.trim(),
        'website': _websiteController.text.trim(),
        'address': _addressController.text.trim(),
        'city': _cityController.text.trim(),
        'updatedAt': Timestamp.now(),
      };

      if (profileUrl != null) updateData['profilePicture'] = profileUrl;
      if (logoUrl != null) updateData['companyLogo'] = logoUrl;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update(updateData);

      if (mounted) {
        _showSnackbar('Profile updated successfully!', isError: false);
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      _showSnackbar('Error updating profile: $e', isError: true);
    }

    setState(() => isLoading = false);
  }

  void _showSnackbar(String message, {required bool isError}) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        backgroundColor: isError ? Colors.red : const Color(0xFF1a73e8),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF1a73e8),
        foregroundColor: Colors.white,
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        actions: [
          if (!isLoading)
            TextButton(
              onPressed: _saveProfile,
              child: const Text(
                'Save',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1a73e8)),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading profile...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Section Header
                      const Text(
                        'Profile Pictures',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Update your profile and company images',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Image Upload Section
                      Row(
                        children: [
                          // Profile Picture
                          Expanded(
                            child: Column(
                              children: [
                                const Text(
                                  'Profile Picture',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Stack(
                                  children: [
                                    Container(
                                      width: 120,
                                      height: 120,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: const Color(0xFF1a73e8).withValues(alpha: 0.1),
                                        border: Border.all(
                                          color: const Color(0xFF1a73e8).withValues(alpha: 0.3),
                                          width: 2,
                                        ),
                                        image: _getProfileImageProvider(),
                                      ),
                                      child: _profileImage == null && 
                                             (_currentProfileImageUrl?.isEmpty ?? true)
                                          ? Icon(
                                              Icons.person,
                                              size: 50,
                                              color: const Color(0xFF1a73e8).withValues(alpha: 0.7),
                                            )
                                          : null,
                                    ),
                                    if (isImageUploading)
                                      Positioned.fill(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.black54,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Center(
                                            child: CircularProgressIndicator(
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          ),
                                        ),
                                      ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: GestureDetector(
                                        onTap: () => _showImageSourceDialog(true),
                                        child: Container(
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF1a73e8),
                                            shape: BoxShape.circle,
                                            border: Border.all(color: Colors.white, width: 2),
                                          ),
                                          child: const Icon(
                                            Icons.camera_alt,
                                            size: 18,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 40),
                          // Company Logo
                          Expanded(
                            child: Column(
                              children: [
                                const Text(
                                  'Company Logo',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Stack(
                                  children: [
                                    Container(
                                      width: 120,
                                      height: 120,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        color: const Color(0xFF1a73e8).withValues(alpha: 0.1),
                                        border: Border.all(
                                          color: const Color(0xFF1a73e8).withValues(alpha: 0.3),
                                          width: 2,
                                        ),
                                        image: _getCompanyLogoProvider(),
                                      ),
                                      child: _companyLogo == null && 
                                             (_currentCompanyLogoUrl?.isEmpty ?? true)
                                          ? Icon(
                                              Icons.business,
                                              size: 50,
                                              color: const Color(0xFF1a73e8).withValues(alpha: 0.7),
                                            )
                                          : null,
                                    ),
                                    if (isImageUploading)
                                      Positioned.fill(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.black54,
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: const Center(
                                            child: CircularProgressIndicator(
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          ),
                                        ),
                                      ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: GestureDetector(
                                        onTap: () => _showImageSourceDialog(false),
                                        child: Container(
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF1a73e8),
                                            shape: BoxShape.circle,
                                            border: Border.all(color: Colors.white, width: 2),
                                          ),
                                          child: const Icon(
                                            Icons.camera_alt,
                                            size: 18,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      if (_imageUploadProgress != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1a73e8).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1a73e8)),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _imageUploadProgress!,
                                  style: const TextStyle(
                                    color: Color(0xFF1a73e8),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      const SizedBox(height: 40),

                      // Personal Information Section
                      _buildSectionHeader('Personal Information'),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _fullNameController,
                        label: 'Full Name / Contact Person',
                        icon: Icons.person_outline,
                        isRequired: true,
                      ),
                      _buildTextField(
                        controller: _emailController,
                        label: 'Email Address',
                        icon: Icons.email_outlined,
                        isEmail: true,
                        isRequired: true,
                      ),
                      _buildTextField(
                        controller: _phoneController,
                        label: 'Phone Number',
                        icon: Icons.phone_outlined,
                        isRequired: true,
                      ),

                      const SizedBox(height: 32),

                      // Company Information Section
                      _buildSectionHeader('Company Information'),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _companyNameController,
                        label: 'Company Name',
                        icon: Icons.business_outlined,
                        isRequired: true,
                      ),
                      _buildTextField(
                        controller: _industryController,
                        label: 'Industry / Sector',
                        icon: Icons.category_outlined,
                        isRequired: true,
                      ),
                      _buildTextField(
                        controller: _companySizeController,
                        label: 'Company Size',
                        icon: Icons.groups_outlined,
                      ),
                      _buildTextField(
                        controller: _websiteController,
                        label: 'Company Website',
                        icon: Icons.language_outlined,
                      ),
                      _buildTextField(
                        controller: _aboutController,
                        label: 'About Company',
                        icon: Icons.description_outlined,
                        maxLines: 4,
                      ),

                      const SizedBox(height: 32),

                      // Address Information Section
                      _buildSectionHeader('Address Information'),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _addressController,
                        label: 'Office Address',
                        icon: Icons.location_on_outlined,
                      ),
                      _buildTextField(
                        controller: _cityController,
                        label: 'City / Country',
                        icon: Icons.location_city_outlined,
                      ),

                      const SizedBox(height: 40),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: isLoading ? null : _saveProfile,
                          icon: isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Icon(Icons.save_outlined, size: 22),
                          label: Text(
                            isLoading ? 'Saving Changes...' : 'Save Changes',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1a73e8),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                            disabledBackgroundColor: Colors.grey[400],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: Colors.black87,
        letterSpacing: -0.3,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isEmail = false,
    bool isRequired = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
        validator: (val) {
          if (isRequired && (val == null || val.trim().isEmpty)) {
            return '$label is required';
          }
          if (isEmail && val != null && val.isNotEmpty && !val.contains('@')) {
            return 'Enter a valid email address';
          }
          return null;
        },
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 12, right: 16),
            child: Icon(
              icon,
              color: const Color(0xFF1a73e8),
              size: 22,
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF1a73e8), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  DecorationImage? _getProfileImageProvider() {
    if (_profileImage != null) {
      return DecorationImage(
        image: FileImage(_profileImage!),
        fit: BoxFit.cover,
      );
    } else if (_currentProfileImageUrl?.isNotEmpty == true) {
      return DecorationImage(
        image: NetworkImage(_currentProfileImageUrl!),
        fit: BoxFit.cover,
      );
    }
    return null;
  }

  DecorationImage? _getCompanyLogoProvider() {
    if (_companyLogo != null) {
      return DecorationImage(
        image: FileImage(_companyLogo!),
        fit: BoxFit.cover,
      );
    } else if (_currentCompanyLogoUrl?.isNotEmpty == true) {
      return DecorationImage(
        image: NetworkImage(_currentCompanyLogoUrl!),
        fit: BoxFit.cover,
      );
    }
    return null;
  }
}
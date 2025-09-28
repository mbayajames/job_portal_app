import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:provider/provider.dart';
import '../../../core/route_names.dart';
import '../../../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _role = 'seeker';
  XFile? _profileImage;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  int _currentTaglineIndex = 0;
  bool _isImageTapped = false;

  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;
  late Animation<Offset> _slideAnimation;

  final List<String> _taglines = [
    'Launch Your Career Today!',
    'Join Thousands of Professionals!',
    'Find Your Dream Job Now!',
    'Your Future Starts Here!'
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeInAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();

    // Rotate taglines every 3 seconds
    Future.delayed(const Duration(seconds: 3), _rotateTaglines);
  }

  void _rotateTaglines() {
    if (!mounted) return;
    setState(() {
      _currentTaglineIndex = (_currentTaglineIndex + 1) % _taglines.length;
    });
    Future.delayed(const Duration(seconds: 3), _rotateTaglines);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      setState(() => _isImageTapped = true);
      await Future.delayed(const Duration(milliseconds: 200));
      setState(() => _isImageTapped = false);

      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxHeight: 500,
        maxWidth: 500,
      );

      if (picked != null) {
        final bytes = await picked.readAsBytes();
        if (bytes.length > 2 * 1024 * 1024) {
          if (!mounted) return;
          _showSnackBar('Image size must be less than 2MB', Colors.orange);
          return;
        }
        setState(() => _profileImage = picked);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Failed to pick image: ${e.toString()}', Colors.red);
    }
  }

  Future<String?> _uploadProfileImage(String uid) async {
    try {
      if (_profileImage == null) return null;
      final ref = FirebaseStorage.instance.ref().child('profiles/$uid.jpg');
      if (kIsWeb) {
        final bytes = await _profileImage!.readAsBytes();
        await ref.putData(bytes);
      } else {
        await ref.putFile(File(_profileImage!.path));
      }
      return await ref.getDownloadURL();
    } catch (e) {
      if (!mounted) return null;
      _showSnackBar('Failed to upload image: ${e.toString()}', Colors.red);
      return null;
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      if (!mounted) return;
      _showSnackBar('Passwords do not match', Colors.orange);
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      final userData = {
        'name': _nameController.text.trim(),
        'role': _role,
      };

      final success = await authProvider.signUp(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        userData,
      );

      if (!mounted) return;

      if (success) {
        final uid = authProvider.user!.uid;
        if (_profileImage != null) {
          final imageUrl = await _uploadProfileImage(uid);
          if (imageUrl != null) {
            await authProvider.updateProfile({'photoUrl': imageUrl});
          }
        }

        if (!mounted) return;
        _showSnackBar('Registration successful! Please verify your email.', Colors.green);
        Navigator.pushReplacementNamed(context, RouteNames.login);
      } else {
        _showSnackBar(authProvider.errorMessage ?? 'Registration failed.', Colors.red);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Error: ${e.toString()}', Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final authProvider = Provider.of<AuthProvider>(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final cardWidth = isMobile ? MediaQuery.of(context).size.width * 0.9 : 420.0;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            height: screenHeight,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1A1A1A), Color(0xFF3366FF)],
              ),
            ),
            child: SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeInAnimation,
                child: Center(
                  child: Container(
                    width: cardWidth,
                    margin: EdgeInsets.all(isMobile ? 16.0 : 32.0),
                    padding: EdgeInsets.all(isMobile ? 24.0 : 32.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Header with Animated Tagline
                          Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Color(0xFF3366FF).withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.person_add,
                                  size: 48,
                                  color: Color(0xFF3366FF),
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Create Your Account',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                              const SizedBox(height: 8),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 500),
                                transitionBuilder: (child, animation) => FadeTransition(
                                  opacity: animation,
                                  child: child,
                                ),
                                child: Text(
                                  _taglines[_currentTaglineIndex],
                                  key: ValueKey<int>(_currentTaglineIndex),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFF3366FF),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 32),

                          // Profile Image Picker
                          GestureDetector(
                            onTap: _pickImage,
                            child: AnimatedScale(
                              scale: _isImageTapped ? 0.95 : 1.0,
                              duration: const Duration(milliseconds: 200),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFF3366FF),
                                        width: 3,
                                      ),
                                      gradient: LinearGradient(
                                        colors: [
                                          Color(0xFF3366FF).withValues(alpha: 0.1),
                                          Colors.white,
                                        ],
                                      ),
                                    ),
                                    child: ClipOval(
                                      child: _profileImage != null
                                          ? (kIsWeb
                                              ? Image.network(
                                                  _profileImage!.path,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) {
                                                    return _buildPlaceholderAvatar();
                                                  },
                                                )
                                              : Image.file(
                                                  File(_profileImage!.path),
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) {
                                                    return _buildPlaceholderAvatar();
                                                  },
                                                ))
                                          : _buildPlaceholderAvatar(),
                                    ),
                                  ),
                                  if (_profileImage == null)
                                    const Positioned(
                                      bottom: 8,
                                      child: Text(
                                        'Add Photo',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF3366FF),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF3366FF),
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
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Form Fields
                          _buildTextField(
                            _nameController,
                            'Full Name',
                            Icons.person_outline,
                            false,
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return 'Please enter your full name';
                              }
                              if (val.length < 2) {
                                return 'Name must be at least 2 characters';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          _buildTextField(
                            _emailController,
                            'Email Address',
                            Icons.email_outlined,
                            false,
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(val)) {
                                return 'Please enter a valid email address';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          _buildPasswordField(
                            _passwordController,
                            'Password',
                            Icons.lock_outline,
                            _obscurePassword,
                            onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return 'Please enter a password';
                              }
                              if (val.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          _buildPasswordField(
                            _confirmPasswordController,
                            'Confirm Password',
                            Icons.lock_outline,
                            _obscureConfirmPassword,
                            onToggle: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return 'Please confirm your password';
                              }
                              if (val != _passwordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          // Role Selection
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                              color: Colors.grey.shade50,
                            ),
                            child: DropdownButtonFormField<String>(
                              initialValue: _role,
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.work_outline, color: Color(0xFF3366FF)),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                labelText: 'Select Role',
                                labelStyle: TextStyle(color: Color(0xFF1A1A1A)),
                              ),
                              dropdownColor: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              items: const [
                                DropdownMenuItem(
                                  value: 'seeker',
                                  child: Text('Job Seeker', style: TextStyle(fontSize: 16, color: Color(0xFF1A1A1A))),
                                ),
                                DropdownMenuItem(
                                  value: 'employer',
                                  child: Text('Employer', style: TextStyle(fontSize: 16, color: Color(0xFF1A1A1A))),
                                ),
                              ],
                              onChanged: (val) => setState(() => _role = val!),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Social Login Buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildSocialButton(
                                icon: Icons.g_mobiledata,
                                label: 'Google',
                                onPressed: () => _showSnackBar('Google Sign-In not implemented yet', Colors.orange),
                              ),
                              _buildSocialButton(
                                icon: Icons.apple,
                                label: 'Apple',
                                onPressed: () => _showSnackBar('Apple Sign-In not implemented yet', Colors.orange),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Register Button
                          authProvider.isLoading
                              ? _buildLoadingIndicator()
                              : _buildRegisterButton(),

                          const SizedBox(height: 24),

                          // Login Redirect
                          _buildLoginRedirect(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderAvatar() {
    return Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFF3366FF), Color(0xFF1A1A1A)],
        ),
      ),
      child: const Icon(
        Icons.person,
        size: 40,
        color: Colors.white,
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon,
    bool obscure, {
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      style: const TextStyle(fontSize: 16, color: Color(0xFF1A1A1A)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade600),
        prefixIcon: Icon(icon, color: const Color(0xFF3366FF)),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: const Color(0xFF3366FF), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
    );
  }

  Widget _buildPasswordField(
    TextEditingController controller,
    String label,
    IconData icon,
    bool obscure, {
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      style: const TextStyle(fontSize: 16, color: Color(0xFF1A1A1A)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade600),
        prefixIcon: Icon(icon, color: const Color(0xFF3366FF)),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            color: Colors.grey.shade500,
          ),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: const Color(0xFF3366FF), width: 2),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          colors: [Color(0xFF3366FF), Color(0xFF1A1A1A)],
        ),
      ),
      child: const Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Creating your account...',
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterButton() {
    return ElevatedButton(
      onPressed: _register,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF3366FF),
        foregroundColor: Colors.white,
        elevation: 4,
        shadowColor: Color(0xFF1A1A1A).withValues(alpha: 0.3),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.app_registration, size: 20),
          SizedBox(width: 8),
          Text(
            'Create Account',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.grey.shade300),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF1A1A1A),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: const Color(0xFF3366FF)),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginRedirect() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have an account? ',
          style: TextStyle(color: Colors.grey.shade600),
        ),
        GestureDetector(
          onTap: () => Navigator.pushReplacementNamed(context, RouteNames.login),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: Color(0xFF3366FF).withValues(alpha: 0.1),
            ),
            child: const Text(
              'Sign In',
              style: TextStyle(
                color: Color(0xFF3366FF),
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
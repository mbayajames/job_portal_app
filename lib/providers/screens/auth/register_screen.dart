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

class _RegisterScreenState extends State<RegisterScreen> 
    with TickerProviderStateMixin {
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
  late AnimationController _successController;
  late Animation<double> _fadeInAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _successAnimation;

  final List<Map<String, String>> _welcomeMessages = [
    {
      'title': 'Welcome to Your Future!',
      'subtitle': 'Join thousands finding their dream careers'
    },
    {
      'title': 'Ready to Get Started?',
      'subtitle': 'Your next opportunity is just moments away'
    },
    {
      'title': 'Let\'s Build Something Great!',
      'subtitle': 'Connect with amazing opportunities today'
    },
    {
      'title': 'Your Journey Begins Here!',
      'subtitle': 'Discover endless career possibilities'
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeInAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    _successAnimation = CurvedAnimation(
      parent: _successController,
      curve: Curves.elasticOut,
    );

    _animationController.forward();
    _startMessageRotation();
  }

  void _startMessageRotation() {
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _currentTaglineIndex = (_currentTaglineIndex + 1) % _welcomeMessages.length;
        });
        _startMessageRotation();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _successController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String _getPersonalizedGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning!';
    } else if (hour < 17) {
      return 'Good Afternoon!';
    } else {
      return 'Good Evening!';
    }
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
          _showCustomSnackBar('Image size must be less than 2MB', SnackBarType.warning);
          return;
        }
        setState(() => _profileImage = picked);
        _showCustomSnackBar('Profile photo selected!', SnackBarType.success);
      }
    } catch (e) {
      if (!mounted) return;
      _showCustomSnackBar('Failed to pick image', SnackBarType.error);
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
      _showCustomSnackBar('Failed to upload profile image', SnackBarType.error);
      return null;
    }
  }

  void _showCustomSnackBar(String message, SnackBarType type) {
    Color backgroundColor;
    IconData icon;
    
    switch (type) {
      case SnackBarType.success:
        backgroundColor = Colors.green[600]!;
        icon = Icons.check_circle;
        break;
      case SnackBarType.error:
        backgroundColor = Colors.red[600]!;
        icon = Icons.error;
        break;
      case SnackBarType.warning:
        backgroundColor = Colors.orange[600]!;
        icon = Icons.warning;
        break;
      case SnackBarType.info:
        backgroundColor = Colors.blue[600]!;
        icon = Icons.info;
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccessGreeting(String name) {
    _successController.forward();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: ScaleTransition(
          scale: _successAnimation,
          child: Container(
            padding: const EdgeInsets.all(32),
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green[400]!, Colors.green[600]!],
                    ),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: const Icon(
                    Icons.celebration,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Welcome aboard, ${name.split(' ').first}!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _role == 'seeker' 
                    ? 'Your account has been created successfully!\nGet ready to discover amazing career opportunities!'
                    : 'Your employer account is ready!\nStart connecting with talented professionals today!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue[600]!, Colors.blue[800]!],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushReplacementNamed(context, RouteNames.login);
                      },
                      child: const Center(
                        child: Text(
                          'Continue to Login',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      _showCustomSnackBar('Passwords do not match', SnackBarType.warning);
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
        final name = _nameController.text.trim();
        
        if (_profileImage != null) {
          final imageUrl = await _uploadProfileImage(uid);
          if (imageUrl != null) {
            await authProvider.updateProfile({'photoUrl': imageUrl});
          }
        }

        if (!mounted) return;
        _showSuccessGreeting(name);
      } else {
        _showCustomSnackBar(
          authProvider.errorMessage ?? 'Registration failed',
          SnackBarType.error,
        );
      }
    } catch (e) {
      if (!mounted) return;
      _showCustomSnackBar('Something went wrong. Please try again.', SnackBarType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue[900]!,
              Colors.blue[700]!,
              Colors.blue[500]!,
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeInAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 20 : 40,
                  vertical: 20,
                ),
                child: Center(
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: isMobile ? double.infinity : 500,
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        
                        // Personalized Greeting Header
                        ScaleTransition(
                          scale: _scaleAnimation,
                          child: _buildGreetingHeader(),
                        ),
                        
                        const SizedBox(height: 30),
                        
                        // Registration Form Card
                        _buildRegistrationCard(authProvider),
                      ],
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

  Widget _buildGreetingHeader() {
    final currentMessage = _welcomeMessages[_currentTaglineIndex];
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              Icons.person_add_outlined,
              size: 40,
              color: Colors.blue[600],
            ),
          ),
          const SizedBox(height: 20),
          
          Text(
            _getPersonalizedGreeting(),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 800),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.3),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: Column(
              key: ValueKey<int>(_currentTaglineIndex),
              children: [
                Text(
                  currentMessage['title']!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  currentMessage['subtitle']!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegistrationCard(AuthProvider authProvider) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Form Title
            Text(
              'Create Your Account',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Join our community and unlock endless opportunities',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),

            // Profile Image Picker
            _buildProfileImagePicker(),
            const SizedBox(height: 32),

            // Form Fields
            _buildStyledTextField(
              controller: _nameController,
              label: 'Full Name',
              icon: Icons.person_outline,
              validator: (val) {
                if (val == null || val.isEmpty) return 'Please enter your full name';
                if (val.length < 2) return 'Name must be at least 2 characters';
                return null;
              },
            ),
            const SizedBox(height: 20),

            _buildStyledTextField(
              controller: _emailController,
              label: 'Email Address',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (val) {
                if (val == null || val.isEmpty) return 'Please enter your email';
                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(val)) {
                  return 'Please enter a valid email address';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            _buildPasswordField(
              controller: _passwordController,
              label: 'Password',
              obscureText: _obscurePassword,
              onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
              validator: (val) {
                if (val == null || val.isEmpty) return 'Please enter a password';
                if (val.length < 6) return 'Password must be at least 6 characters';
                return null;
              },
            ),
            const SizedBox(height: 20),

            _buildPasswordField(
              controller: _confirmPasswordController,
              label: 'Confirm Password',
              obscureText: _obscureConfirmPassword,
              onToggle: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
              validator: (val) {
                if (val == null || val.isEmpty) return 'Please confirm your password';
                if (val != _passwordController.text) return 'Passwords do not match';
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Role Selection
            _buildRoleSelector(),
            const SizedBox(height: 32),

            // Register Button
            authProvider.isLoading
                ? _buildLoadingButton()
                : _buildRegisterButton(),
            
            const SizedBox(height: 24),

            // Login Redirect
            _buildLoginRedirect(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImagePicker() {
    return Center(
      child: GestureDetector(
        onTap: _pickImage,
        child: AnimatedScale(
          scale: _isImageTapped ? 0.95 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.blue[600]!,
                    width: 3,
                  ),
                  gradient: _profileImage != null 
                    ? null
                    : LinearGradient(
                        colors: [
                          Colors.blue[50]!,
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
                              errorBuilder: (context, error, stackTrace) => _buildPlaceholderAvatar(),
                            )
                          : Image.file(
                              File(_profileImage!.path),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => _buildPlaceholderAvatar(),
                            ))
                      : _buildPlaceholderAvatar(),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.blue[600],
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderAvatar() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Colors.blue[100]!, Colors.blue[200]!],
        ),
      ),
      child: Icon(
        Icons.person,
        size: 40,
        color: Colors.blue[600],
      ),
    );
  }

  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[600]),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.blue[600], size: 20),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        validator: validator,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[600]),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.lock_outline, color: Colors.blue[600], size: 20),
          ),
          suffixIcon: IconButton(
            icon: Icon(
              obscureText ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey[600],
            ),
            onPressed: onToggle,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        ),
      ),
    );
  }

  Widget _buildRoleSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: DropdownButtonFormField<String>(
        value: _role,
        decoration: InputDecoration(
          labelText: 'I am a...',
          labelStyle: TextStyle(color: Colors.grey[600]),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.work_outline, color: Colors.blue[600], size: 20),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        ),
        items: const [
          DropdownMenuItem(
            value: 'seeker',
            child: Text('Job Seeker - Looking for opportunities'),
          ),
          DropdownMenuItem(
            value: 'employer',
            child: Text('Employer - Hiring talent'),
          ),
        ],
        onChanged: (val) => setState(() => _role = val!),
      ),
    );
  }

  Widget _buildLoadingButton() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey[400]!, Colors.grey[500]!],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Creating your account...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterButton() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[600]!, Colors.blue[800]!],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _register,
          borderRadius: BorderRadius.circular(16),
          child: const Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_add, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'Create My Account',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
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
          style: TextStyle(color: Colors.grey[600]),
        ),
        GestureDetector(
          onTap: () => Navigator.pushReplacementNamed(context, RouteNames.login),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Sign In',
              style: TextStyle(
                color: Colors.blue[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

enum SnackBarType { success, error, warning, info }
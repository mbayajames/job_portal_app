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

  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _fadeInAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeIn);
    _animationController.forward();
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image size must be less than 2MB')),
          );
          return;
        }
        setState(() => _profileImage = picked);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload image: $e')),
      );
      return null;
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration successful! Verify email before login.'),
          ),
        );
        Navigator.pushReplacementNamed(context, RouteNames.login);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? 'Registration failed.'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Register'),
        backgroundColor: Colors.blue.shade800,
      ),
      body: FadeTransition(
        opacity: _fadeInAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Center(
            child: Container(
              width: isMobile ? double.infinity : 500,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.blue.shade50,
                        backgroundImage: _profileImage != null
                            ? kIsWeb
                                ? NetworkImage(_profileImage!.path)
                                : FileImage(File(_profileImage!.path)) as ImageProvider
                            : null,
                        child: _profileImage == null
                            ? const Icon(Icons.camera_alt, size: 40, color: Colors.blue)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      _nameController,
                      'Full Name',
                      Icons.person,
                      false,
                      validator: (val) {
                        if (val == null || val.isEmpty) {
                          return 'Enter your full name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      _emailController,
                      'Email',
                      Icons.email,
                      false,
                      validator: (val) {
                        if (val == null || val.isEmpty) {
                          return 'Enter email';
                        }
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(val)) {
                          return 'Enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      _passwordController,
                      'Password',
                      Icons.lock,
                      true,
                      validator: (val) {
                        if (val == null || val.isEmpty) {
                          return 'Enter password';
                        }
                        if (val.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      _confirmPasswordController,
                      'Confirm Password',
                      Icons.lock_outline,
                      true,
                      validator: (val) {
                        if (val == null || val.isEmpty) {
                          return 'Confirm your password';
                        }
                        if (val != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _role,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.account_circle, color: Colors.blue),
                        labelText: 'Role',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'seeker', child: Text('Job Seeker')),
                        DropdownMenuItem(value: 'employer', child: Text('Employer')),
                      ],
                      onChanged: (val) => setState(() => _role = val!),
                    ),
                    const SizedBox(height: 20),
                    authProvider.isLoading
                        ? const Center(child: CircularProgressIndicator(color: Colors.blue))
                        : ElevatedButton.icon(
                            onPressed: _register,
                            icon: const Icon(Icons.app_registration),
                            label: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 14),
                              child: Text(
                                'Register',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade800,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: () => Navigator.pushReplacementNamed(context, RouteNames.login),
                      icon: const Icon(Icons.login, color: Colors.blue),
                      label: const Text(
                        'Already have an account? Login',
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
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
      style: const TextStyle(color: Colors.black),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blue),
        filled: true,
        fillColor: Colors.blue.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
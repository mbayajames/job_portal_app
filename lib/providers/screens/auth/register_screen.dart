import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:job_portal_app/core/constants.dart';
import 'package:job_portal_app/core/routes.dart';
import 'package:job_portal_app/services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  String _role = kJobSeekerRole;
  bool _loading = false;

  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      await _authService.register(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _nameController.text.trim(),
        _role,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Registration successful! Please log in.")),
      );

      Navigator.pushReplacementNamed(context, Routes.login);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(20),
            width: size.width > 600 ? 420 : size.width * 0.9,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Icon(
                    MaterialCommunityIcons.account_plus,
                    size: 65,
                    color: kPrimaryColor,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Create an Account",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: kSecondaryColor,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Full Name
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      prefixIcon: Icon(MaterialIcons.person, color: kPrimaryColor),
                      labelText: "Full Name",
                      filled: true,
                      fillColor: kLightColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (val) =>
                        val == null || val.isEmpty ? "Enter your full name" : null,
                  ),
                  const SizedBox(height: 16),

                  // Email
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      prefixIcon: Icon(MaterialIcons.email, color: kPrimaryColor),
                      labelText: "Email",
                      filled: true,
                      fillColor: kLightColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) return "Enter email";
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(val)) {
                        return "Enter valid email";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      prefixIcon: Icon(MaterialIcons.lock, color: kPrimaryColor),
                      labelText: "Password",
                      filled: true,
                      fillColor: kLightColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) return "Enter password";
                      if (val.length < 6) return "Password must be at least 6 characters";
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Role selection
                  DropdownButtonFormField<String>(
                    initialValue: _role,
                    items: const [
                      DropdownMenuItem(
                        value: kJobSeekerRole,
                        child: Text("Job Seeker"),
                      ),
                      DropdownMenuItem(
                        value: kEmployerRole,
                        child: Text("Employer"),
                      ),
                    ],
                    onChanged: (val) {
                      setState(() => _role = val!);
                    },
                    decoration: InputDecoration(
                      prefixIcon: Icon(MaterialIcons.work, color: kPrimaryColor),
                      labelText: "Select Role",
                      filled: true,
                      fillColor: kLightColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Register Button
                  _loading
                      ? const CircularProgressIndicator()
                      : ElevatedButton.icon(
                          icon: const Icon(Icons.person_add),
                          onPressed: _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimaryColor,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          label: const Text("Register"),
                        ),
                  const SizedBox(height: 12),

                  // Already have an account
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Already have an account?"),
                      TextButton.icon(
                        icon: const Icon(
                          Feather.log_in,
                          size: 18,
                          color: kPrimaryColor,
                        ),
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, Routes.login);
                        },
                        label: const Text("Login"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

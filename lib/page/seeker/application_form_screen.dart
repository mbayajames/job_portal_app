import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';

import '../../models/job_model.dart';
import '../../providers/application_provider.dart';
import '../../utils/file_picker_util.dart';
import '../../services/file_upload_service.dart';
import '../../core/route_names.dart';

import 'application_submission_helper_screen.dart';

class ApplicationFormScreen extends StatefulWidget {
  final JobModel? job;
  final String? jobId;

  const ApplicationFormScreen({
    super.key,
    this.job,
    this.jobId,
  });

  @override
  ApplicationFormScreenState createState() => ApplicationFormScreenState();
}

class ApplicationFormScreenState extends State<ApplicationFormScreen>
    with TickerProviderStateMixin {
  final Logger _logger = Logger('ApplicationFormScreenState');
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _coverLetterController = TextEditingController();

  final _fileUploadService = FileUploadService();
  String? _resumeUrl;

  bool _isSubmitting = false;
  bool _isLoadingJob = false;

  String? _selectedExperience;
  String? _selectedEducation;

  JobModel? _job;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _prefillUserData();
    _loadJobIfNeeded();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _coverLetterController.dispose();
    super.dispose();
  }

  void _loadJobIfNeeded() async {
    if (widget.job != null) {
      setState(() => _job = widget.job);
    } else if (widget.jobId != null) {
      setState(() => _isLoadingJob = true);
      try {
        final doc = await FirebaseFirestore.instance
            .collection('jobs')
            .doc(widget.jobId)
            .get();

        if (doc.exists) {
          setState(() {
            _job = JobModel.fromMap(doc.data()!, doc.id);
          });
        }
      } catch (e) {
        _logger.severe("Error fetching job: $e");
      } finally {
        setState(() => _isLoadingJob = false);
      }
    }
  }

  void _prefillUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _emailController.text = user.email ?? '';
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data();
          if (userData != null) {
            _fullNameController.text = userData['fullName'] ?? '';
            _phoneController.text = userData['phoneNumber'] ?? '';
          }
        }
      } catch (e) {
        _logger.severe('Error fetching user data: $e');
      }
    }
  }

  bool get _isFormValid {
    return _fullNameController.text.isNotEmpty &&
        _emailController.text.isNotEmpty &&
        _phoneController.text.isNotEmpty &&
        _resumeUrl != null &&
        _selectedExperience != null &&
        _selectedEducation != null;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingJob) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading job details...',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_job == null) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.work_off_outlined,
                size: 80,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Job not found',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'The job you\'re looking for doesn\'t exist',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          'Apply for Position',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Card
                  _buildHeaderCard(),
                  const SizedBox(height: 24),

                  // Personal Information Section
                  _buildSectionCard(
                    title: 'Personal Information',
                    icon: Icons.person_outline,
                    children: [
                      _buildStyledTextField(
                        controller: _fullNameController,
                        label: 'Full Name',
                        icon: Icons.badge_outlined,
                        validator: (val) => val == null || val.isEmpty 
                            ? 'Full Name is required' : null,
                      ),
                      const SizedBox(height: 16),
                      _buildStyledTextField(
                        controller: _emailController,
                        label: 'Email Address',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Email is required';
                          final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                          if (!emailRegex.hasMatch(val)) return 'Enter a valid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildStyledTextField(
                        controller: _phoneController,
                        label: 'Phone Number',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Phone number is required';
                          if (val.length < 7) return 'Enter a valid phone number';
                          return null;
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Professional Details Section
                  _buildSectionCard(
                    title: 'Professional Details',
                    icon: Icons.work_outline,
                    children: [
                      _buildStyledDropdown(
                        initialValue: _selectedExperience,
                        label: 'Experience Level',
                        icon: Icons.timeline_outlined,
                        items: ['0-1 years', '1-3 years', '3-5 years', '5+ years'],
                        onChanged: (val) => setState(() => _selectedExperience = val),
                        validator: (val) => val == null ? 'Please select experience level' : null,
                      ),
                      const SizedBox(height: 16),
                      _buildStyledDropdown(
                        initialValue: _selectedEducation,
                        label: 'Education Level',
                        icon: Icons.school_outlined,
                        items: ['High School', 'Diploma', 'Bachelor', 'Master', 'PhD'],
                        onChanged: (val) => setState(() => _selectedEducation = val),
                        validator: (val) => val == null ? 'Please select education level' : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Cover Letter Section
                  _buildSectionCard(
                    title: 'Cover Letter',
                    icon: Icons.description_outlined,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: TextFormField(
                          controller: _coverLetterController,
                          maxLines: 6,
                          decoration: InputDecoration(
                            labelText: 'Tell us why you\'re perfect for this role',
                            labelStyle: TextStyle(color: Colors.grey[600]),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(16),
                            floatingLabelBehavior: FloatingLabelBehavior.never,
                          ),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Resume Upload Section
                  _buildSectionCard(
                    title: 'Resume',
                    icon: Icons.attach_file_outlined,
                    children: [_buildResumeSection()],
                  ),
                  const SizedBox(height: 32),

                  // Submit Button
                  _buildSubmitButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue[600]!,
            Colors.blue[800]!,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _job!.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.business, color: Colors.white70, size: 18),
              const SizedBox(width: 8),
              Text(
                _job!.company,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          if (_job!.location.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.white70, size: 18),
                const SizedBox(width: 8),
                Text(
                  _job!.location,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.blue[600], size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[600]),
          prefixIcon: Icon(icon, color: Colors.blue[600]),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        style: const TextStyle(fontSize: 16),
      ),
    );
  }

  Widget _buildStyledDropdown({
    required String? initialValue,
    required String label,
    required IconData icon,
    required List<String> items,
    required void Function(String?) onChanged,
    String? Function(String?)? validator,
  }) {
    return FormField<String>(
      initialValue: initialValue,
      validator: validator,
      builder: (FormFieldState<String> state) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(color: Colors.grey[600]),
              prefixIcon: Icon(icon, color: Colors.blue[600]),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              errorText: state.errorText,
            ),
            child: DropdownButton<String>(
              value: state.value,
              onChanged: (val) {
                state.didChange(val);
                onChanged(val);
              },
              items: items.map((item) => DropdownMenuItem(
                value: item,
                child: Text(item, style: const TextStyle(fontSize: 16)),
              )).toList(),
              style: const TextStyle(fontSize: 16, color: Colors.black),
              dropdownColor: Colors.white,
              isExpanded: true,
              underline: const SizedBox(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildResumeSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _resumeUrl == null ? Colors.grey[50] : Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _resumeUrl == null ? Colors.grey[300]! : Colors.green[300]!,
          style: BorderStyle.solid,
        ),
      ),
      child: _resumeUrl == null
          ? Column(
              children: [
                Icon(
                  Icons.cloud_upload_outlined,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 12),
                Text(
                  'Upload your resume',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Supported formats: PDF, DOC, DOCX',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _uploadResume,
                  icon: const Icon(Icons.upload_file, size: 20),
                  label: const Text('Choose File'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.check_circle, color: Colors.green[600], size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Resume uploaded successfully',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.green[700],
                        ),
                      ),
                      Text(
                        'Your resume is ready for submission',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.green[600],
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: _uploadResume,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Change'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blue[600],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSubmitButton() {
    return Consumer<ApplicationProvider>(
      builder: (context, applicationProvider, child) {
        return Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: _isFormValid && !_isSubmitting
                ? LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [Colors.blue[600]!, Colors.blue[800]!],
                  )
                : null,
            color: !_isFormValid || _isSubmitting ? Colors.grey[300] : null,
            borderRadius: BorderRadius.circular(12),
            boxShadow: _isFormValid && !_isSubmitting
                ? [
                    BoxShadow(
                      color: Colors.blue.withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isSubmitting || !_isFormValid ? null : _submitApplication,
              borderRadius: BorderRadius.circular(12),
              child: Center(
                child: _isSubmitting
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Submitting Application...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.send,
                            color: _isFormValid ? Colors.white : Colors.grey[600],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Submit Application',
                            style: TextStyle(
                              color: _isFormValid ? Colors.white : Colors.grey[600],
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _uploadResume() async {
    final file = await FilePickerUtil.pickResume();
    if (file != null) {
      try {
        final url = await _fileUploadService.uploadFile(file);
        if (mounted) {
          setState(() => _resumeUrl = url);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Resume uploaded successfully!'),
                ],
              ),
              backgroundColor: Colors.green[600],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Failed to upload resume: $e')),
                ],
              ),
              backgroundColor: Colors.red[600],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
        }
      }
    }
  }

  void _submitApplication() async {
    if (!_formKey.currentState!.validate() || _job == null) return;

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        CustomSnackBar.show(
          context,
          message: 'Please login to apply for jobs',
          type: SnackBarType.warning,
        );
        Navigator.pushNamed(context, RouteNames.login);
        return;
      }

      // Use the enhanced submission helper
      final result = await ApplicationSubmissionHelper.submitApplicationSafely(
        jobId: _job!.id,
        jobTitle: _job!.title,
        companyName: _job!.company,
        fullName: _fullNameController.text,
        email: _emailController.text,
        phone: _phoneController.text,
        coverLetter: _coverLetterController.text,
        resumeUrl: _resumeUrl ?? '',
        experience: _selectedExperience ?? '',
        education: _selectedEducation ?? '',
      );

      if (mounted) {
        if (result['success'] == true) {
          // Show success message
          CustomSnackBar.show(
            context,
            message: result['message'] ?? 'Application submitted successfully!',
            type: SnackBarType.success,
            duration: const Duration(seconds: 3),
          );

          // Show success dialog for better user experience
          ApplicationSubmissionHelper.showSuccessDialog(
            context,
            'Your application has been submitted successfully! The employer will review your application and get back to you soon.',
            onOk: () => Navigator.pop(context, true),
          );
        } else {
          // Handle different error types
          final errorCode = result['code'] ?? 'unknown_error';
          final errorMessage = result['error'] ?? 'Failed to submit application';

          if (errorCode == 'already_applied') {
            CustomSnackBar.show(
              context,
              message: errorMessage,
              type: SnackBarType.warning,
            );
          } else if (errorCode == 'permission_denied') {
            ApplicationSubmissionHelper.showErrorDialog(
              context,
              'Permission Denied',
              'You don\'t have permission to submit applications. This might be due to:\n\n'
              '• Firestore security rules not being configured correctly\n'
              '• Your account not being properly authenticated\n'
              '• Network connectivity issues\n\n'
              'Please contact support or try again later.',
              onRetry: _submitApplication,
            );
          } else {
            CustomSnackBar.show(
              context,
              message: errorMessage,
              type: SnackBarType.error,
              duration: const Duration(seconds: 5),
              onAction: _submitApplication,
              actionLabel: 'RETRY',
            );
          }
        }
      }
    } catch (e) {
      _logger.severe('Unexpected error in _submitApplication: $e');
      
      if (mounted) {
        CustomSnackBar.show(
          context,
          message: 'An unexpected error occurred. Please try again.',
          type: SnackBarType.error,
          onAction: _submitApplication,
          actionLabel: 'RETRY',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
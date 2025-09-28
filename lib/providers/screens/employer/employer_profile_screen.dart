import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'my_jobs_screen.dart';
import 'post_job_screen.dart';
import 'edit_profile_screen.dart';
import 'dart:io';
import '../../../services/payment_service.dart';

class EmployerProfileScreen extends StatefulWidget {
  const EmployerProfileScreen({super.key});

  @override
  State<EmployerProfileScreen> createState() => _EmployerProfileScreenState();
}

class _EmployerProfileScreenState extends State<EmployerProfileScreen>
    with SingleTickerProviderStateMixin {
  final user = FirebaseAuth.instance.currentUser!;
  final ImagePicker _imagePicker = ImagePicker();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  Map<String, dynamic>? employerData;
  List<Map<String, dynamic>>? transactions;
  int jobsPosted = 0;
  int activeApplications = 0;
  int recentHires = 0;
  bool isLoading = true;
  bool isUploading = false;
  bool hasError = false;

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
    _loadEmployerProfile();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadEmployerProfile() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      // Load employer info
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      if (userDoc.exists) {
        employerData = userDoc.data();
        
        // Count jobs posted
        final jobsSnapshot = await FirebaseFirestore.instance
            .collection('jobs')
            .where('employerId', isEqualTo: user.uid)
            .get();
        
        jobsPosted = jobsSnapshot.docs.length;

        // Calculate statistics
        activeApplications = 0;
        recentHires = 0;
        
        for (var job in jobsSnapshot.docs) {
          try {
            // Count applications for this job
            final applicationsSnapshot = await FirebaseFirestore.instance
                .collection('applications')
                .where('jobId', isEqualTo: job.id)
                .where('status', isEqualTo: 'pending')
                .get();
            
            activeApplications += applicationsSnapshot.docs.length;

            // Count hires for this job
            final hiresSnapshot = await FirebaseFirestore.instance
                .collection('applications')
                .where('jobId', isEqualTo: job.id)
                .where('status', isEqualTo: 'hired')
                .get();
            
            recentHires += hiresSnapshot.docs.length;
          } catch (e) {
            debugPrint('Error loading job statistics for ${job.id}: $e');
            // Continue loading other jobs even if one fails
          }
        }
      } else {
        throw Exception('User document not found');
      }

      // Load payment transactions with error handling
      try {
        transactions = await PaymentService.getAllTransactions() ?? [];
      } catch (e) {
        debugPrint('Error loading transactions: $e');
        transactions = [];
      }

      _animationController.forward();
    } catch (e) {
      debugPrint('Error loading employer profile: $e');
      if (mounted) setState(() => hasError = true);
      _showErrorSnackBar('Failed to load profile data');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _updateProfilePicture() async {
    if (isUploading) return;

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() => isUploading = true);

        // Validate file size (max 5MB)
        final File imageFile = File(image.path);
        final int fileSize = await imageFile.length();
        if (fileSize > 5 * 1024 * 1024) {
          throw Exception('Image size must be less than 5MB');
        }

        // Upload to Firebase Storage
        final String fileName = 'profile_pictures/${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        
        final Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
        final UploadTask uploadTask = storageRef.putFile(imageFile);
        
        // Monitor upload progress
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          debugPrint('Upload progress: ${(progress * 100).toStringAsFixed(2)}%');
        });

        final TaskSnapshot snapshot = await uploadTask;
        
        // Get download URL
        final String downloadUrl = await snapshot.ref.getDownloadURL();

        // Update Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'profilePicture': downloadUrl});

        // Update local state
        if (mounted) {
          setState(() {
            employerData!['profilePicture'] = downloadUrl;
          });
        }

        _showSuccessSnackBar('Profile picture updated successfully');
      }
    } catch (e) {
      debugPrint('Error updating profile picture: $e');
      String errorMessage = 'Failed to update profile picture';

      if (e.toString().contains('5MB')) {
        errorMessage = 'Image size must be less than 5MB';
      } else if (e.toString().contains('network')) {
        errorMessage = 'Network error. Please check your connection.';
      }

      _showErrorSnackBar(errorMessage);
    } finally {
      if (mounted) setState(() => isUploading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green[700],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<void> _changePassword() async {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final TextEditingController currentPasswordController = TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController = TextEditingController();
    bool isCurrentPasswordVisible = false;
    bool isNewPasswordVisible = false;
    bool isConfirmPasswordVisible = false;
    bool isChangingPassword = false;

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.lock_outline, color: Colors.blue[700], size: 20),
              ),
              const SizedBox(width: 12),
              const Text('Change Password'),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: currentPasswordController,
                  obscureText: !isCurrentPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'Current Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        isCurrentPasswordVisible ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () => setDialogState(() => isCurrentPasswordVisible = !isCurrentPasswordVisible),
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) => value?.isEmpty == true ? 'Please enter current password' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: newPasswordController,
                  obscureText: !isNewPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        isNewPasswordVisible ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () => setDialogState(() => isNewPasswordVisible = !isNewPasswordVisible),
                    ),
                    border: const OutlineInputBorder(),
                    helperText: 'At least 6 characters',
                  ),
                  validator: (value) {
                    if (value?.isEmpty == true) return 'Please enter new password';
                    if (value!.length < 6) return 'Password must be at least 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: confirmPasswordController,
                  obscureText: !isConfirmPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'Confirm New Password',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () => setDialogState(() => isConfirmPasswordVisible = !isConfirmPasswordVisible),
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value?.isEmpty == true) return 'Please confirm new password';
                    if (value != newPasswordController.text) return 'Passwords do not match';
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isChangingPassword ? null : () {
                currentPasswordController.dispose();
                newPasswordController.dispose();
                confirmPasswordController.dispose();
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isChangingPassword ? null : () async {
                if (!formKey.currentState!.validate()) return;

                final BuildContext dialogContext = context;
                setDialogState(() => isChangingPassword = true);

                try {
                   // Reauthenticate user
                   final AuthCredential credential = EmailAuthProvider.credential(
                     email: user.email!,
                     password: currentPasswordController.text,
                   );

                   await user.reauthenticateWithCredential(credential);
                   await user.updatePassword(newPasswordController.text);

                   currentPasswordController.dispose();
                   newPasswordController.dispose();
                   confirmPasswordController.dispose();
                   if (dialogContext.mounted) {
                     Navigator.pop(dialogContext);
                     _showSuccessSnackBar('Password updated successfully');
                   }
                 } catch (e) {
                   String errorMessage = 'Failed to update password';
                   if (e.toString().contains('wrong-password')) {
                     errorMessage = 'Current password is incorrect';
                   } else if (e.toString().contains('too-many-requests')) {
                     errorMessage = 'Too many attempts. Please try again later';
                   }
                   if (mounted) {
                     _showErrorSnackBar(errorMessage);
                   }
                 } finally {
                   setDialogState(() => isChangingPassword = false);
                 }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
              ),
              child: isChangingPassword
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Update Password'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSupportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.support_agent, color: Colors.blue[700], size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Customer Support'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Get help with your account and job postings:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            _ContactInfo(
              icon: Icons.email_outlined,
              title: 'Email Support',
              value: 'support@jobfinder.com',
            ),
            const SizedBox(height: 12),
            _ContactInfo(
              icon: Icons.phone_outlined,
              title: 'Phone Support',
              value: '+1 (555) 123-4567',
            ),
            const SizedBox(height: 12),
            _ContactInfo(
              icon: Icons.schedule_outlined,
              title: 'Support Hours',
              value: 'Mon-Fri 9AM-6PM EST',
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
            ),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSubscriptionDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.workspace_premium, color: Colors.blue[700], size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Subscription Plans',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _SubscriptionPlanTile(
                title: 'Basic Plan',
                price: 'Free',
                features: ['Post up to 5 jobs', 'Basic analytics', 'Email support'],
                isCurrent: true,
              ),
              const SizedBox(height: 16),
              _SubscriptionPlanTile(
                title: 'Pro Plan',
                price: '\$29/month',
                features: [
                  'Unlimited job posts',
                  'Advanced analytics',
                  'Priority support',
                  'Featured listings',
                  'Candidate screening tools'
                ],
                isCurrent: false,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _showSuccessSnackBar('Upgrade feature coming soon!');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Upgrade to Pro'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseAuth.instance.signOut();
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
      } catch (e) {
        _showErrorSnackBar('Failed to sign out. Please try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  shape: BoxShape.circle,
                ),
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[700]!),
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Loading Profile...',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (hasError || employerData == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.error_outline, size: 48, color: Colors.red[700]),
              ),
              const SizedBox(height: 24),
              Text(
                hasError ? 'Failed to Load Profile' : 'Profile Not Found',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                hasError 
                    ? 'Please check your internet connection and try again.'
                    : 'Employer profile data could not be found.',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadEmployerProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Employer Profile',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.blue[700],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEmployerProfile,
            tooltip: 'Refresh Profile',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'sign_out':
                  _signOut();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'sign_out',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Sign Out'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== PROFILE HEADER =====
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue[50]!, Colors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.blue[100]!),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.blue[200]!, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withValues(alpha: 0.2),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 55,
                            backgroundColor: Colors.blue[50],
                            backgroundImage: employerData!['profilePicture'] != null &&
                                    employerData!['profilePicture'].toString().isNotEmpty
                                ? NetworkImage(employerData!['profilePicture'])
                                : null,
                            child: employerData!['profilePicture'] == null ||
                                    employerData!['profilePicture'].toString().isEmpty
                                ? Icon(Icons.person, size: 55, color: Colors.blue[700])
                                : null,
                          ),
                        ),
                        if (isUploading)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(55),
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  strokeWidth: 3,
                                ),
                              ),
                            ),
                          ),
                        Positioned(
                          bottom: 4,
                          right: 4,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.blue[700],
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                              onPressed: isUploading ? null : _updateProfilePicture,
                              padding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      employerData!['fullName'] ?? 'Not Provided',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue[700],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Employer',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.email_outlined, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Text(
                          employerData!['email'] ?? 'Not Provided',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    if (employerData!['phoneNumber'] != null && employerData!['phoneNumber'].toString().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.phone_outlined, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 8),
                            Text(
                              employerData!['phoneNumber'],
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // ===== JOB STATISTICS =====
              _SectionHeader(title: 'Job Statistics'),
              const SizedBox(height: 16),
              SizedBox(
                height: 140,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _StatCard(
                      title: 'Jobs Posted',
                      value: jobsPosted.toString(),
                      icon: Icons.work_outline,
                      color: Colors.blue[700]!,
                    ),
                    const SizedBox(width: 16),
                    _StatCard(
                      title: 'Active Applications',
                      value: activeApplications.toString(),
                      icon: Icons.assignment_outlined,
                      color: Colors.black87,
                    ),
                    const SizedBox(width: 16),
                    _StatCard(
                      title: 'Recent Hires',
                      value: recentHires.toString(),
                      icon: Icons.check_circle_outline,
                      color: Colors.blue[700]!,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // ===== COMPANY DETAILS =====
              _SectionHeader(title: 'Company Information'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _InfoTile(
                      title: 'Company Name',
                      value: employerData!['companyName'] ?? 'Not Provided',
                      icon: Icons.business,
                    ),
                    const Divider(height: 32),
                    _InfoTile(
                      title: 'Industry / Sector',
                      value: employerData!['industry'] ?? 'Not Provided',
                      icon: Icons.category_outlined,
                    ),
                    const Divider(height: 32),
                    _InfoTile(
                      title: 'Company Size',
                      value: employerData!['companySize'] ?? 'Not Provided',
                      icon: Icons.groups_outlined,
                    ),
                    const Divider(height: 32),
                    _InfoTile(
                      title: 'Website',
                      value: employerData!['website'] ?? 'Not Provided',
                      icon: Icons.language,
                    ),
                    if (employerData!['about'] != null && employerData!['about'].toString().isNotEmpty) ...[
                      const Divider(height: 32),
                      _InfoTile(
                        title: 'About Company',
                        value: employerData!['about'],
                        icon: Icons.info_outline,
                        isMultiLine: true,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // ===== ADDRESS INFORMATION =====
              if (employerData!['address'] != null || employerData!['city'] != null) ...[
                _SectionHeader(title: 'Location'),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      if (employerData!['address'] != null) ...[
                        _InfoTile(
                          title: 'Office Address',
                          value: employerData!['address'],
                          icon: Icons.location_on_outlined,
                        ),
                        if (employerData!['city'] != null) const Divider(height: 32),
                      ],
                      if (employerData!['city'] != null)
                        _InfoTile(
                          title: 'City / Country',
                          value: employerData!['city'],
                          icon: Icons.location_city,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],

              // ===== PAYMENT TRANSACTIONS =====
              _SectionHeader(title: 'Payment History'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: transactions == null || transactions!.isEmpty
                    ? Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.payment_outlined,
                              size: 40,
                              color: Colors.grey[400],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No Payment Transactions',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your payment history will appear here',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      )
                    : Column(
                        children: transactions!.map((tx) => Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: tx['status']?.toUpperCase() == 'COMPLETED' 
                                  ? Colors.green.shade200 
                                  : Colors.red.shade200,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: tx['status']?.toUpperCase() == 'COMPLETED' 
                                      ? Colors.green[100] 
                                      : Colors.red[100],
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  tx['status']?.toUpperCase() == 'COMPLETED' 
                                      ? Icons.check_circle 
                                      : Icons.error,
                                  color: tx['status']?.toUpperCase() == 'COMPLETED' 
                                      ? Colors.green[700] 
                                      : Colors.red[700],
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'KES ${tx['amount'] ?? 'N/A'}',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: tx['status']?.toUpperCase() == 'COMPLETED' 
                                                ? Colors.green[700] 
                                                : Colors.red[700],
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            tx['status']?.toUpperCase() ?? 'UNKNOWN',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    if (tx['transactionDate'] != null)
                                      Text(
                                        'Date: ${tx['transactionDate']}',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                    if (tx['mpesaReceiptNumber'] != null)
                                      Text(
                                        'Receipt: ${tx['mpesaReceiptNumber']}',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                    if (tx['phoneNumber'] != null)
                                      Text(
                                        'Phone: ${tx['phoneNumber']}',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )).toList(),
                      ),
              ),
              const SizedBox(height: 32),

              // ===== ACCOUNT SETTINGS =====
              _SectionHeader(title: 'Account Settings'),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _SettingTile(
                      title: 'Change Password',
                      icon: Icons.lock_outline,
                      onTap: _changePassword,
                    ),
                    Divider(height: 1, color: Colors.grey.shade200),
                    _SettingTile(
                      title: 'Notification Preferences',
                      icon: Icons.notifications_outlined,
                      onTap: () => _showSuccessSnackBar('Notification preferences feature coming soon!'),
                    ),
                    Divider(height: 1, color: Colors.grey.shade200),
                    _SettingTile(
                      title: 'Subscription Plan',
                      icon: Icons.workspace_premium,
                      onTap: _showSubscriptionDialog,
                    ),
                    Divider(height: 1, color: Colors.grey.shade200),
                    _SettingTile(
                      title: 'Two-Factor Authentication',
                      icon: Icons.security_outlined,
                      onTap: () => _showSuccessSnackBar('2FA feature coming soon!'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // ===== QUICK ACTIONS =====
              _SectionHeader(title: 'Quick Actions'),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.1,
                children: [
                  _ActionCard(
                    icon: Icons.edit_outlined,
                    label: 'Edit Profile',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                    ).then((_) => _loadEmployerProfile()),
                  ),
                  _ActionCard(
                    icon: Icons.post_add_outlined,
                    label: 'Post New Job',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PostJobScreen()),
                    ).then((_) => _loadEmployerProfile()),
                  ),
                  _ActionCard(
                    icon: Icons.work_history_outlined,
                    label: 'Manage Jobs',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MyJobsScreen()),
                    ),
                  ),
                  _ActionCard(
                    icon: Icons.support_agent_outlined,
                    label: 'Get Support',
                    onTap: _showSupportDialog,
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ===================== CUSTOM WIDGETS =====================

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.blue[700],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final bool isMultiLine;

  const _InfoTile({
    required this.title,
    required this.value,
    required this.icon,
    this.isMultiLine = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: Colors.blue[700]),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  height: isMultiLine ? 1.4 : 1.2,
                ),
                maxLines: isMultiLine ? null : 2,
                overflow: isMultiLine ? null : TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _SettingTile({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: Colors.blue[700]),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 0,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 28, color: Colors.blue[700]),
                ),
                const SizedBox(height: 12),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SubscriptionPlanTile extends StatelessWidget {
  final String title;
  final String price;
  final List<String> features;
  final bool isCurrent;

  const _SubscriptionPlanTile({
    required this.title,
    required this.price,
    required this.features,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isCurrent ? Colors.blue[50] : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrent ? Colors.blue[300]! : Colors.grey[300]!,
          width: isCurrent ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  fontSize: 18,
                ),
              ),
              if (isCurrent)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue[700],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'Current Plan',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            price,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Colors.blue[700],
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 16),
          ...features.map((feature) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.blue[700],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, size: 14, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    feature,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

class _ContactInfo extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _ContactInfo({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: Colors.blue[700]),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
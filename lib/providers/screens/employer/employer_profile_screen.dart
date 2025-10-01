import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'my_jobs_screen.dart';
import 'post_job_screen.dart';
import 'edit_profile_screen.dart';
import 'dart:io';
import '../../../services/payment_service.dart';
import '../../../../page/seeker/cloudinary_service.dart';

class EmployerProfileScreen extends StatefulWidget {
  const EmployerProfileScreen({super.key});

  @override
  State<EmployerProfileScreen> createState() => _EmployerProfileScreenState();
}

class _EmployerProfileScreenState extends State<EmployerProfileScreen> {
  final user = FirebaseAuth.instance.currentUser!;
  final ImagePicker _imagePicker = ImagePicker();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  
  Map<String, dynamic>? employerData;
  List<Map<String, dynamic>>? transactions;
  int jobsPosted = 0;
  int activeApplications = 0;
  int recentHires = 0;
  
  bool isLoadingBasicInfo = true;
  bool isLoadingStats = false;
  bool isLoadingTransactions = false;
  bool hasError = false;
  bool isUploading = false;

  static Map<String, dynamic>? _cachedEmployerData;
  static Map<String, int>? _cachedStats;
  static List<Map<String, dynamic>>? _cachedTransactions;
  static int _cacheTimestamp = 0;
  static const int cacheDuration = 15000;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() {
    _loadBasicInfo();
    Future.delayed(const Duration(milliseconds: 100), () {
      _loadStatistics();
      _loadTransactions();
    });
  }

  bool _isCacheValid() {
    return _cachedEmployerData != null &&
           (DateTime.now().millisecondsSinceEpoch - _cacheTimestamp) < cacheDuration;
  }

  Future<void> _loadBasicInfo() async {
    if (_isCacheValid() && _cachedEmployerData != null) {
      if (mounted) {
        setState(() {
          employerData = _cachedEmployerData;
          isLoadingBasicInfo = false;
        });
      }
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get(const GetOptions(source: Source.serverAndCache));

      if (mounted) {
        setState(() {
          employerData = userDoc.data();
          _cachedEmployerData = employerData;
          _cacheTimestamp = DateTime.now().millisecondsSinceEpoch;
          isLoadingBasicInfo = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading basic info: $e');
      if (mounted) {
        setState(() {
          hasError = true;
          isLoadingBasicInfo = false;
        });
      }
    }
  }

  Future<void> _loadStatistics() async {
    if (_isCacheValid() && _cachedStats != null) {
      if (mounted) {
        setState(() {
          jobsPosted = _cachedStats!['jobsPosted'] ?? 0;
          activeApplications = _cachedStats!['activeApplications'] ?? 0;
          recentHires = _cachedStats!['recentHires'] ?? 0;
        });
      }
      return;
    }

    if (mounted) {
      setState(() => isLoadingStats = true);
    }

    try {
      final jobsSnapshot = await FirebaseFirestore.instance
          .collection('jobs')
          .where('employerId', isEqualTo: user.uid)
          .get(const GetOptions(source: Source.serverAndCache));

      final jobIds = jobsSnapshot.docs.map((doc) => doc.id).toList();
      
      int applicationsCount = 0;
      int hiresCount = 0;

      if (jobIds.isNotEmpty) {
        final pendingQuery = FirebaseFirestore.instance
            .collection('applications')
            .where('jobId', whereIn: jobIds.length > 10 ? jobIds.sublist(0, 10) : jobIds)
            .where('status', isEqualTo: 'pending');

        final hiredQuery = FirebaseFirestore.instance
            .collection('applications')
            .where('jobId', whereIn: jobIds.length > 10 ? jobIds.sublist(0, 10) : jobIds)
            .where('status', isEqualTo: 'hired');

        final [pendingSnapshot, hiredSnapshot] = await Future.wait([
          pendingQuery.get(const GetOptions(source: Source.serverAndCache)),
          hiredQuery.get(const GetOptions(source: Source.serverAndCache)),
        ]);

        applicationsCount = pendingSnapshot.docs.length;
        hiresCount = hiredSnapshot.docs.length;
      }

      if (mounted) {
        setState(() {
          jobsPosted = jobIds.length;
          activeApplications = applicationsCount;
          recentHires = hiresCount;
          _cachedStats = {
            'jobsPosted': jobIds.length,
            'activeApplications': applicationsCount,
            'recentHires': hiresCount,
          };
          isLoadingStats = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading statistics: $e');
      if (mounted) {
        setState(() => isLoadingStats = false);
      }
    }
  }

  Future<void> _loadTransactions() async {
    if (_isCacheValid() && _cachedTransactions != null) {
      if (mounted) {
        setState(() {
          transactions = _cachedTransactions;
        });
      }
      return;
    }

    if (mounted) {
      setState(() => isLoadingTransactions = true);
    }

    try {
      final tx = await PaymentService.getAllTransactions();
      if (mounted) {
        setState(() {
          transactions = tx;
          _cachedTransactions = tx;
          isLoadingTransactions = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading transactions: $e');
      if (mounted) {
        setState(() {
          transactions = [];
          isLoadingTransactions = false;
        });
      }
    }
  }

  Future<void> _updateProfilePicture() async {
    if (isUploading) return;

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() => isUploading = true);

        final File imageFile = File(image.path);
        
        // Check file size
        final int fileSize = await imageFile.length();
        if (fileSize > 5 * 1024 * 1024) {
          throw Exception('Image size must be less than 5MB');
        }

        // Delete old image from Cloudinary if exists (optional - only if you have API secret)
        if (employerData?['profilePicture'] != null) {
          final oldPublicId = _cloudinaryService.getPublicIdFromUrl(
            employerData!['profilePicture']
          );
          if (oldPublicId != null) {
            // Note: This requires API secret to be configured
            await _cloudinaryService.deleteImage(oldPublicId);
          }
        }

        // Upload to Cloudinary
        final String? downloadUrl = await _cloudinaryService.uploadImage(
          imageFile: imageFile,
          folder: 'employers',
          publicId: '${user.uid}_profile',
        );

        if (downloadUrl == null) {
          throw Exception('Failed to upload image to Cloudinary');
        }

        // Update Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
              'profilePicture': downloadUrl,
              'updatedAt': FieldValue.serverTimestamp(),
            });

        if (mounted) {
          setState(() {
            employerData!['profilePicture'] = downloadUrl;
            _cachedEmployerData = employerData;
          });
        }

        _showSuccessSnackBar('Profile picture updated successfully');
      }
    } catch (e) {
      debugPrint('Error updating profile picture: $e');
      _showErrorSnackBar('Failed to update profile picture: ${e.toString()}');
    } finally {
      if (mounted) setState(() => isUploading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _refreshData() {
    _cachedEmployerData = null;
    _cachedStats = null;
    _cachedTransactions = null;
    _cacheTimestamp = 0;
    
    setState(() {
      isLoadingBasicInfo = true;
      isLoadingStats = true;
      isLoadingTransactions = true;
      hasError = false;
    });
    
    _loadInitialData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Employer Profile'),
        backgroundColor: Colors.blue[700],
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (hasError) {
      return _ErrorWidget(onRetry: _refreshData);
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _ProfileHeader(
            employerData: employerData,
            isLoading: isLoadingBasicInfo,
            isUploading: isUploading,
            onUpdateProfilePicture: _updateProfilePicture,
          ),
        ),

        SliverToBoxAdapter(
          child: _StatisticsSection(
            jobsPosted: jobsPosted,
            activeApplications: activeApplications,
            recentHires: recentHires,
            isLoading: isLoadingStats,
          ),
        ),

        if (!isLoadingBasicInfo && employerData != null)
          SliverToBoxAdapter(
            child: _CompanyInfoSection(employerData: employerData!),
          ),

        if (!isLoadingBasicInfo && employerData != null && 
            (employerData!['address'] != null || employerData!['city'] != null))
          SliverToBoxAdapter(
            child: _LocationInfoSection(employerData: employerData!),
          ),

        SliverToBoxAdapter(
          child: _TransactionsSection(
            transactions: transactions,
            isLoading: isLoadingTransactions,
          ),
        ),

        SliverToBoxAdapter(
          child: _AccountSettingsSection(
            onChangePassword: _changePassword,
            onShowSubscription: _showSubscriptionDialog,
          ),
        ),

        SliverToBoxAdapter(
          child: _QuickActionsSection(
            onEditProfile: () => _navigateToEditProfile(context),
            onPostJob: () => _navigateToPostJob(context),
            onManageJobs: () => _navigateToManageJobs(context),
            onGetSupport: _showSupportDialog,
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 20)),
      ],
    );
  }

  void _navigateToEditProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
    ).then((_) {
      _cachedEmployerData = null;
      _loadBasicInfo();
    });
  }

  void _navigateToPostJob(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PostJobScreen()),
    ).then((_) {
      _cachedStats = null;
      _loadStatistics();
    });
  }

  void _navigateToManageJobs(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MyJobsScreen()),
    );
  }

  Future<void> _changePassword() async {
    try {
      final email = user.email;
      if (email == null) {
        _showErrorSnackBar('No email associated with this account');
        return;
      }

      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      _showSuccessSnackBar('Password reset email sent to $email');
    } catch (e) {
      debugPrint('Error sending password reset email: $e');
      _showErrorSnackBar('Failed to send password reset email');
    }
  }

  void _showSupportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Support'),
        content: const Text(
          'For assistance, please contact our support team at:\n\n'
          'support@jobapp.com\n'
          '+254 700 000 000\n\n'
          'We\'re here to help you with any issues or questions.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSubscriptionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Subscription Plan'),
        content: const Text(
          'Current Plan: Basic Employer\n\n'
          'Features:\n'
          '• Post up to 5 jobs\n'
          '• View applications\n'
          '• Basic analytics\n\n'
          'Upgrade to Premium for more features!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to subscription page
            },
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );
  }
}

// ===================== WIDGETS =====================

class _ProfileHeader extends StatelessWidget {
  final Map<String, dynamic>? employerData;
  final bool isLoading;
  final bool isUploading;
  final VoidCallback onUpdateProfilePicture;

  const _ProfileHeader({
    required this.employerData,
    required this.isLoading,
    required this.isUploading,
    required this.onUpdateProfilePicture,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue[700]!, Colors.blue[500]!],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.white,
                child: CircleAvatar(
                  radius: 47,
                  backgroundColor: Colors.blue[50],
                  backgroundImage: employerData?['profilePicture'] != null
                      ? NetworkImage(employerData!['profilePicture'])
                      : null,
                  child: employerData?['profilePicture'] == null
                      ? Icon(Icons.person, size: 45, color: Colors.blue[700])
                      : null,
                ),
              ),
              if (isUploading)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
                ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: isUploading ? null : onUpdateProfilePicture,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Icon(Icons.camera_alt, size: 18, color: Colors.blue[700]),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            employerData?['fullName'] ?? 'Not Provided',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            ),
            child: const Text(
              'Employer',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            employerData?['email'] ?? 'Not Provided',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _StatisticsSection extends StatelessWidget {
  final int jobsPosted;
  final int activeApplications;
  final int recentHires;
  final bool isLoading;

  const _StatisticsSection({
    required this.jobsPosted,
    required this.activeApplications,
    required this.recentHires,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    
    if (isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: List.generate(3, (index) => Expanded(
            child: Container(
              height: 130,
              margin: EdgeInsets.only(right: index < 2 ? 8 : 0, left: index > 0 ? 8 : 0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(child: CircularProgressIndicator()),
            ),
          )),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              title: isSmallScreen ? 'Jobs' : 'Jobs Posted',
              value: jobsPosted.toString(),
              icon: Icons.work_outline,
              gradient: LinearGradient(
                colors: [Colors.blue[600]!, Colors.blue[400]!],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StatCard(
              title: isSmallScreen ? 'Active' : 'Active Apps',
              value: activeApplications.toString(),
              icon: Icons.assignment_outlined,
              gradient: LinearGradient(
                colors: [Colors.orange[600]!, Colors.orange[400]!],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StatCard(
              title: isSmallScreen ? 'Hires' : 'Recent Hires',
              value: recentHires.toString(),
              icon: Icons.check_circle_outline,
              gradient: LinearGradient(
                colors: [Colors.green[600]!, Colors.green[400]!],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Gradient gradient;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _CompanyInfoSection extends StatelessWidget {
  final Map<String, dynamic> employerData;

  const _CompanyInfoSection({required this.employerData});

  @override
  Widget build(BuildContext context) {
    return _SectionContainer(
      title: 'Company Information',
      icon: Icons.business,
      child: Column(
        children: [
          _InfoRow(
            label: 'Company Name',
            value: employerData['companyName'] ?? 'Not Provided',
          ),
          const Divider(height: 24),
          _InfoRow(
            label: 'Industry',
            value: employerData['industry'] ?? 'Not Provided',
          ),
          const Divider(height: 24),
          _InfoRow(
            label: 'Company Size',
            value: employerData['companySize'] ?? 'Not Provided',
          ),
          if (employerData['about'] != null) ...[
            const Divider(height: 24),
            _InfoRow(
              label: 'About',
              value: employerData['about'],
              isMultiLine: true,
            ),
          ],
        ],
      ),
    );
  }
}

class _LocationInfoSection extends StatelessWidget {
  final Map<String, dynamic> employerData;

  const _LocationInfoSection({required this.employerData});

  @override
  Widget build(BuildContext context) {
    return _SectionContainer(
      title: 'Location',
      icon: Icons.location_on,
      child: Column(
        children: [
          if (employerData['address'] != null)
            _InfoRow(
              label: 'Address',
              value: employerData['address'],
            ),
          if (employerData['city'] != null) ...[
            if (employerData['address'] != null) const Divider(height: 24),
            _InfoRow(
              label: 'City',
              value: employerData['city'],
            ),
          ],
        ],
      ),
    );
  }
}

class _TransactionsSection extends StatelessWidget {
  final List<Map<String, dynamic>>? transactions;
  final bool isLoading;

  const _TransactionsSection({
    required this.transactions,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionContainer(
      title: 'Payment History',
      icon: Icons.payment,
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : transactions == null || transactions!.isEmpty
              ? Column(
                  children: [
                    Icon(Icons.receipt_long, size: 48, color: Colors.grey[300]),
                    const SizedBox(height: 12),
                    Text(
                      'No transactions found',
                      style: TextStyle(color: Colors.grey[500], fontSize: 14),
                    ),
                  ],
                )
              : Column(
                  children: transactions!
                      .take(5)
                      .map((tx) => _TransactionItem(transaction: tx))
                      .toList(),
                ),
    );
  }
}

class _TransactionItem extends StatelessWidget {
  final Map<String, dynamic> transaction;

  const _TransactionItem({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isCompleted = transaction['status']?.toUpperCase() == 'COMPLETED';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isCompleted ? Colors.green[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted ? Colors.green[200]! : Colors.red[200]!,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isCompleted ? Colors.green[100] : Colors.red[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCompleted ? Icons.check_circle : Icons.error,
              color: isCompleted ? Colors.green[700] : Colors.red[700],
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'KES ${transaction['amount'] ?? '0'}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                if (transaction['transactionDate'] != null)
                  Text(
                    transaction['transactionDate'],
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isCompleted ? Colors.green : Colors.red,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isCompleted ? 'Paid' : 'Failed',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountSettingsSection extends StatelessWidget {
  final VoidCallback onChangePassword;
  final VoidCallback onShowSubscription;

  const _AccountSettingsSection({
    required this.onChangePassword,
    required this.onShowSubscription,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionContainer(
      title: 'Account Settings',
      icon: Icons.settings,
      child: Column(
        children: [
          _SettingsItem(
            icon: Icons.lock_outline,
            title: 'Change Password',
            onTap: onChangePassword,
            color: Colors.blue,
          ),
          const Divider(height: 1),
          _SettingsItem(
            icon: Icons.workspace_premium,
            title: 'Subscription Plan',
            onTap: onShowSubscription,
            color: Colors.amber,
          ),
        ],
      ),
    );
  }
}

class _QuickActionsSection extends StatelessWidget {
  final VoidCallback onEditProfile;
  final VoidCallback onPostJob;
  final VoidCallback onManageJobs;
  final VoidCallback onGetSupport;

  const _QuickActionsSection({
    required this.onEditProfile,
    required this.onPostJob,
    required this.onManageJobs,
    required this.onGetSupport,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionContainer(
      title: 'Quick Actions',
      icon: Icons.flash_on,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = constraints.maxWidth < 360 ? 2 : 2;
          final childAspectRatio = constraints.maxWidth < 360 ? 1.3 : 1.4;
          
          return GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: childAspectRatio,
            children: [
              _ActionItem(
                icon: Icons.edit,
                label: 'Edit Profile',
                onTap: onEditProfile,
                color: Colors.blue,
              ),
              _ActionItem(
                icon: Icons.post_add,
                label: 'Post Job',
                onTap: onPostJob,
                color: Colors.green,
              ),
              _ActionItem(
                icon: Icons.work,
                label: 'Manage Jobs',
                onTap: onManageJobs,
                color: Colors.orange,
              ),
              _ActionItem(
                icon: Icons.support,
                label: 'Support',
                onTap: onGetSupport,
                color: Colors.purple,
              ),
            ],
          );
        },
      ),
    );
  }
}

// ===================== REUSABLE COMPONENTS =====================

class _SectionContainer extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionContainer({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                child: Icon(icon, size: 20, color: Colors.blue[700]),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isMultiLine;

  const _InfoRow({
    required this.label,
    required this.value,
    this.isMultiLine = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14, height: 1.4),
            maxLines: isMultiLine ? null : 2,
            overflow: isMultiLine ? null : TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color color;

  const _SettingsItem({
    required this.icon,
    required this.title,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}

class _ActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _ActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorWidget extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorWidget({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          const Text(
            'Failed to load profile',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  } 
}
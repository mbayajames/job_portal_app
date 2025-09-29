// Enhanced Edit Job Screen
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/job_model.dart';
import '../../../providers/job_provider.dart';

class EditJobScreen extends StatefulWidget {
  final JobModel job;
  const EditJobScreen({super.key, required this.job});

  @override
  State<EditJobScreen> createState() => _EditJobScreenState();
}

class _EditJobScreenState extends State<EditJobScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  late TextEditingController _titleController;
  late TextEditingController _companyController;
  late TextEditingController _locationController;
  late TextEditingController _industryController;
  late TextEditingController _jobTypeController;
  late TextEditingController _salaryController;
  late TextEditingController _descriptionController;
  late TextEditingController _requirementsController;
  late TextEditingController _benefitsController;

  bool _isLoading = false;
  bool _isRemote = false;
  String _selectedJobType = 'Full-time';
  String _selectedExperience = 'Mid-level';

  final List<String> _jobTypes = ['Full-time', 'Part-time', 'Contract', 'Internship', 'Temporary'];
  final List<String> _experienceLevels = ['Entry-level', 'Mid-level', 'Senior-level', 'Executive'];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    final job = widget.job;
    _titleController = TextEditingController(text: job.title);
    _companyController = TextEditingController(text: job.company);
    _locationController = TextEditingController(text: job.location);
    _industryController = TextEditingController(text: job.industry);
    _jobTypeController = TextEditingController(text: job.employmentType);
    _salaryController = TextEditingController(text: job.salaryRange);
    _descriptionController = TextEditingController(text: job.description);
    _requirementsController = TextEditingController(text: job.requirements.join('\n'));
    _benefitsController = TextEditingController(text: job.benefits.join('\n'));
    
    // Validate and set job type - use default if not in list
    _selectedJobType = _jobTypes.contains(job.employmentType) 
        ? job.employmentType 
        : 'Full-time';
    
    // Validate and set experience level - use default if not in list
    _selectedExperience = _experienceLevels.contains(job.experienceLevel) 
        ? job.experienceLevel 
        : 'Mid-level';
    
    _isRemote = job.isRemote;

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _titleController.dispose();
    _companyController.dispose();
    _locationController.dispose();
    _industryController.dispose();
    _jobTypeController.dispose();
    _salaryController.dispose();
    _descriptionController.dispose();
    _requirementsController.dispose();
    _benefitsController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final updatedJob = JobModel(
        id: widget.job.id,
        title: _titleController.text.trim(),
        company: _companyController.text.trim(),
        employerId: widget.job.employerId,
        location: _locationController.text.trim(),
        description: _descriptionController.text.trim(),
        salaryRange: _salaryController.text.trim(),
        employmentType: _selectedJobType,
        experienceLevel: _selectedExperience,
        requirements: _requirementsController.text.trim().split('\n').where((e) => e.isNotEmpty).toList(),
        responsibilities: widget.job.responsibilities,
        benefits: _benefitsController.text.trim().split('\n').where((e) => e.isNotEmpty).toList(),
        createdAt: widget.job.createdAt,
        applicationDeadline: widget.job.applicationDeadline,
        applicationCount: widget.job.applicationCount,
        isRemote: _isRemote,
        category: widget.job.category,
        industry: _industryController.text.trim(),
        contactEmail: widget.job.contactEmail,
        applicationInstructions: widget.job.applicationInstructions,
        status: widget.job.status,
      );

      await Provider.of<JobProvider>(context, listen: false).updateJob(updatedJob);

      if (mounted) {
        _showSuccessSnackBar('Job updated successfully!');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to update job. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Edit Job',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (!_isLoading)
            TextButton.icon(
              onPressed: _saveChanges,
              icon: const Icon(Icons.save, color: Colors.white, size: 20),
              label: const Text(
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
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader('Basic Information'),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _titleController,
                        label: 'Job Title',
                        icon: Icons.work_outline,
                        isRequired: true,
                      ),
                      _buildTextField(
                        controller: _companyController,
                        label: 'Company Name',
                        icon: Icons.business_outlined,
                        isRequired: true,
                      ),
                      _buildTextField(
                        controller: _locationController,
                        label: 'Location',
                        icon: Icons.location_on_outlined,
                        isRequired: true,
                      ),
                      _buildTextField(
                        controller: _industryController,
                        label: 'Industry',
                        icon: Icons.category_outlined,
                        isRequired: true,
                      ),

                      const SizedBox(height: 24),
                      _buildSectionHeader('Job Details'),
                      const SizedBox(height: 16),

                      // Job Type Dropdown
                      _buildDropdownField(
                        value: _selectedJobType,
                        items: _jobTypes,
                        label: 'Employment Type',
                        icon: Icons.schedule_outlined,
                        onChanged: (value) => setState(() => _selectedJobType = value!),
                      ),

                      // Experience Level Dropdown
                      _buildDropdownField(
                        value: _selectedExperience,
                        items: _experienceLevels,
                        label: 'Experience Level',
                        icon: Icons.trending_up_outlined,
                        onChanged: (value) => setState(() => _selectedExperience = value!),
                      ),

                      _buildTextField(
                        controller: _salaryController,
                        label: 'Salary Range',
                        icon: Icons.attach_money_outlined,
                        isRequired: true,
                      ),

                      // Remote Work Switch
                      Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.home_work_outlined, color: Colors.blue[700]),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Remote Work',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    'Allow remote work for this position',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch.adaptive(
                              value: _isRemote,
                              onChanged: (value) => setState(() => _isRemote = value),
                              activeThumbColor: Colors.blue[700],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
                      _buildSectionHeader('Job Description'),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _descriptionController,
                        label: 'Job Description',
                        icon: Icons.description_outlined,
                        maxLines: 6,
                        isRequired: true,
                      ),
                      _buildTextField(
                        controller: _requirementsController,
                        label: 'Requirements (one per line)',
                        icon: Icons.checklist_outlined,
                        maxLines: 4,
                      ),
                      _buildTextField(
                        controller: _benefitsController,
                        label: 'Benefits (one per line)',
                        icon: Icons.card_giftcard_outlined,
                        maxLines: 4,
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),

              // Bottom Save Button
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _saveChanges,
                    icon: _isLoading
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
                      _isLoading ? 'Saving Changes...' : 'Save Changes',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
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
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isRequired = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 12, right: 16),
            child: Icon(icon, color: Colors.blue[700], size: 22),
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
            borderSide: BorderSide(color: Colors.blue[700]!, width: 2),
          ),
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        validator: (value) {
          if (isRequired && (value == null || value.trim().isEmpty)) {
            return '$label is required';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDropdownField({
    required String value,
    required List<String> items,
    required String label,
    required IconData icon,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 12, right: 16),
            child: Icon(icon, color: Colors.blue[700], size: 22),
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
            borderSide: BorderSide(color: Colors.blue[700]!, width: 2),
          ),
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}
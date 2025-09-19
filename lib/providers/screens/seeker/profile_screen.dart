import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../providers/auth_provider.dart' as app_auth;
import '../../../core/routes.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  bool _isEditing = false;
  bool _isSaving = false;
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final authProvider = Provider.of<app_auth.AuthProvider>(context, listen: false);
    final userData = authProvider.currentUserData;
    if (userData != null) {
      _nameController.text = userData['fullName'] ?? authProvider.user?.displayName ?? "";
      _phoneController.text = userData['phone'] ?? "";
      _bioController.text = userData['bio'] ?? "";
    } else {
      _nameController.text = authProvider.user?.displayName ?? "";
    }
    if (mounted) setState(() {});
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadProfilePicture(File file) async {
    try {
      final authProvider = Provider.of<app_auth.AuthProvider>(context, listen: false);
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_pics')
          .child("${authProvider.user!.uid}.jpg");
      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Upload failed: $e")));
      }
      return null;
    }
  }

  Future<void> _saveProfile() async {
    final authProvider = Provider.of<app_auth.AuthProvider>(context, listen: false);
    final user = authProvider.user;
    if (user == null) return;

    setState(() => _isSaving = true);

    String? photoUrl = user.photoURL;
    if (_imageFile != null) {
      photoUrl = await _uploadProfilePicture(_imageFile!);
    }

    await user.updateDisplayName(_nameController.text.trim());
    if (photoUrl != null) await user.updatePhotoURL(photoUrl);

    await FirebaseFirestore.instance.collection("users").doc(user.uid).set({
      "fullName": _nameController.text.trim(),
      "email": user.email,
      "phone": _phoneController.text.trim(),
      "bio": _bioController.text.trim(),
      "photoUrl": photoUrl,
      "role": authProvider.currentUserData?['role'] ?? 'seeker',
      "updatedAt": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await user.reload();
    if (mounted) {
      setState(() {
        _isEditing = false;
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated successfully!")),
      );
    }
  }

  Future<void> _logout() async {
    try {
      final authProvider = Provider.of<app_auth.AuthProvider>(context, listen: false);
      await authProvider.signOut();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, Routes.login, (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error logging out: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<app_auth.AuthProvider>(context);
    final user = authProvider.user;
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A73E8),
        title: const Text(
          "Profile",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isTablet ? 24 : 16),
        child: Column(
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: isTablet ? 60 : 50,
                    backgroundColor: Colors.black12,
                    backgroundImage: _imageFile != null
                        ? FileImage(_imageFile!)
                        : (user?.photoURL != null
                            ? NetworkImage(user!.photoURL!)
                            : null) as ImageProvider?,
                    child: (user?.photoURL == null && _imageFile == null)
                        ? const Icon(Icons.person, size: 50, color: Colors.black)
                        : null,
                  ),
                  if (_isEditing)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: InkWell(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            builder: (ctx) => SafeArea(
                              child: Wrap(
                                children: [
                                  ListTile(
                                    leading: const Icon(Icons.camera_alt),
                                    title: const Text("Take Photo"),
                                    onTap: () {
                                      Navigator.pop(ctx);
                                      _pickImage(ImageSource.camera);
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.photo_library),
                                    title: const Text("Choose from Gallery"),
                                    onTap: () {
                                      Navigator.pop(ctx);
                                      _pickImage(ImageSource.gallery);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.blue,
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _isEditing
                ? TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: "Full Name",
                      border: OutlineInputBorder(),
                    ),
                  )
                : Text(
                    _nameController.text.isNotEmpty ? _nameController.text : "No Name",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
            const SizedBox(height: 8),
            Text(
              user?.email ?? "No Email",
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 20),
            _isEditing
                ? TextField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: "Phone Number",
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                  )
                : _infoRow("Phone", _phoneController.text.isNotEmpty ? _phoneController.text : "Not added"),
            const SizedBox(height: 20),
            _isEditing
                ? TextField(
                    controller: _bioController,
                    decoration: const InputDecoration(
                      labelText: "Bio",
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  )
                : _infoRow("Bio", _bioController.text.isNotEmpty ? _bioController.text : "Not added"),
            const SizedBox(height: 30),
            _buildOptionCard("Account Settings", Icons.settings, () {
              Navigator.pushNamed(context, Routes.accountSettings);
            }),
            _buildOptionCard("Payment History", Icons.payment, () {
              Navigator.pushNamed(context, Routes.paymentHistory);
            }),
            _buildOptionCard("Support & Help", Icons.support_agent, () {
              Navigator.pushNamed(context, Routes.supportHelp);
            }),
            _buildOptionCard("About", Icons.info, () {
              Navigator.pushNamed(context, Routes.about);
            }),
            _buildOptionCard("Notifications", Icons.notifications, () {
              Navigator.pushNamed(context, Routes.notifications);
            }),
            _buildOptionCard("Logout", Icons.logout, _logout, isLogout: true),
            if (_isEditing)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A73E8),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  ),
                  icon: _isSaving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.save, color: Colors.white),
                  label: Text(
                    _isSaving ? "Saving..." : "Save Changes",
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  onPressed: _isSaving ? null : _saveProfile,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      children: [
        Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        Expanded(child: Text(value, style: const TextStyle(color: Colors.black54))),
      ],
    );
  }

  Widget _buildOptionCard(String title, IconData icon, VoidCallback onTap, {bool isLogout = false}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isLogout
              ? Color.fromRGBO(244, 67, 54, 0.15)
              : Color.fromRGBO(26, 115, 232, 0.15),
          child: Icon(
            icon,
            color: isLogout ? Colors.red : const Color(0xFF1A73E8),
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isLogout ? Colors.red : Colors.black,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black54),
        onTap: onTap,
      ),
    );
  }
}
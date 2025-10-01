import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:crypto/crypto.dart';

class CloudinaryService {
  // Replace with your actual Cloudinary credentials
  static const String cloudName = 'dnpgx8emx';
  static const String uploadPreset = 'job_portal_app';
  static const String apiKey = '951644381836647';
  static const String apiSecret = 'YOUR_API_SECRET'; // Add your actual API secret here

  /// Upload image to Cloudinary using unsigned upload
  Future<String?> uploadImage({
    required File imageFile,
    required String folder,
    String? publicId,
  }) async {
    try {
      final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
      );

      final request = http.MultipartRequest('POST', url);

      // Add the upload preset (required for unsigned uploads)
      request.fields['upload_preset'] = uploadPreset;
      request.fields['folder'] = folder;
      
      if (publicId != null) {
        request.fields['public_id'] = publicId;
      }

      // Add the image file
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
        ),
      );

      final response = await request.send();
      final responseData = await response.stream.toBytes();
      final responseString = String.fromCharCodes(responseData);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(responseString);
        return jsonResponse['secure_url'] as String;
      } else {
        debugPrint('Upload failed: ${response.statusCode}');
        debugPrint('Response: $responseString');
        return null;
      }
    } catch (e) {
      debugPrint('Upload error: $e');
      return null;
    }
  }

  /// Upload document (PDF, DOCX, etc.) to Cloudinary
  Future<String?> uploadDocument({
    required File documentFile,
    required String folder,
    String? publicId,
  }) async {
    try {
      final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/raw/upload',
      );

      final request = http.MultipartRequest('POST', url);

      request.fields['upload_preset'] = uploadPreset;
      request.fields['folder'] = folder;
      
      if (publicId != null) {
        request.fields['public_id'] = publicId;
      }

      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          documentFile.path,
        ),
      );

      final response = await request.send();
      final responseData = await response.stream.toBytes();
      final responseString = String.fromCharCodes(responseData);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(responseString);
        return jsonResponse['secure_url'] as String;
      } else {
        debugPrint('Document upload failed: ${response.statusCode}');
        debugPrint('Response: $responseString');
        return null;
      }
    } catch (e) {
      debugPrint('Document upload error: $e');
      return null;
    }
  }

  /// Delete image from Cloudinary (convenience method)
  Future<bool> deleteImage(String publicId) async {
    return await deleteResource(publicId, isImage: true);
  }

  /// Delete document from Cloudinary (convenience method)
  Future<bool> deleteDocument(String publicId) async {
    return await deleteResource(publicId, isImage: false);
  }

  /// Delete resource from Cloudinary (requires API secret)
  Future<bool> deleteResource(String publicId, {bool isImage = true}) async {
    try {
      // Check if API secret is configured
      if (apiSecret == 'YOUR_API_SECRET') {
        debugPrint('Warning: API secret not configured. Cannot delete resources.');
        return false;
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final signature = _generateSignature(publicId, timestamp);
      
      final resourceType = isImage ? 'image' : 'raw';
      final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/$resourceType/destroy',
      );

      final response = await http.post(
        url,
        body: {
          'public_id': publicId,
          'api_key': apiKey,
          'timestamp': timestamp,
          'signature': signature,
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return jsonResponse['result'] == 'ok';
      }
      return false;
    } catch (e) {
      debugPrint('Delete error: $e');
      return false;
    }
  }

  /// Generate signature for authenticated requests
  String _generateSignature(String publicId, String timestamp) {
    final String toSign = 'public_id=$publicId&timestamp=$timestamp$apiSecret';
    final bytes = utf8.encode(toSign);
    final digest = sha1.convert(bytes);
    return digest.toString();
  }

  /// Extract public ID from Cloudinary URL
  String? getPublicIdFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;

      if (pathSegments.length < 3) return null;

      // Skip the first segments (version, resource type)
      final relevantSegments = pathSegments.skip(2);
      
      // Join remaining segments and remove file extension
      final fullPath = relevantSegments.join('/');
      final lastDotIndex = fullPath.lastIndexOf('.');
      
      if (lastDotIndex != -1) {
        return fullPath.substring(0, lastDotIndex);
      }
      return fullPath;
    } catch (e) {
      debugPrint('Error extracting public ID: $e');
      return null;
    }
  }

  /// Pick and upload image
  Future<String?> pickAndUploadImage({
    required String folder,
    String? publicId,
  }) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) return null;

      final File imageFile = File(image.path);
      
      // Check file size (max 5MB)
      final int fileSize = await imageFile.length();
      if (fileSize > 5 * 1024 * 1024) {
        debugPrint('Image too large. Max size is 5MB');
        return null;
      }

      return await uploadImage(
        imageFile: imageFile,
        folder: folder,
        publicId: publicId,
      );
    } catch (e) {
      debugPrint('Pick and upload error: $e');
      return null;
    }
  }
}

// Mixin for easy integration
mixin ImageUploadMixin<T extends StatefulWidget> on State<T> {
  final CloudinaryService _cloudinaryService = CloudinaryService();
  bool isUploading = false;

  Future<String?> uploadProfileImage({
    required String folder,
    required String userId,
  }) async {
    setState(() => isUploading = true);

    try {
      final String? imageUrl = await _cloudinaryService.pickAndUploadImage(
        folder: folder,
        publicId: '${userId}_profile',
      );

      if (imageUrl == null) {
        _showSnackBar('Failed to upload image', Colors.red);
        return null;
      }

      _showSnackBar('Image uploaded successfully', Colors.green);
      return imageUrl;
    } finally {
      if (mounted) {
        setState(() => isUploading = false);
      }
    }
  }

  Future<String?> uploadDocument({
    required String folder,
    required String userId,
    required String documentType,
  }) async {
    setState(() => isUploading = true);

    try {
      // Use file_picker package to select document
      final ImagePicker picker = ImagePicker();
      final XFile? file = await picker.pickImage(source: ImageSource.gallery);
      
      if (file == null) {
        _showSnackBar('No document selected', Colors.orange);
        return null;
      }

      final File documentFile = File(file.path);

      // Check file size (max 10MB)
      final int fileSize = await documentFile.length();
      if (fileSize > 10 * 1024 * 1024) {
        _showSnackBar('Document too large. Max size is 10MB', Colors.red);
        return null;
      }

      final String? documentUrl = await _cloudinaryService.uploadDocument(
        documentFile: documentFile,
        folder: folder,
        publicId: '${userId}_$documentType',
      );

      if (documentUrl == null) {
        _showSnackBar('Failed to upload document', Colors.red);
        return null;
      }

      _showSnackBar('Document uploaded successfully', Colors.green);
      return documentUrl;
    } finally {
      if (mounted) {
        setState(() => isUploading = false);
      }
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
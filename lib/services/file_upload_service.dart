import 'dart:io';
import 'package:image_picker/image_picker.dart';

class FileUploadService {
  final ImagePicker _imagePicker = ImagePicker();

  Future<File?> pickImage() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 80,
    );

    if (image != null) {
      return File(image.path);
    }
    return null;
  }

  Future<File?> pickDocument() async {
    final XFile? file = await _imagePicker.pickImage(
      source: ImageSource.gallery,
    );

    if (file != null) {
      return File(file.path);
    }
    return null;
  }

  Future<String> uploadFile(File file) async {
    // Simulate file upload process
    await Future.delayed(const Duration(seconds: 2));
    
    // In a real app, you would upload to your server
    return 'https://your-server.com/uploads/${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
  }
}
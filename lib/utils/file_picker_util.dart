import 'dart:io';
import 'package:file_picker/file_picker.dart';

class FilePickerUtil {
  /// Pick a file (PDF, DOC, DOCX)
  static Future<File?> pickResume() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
    );
    if (result != null && result.files.isNotEmpty) {
      return File(result.files.first.path!);
    }
    return null;
  }
}

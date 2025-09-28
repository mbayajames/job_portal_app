import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/application_model.dart';

class EmployerApplicationService {
  static const String _baseUrl = 'https://job-portal-app3-8.onrender.com';

  static Future<List<ApplicationModel>?> getApplications() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/employer/applications'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<ApplicationModel>.from(data['applications'].map((x) => ApplicationModel.fromMap(x)));
      } else {
        throw Exception('Failed to load applications');
      }
    } catch (e) {
      debugPrint('Error fetching applications: $e');
      return null;
    }
  }

  static Future<bool> updateApplicationStatus(String id, String newStatus) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/employer/applications/$id/status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': newStatus}),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error updating status: $e');
      return false;
    }
  }
}

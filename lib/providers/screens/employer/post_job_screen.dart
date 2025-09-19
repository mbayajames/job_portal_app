import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth_provider.dart';

class PostJobScreen extends StatefulWidget {
  @override
  _PostJobScreenState createState() => _PostJobScreenState();
}

class _PostJobScreenState extends State<PostJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _salaryRangeController = TextEditingController();
  String _jobType = 'Full-time';
  final _questionController = TextEditingController();
  List<String> _questions = [];

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: Text('Post a Job', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(labelText: 'Job Title'),
                  validator: (value) => value!.isEmpty ? 'Enter job title' : null,
                ),
                TextFormField(
                  controller: _companyNameController,
                  decoration: InputDecoration(labelText: 'Company Name'),
                  validator: (value) => value!.isEmpty ? 'Enter company name' : null,
                ),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                  validator: (value) => value!.isEmpty ? 'Enter description' : null,
                ),
                TextFormField(
                  controller: _locationController,
                  decoration: InputDecoration(labelText: 'Location'),
                  validator: (value) => value!.isEmpty ? 'Enter location' : null,
                ),
                TextFormField(
                  controller: _salaryRangeController,
                  decoration: InputDecoration(labelText: 'Salary Range'),
                  validator: (value) => value!.isEmpty ? 'Enter salary range' : null,
                ),
                DropdownButtonFormField<String>(
                  value: _jobType,
                  decoration: InputDecoration(labelText: 'Job Type'),
                  items: ['Full-time', 'Part-time', 'Contract']
                      .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                      .toList(),
                  onChanged: (value) => setState(() => _jobType = value!),
                ),
                SizedBox(height: 16),
                Text('Custom Questions', style: Theme.of(context).textTheme.headlineSmall),
                ..._questions.asMap().entries.map((entry) {
                  final index = entry.key;
                  final question = entry.value;
                  return ListTile(
                    title: Text(question),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => setState(() => _questions.removeAt(index)),
                    ),
                  );
                }).toList(),
                TextFormField(
                  controller: _questionController,
                  decoration: InputDecoration(labelText: 'Add Question'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_questionController.text.isNotEmpty) {
                      setState(() {
                        _questions.add(_questionController.text);
                        _questionController.clear();
                      });
                    }
                  },
                  child: Text('Add Question'),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _postJob(context, user!.uid),
                  child: Text('Post Job'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _postJob(BuildContext context, String employerId) async {
    if (_formKey.currentState!.validate()) {
      try {
        final jobRef = await FirebaseFirestore.instance.collection('jobs').add({
          'title': _titleController.text,
          'companyName': _companyNameController.text,
          'description': _descriptionController.text,
          'location': _locationController.text,
          'salaryRange': _salaryRangeController.text,
          'jobType': _jobType,
          'employerId': employerId,
          'createdAt': FieldValue.serverTimestamp(),
        });
        for (var question in _questions) {
          await FirebaseFirestore.instance.collection('jobs/${jobRef.id}/questions').add({
            'question': question,
          });
        }
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Job posted successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error posting job: $e')),
        );
      }
    }
  }
}
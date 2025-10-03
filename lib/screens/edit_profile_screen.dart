import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EditProfileScreen extends StatefulWidget {
  final int userId;
  final Map<String, dynamic> currentData;
  final VoidCallback onUpdated;

  const EditProfileScreen({
    Key? key,
    required this.userId,
    required this.currentData,
    required this.onUpdated,
  }) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;

  final baseUrl = 'http://your-api-url.com/api';

  @override
  void initState() {
    _nameController = TextEditingController(text: widget.currentData['name']);
    _emailController = TextEditingController(text: widget.currentData['email']);
    super.initState();
  }

  Future<void> updateProfile() async {
    final response = await http.put(
      Uri.parse('$baseUrl/Users/update-profile/${widget.userId}'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'id': widget.userId,
        'name': _nameController.text,
        'email': _emailController.text,
      }),
    );

    if (response.statusCode == 200) {
      widget.onUpdated();
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update profile")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Edit Profile")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(labelText: "Name"),
              validator: (val) => val!.isEmpty ? 'Required' : null,
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(labelText: "Email"),
              validator: (val) => val!.isEmpty ? 'Required' : null,
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  updateProfile();
                }
              },
              child: Text("Update Profile"),
            )
          ]),
        ),
      ),
    );
  }
}

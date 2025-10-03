import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'map_picker.dart';

class ListItemScreen extends StatefulWidget {
  const ListItemScreen({super.key});

  @override
  State<ListItemScreen> createState() => _ListItemScreenState();
}

class _ListItemScreenState extends State<ListItemScreen> {
  static const Color primaryColor = Color.fromARGB(255, 14, 44, 85);
  static const Color lightBgColor = Color.fromARGB(255, 248, 249, 252);

  double? _latitude;
  double? _longitude;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _depositController = TextEditingController();

  String _selectedCategory = 'Tools';
  String _selectedCondition = 'New';

  final List<String> _categories = [
    'Tools',
    'Furniture',
    'Vehicles',
    'Electronics',
    'Fashion'
  ];
  final List<String> _conditions = ['New', 'Like New', 'Used', 'Old'];

  final List<XFile> _images = [];
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadUserLocation();
  }

  Future<void> _loadUserLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final location = prefs.getString('location');
    final lat = prefs.getDouble('latitude');
    final lng = prefs.getDouble('longitude');

    if (location != null && lat != null && lng != null) {
      _locationController.text = location;
      _latitude = lat;
      _longitude = lng;
    }
  }

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> picked = await picker.pickMultiImage();
    if (picked.isNotEmpty && _images.length < 4) {
      setState(() {
        final remainingSlots = 4 - _images.length;
        _images.addAll(picked.take(remainingSlots));
      });
    }
  }

  Future<void> _removeImage(int index) async {
    setState(() {
      _images.removeAt(index);
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a pickup location")),
      );
      return;
    }

    if (_images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please upload at least 1 image")),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("You must log in first.")),
        );
        return;
      }

      final uri = Uri.parse("http://10.0.2.2:5297/api/item");

      var request = http.MultipartRequest("POST", uri);
      request.headers['Authorization'] = "Bearer $token";

      // Fields
      request.fields.addAll({
        'title': _titleController.text,
        'description': _descController.text,
        'category': _selectedCategory,
        'condition': _selectedCondition,
        'pricePerDay': _priceController.text,
        'securityDeposit': _depositController.text,
        'pickupLocation': _locationController.text,
        'latitude': _latitude.toString(),
        'longitude': _longitude.toString(),
      });

      // Multiple images
      for (var image in _images) {
        request.files.add(await http.MultipartFile.fromPath('images', image.path));
      }

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      setState(() => _isSubmitting = false);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Item added successfully!")),
        );

        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error ${response.statusCode}: $responseBody")),
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("List Your Item"),
        centerTitle: true,
        backgroundColor: primaryColor,
        titleTextStyle: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Item Details",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              Text("Item Title", style: _labelStyle()),
              _textField(_titleController, "Enter title"),
              const SizedBox(height: 20),
              Text("Category", style: _labelStyle()),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                items: _categories.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value, style: GoogleFonts.poppins()),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedCategory = value!),
                decoration: _inputDecoration(),
              ),
              const SizedBox(height: 20),
              Text("Condition", style: _labelStyle()),
              DropdownButtonFormField<String>(
                value: _selectedCondition,
                items: _conditions.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value, style: GoogleFonts.poppins()),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedCondition = value!),
                decoration: _inputDecoration(),
              ),
              const SizedBox(height: 20),
              Text("Description", style: _labelStyle()),
              _textField(_descController, "Write about your item", maxLines: 4),
              const SizedBox(height: 24),
              Text(
                "Pricing",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Price per day (Rs.)", style: _labelStyle()),
                        _textField(_priceController, "e.g. 500", keyboardType: TextInputType.number),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Security Deposit (Rs.)", style: _labelStyle()),
                        _textField(_depositController, "Optional", keyboardType: TextInputType.number),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                "Location",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              Text("Pickup Location", style: _labelStyle()),
              GestureDetector(
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MapPickerScreen(
                        onLocationSelected: (lat, lng) {
                          setState(() {
                            _latitude = lat;
                            _longitude = lng;
                          });
                        },
                      ),
                    ),
                  );

                  if (result != null && result is Map) {
                    setState(() {
                      _latitude = result['latitude'];
                      _longitude = result['longitude'];
                      _locationController.text = result['address'];
                    });

                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('location', result['address']);
                    await prefs.setDouble('latitude', result['latitude']);
                    await prefs.setDouble('longitude', result['longitude']);
                  }
                },
                child: AbsorbPointer(
                  child: _textField(_locationController, "Tap to select location"),
                ),
              ),
              if (_latitude != null && _longitude != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    "Location selected: ${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.green.shade700,
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              Text(
                "Images",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              Text("Upload Images (Max 4)", style: _labelStyle()),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  ..._images.asMap().entries.map((entry) {
                    final index = entry.key;
                    final file = entry.value;
                    return Stack(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(file.path),
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => _removeImage(index),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                  if (_images.length < 4)
                    GestureDetector(
                      onTap: _pickImages,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add_a_photo, color: Colors.grey, size: 24),
                            const SizedBox(height: 4),
                            Text(
                              "Add",
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _isSubmitting ? null : _submitForm,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          "List Item",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  TextStyle _labelStyle() => GoogleFonts.poppins(
        fontWeight: FontWeight.w500,
        fontSize: 14,
        color: Colors.black87,
      );

  InputDecoration _inputDecoration() => InputDecoration(
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      );

  Widget _textField(TextEditingController controller, String hint,
      {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: (value) => value == null || value.isEmpty ? 'Required' : null,
      decoration: _inputDecoration().copyWith(hintText: hint),
      style: GoogleFonts.poppins(),
    );
  }
}
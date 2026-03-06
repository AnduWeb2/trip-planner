import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'widgets/custom_button.dart';
import 'widgets/custom_text_field.dart';

class AddTravelerPage extends StatefulWidget {
  const AddTravelerPage({super.key});

  @override
  State<AddTravelerPage> createState() => _AddTravelerPageState();
}

class _AddTravelerPageState extends State<AddTravelerPage> {
  final storage = const FlutterSecureStorage();
  final _formKey = GlobalKey<FormState>();

  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final phoneCodeController = TextEditingController();
  final phoneNumberController = TextEditingController();
  final nationalityController = TextEditingController();

  DateTime? dateOfBirth;
  String gender = 'Male';
  bool isLoading = false;

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    phoneCodeController.dispose();
    phoneNumberController.dispose();
    nationalityController.dispose();
    super.dispose();
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) {
      setState(() => dateOfBirth = picked);
    }
  }

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<String?> _refreshAccessToken() async {
    try {
      final refreshToken = await storage.read(key: 'refresh_token');
      if (refreshToken == null) return null;

      final response = await http.post(
        Uri.parse('http://127.0.0.1:8000/user/api/token/refresh/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newAccess = data['access'] as String?;
        if (newAccess != null) {
          await storage.write(key: 'access_token', value: newAccess);
          return newAccess;
        }
      }
    } catch (_) {}
    return null;
  }

  Future<void> _submit() async {
    if (dateOfBirth == null) {
      _showError('Validation', 'Please select a date of birth.');
      return;
    }

    setState(() => isLoading = true);

    try {
      final payload = {
        'first_name': firstNameController.text.trim(),
        'last_name': lastNameController.text.trim(),
        'date_of_birth': _formatDate(dateOfBirth!),
        'gender': gender,
        'phone_country_code': phoneCodeController.text.trim(),
        'phone_number': phoneNumberController.text.trim(),
        'nationality': nationalityController.text.trim().toUpperCase(),
      };

      Future<http.Response> sendRequest(String? token) {
        return http.post(
          Uri.parse('http://127.0.0.1:8000/user/api/create-traveler/'),
          headers: {
            if (token != null) 'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(payload),
        );
      }

      String? token = await storage.read(key: 'access_token');
      http.Response response = await sendRequest(token);

      if (response.statusCode == 401) {
        final refreshed = await _refreshAccessToken();
        if (refreshed != null) {
          token = refreshed;
          response = await sendRequest(token);
        }
      }

      if (response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Traveler added successfully!',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        String errorMsg = 'Failed to add traveler.';
        try {
          final body = jsonDecode(response.body);
          if (body is Map) {
            final errors = body.entries
                .map((e) => '${e.key}: ${e.value is List ? (e.value as List).join(', ') : e.value}')
                .join('\n');
            errorMsg = errors;
          }
        } catch (_) {}
        if (mounted) _showError('Error', errorMsg);
      }
    } catch (e) {
      if (mounted) _showError('Error', e.toString());
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showError(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.red)),
        content: Text(message, style: GoogleFonts.poppins(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: GoogleFonts.poppins(color: const Color(0xFF5B85AA), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Traveler', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF5B85AA),
        elevation: 4,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Traveler Details', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 24),

              CustomTextField(
                controller: firstNameController,
                label: 'First Name',
                hint: 'Enter first name',
                prefixIcon: Icons.person,
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: lastNameController,
                label: 'Last Name',
                hint: 'Enter last name',
                prefixIcon: Icons.person_outline,
              ),
              const SizedBox(height: 16),

              // Date of Birth
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Date of Birth',
                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF333333)),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _pickDateOfBirth,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAFAFA),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFD0D0D0), width: 1.5),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, color: Color(0xFF5B85AA), size: 20),
                          const SizedBox(width: 12),
                          Text(
                            dateOfBirth != null ? _formatDate(dateOfBirth!) : 'Select date of birth',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: dateOfBirth != null ? const Color(0xFF333333) : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Gender
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gender',
                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF333333)),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAFAFA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFD0D0D0), width: 1.5),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: gender,
                        isExpanded: true,
                        style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF333333)),
                        items: const [
                          DropdownMenuItem(value: 'Male', child: Text('Male')),
                          DropdownMenuItem(value: 'Female', child: Text('Female')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => gender = val);
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  SizedBox(
                    width: 100,
                    child: CustomTextField(
                      controller: phoneCodeController,
                      label: 'Code',
                      hint: '+40',
                      prefixIcon: Icons.public,
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      controller: phoneNumberController,
                      label: 'Phone Number',
                      hint: '0712345678',
                      prefixIcon: Icons.phone,
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: nationalityController,
                label: 'Nationality (2-letter code)',
                hint: 'RO',
                prefixIcon: Icons.flag,
              ),
              const SizedBox(height: 32),

              CustomButton(
                label: 'Add Traveler',
                onPressed: _submit,
                isLoading: isLoading,
                icon: Icons.person_add,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

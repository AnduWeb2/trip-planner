import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'widgets/custom_button.dart';
import 'widgets/custom_text_field.dart';
import 'widgets/app_header.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final storage = const FlutterSecureStorage();
  bool isLoading = false;

  Future<void> login() async {
    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:8000/user/api/token/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': usernameController.text,
          'password': passwordController.text,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final accessToken = responseData['access'];
        final refreshToken = responseData['refresh'];

        await storage.write(key: 'access_token', value: accessToken);
        await storage.write(key: 'refresh_token', value: refreshToken);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Login successful!',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        String errorMessage = 'Login failed. Please try again.';

        try {
          final errorBody = jsonDecode(response.body);

          if (errorBody is Map) {
            if (errorBody.containsKey('detail')) {
              errorMessage = errorBody['detail'];
            } else if (errorBody.containsKey('username')) {
              errorMessage = 'Invalid username';
            } else if (errorBody.containsKey('password')) {
              errorMessage = 'Invalid password';
            } else {
              errorMessage = 'Login failed. Please check your credentials.';
            }
          }
        } catch (e) {
          errorMessage = 'Login failed. Please try again.';
        }

        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(
                'Login Error',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
              content: Text(
                errorMessage,
                style: GoogleFonts.poppins(fontSize: 14),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'OK',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF5B85AA),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              'Connection Error',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
            content: Text(
              'Unable to connect to server. Please check your internet connection.',
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'OK',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF5B85AA),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo or Header
                Container(
                   constraints: const BoxConstraints.tightFor(width: 80, height: 80),
                   decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF5B85AA), Color(0xFF7BA5C9)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                         color: const Color(0xFF5B85AA).withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.flight, color: Colors.white, size: 40),
                ),
                const SizedBox(height: 32),

                // Header
                const AppHeader(
                  title: 'Welcome Back',
                  subtitle: 'Sign in to your account to continue',
                ),
                const SizedBox(height: 40),

                // Form
                CustomTextField(
                  controller: usernameController,
                  label: 'Username',
                  hint: 'Enter your username',
                  prefixIcon: Icons.person,
                  keyboardType: TextInputType.text,
                ),
                const SizedBox(height: 20),

                CustomTextField(
                  controller: passwordController,
                  label: 'Password',
                  hint: 'Enter your password',
                  prefixIcon: Icons.lock,
                  obscureText: true,
                ),
                const SizedBox(height: 32),

                // Buttons
                CustomButton(
                  label: 'Sign In',
                  icon: Icons.check_circle,
                  isLoading: isLoading,
                  onPressed: login,
                ),
                const SizedBox(height: 12),

                CustomButton(
                  label: 'Create Account',
                  icon: Icons.person_add,
                  isOutlined: true,
                  onPressed: () => Navigator.pushNamed(context, '/register'),
                ),

                const SizedBox(height: 24),
                Text(
                  'Trip Planner v1.0',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[400],
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

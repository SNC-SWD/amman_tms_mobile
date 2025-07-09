import 'package:flutter/material.dart';
import 'package:amman_tms_mobile/core/services/auth_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class LoginScreen extends StatefulWidget {
  final void Function(String userRole) onLoginSuccess;
  const LoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  final AuthService _authService = AuthService();

  // Palet warna global untuk login screen
  static const kPrimaryBlue = Color(0xFF163458);
  static const kAccentGold = Color(0xFFC88C2C);
  static const kLightGray = Color(0xFFF4F6F9);
  static const kSlateGray = Color(0xFF4C5C74);
  static const kSoftGold = Color(0xFFE0B352);
  static const kBlueTint = Color(0xFFE6EDF6);

  void _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final Map<String, dynamic> result = await _authService.login(
        _usernameController.text.trim(),
        _passwordController.text.trim(),
      );

      if (result['success'] == true) {
        String? fcmToken = await FirebaseMessaging.instance.getToken();
        print("FCM Token: $fcmToken");
        // You might want to send this token to your backend along with login credentials
        widget.onLoginSuccess(result['userRole']);
      } else {
        setState(() {
          _errorMessage = result['message'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage =
            'Unable to connect to the server. Please check your internet connection or try again later.';
        if (e is Exception) {
          print('Network error details: $e');
        }
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kLightGray,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: kPrimaryBlue.withOpacity(0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/logo/logo.png',
                    width: 250,
                    height: 250,
                    fit: BoxFit.fill,
                  ),
                  const SizedBox(height: 0),
                  const Text(
                    'Transport Management System',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: kPrimaryBlue,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Please login to continue',
                    style: TextStyle(
                      fontSize: 11,
                      color: kSlateGray,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                  const SizedBox(height: 32),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _usernameController,
                          style: const TextStyle(fontSize: 12),
                          decoration: InputDecoration(
                            labelText: 'Username',
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            prefixIcon: const Icon(
                              Icons.person_outline,
                              color: kPrimaryBlue,
                            ),
                            labelStyle: const TextStyle(
                              color: kSlateGray,
                              fontSize: 12,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: kPrimaryBlue,
                                width: 2,
                              ),
                            ),
                          ),
                          validator: (value) => value == null || value.isEmpty
                              ? 'Username wajib diisi'
                              : null,
                        ),
                        const SizedBox(height: 18),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          style: const TextStyle(fontSize: 12),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            prefixIcon: const Icon(
                              Icons.lock_outline,
                              color: kPrimaryBlue,
                            ),
                            labelStyle: const TextStyle(
                              color: kSlateGray,
                              fontSize: 12,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: kPrimaryBlue,
                                width: 2,
                              ),
                            ),
                          ),
                          validator: (value) => value == null || value.isEmpty
                              ? 'Password wajib diisi'
                              : null,
                        ),
                      ],
                    ),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 10),
                    ),
                  ],
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kAccentGold,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 6,
                        textStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Montserrat',
                        ),
                      ),
                      onPressed: _isLoading
                          ? null
                          : () {
                              if (_formKey.currentState?.validate() ?? false) {
                                _login();
                              }
                            },
                      child: _isLoading
                          ? const CircularProgressIndicator(color: kPrimaryBlue)
                          : const Text(
                              'Login',
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'Montserrat',
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Removed hardcoded demo text as API is now integrated
                  // const Text(
                  //   'Demo: user demo, pass demo123',
                  //   style: TextStyle(
                  //     color: kSlateGray,
                  //     fontSize: 14,
                  //     fontFamily: 'Montserrat',
                  //   ),
                  // ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
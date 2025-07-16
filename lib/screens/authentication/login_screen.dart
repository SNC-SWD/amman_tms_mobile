import 'package:flutter/material.dart';
import 'package:amman_tms_mobile/core/services/auth_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:ui'; // Diperlukan untuk ImageFilter

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
  bool _isPasswordVisible = false;

  // Palet warna yang disesuaikan untuk desain baru
  static const kAccentGold = Color(0xFFE0B352); // Warna emas untuk tombol
  static const kTextColor = Colors.white;
  static const kHintTextColor = Color(0x99FFFFFF); // Putih dengan 70% opacity

  void _login() async {
    // Sembunyikan keyboard saat login ditekan
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

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
            'Unable to connect to the server. Please check your internet connection.';
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
      // Menggunakan Stack untuk menumpuk background dan konten
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Layer 1: Background Image (Sama seperti Splash Screen)
          Image.asset(
            'assets/image/background.png', // <-- PASTIKAN PATH INI BENAR
            fit: BoxFit.cover,
            color: Colors.blueGrey.withOpacity(0.5),
            colorBlendMode: BlendMode.darken,
          ),

          // Layer 2: Konten Login
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Logo Aplikasi
                          Image.asset(
                            'assets/logo/new_logo_4.png', // <-- PASTIKAN PATH INI BENAR
                            width: 250,
                            height: 250,
                          ),

                          // Judul Halaman
                          const Text(
                            'Welcome Back',
                            style: TextStyle(
                              color: kTextColor,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Sign in to your account',
                            style: TextStyle(
                              color: kTextColor.withOpacity(0.8),
                              fontSize: 16,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          const SizedBox(height: 30),

                          // Container dengan efek Glassmorphism
                          _buildGlassmorphicForm(),
                        ],
                      ),
                    ),
                  ),
                ),
                // Bagian "Powered By" di bagian bawah
                _buildPoweredBy(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassmorphicForm() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(25.0),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Input field untuk Username
                TextFormField(
                  controller: _usernameController,
                  keyboardType: TextInputType.text,
                  style: const TextStyle(
                    color: kTextColor,
                    fontSize: 14,
                    fontFamily: 'Poppins',
                  ),
                  decoration: _buildInputDecoration(
                    label: 'Username',
                    icon: Icons.person_outline,
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Username is required'
                      : null,
                ),
                const SizedBox(height: 20),

                // Input field untuk Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  style: const TextStyle(
                    color: kTextColor,
                    fontSize: 14,
                    fontFamily: 'Poppins',
                  ),
                  decoration: _buildInputDecoration(
                    label: 'Password',
                    icon: Icons.lock_outline,
                    isPassword: true,
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Password is required'
                      : null,
                ),
                const SizedBox(height: 16),

                // Menampilkan pesan error jika ada
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.red[300],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                // Tombol Login
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kAccentGold,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 8,
                      shadowColor: Colors.black.withOpacity(0.4),
                    ),
                    onPressed: _isLoading ? null : _login,
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                        : const Text(
                            'LOGIN',
                            style: TextStyle(
                              color: Color(
                                0xFF163458,
                              ), // Warna teks gelap agar kontras
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                              letterSpacing: 1.2,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper method untuk membuat dekorasi input field
  InputDecoration _buildInputDecoration({
    required String label,
    required IconData icon,
    bool isPassword = false,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: kHintTextColor, fontSize: 14),
      prefixIcon: Icon(icon, color: kHintTextColor, size: 20),
      suffixIcon: isPassword
          ? IconButton(
              icon: Icon(
                _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                color: kHintTextColor,
                size: 20,
              ),
              onPressed: () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
            )
          : null,
      filled: true,
      fillColor: Colors.black.withOpacity(0.2),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15.0),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15.0),
        borderSide: BorderSide(color: kAccentGold.withOpacity(0.8), width: 2),
      ),
      errorStyle: TextStyle(
        color: Colors.red[300],
        fontWeight: FontWeight.w500,
      ),
    );
  }

  // Widget baru untuk menampilkan "Powered By"
  Widget _buildPoweredBy() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Powered By',
            style: TextStyle(
              fontFamily: 'Poppins',
              color: Colors.white.withOpacity(0.6),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Image.asset(
            'assets/logo/logo_snc.png', // <-- GANTI DENGAN PATH LOGO ANDA
            height: 35,
            // Tambahkan error builder untuk menangani jika logo tidak ditemukan
            errorBuilder: (context, error, stackTrace) {
              return const Icon(
                Icons.business,
                color: Colors.white54,
                size: 35,
              );
            },
          ),
        ],
      ),
    );
  }
}

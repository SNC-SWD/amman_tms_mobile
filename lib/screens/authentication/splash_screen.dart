import 'package:flutter/material.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  final VoidCallback onFinish;
  const SplashScreen({super.key, required this.onFinish});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

// Gunakan SingleTickerProviderStateMixin untuk Vsync animasi
class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Inisialisasi AnimationController untuk durasi animasi 1.5 detik
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Buat animasi fade dari 0.0 (transparan) ke 1.0 (terlihat)
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Mulai animasi
    _animationController.forward();

    // Atur timer untuk pindah ke halaman berikutnya setelah 3 detik
    Timer(const Duration(seconds: 3), widget.onFinish);
  }

  @override
  void dispose() {
    // Hapus controller saat widget tidak lagi digunakan untuk mencegah memory leak
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Menggunakan Stack untuk menumpuk beberapa layer widget
      body: Stack(
        fit: StackFit.expand, // Membuat semua child di Stack memenuhi layar
        children: [
          // Layer 1: Background Image
          // Ganti 'assets/images/background.jpg' dengan path gambar Anda
          // Pastikan Anda sudah menambahkan gambar ke folder assets dan mendaftarkannya di pubspec.yaml
          Image.asset(
            'assets/image/background.png', // <-- GANTI DENGAN GAMBAR ANDA
            fit: BoxFit.cover,
            // Tambahkan color blend untuk membuat gambar tidak terlalu terang
            color: Colors.black.withOpacity(0.5),
            colorBlendMode: BlendMode.darken,
          ),

          // Layer 2: Gradient Overlay (Opsional, untuk efek lebih dramatis)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blueGrey.withOpacity(0.3),
                  Colors.blueGrey.withOpacity(0.7),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Layer 3: Konten Utama (Logo dan Tagline)
          Center(
            // Gunakan FadeTransition untuk menganimasikan konten
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Widget untuk Logo
                  Container(
                    width: 500, // Sesuaikan ukuran logo
                    height: 500,
                    child: Image.asset(
                      'assets/logo/new_logo_4.png', // Path ke logo Anda
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Widget untuk Tagline
                  const Text(
                    'Employee Transport Management System',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily:
                          'Poppins', // Pastikan font ini ada di project Anda
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

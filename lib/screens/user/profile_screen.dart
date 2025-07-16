import 'package:flutter/material.dart';
import 'package:amman_tms_mobile/core/services/auth_service.dart';

// Color Palette (Unchanged)
const kPrimaryBlue = Color(0xFF163458);
const kAccentGold = Color(0xFFC88C2C);
const kLightGray = Color(0xFFF4F6F9);
const kSlateGray = Color(0xFF4C5C74);
const kSoftGold = Color(0xFFE0B352);
const kBlueTint = Color(0xFFE6EDF6);

class ProfileScreen extends StatefulWidget {
  final VoidCallback onLogout;
  const ProfileScreen({super.key, required this.onLogout});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // State variables remain the same
  bool _darkMode = false;
  String _language = 'ID';
  String _name = 'Memuat...';
  String _email = 'Memuat...';
  String _jobTitle = 'Memuat...';
  final AuthService _authService = AuthService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final userProfile = await _authService.getUserProfile();
      if (userProfile != null && mounted) {
        setState(() {
          final employee = userProfile['employee'];
          _name = employee['name'] ?? 'Nama Tidak Diketahui';
          _email = employee['work_email'] ?? 'Tidak ada email';
          _jobTitle = employee['job_title'] ?? 'Posisi Tidak Diketahui';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _name = 'Gagal memuat profil';
          _email = 'Silakan coba lagi';
          _jobTitle = 'Tidak diketahui';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kLightGray,
      body: Stack(
        children: [
          // Background Header
          Container(
            height: 200,
            decoration: const BoxDecoration(
              color: kPrimaryBlue,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  _buildProfileHeader(),
                  const SizedBox(height: 24),
                  _buildSectionHeader('Informasi Akun'),
                  _buildInfoCard(),
                  const SizedBox(height: 24),
                  _buildSectionHeader('Pengaturan'),
                  _buildPreferencesCard(),
                  const SizedBox(height: 30),
                  _buildLogoutButton(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Reusable UI Builder Widgets ---

  /// Builds the main profile card with avatar, name, and edit button.
  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            children: [
              CircleAvatar(
                radius: 45,
                backgroundColor: kBlueTint,
                backgroundImage: const AssetImage('assets/logo/logo.png'),
              ),
              const SizedBox(height: 16),
              Text(
                _name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: kPrimaryBlue,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _jobTitle,
                style: const TextStyle(
                  color: kSlateGray,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _email,
                style: TextStyle(
                  color: kSlateGray.withOpacity(0.8),
                  fontSize: 14,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          Positioned(
            top: -8,
            right: -8,
            child: IconButton(
              icon: const Icon(
                Icons.edit_outlined,
                color: kSlateGray,
                size: 22,
              ),
              onPressed: _showEditProfileSheet,
              tooltip: 'Edit Profil',
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a section header with a title.
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(
          color: kPrimaryBlue,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }

  /// Builds the card containing account information.
  Widget _buildInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildInfoTile(
            icon: Icons.directions_bus_rounded,
            iconColor: kAccentGold,
            label: 'Total Perjalanan',
            value: _isLoading ? '-' : '24',
          ),
          _buildInfoTile(
            icon: Icons.location_on_rounded,
            iconColor: kPrimaryBlue,
            label: 'Lokasi Terakhir',
            value: _isLoading ? '-' : 'Terminal Benete',
          ),
          _buildInfoTile(
            icon: Icons.access_time_filled_rounded,
            iconColor: kAccentGold,
            label: 'Aktif Sejak',
            value: _isLoading ? '-' : '2023',
          ),
          _buildInfoTile(
            icon: Icons.lock_outline_rounded,
            iconColor: kSlateGray,
            label: 'Ubah Kata Sandi',
            isNavigable: true,
            onTap: () {
              // TODO: Implement navigation to change password screen
            },
          ),
        ],
      ),
    );
  }

  /// Builds the card containing user preferences.
  Widget _buildPreferencesCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildInfoTile(
            icon: Icons.nightlight_round,
            iconColor: kSlateGray,
            label: 'Mode Gelap',
            trailing: Switch(
              value: _darkMode,
              onChanged: (val) => setState(() => _darkMode = val),
              activeColor: kAccentGold,
              inactiveTrackColor: kBlueTint,
            ),
          ),
          _buildInfoTile(
            icon: Icons.language_rounded,
            iconColor: kSlateGray,
            label: 'Bahasa',
            trailing: DropdownButton<String>(
              value: _language,
              underline: const SizedBox(),
              icon: const Icon(Icons.keyboard_arrow_down, color: kSlateGray),
              items: ['ID', 'EN']
                  .map(
                    (lang) => DropdownMenuItem(
                      value: lang,
                      child: Text(
                        lang,
                        style: const TextStyle(
                          color: kPrimaryBlue,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (val) => setState(() => _language = val ?? 'ID'),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a generic list tile for info and settings.
  Widget _buildInfoTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    String? value,
    Widget? trailing,
    bool isNavigable = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: isNavigable ? BorderRadius.circular(16) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(
                color: kSlateGray,
                fontWeight: FontWeight.w600,
                fontSize: 14,
                fontFamily: 'Poppins',
              ),
            ),
            const Spacer(),
            if (value != null)
              Text(
                value,
                style: const TextStyle(
                  color: kPrimaryBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  fontFamily: 'Poppins',
                ),
              ),
            if (trailing != null) trailing,
            if (isNavigable && trailing == null)
              const Icon(Icons.chevron_right, color: kSlateGray, size: 22),
          ],
        ),
      ),
    );
  }

  /// Builds the logout button.
  Widget _buildLogoutButton() {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red.shade600,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(vertical: 14),
        elevation: 2,
        shadowColor: Colors.red.withOpacity(0.4),
      ),
      icon: const Icon(Icons.logout_rounded, size: 20),
      label: const Text(
        'Logout',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          fontFamily: 'Poppins',
        ),
      ),
      onPressed: _showLogoutConfirmationDialog,
    );
  }

  // --- Logic and Dialogs ---

  /// Shows the modal bottom sheet for editing profile information.
  void _showEditProfileSheet() async {
    final nameController = TextEditingController(text: _name);
    final emailController = TextEditingController(text: _email);
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  'Edit Profil',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: kPrimaryBlue,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Nama Lengkap',
                  prefixIcon: const Icon(Icons.person, color: kPrimaryBlue),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email, color: kAccentGold),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        'Batal',
                        style: TextStyle(
                          color: kSlateGray,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kAccentGold,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          setState(() {
                            _name = nameController.text;
                            _email = emailController.text;
                          });
                          Navigator.of(context).pop();
                        }
                      },
                      child: const Text(
                        'Simpan',
                        style: TextStyle(fontFamily: 'Poppins'),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Shows the confirmation dialog before logging out.
  void _showLogoutConfirmationDialog() async {
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Konfirmasi Logout',
          style: TextStyle(
            color: kPrimaryBlue,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        content: const Text(
          'Apakah Anda yakin ingin keluar?',
          style: TextStyle(fontFamily: 'Poppins', fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal', style: TextStyle(fontFamily: 'Poppins')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.of(context).pop(true);
              widget.onLogout();
            },
            child: const Text(
              'Ya, Keluar',
              style: TextStyle(fontFamily: 'Poppins'),
            ),
          ),
        ],
      ),
    );
  }
}

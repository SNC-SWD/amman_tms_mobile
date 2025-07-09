import 'package:flutter/material.dart';
import 'package:amman_tms_mobile/core/services/auth_service.dart';

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
  bool _darkMode = false;
  String _language = 'ID';
  String _name = 'Loading...';
  String _email = 'Loading...';
  String _jobTitle = 'Loading...';
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
          _name = employee['name'] ?? 'Unknown';
          _email = employee['work_email'] ?? 'No email';
          _jobTitle = employee['job_title'] ?? 'Unknown';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _name = 'Error loading profile';
          _email = 'Please try again';
          _jobTitle = 'Unknown';
          _isLoading = false;
        });
      }
    }
  }

  void _showEditProfileSheet() async {
    final nameController = TextEditingController(text: _name);
    final emailController = TextEditingController(text: _email);
    final formKey = GlobalKey<FormState>();
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 32,
          left: 0,
          right: 0,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: kPrimaryBlue.withOpacity(0.10),
                blurRadius: 24,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 18),
                    decoration: BoxDecoration(
                      color: kBlueTint,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const Center(
                  child: Text(
                    'Edit Profile',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: kPrimaryBlue,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                TextFormField(
                  controller: nameController,
                  style: TextStyle(fontSize: responsiveFont(16, context)),
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    labelStyle: TextStyle(
                      fontSize: responsiveFont(16, context),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.person, color: kPrimaryBlue),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: emailController,
                  style: TextStyle(fontSize: responsiveFont(16, context)),
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: TextStyle(
                      fontSize: responsiveFont(16, context),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.email, color: kAccentGold),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Batal'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kAccentGold,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          setState(() {
                            _name = nameController.text;
                            _email = emailController.text;
                          });
                          Navigator.of(context).pop(true);
                        }
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        child: Text('Simpan'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Responsive font size helper
  double responsiveFont(double base, BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    // Reduce base font size by 2 levels (e.g., 22 -> 16, 20 -> 14, 15 -> 11, 14 -> 10, 13 -> 9, 12 -> 8, 11 -> 7, 10 -> 6)
    double reduced = base - 3; // 1 levels down (each level ~3pt)
    if (reduced < 6) reduced = 6; // Minimum font size
    if (width < 320) return reduced * 0.8;
    if (width < 360) return reduced * 0.85;
    if (width < 400) return reduced * 0.9;
    if (width < 480) return reduced * 0.95;
    if (width > 600) return reduced * 1.1;
    return reduced;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kLightGray,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Profile Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 28,
                  horizontal: 18,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: kPrimaryBlue.withOpacity(0.08),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 44,
                      backgroundColor: kBlueTint,
                      backgroundImage: const AssetImage('assets/logo/logo.png'),
                      child: Container(),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      _name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: responsiveFont(22, context),
                        color: kPrimaryBlue,
                        letterSpacing: 1.1,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _jobTitle,
                      style: TextStyle(
                        color: kSlateGray.withOpacity(0.85),
                        fontSize: responsiveFont(16, context),
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _email,
                      style: TextStyle(
                        color: kSlateGray.withOpacity(0.85),
                        fontSize: responsiveFont(16, context),
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kAccentGold,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 2,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 8,
                        ),
                        textStyle: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      icon: const Icon(Icons.edit_rounded, size: 18),
                      label: const Text('Edit Profile'),
                      onPressed: _showEditProfileSheet,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              // Info Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 22,
                  horizontal: 18,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: kPrimaryBlue.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.directions_bus_rounded,
                          color: kAccentGold,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Total Trips',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: kSlateGray,
                            fontSize: responsiveFont(16, context),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '24',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: kPrimaryBlue,
                            fontSize: responsiveFont(16, context),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 28, thickness: 0.7, color: kBlueTint),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          color: kPrimaryBlue,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Last Trip Location',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: responsiveFont(16, context),
                            color: kSlateGray,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Benete Terminal',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: kPrimaryBlue,
                            fontSize: responsiveFont(16, context),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 28, thickness: 0.7, color: kBlueTint),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          color: kAccentGold,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Active Since',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: responsiveFont(16, context),
                            color: kSlateGray,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '2023',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: kPrimaryBlue,
                            fontSize: responsiveFont(16, context),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 28, thickness: 0.7, color: kBlueTint),
                    InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {},
                      child: Row(
                        children: [
                          const Icon(
                            Icons.lock_rounded,
                            color: kSlateGray,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Change Password',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: responsiveFont(16, context),
                              color: kSlateGray,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: kSlateGray.withOpacity(0.7),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              // Preferences Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 22,
                  horizontal: 18,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: kPrimaryBlue.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.nightlight_round,
                          color: kSlateGray,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Dark Mode',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: responsiveFont(16, context),
                            color: kSlateGray,
                          ),
                        ),
                        const Spacer(),
                        Switch(
                          value: _darkMode,
                          activeColor: kAccentGold,
                          onChanged: (val) => setState(() => _darkMode = val),
                        ),
                      ],
                    ),
                    const Divider(height: 28, thickness: 0.7, color: kBlueTint),
                    Row(
                      children: [
                        const Icon(
                          Icons.language_rounded,
                          color: kSlateGray,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Language',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: responsiveFont(16, context),
                            color: kSlateGray,
                          ),
                        ),
                        const Spacer(),
                        DropdownButton<String>(
                          value: _language,
                          underline: const SizedBox(),
                          borderRadius: BorderRadius.circular(12),
                          items: const [
                            DropdownMenuItem(
                              value: 'ID',
                              child: Text(
                                'ID',
                                style: TextStyle(fontWeight: FontWeight.normal),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'EN',
                              child: Text(
                                'EN',
                                style: TextStyle(fontWeight: FontWeight.normal),
                              ),
                            ),
                          ],
                          onChanged: (val) =>
                              setState(() => _language = val ?? 'ID'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),
              // Logout Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                    elevation: 2,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.logout_rounded, size: 22),
                  label: const Text('Logout'),
                  onPressed: () async {
                    final shouldLogout = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        title: Text(
                          'Konfirmasi Logout',
                          style: TextStyle(
                            color: kPrimaryBlue,
                            fontWeight: FontWeight.bold,
                            fontSize: responsiveFont(20, context),
                          ),
                        ),
                        content: Text(
                          'Apakah Anda yakin ingin logout?',
                          style: TextStyle(
                            fontSize: responsiveFont(16, context),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: Text(
                              'Batal',
                              style: TextStyle(
                                fontSize: responsiveFont(16, context),
                              ),
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimaryBlue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {
                              widget.onLogout();
                              Navigator.of(context).pop(true);
                            },
                            child: Text(
                              'Ya',
                              style: TextStyle(
                                fontSize: responsiveFont(16, context),
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
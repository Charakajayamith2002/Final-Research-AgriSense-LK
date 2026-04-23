import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../services/api_service.dart';
import '../services/language_service.dart';
import '../widgets/language_switcher.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with LangMixin {
  String _username = '';
  String _email = '';
  String _userType = 'farmer';
  String _photoUrl = '';
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    // Load cached values immediately for fast display
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('username') ?? '';
      _email = prefs.getString('user_email') ?? '';
      _userType = prefs.getString('user_type') ?? 'farmer';
      _photoUrl = prefs.getString('photo_url') ?? '';
    });
    // Then refresh from server — silently ignore auth failures (use cached data)
    final result = await ApiService().getProfile();
    if (!mounted) return;
    if (result['success'] == true) {
      final photoPath = result['profile_photo'] ?? '';
      setState(() {
        _username = result['username'] ?? _username;
        _email = result['email'] ?? _email;
        _userType = result['user_type'] ?? _userType;
        _photoUrl = photoPath;
      });
      await prefs.setString('photo_url', photoPath);
    }
    // On auth failure: cached data stays, no error shown
  }

  Future<void> _pickAndUpload(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 80, maxWidth: 800);
    if (picked == null) return;

    setState(() => _uploading = true);
    final result = await ApiService().uploadProfilePhoto(picked);
    if (!mounted) return;
    setState(() => _uploading = false);

    if (result['success'] == true) {
      setState(() => _photoUrl = result['photo_url'] ?? '');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile photo updated'), backgroundColor: Color(0xFF2E7D32)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Upload failed'), backgroundColor: Colors.red[700]),
      );
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF2E7D32)),
              title: const Text('Take a photo'),
              onTap: () { Navigator.pop(context); _pickAndUpload(ImageSource.camera); },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFF2E7D32)),
              title: const Text('Choose from gallery'),
              onTap: () { Navigator.pop(context); _pickAndUpload(ImageSource.gallery); },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _logout() async {
    await ApiService().logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = LanguageService();
    // _photoUrl is a server path like /api/profile-photo/<id>; prepend baseUrl
    final fullPhotoUrl = _photoUrl.isNotEmpty
        ? (_photoUrl.startsWith('http') ? _photoUrl : '${ApiConfig.baseUrl}$_photoUrl')
        : '';

    return Scaffold(
      backgroundColor: const Color(0xFFF1F8E9),
      appBar: AppBar(
        title: Text(lang.t('profile_title')),
        actions: const [LanguageSwitcher()],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Avatar card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _showPhotoOptions,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: const Color(0xFF2E7D32),
                            child: _uploading
                                ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
                                : fullPhotoUrl.isNotEmpty
                                    ? ClipOval(
                                        child: CachedNetworkImage(
                                          imageUrl: fullPhotoUrl,
                                          width: 100,
                                          height: 100,
                                          fit: BoxFit.cover,
                                          placeholder: (_, __) => _initialsWidget(),
                                          errorWidget: (_, __, ___) => _initialsWidget(),
                                        ),
                                      )
                                    : _initialsWidget(),
                          ),
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2E7D32),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.camera_alt, size: 15, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(_username,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(_email, style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D32).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(_userType.toUpperCase(),
                          style: const TextStyle(
                              color: Color(0xFF2E7D32),
                              fontWeight: FontWeight.bold,
                              fontSize: 12)),
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: _showPhotoOptions,
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Change photo'),
                      style: TextButton.styleFrom(foregroundColor: const Color(0xFF2E7D32)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Info card
            Card(
              child: Column(
                children: [
                  _infoTile(Icons.person, lang.t('profile_username'), _username),
                  const Divider(height: 1),
                  _infoTile(Icons.email, lang.t('profile_email'), _email),
                  const Divider(height: 1),
                  _infoTile(Icons.agriculture, lang.t('profile_type'), _userType),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // App info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(lang.t('profile_about'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const Divider(),
                    _appInfoRow(lang.t('profile_version'), '1.0.0'),
                    const SizedBox(height: 8),
                    _appInfoRow(lang.t('profile_platform'), 'Flutter'),
                    const SizedBox(height: 8),
                    _appInfoRow(lang.t('profile_backend'), 'Flask + ML Models'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Logout button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[700],
                  foregroundColor: Colors.white,
                ),
                onPressed: _logout,
                icon: const Icon(Icons.logout),
                label: Text(lang.t('logout'), style: const TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _initialsWidget() => Text(
        _username.isNotEmpty ? _username[0].toUpperCase() : 'U',
        style: const TextStyle(fontSize: 36, color: Colors.white, fontWeight: FontWeight.bold),
      );

  Widget _infoTile(IconData icon, String label, String value) => ListTile(
        leading: Icon(icon, color: const Color(0xFF2E7D32)),
        title: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        subtitle: Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
      );

  Widget _appInfoRow(String label, String value) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value),
        ],
      );
}

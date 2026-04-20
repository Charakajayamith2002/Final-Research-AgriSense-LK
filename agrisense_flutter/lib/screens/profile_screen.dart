import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('username') ?? '';
      _email = prefs.getString('user_email') ?? '';
      _userType = prefs.getString('user_type') ?? 'farmer';
    });
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
                    CircleAvatar(
                      radius: 45,
                      backgroundColor: const Color(0xFF2E7D32),
                      child: Text(
                        _username.isNotEmpty ? _username[0].toUpperCase() : 'U',
                        style: const TextStyle(fontSize: 36, color: Colors.white, fontWeight: FontWeight.bold),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(lang.t('profile_version'), style: const TextStyle(color: Colors.grey)),
                        const Text('1.0.0'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(lang.t('profile_platform'), style: const TextStyle(color: Colors.grey)),
                        const Text('Flutter'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(lang.t('profile_backend'), style: const TextStyle(color: Colors.grey)),
                        const Text('Flask + ML Models'),
                      ],
                    ),
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

  Widget _infoTile(IconData icon, String label, String value) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF2E7D32)),
      title: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      subtitle: Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
    );
  }
}

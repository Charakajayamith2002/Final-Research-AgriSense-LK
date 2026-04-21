import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/language_service.dart';
import '../theme/auth_widgets.dart';
import 'home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with LangMixin {
  final _formKey   = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final result = await ApiService().login(_emailCtrl.text.trim(), _passCtrl.text);
    setState(() => _loading = false);
    if (!mounted) return;
    if (result['success'] == true) {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const HomeScreen()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result['message'] ?? 'Login failed'),
        backgroundColor: Colors.red.shade700,
      ));
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = LanguageService();
    return Scaffold(
      backgroundColor: authBg,
      // Language switcher overlay in top-right corner
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // ── Hero ──────────────────────────────────
                  AuthHeroSection(
                    headline: 'Farm smarter.\nSell better.\nEarn more.',
                    features: const [
                      AuthFeature(Icons.trending_up,           'Price Forecasting', 'Know what your crop will fetch before harvest day.'),
                      AuthFeature(Icons.map_outlined,          'Market Ranking',    'Find the best market with lowest transport cost.'),
                      AuthFeature(Icons.grass,                 'Cultivation AI',    'AI tells you exactly what to plant next season.'),
                      AuthFeature(Icons.photo_camera_outlined, 'Quality Vision',    'Upload a photo — get an instant income estimate.'),
                    ],
                  ),

                  // ── Card ──────────────────────────────────
                  AuthCard(
                    activeTab: 0,
                    onTabSwitch: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const RegisterScreen())),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AuthCardHeading(
                              title: lang.t('welcome_back'),
                              sub: lang.t('sign_in_sub')),
                          AuthField(
                            label: lang.t('email'),
                            icon: Icons.email_outlined,
                            controller: _emailCtrl,
                            hint: 'you@example.com',
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) =>
                                v == null || !v.contains('@') ? 'Enter a valid email' : null,
                          ),
                          const SizedBox(height: 12),
                          AuthField(
                            label: lang.t('password'),
                            icon: Icons.lock_outline,
                            controller: _passCtrl,
                            hint: 'Enter your password',
                            obscure: _obscure,
                            onToggleObscure: () => setState(() => _obscure = !_obscure),
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Enter your password' : null,
                          ),
                          const SizedBox(height: 20),
                          AuthSubmitBtn(
                            loading: _loading,
                            label: lang.t('sign_in'),
                            loadingLabel: lang.t('signing_in'),
                            icon: Icons.login,
                            onPressed: _login,
                          ),
                          const SizedBox(height: 4),
                          const AuthDivider(),
                          AuthOutlineBtn(
                            label: lang.t('create_account'),
                            icon: Icons.person_add_outlined,
                            onPressed: () => Navigator.push(context,
                                MaterialPageRoute(builder: (_) => const RegisterScreen())),
                          ),
                          const SizedBox(height: 12),
                          Center(
                            child: GestureDetector(
                              onTap: () => Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => const RegisterScreen())),
                              child: RichText(
                                text: TextSpan(
                                  style: const TextStyle(fontSize: 12.5, color: authMuted),
                                  children: [
                                    TextSpan(text: '${lang.t('no_account')} '),
                                    TextSpan(text: lang.t('register'),
                                        style: const TextStyle(color: authLeaf, fontWeight: FontWeight.w700)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
          // Language switcher floating top-right
          Positioned(
            top: 8,
            right: 8,
            child: SafeArea(child: _LangBtn()),
          ),
        ],
      ),
    );
  }
}

// ── Compact language picker for dark auth screens ─────────────────────────
class _LangBtn extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final svc = LanguageService();
    return PopupMenuButton<String>(
      icon: const Icon(Icons.language, color: Colors.white70, size: 22),
      tooltip: 'Language',
      onSelected: (lang) => svc.setLanguage(lang),
      itemBuilder: (_) => LanguageService.languages.entries.map((e) {
        final sel = svc.lang == e.key;
        return PopupMenuItem<String>(
          value: e.key,
          child: Row(children: [
            if (sel) const Icon(Icons.check, color: Color(0xFF2A7525), size: 18)
            else const SizedBox(width: 18),
            const SizedBox(width: 8),
            Text(e.value, style: TextStyle(fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
          ]),
        );
      }).toList(),
    );
  }
}

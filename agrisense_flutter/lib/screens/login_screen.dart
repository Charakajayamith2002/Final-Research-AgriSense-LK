import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/auth_widgets.dart';
import 'home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
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
    return Scaffold(
      backgroundColor: authBg,
      body: SafeArea(
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
                      const AuthCardHeading(
                          title: 'Welcome back',
                          sub: 'Sign in to your AgriSense account'),
                      AuthField(
                        label: 'Email address',
                        icon: Icons.email_outlined,
                        controller: _emailCtrl,
                        hint: 'you@example.com',
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) =>
                            v == null || !v.contains('@') ? 'Enter a valid email' : null,
                      ),
                      const SizedBox(height: 12),
                      AuthField(
                        label: 'Password',
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
                        label: 'Sign In',
                        loadingLabel: 'Signing in…',
                        icon: Icons.login,
                        onPressed: _login,
                      ),
                      const SizedBox(height: 4),
                      const AuthDivider(),
                      AuthOutlineBtn(
                        label: 'Create a new account',
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
                            text: const TextSpan(
                              style: TextStyle(fontSize: 12.5, color: authMuted),
                              children: [
                                TextSpan(text: "Don't have an account? "),
                                TextSpan(text: 'Register',
                                    style: TextStyle(color: authLeaf, fontWeight: FontWeight.w700)),
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
    );
  }
}

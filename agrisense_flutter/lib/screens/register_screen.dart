import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/language_service.dart';
import '../theme/auth_widgets.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with LangMixin {
  final _formKey       = GlobalKey<FormState>();
  final _emailCtrl     = TextEditingController();
  final _usernameCtrl  = TextEditingController();
  final _passCtrl      = TextEditingController();
  final _confirmCtrl   = TextEditingController();
  String _userType     = 'buyer';
  bool _loading        = false;
  bool _obscure        = true;
  bool _obscureConfirm = true;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passCtrl.text != _confirmCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Passwords do not match'),
        backgroundColor: Colors.red,
      ));
      return;
    }
    setState(() => _loading = true);
    final result = await ApiService().register(
      _usernameCtrl.text.trim(),
      _emailCtrl.text.trim(),
      _passCtrl.text,
      _userType,
    );
    setState(() => _loading = false);
    if (!mounted) return;
    if (result['success'] == true) {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const HomeScreen()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result['message'] ?? 'Registration failed'),
        backgroundColor: Colors.red.shade700,
      ));
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose(); _usernameCtrl.dispose();
    _passCtrl.dispose(); _confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = LanguageService();
    return Scaffold(
      backgroundColor: authBg,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // ── Hero ──────────────────────────────────
                  AuthHeroSection(
                    headline: 'Your farm\'s AI\nadvantage\nstarts here.',
                    features: const [
                      AuthFeature(Icons.lightbulb_outline,     'Profitable Strategy', 'AI recommends the most profitable business type for your profile.'),
                      AuthFeature(Icons.trending_up,           'Price Forecasting',   'Know what your crop will fetch before harvest day.'),
                      AuthFeature(Icons.map_outlined,          'Market Ranking',      'Find the best market with lowest transport cost.'),
                      AuthFeature(Icons.grass,                 'Cultivation AI',      'AI tells you exactly what to plant next season.'),
                    ],
                  ),

                  // ── Card ──────────────────────────────────
                  AuthCard(
                    activeTab: 1,
                    onTabSwitch: () => Navigator.pushReplacement(context,
                        MaterialPageRoute(builder: (_) => const LoginScreen())),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AuthCardHeading(title: lang.t('create_acct_sub'), sub: ''),

                          // Account info
                          AuthSectionLabel(lang.t('account_info')),
                          Row(children: [
                            Expanded(child: AuthField(
                              label: lang.t('email'),
                              icon: Icons.email_outlined,
                              controller: _emailCtrl,
                              hint: 'you@example.com',
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) =>
                                  v == null || !v.contains('@') ? 'Enter a valid email' : null,
                            )),
                            const SizedBox(width: 10),
                            Expanded(child: AuthField(
                              label: lang.t('username'),
                              icon: Icons.person_outline,
                              controller: _usernameCtrl,
                              hint: 'Display name',
                              validator: (v) =>
                                  v == null || v.isEmpty ? 'Enter username' : null,
                            )),
                          ]),
                          const SizedBox(height: 14),

                          // Security
                          AuthSectionLabel(lang.t('security')),
                          Row(children: [
                            Expanded(child: AuthField(
                              label: lang.t('password'),
                              icon: Icons.lock_outline,
                              controller: _passCtrl,
                              hint: 'Min. 6 characters',
                              obscure: _obscure,
                              onToggleObscure: () => setState(() => _obscure = !_obscure),
                              validator: (v) =>
                                  v == null || v.length < 6 ? 'Min. 6 characters' : null,
                            )),
                            const SizedBox(width: 10),
                            Expanded(child: AuthField(
                              label: lang.t('confirm_password'),
                              icon: Icons.lock_outline,
                              controller: _confirmCtrl,
                              hint: 'Repeat password',
                              obscure: _obscureConfirm,
                              onToggleObscure: () => setState(() => _obscureConfirm = !_obscureConfirm),
                              validator: (v) =>
                                  v == null || v.isEmpty ? 'Confirm password' : null,
                            )),
                          ]),
                          const SizedBox(height: 16),

                          // User type
                          AuthSectionLabel(lang.t('i_am_a')),
                          Row(children: [
                            Expanded(child: UserTypeCard(
                              icon: '🛒',
                              title: lang.t('buyer'),
                              sub: 'Purchase crops & products',
                              selected: _userType == 'buyer',
                              onTap: () => setState(() => _userType = 'buyer'),
                            )),
                            const SizedBox(width: 10),
                            Expanded(child: UserTypeCard(
                              icon: '🌾',
                              title: lang.t('seller'),
                              sub: 'Sell & manage produce',
                              selected: _userType == 'seller',
                              onTap: () => setState(() => _userType = 'seller'),
                            )),
                          ]),
                          const SizedBox(height: 18),

                          AuthSubmitBtn(
                            loading: _loading,
                            label: lang.t('create_account'),
                            loadingLabel: lang.t('creating_acct'),
                            icon: Icons.person_add_outlined,
                            onPressed: _register,
                          ),
                          const SizedBox(height: 12),
                          Center(
                            child: GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: RichText(
                                text: TextSpan(
                                  style: const TextStyle(fontSize: 12.5, color: authMuted),
                                  children: [
                                    TextSpan(text: '${lang.t('already_account')} '),
                                    TextSpan(text: lang.t('sign_in'),
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

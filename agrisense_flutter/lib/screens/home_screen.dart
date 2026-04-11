import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/language_service.dart';
import '../widgets/language_switcher.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';
import 'price_demand_screen.dart';
import 'market_ranking_screen.dart';
import 'cultivation_targeting_screen.dart';
import 'yield_quality_screen.dart';
import 'profitable_strategy_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _username = 'User';

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() { _username = prefs.getString('username') ?? 'User'; });
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Logout')),
        ],
      ),
    );
    if (confirm == true) {
      await ApiService().logout();
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      }
    }
  }

  List<Map<String, dynamic>> get _features {
    final lang = LanguageService();
    return [
      {
        'title': lang.t('price_demand'),
        'subtitle': lang.t('price_demand_sub'),
        'icon': Icons.trending_up,
        'color': AppColors.g600,
        'screen': const PriceDemandScreen(),
      },
      {
        'title': lang.t('market_ranking'),
        'subtitle': lang.t('market_ranking_sub'),
        'icon': Icons.map_outlined,
        'color': AppColors.g700,
        'screen': const MarketRankingScreen(),
      },
      {
        'title': lang.t('cultivation'),
        'subtitle': lang.t('cultivation_sub'),
        'icon': Icons.grass,
        'color': AppColors.g500,
        'screen': const CultivationTargetingScreen(),
      },
      {
        'title': lang.t('yield_quality'),
        'subtitle': lang.t('yield_quality_sub'),
        'icon': Icons.photo_camera_outlined,
        'color': AppColors.g400,
        'screen': const YieldQualityScreen(),
      },
      {
        'title': lang.t('profitable_strategy'),
        'subtitle': lang.t('profitable_strategy_sub'),
        'icon': Icons.lightbulb_outline,
        'color': AppColors.g600,
        'screen': const ProfitableStrategyScreen(),
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final lang = LanguageService();
    return Scaffold(
      backgroundColor: AppColors.g50,
      appBar: AppBar(
        backgroundColor: AppColors.g600,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.eco, color: Colors.white, size: 22),
            SizedBox(width: 8),
            Text('AgriSense LK', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
          ],
        ),
        actions: [
          const LanguageSwitcher(),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'History',
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const HistoryScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Profile',
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Welcome Banner ──────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.g700, AppColors.g500],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(13),
                boxShadow: const [
                  BoxShadow(color: Color(0x331E571A), blurRadius: 18, offset: Offset(0, 6)),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${lang.t('welcome_back')}, $_username!',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          lang.t('predict_today'),
                          style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 54, height: 54,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.agriculture, color: Colors.white, size: 28),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Section Label ───────────────────────────
            const Text(
              'AI FEATURES',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: AppColors.g500,
              ),
            ),
            const SizedBox(height: 2),
            Container(height: 1, color: AppColors.g100),
            const SizedBox(height: 14),

            // ── Feature Cards Grid ──────────────────────
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.92,
              ),
              itemCount: _features.length,
              itemBuilder: (context, index) {
                final f = _features[index];
                return _FeatureCard(
                  title: f['title'],
                  subtitle: f['subtitle'],
                  icon: f['icon'],
                  color: f['color'],
                  onTap: () => Navigator.push(
                      context, MaterialPageRoute(builder: (_) => f['screen'])),
                );
              },
            ),
            const SizedBox(height: 24),

            // ── Quick Access ────────────────────────────
            const Text(
              'QUICK ACCESS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: AppColors.g500,
              ),
            ),
            const SizedBox(height: 2),
            Container(height: 1, color: AppColors.g100),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: _QuickCard(
                  icon: Icons.history,
                  label: 'View History',
                  onTap: () => Navigator.push(
                      context, MaterialPageRoute(builder: (_) => const HistoryScreen())),
                )),
                const SizedBox(width: 12),
                Expanded(child: _QuickCard(
                  icon: Icons.person_outline,
                  label: 'My Profile',
                  onTap: () => Navigator.push(
                      context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
                )),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.bdr),
        boxShadow: const [
          BoxShadow(color: Color(0x0D34912F), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(height: 12),
              Text(title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                    color: AppColors.textDark,
                  )),
              const SizedBox(height: 4),
              Text(subtitle,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
              const Spacer(),
              Row(children: [
                Text('Predict',
                    style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
                const SizedBox(width: 3),
                Icon(Icons.arrow_forward_ios, size: 10, color: color),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickCard({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.bdr),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          child: Row(children: [
            Icon(icon, color: AppColors.g600, size: 20),
            const SizedBox(width: 10),
            Text(label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                  fontSize: 13.5,
                )),
          ]),
        ),
      ),
    );
  }
}

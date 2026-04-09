import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/language_service.dart';
import '../widgets/language_switcher.dart';
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
    setState(() {
      _username = prefs.getString('username') ?? 'User';
    });
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
        'color': const Color(0xFF1565C0),
        'screen': const PriceDemandScreen(),
      },
      {
        'title': lang.t('market_ranking'),
        'subtitle': lang.t('market_ranking_sub'),
        'icon': Icons.store,
        'color': const Color(0xFF6A1B9A),
        'screen': const MarketRankingScreen(),
      },
      {
        'title': lang.t('cultivation'),
        'subtitle': lang.t('cultivation_sub'),
        'icon': Icons.grass,
        'color': const Color(0xFF2E7D32),
        'screen': const CultivationTargetingScreen(),
      },
      {
        'title': lang.t('yield_quality'),
        'subtitle': lang.t('yield_quality_sub'),
        'icon': Icons.photo_camera,
        'color': const Color(0xFFE65100),
        'screen': const YieldQualityScreen(),
      },
      {
        'title': lang.t('profitable_strategy'),
        'subtitle': lang.t('profitable_strategy_sub'),
        'icon': Icons.lightbulb,
        'color': const Color(0xFFF9A825),
        'screen': const ProfitableStrategyScreen(),
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final lang = LanguageService();
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8E9),
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.eco, color: Colors.white),
            SizedBox(width: 8),
            Text('AgriSense LK'),
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
            icon: const Icon(Icons.person),
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
            // Welcome Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${lang.t('welcome_back')}, $_username!',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(lang.t('predict_today'),
                            style: const TextStyle(color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ),
                  const Icon(Icons.agriculture, color: Colors.white54, size: 50),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(lang.t('ai_features'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
            const SizedBox(height: 12),
            // Feature Cards Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.95,
              ),
              itemCount: _features.length,
              itemBuilder: (context, index) {
                final feature = _features[index];
                return _FeatureCard(
                  title: feature['title'],
                  subtitle: feature['subtitle'],
                  icon: feature['icon'],
                  color: feature['color'],
                  onTap: () => Navigator.push(
                      context, MaterialPageRoute(builder: (_) => feature['screen'])),
                );
              },
            ),
            const SizedBox(height: 24),
            // Quick Stats Row
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.history,
                    label: 'View History',
                    color: const Color(0xFF0288D1),
                    onTap: () => Navigator.push(
                        context, MaterialPageRoute(builder: (_) => const HistoryScreen())),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.person,
                    label: 'My Profile',
                    color: const Color(0xFF6A1B9A),
                    onTap: () => Navigator.push(
                        context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
                  ),
                ),
              ],
            ),
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
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 4),
              Text(subtitle,
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
              const Spacer(),
              Row(
                children: [
                  Text('Predict', style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
                  Icon(Icons.arrow_forward_ios, size: 10, color: color),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _StatCard({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 10),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

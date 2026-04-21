import 'package:flutter/material.dart';
import '../services/language_service.dart';
import '../widgets/language_switcher.dart';

class ProfitableStrategyResultScreen extends StatefulWidget {
  final Map<String, dynamic> data;
  const ProfitableStrategyResultScreen({super.key, required this.data});

  @override
  State<ProfitableStrategyResultScreen> createState() =>
      _ProfitableStrategyResultScreenState();
}

class _ProfitableStrategyResultScreenState
    extends State<ProfitableStrategyResultScreen> with LangMixin {
  static const Color _green   = Color(0xFF1B5E20);
  static const Color _green2  = Color(0xFF2E7D32);
  static const Color _green3  = Color(0xFF388E3C);
  static const Color _bg      = Color(0xFFF1F8E9);

  @override
  Widget build(BuildContext context) {
    final lang = LanguageService();
    final d = widget.data;

    final String bizName   = d['predicted_business_name'] ?? '';
    final String bizCode   = d['predicted_business_code'] ?? '';
    final double conf      = ((d['confidence'] ?? 0) as num).toDouble();
    final String confLevel = d['confidence_level'] ?? '';
    final String risk      = d['risk_level'] ?? '';
    final String capital   = d['capital_required'] ?? '';
    final String desc      = d['description'] ?? '';
    final List<String> considerations =
        List<String>.from(d['key_considerations'] ?? []);
    final List<String> challenges =
        List<String>.from(d['potential_challenges'] ?? []);
    final List<dynamic> topPredictions =
        List<dynamic>.from(d['top_predictions'] ?? []);

    // Alternatives = top_predictions excluding the first (main prediction)
    final List<Map<String, dynamic>> alternatives = topPredictions.length > 1
        ? topPredictions
            .skip(1)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList()
        : [];

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: Text(lang.t('ps_result_title')),
        backgroundColor: _green2,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: const [LanguageSwitcher()],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero card ─────────────────────────────────────
            _HeroCard(
              lang: lang,
              bizName: bizName,
              bizCode: bizCode,
              conf: conf,
              confLevel: confLevel,
              risk: risk,
              capital: capital,
            ),
            const SizedBox(height: 16),

            // ── Description ───────────────────────────────────
            _SectionCard(
              icon: Icons.info_outline,
              title: lang.t('ps_res_description'),
              child: Text(desc,
                  style: const TextStyle(fontSize: 14, height: 1.5,
                      color: Color(0xFF424242))),
            ),
            const SizedBox(height: 12),

            // ── Considerations & Challenges ───────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _SectionCard(
                  icon: Icons.check_circle_outline,
                  title: lang.t('ps_res_consider'),
                  child: _BulletList(items: considerations, color: _green2),
                )),
                const SizedBox(width: 12),
                Expanded(child: _SectionCard(
                  icon: Icons.warning_amber_outlined,
                  title: lang.t('ps_res_challenges'),
                  child: _BulletList(
                      items: challenges, color: Colors.red.shade600),
                )),
              ],
            ),
            const SizedBox(height: 12),

            // ── Alternative Options ───────────────────────────
            if (alternatives.isNotEmpty) ...[
              _SectionCard(
                icon: Icons.compare_arrows,
                title: lang.t('ps_res_alternatives'),
                child: Column(
                  children: alternatives.asMap().entries.map((entry) {
                    final idx = entry.key + 2; // #2, #3, …
                    final alt = entry.value;
                    final altConf =
                        ((alt['confidence'] ?? 0) as num).toDouble();
                    return _AltCard(
                      rank: idx,
                      name: alt['business_name'] ?? '',
                      code: alt['business_code'] ?? '',
                      confidence: altConf,
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // ── Confidence Distribution chart ─────────────────
            _SectionCard(
              icon: Icons.bar_chart,
              title: lang.t('ps_res_conf_dist'),
              child: _ConfidenceChart(
                predictions: topPredictions
                    .map((e) => Map<String, dynamic>.from(e as Map))
                    .toList(),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ─── Hero card ────────────────────────────────────────────────
class _HeroCard extends StatelessWidget {
  final LanguageService lang;
  final String bizName, bizCode, confLevel, risk, capital;
  final double conf;

  const _HeroCard({
    required this.lang,
    required this.bizName,
    required this.bizCode,
    required this.conf,
    required this.confLevel,
    required this.risk,
    required this.capital,
  });

  Color get _confColor {
    if (confLevel.toLowerCase() == 'high') return const Color(0xFF388E3C);
    if (confLevel.toLowerCase() == 'medium') return const Color(0xFFF57C00);
    return const Color(0xFFC62828);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF388E3C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B5E20).withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                  color: Colors.white.withOpacity(0.5), width: 1),
            ),
            child: Text(
              lang.t('ps_res_ai_rec'),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2),
            ),
          ),
          const SizedBox(height: 12),

          // Strategy name
          Text(bizName,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  height: 1.2)),
          const SizedBox(height: 4),
          Text(bizCode,
              style: const TextStyle(
                  color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 16),

          // Confidence bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${lang.t('ps_res_confidence')}: ${(conf * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(color: Colors.white, fontSize: 13)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _confColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(confLevel,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: conf.clamp(0.0, 1.0),
              backgroundColor: Colors.white.withOpacity(0.25),
              valueColor:
                  AlwaysStoppedAnimation<Color>(_confColor),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 16),

          // Info boxes
          Row(
            children: [
              Expanded(child: _InfoBox(
                  label: lang.t('ps_res_risk_level'), value: risk)),
              const SizedBox(width: 8),
              Expanded(child: _InfoBox(
                  label: lang.t('ps_res_capital'), value: capital)),
              const SizedBox(width: 8),
              Expanded(child: _InfoBox(
                  label: lang.t('ps_res_biz_code'), value: bizCode)),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final String label, value;
  const _InfoBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: Colors.white70, fontSize: 9, letterSpacing: 0.5)),
          const SizedBox(height: 3),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// ─── Section card ─────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  const _SectionCard(
      {required this.icon, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, color: const Color(0xFF2E7D32), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32))),
              ),
            ]),
            const Divider(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

// ─── Bullet list ──────────────────────────────────────────────
class _BulletList extends StatelessWidget {
  final List<String> items;
  final Color color;
  const _BulletList({required this.items, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((item) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Container(
                  width: 6, height: 6,
                  decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle)),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(item,
                style: const TextStyle(fontSize: 13, height: 1.4,
                    color: Color(0xFF424242)))),
          ],
        ),
      )).toList(),
    );
  }
}

// ─── Alternative option card ──────────────────────────────────
class _AltCard extends StatelessWidget {
  final int rank;
  final String name, code;
  final double confidence;
  const _AltCard(
      {required this.rank,
      required this.name,
      required this.code,
      required this.confidence});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8E9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFA5D6A7)),
      ),
      child: Row(
        children: [
          // Rank badge
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32),
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: Text('#$rank',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                Text(code,
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 11)),
              ],
            ),
          ),
          // Confidence badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF388E3C).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF388E3C).withOpacity(0.4)),
            ),
            child: Text(
              '${(confidence * 100).toStringAsFixed(0)}%',
              style: const TextStyle(
                  color: Color(0xFF2E7D32),
                  fontWeight: FontWeight.bold,
                  fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Confidence distribution bar chart ───────────────────────
class _ConfidenceChart extends StatelessWidget {
  final List<Map<String, dynamic>> predictions;
  const _ConfidenceChart({required this.predictions});

  @override
  Widget build(BuildContext context) {
    if (predictions.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      children: predictions.asMap().entries.map((entry) {
        final idx = entry.key;
        final p = entry.value;
        final conf = ((p['confidence'] ?? 0) as num).toDouble().clamp(0.0, 1.0);
        final name = p['business_name'] as String? ?? '';
        final isFirst = idx == 0;

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              SizedBox(
                width: 140,
                child: Text(
                  name,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: isFirst
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isFirst
                          ? const Color(0xFF1B5E20)
                          : const Color(0xFF616161)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      height: 18,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: conf,
                      child: Container(
                        height: 18,
                        decoration: BoxDecoration(
                          color: isFirst
                              ? const Color(0xFF2E7D32)
                              : const Color(0xFF81C784),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: 38,
                child: Text(
                  '${(conf * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: isFirst
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isFirst
                          ? const Color(0xFF1B5E20)
                          : const Color(0xFF757575)),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

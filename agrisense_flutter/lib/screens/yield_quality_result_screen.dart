import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/language_service.dart';
import '../widgets/language_switcher.dart';
import '../theme/app_theme.dart';

class YieldQualityResultScreen extends StatefulWidget {
  final Map<String, dynamic> data;
  final List<XFile> images;

  const YieldQualityResultScreen({
    super.key,
    required this.data,
    required this.images,
  });

  @override
  State<YieldQualityResultScreen> createState() =>
      _YieldQualityResultScreenState();
}

class _YieldQualityResultScreenState extends State<YieldQualityResultScreen>
    with LangMixin {
  // ── Helpers ──────────────────────────────────────────────
  String _gradeLabel(String grade, LanguageService lang) {
    switch (grade) {
      case 'Grade_A':
        return lang.t('yq_grade_a');
      case 'Grade_B':
        return lang.t('yq_grade_b');
      case 'Grade_C':
        return lang.t('yq_grade_c');
      default:
        return lang.t('yq_grade_rotten');
    }
  }

  Color _gradeColor(String grade) {
    switch (grade) {
      case 'Grade_A':
        return const Color(0xFF16A34A);
      case 'Grade_B':
        return const Color(0xFF2563EB);
      case 'Grade_C':
        return const Color(0xFFD97706);
      default:
        return const Color(0xFFDC2626);
    }
  }

  IconData _gradeIcon(String grade) {
    switch (grade) {
      case 'Grade_A':
        return Icons.workspace_premium;
      case 'Grade_B':
        return Icons.thumb_up_outlined;
      case 'Grade_C':
        return Icons.remove_circle_outline;
      default:
        return Icons.warning_amber_outlined;
    }
  }

  String _gradeDisplayText(String grade) {
    switch (grade) {
      case 'Grade_A':
        return 'A';
      case 'Grade_B':
        return 'B';
      case 'Grade_C':
        return 'C';
      default:
        return '✕';
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = LanguageService();
    final d = widget.data;

    final String predictedClass = d['predicted_class'] ?? 'Grade_C';
    final double meanProb =
        (d['mean_probability'] as num?)?.toDouble() ?? 0.0;
    final double bestUnitPrice =
        (d['best_unit_price'] as num?)?.toDouble() ?? 0.0;
    final int numImages = (d['num_images'] as num?)?.toInt() ?? 0;
    final String uploadTime = d['upload_time'] ?? '';
    final List<dynamic> indProbs = d['individual_probabilities'] ?? [];
    final List<dynamic> indClasses = d['individual_classes'] ?? [];
    final double predictedUnitPrice = meanProb * bestUnitPrice;
    final gradeColor = _gradeColor(predictedClass);

    return Scaffold(
      backgroundColor: AppColors.g50,
      appBar: AppBar(
        title: Text(lang.t('yq_res_title')),
        backgroundColor: AppColors.g600,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: const [LanguageSwitcher()],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ── Header subtitle ──────────────────────────
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.g100,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: AppColors.bdr),
              ),
              child: Row(children: [
                const Icon(Icons.check_circle,
                    color: AppColors.g600, size: 16),
                const SizedBox(width: 8),
                Text(
                  '${lang.t('yq_res_subtitle')} — $numImages ${lang.t('yq_res_images_analyzed')}',
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.g700,
                      fontWeight: FontWeight.w600),
                ),
              ]),
            ),
            const SizedBox(height: 16),

            // ── Grade Hero Card ──────────────────────────
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    gradeColor,
                    gradeColor.withOpacity(0.75),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                      color: gradeColor.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4))
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                // Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: Colors.white.withOpacity(0.4)),
                  ),
                  child: Text(
                    lang.t('yq_res_grade_header').toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2),
                  ),
                ),
                const SizedBox(height: 16),
                // Grade circle
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white.withOpacity(0.5), width: 2),
                  ),
                  child: Center(
                    child: Text(
                      _gradeDisplayText(predictedClass),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(_gradeIcon(predictedClass),
                      color: Colors.white, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    _gradeLabel(predictedClass, lang),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700),
                  ),
                ]),
                const SizedBox(height: 16),
                // Confidence bar
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(lang.t('yq_res_confidence'),
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.85),
                                fontSize: 12)),
                        Text('${(meanProb * 100).toStringAsFixed(1)}%',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700)),
                      ]),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: meanProb.clamp(0.0, 1.0),
                      backgroundColor: Colors.white.withOpacity(0.25),
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.white),
                      minHeight: 8,
                    ),
                  ),
                ]),
              ]),
            ),
            const SizedBox(height: 16),

            // ── Stats Row ────────────────────────────────
            Row(children: [
              Expanded(
                  child: _statBox(
                      Icons.access_time_outlined,
                      lang.t('yq_res_timestamp'),
                      uploadTime.isEmpty ? '—' : uploadTime.split(' ').first,
                      AppColors.g600)),
              const SizedBox(width: 10),
              Expanded(
                  child: _statBox(
                      Icons.photo_library_outlined,
                      lang.t('yq_res_img_count'),
                      numImages.toString(),
                      AppColors.g600)),
              const SizedBox(width: 10),
              Expanded(
                  child: _statBox(
                      Icons.analytics_outlined,
                      lang.t('yq_res_avg_conf'),
                      '${(meanProb * 100).toStringAsFixed(1)}%',
                      AppColors.g600)),
            ]),
            const SizedBox(height: 16),

            // ── Metrics Grid ─────────────────────────────
            FlaskCard(
              icon: Icons.bar_chart_outlined,
              title: 'Analysis Metrics',
              children: [
                Row(children: [
                  Expanded(
                      child: _metricBox(
                          lang.t('yq_res_mean_prob'),
                          '${(meanProb * 100).toStringAsFixed(2)}%',
                          Icons.percent,
                          AppColors.g600)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _metricBox(
                          lang.t('yq_res_img_count'),
                          numImages.toString(),
                          Icons.image_outlined,
                          Colors.blue)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _metricBox(
                          '${lang.t('yq_res_market_rate')} (Rs.)',
                          'Rs. ${bestUnitPrice.toStringAsFixed(0)}${lang.t('yq_res_per_kg')}',
                          Icons.monetization_on_outlined,
                          Colors.orange)),
                ]),
              ],
            ),
            const SizedBox(height: 16),

            // ── Predicted Price Card ─────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.bdr),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2))
                ],
              ),
              child: Row(children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.g100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.price_check,
                      color: AppColors.g600, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(lang.t('yq_res_pred_price'),
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMedium,
                              fontWeight: FontWeight.w500)),
                      const SizedBox(height: 2),
                      Text(
                        'Rs. ${predictedUnitPrice.toStringAsFixed(2)} / kg',
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.g700),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: gradeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: gradeColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    predictedClass.replaceAll('_', ' '),
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: gradeColor),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 16),

            // ── Individual Image Results ─────────────────
            if (widget.images.isNotEmpty) ...[
              FlaskCard(
                icon: Icons.photo_library_outlined,
                title: lang.t('yq_res_img_results'),
                children: [
                  ...List.generate(widget.images.length, (i) {
                    final prob = i < indProbs.length
                        ? (indProbs[i] as num).toDouble()
                        : 0.0;
                    final cls = i < indClasses.length
                        ? indClasses[i] as String
                        : 'Grade_C';
                    final clsColor = _gradeColor(cls);
                    return Padding(
                      padding: EdgeInsets.only(
                          bottom: i < widget.images.length - 1 ? 12 : 0),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.g50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.bdr),
                        ),
                        child: Row(children: [
                          // Thumbnail
                          FutureBuilder<dynamic>(
                            future: widget.images[i].readAsBytes(),
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.memory(
                                    snapshot.data!,
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                  ),
                                );
                              }
                              return Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: AppColors.g100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                      color: AppColors.g400,
                                      strokeWidth: 2),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${lang.t('yq_res_image')} ${i + 1}',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textDark),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color:
                                              clsColor.withOpacity(0.12),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          border: Border.all(
                                              color: clsColor
                                                  .withOpacity(0.3)),
                                        ),
                                        child: Text(
                                          cls.replaceAll('_', ' '),
                                          style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: clsColor),
                                        ),
                                      ),
                                    ]),
                                const SizedBox(height: 6),
                                Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        lang.t('yq_res_confidence'),
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textMuted),
                                      ),
                                      Text(
                                        '${(prob * 100).toStringAsFixed(1)}%',
                                        style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: clsColor),
                                      ),
                                    ]),
                                const SizedBox(height: 4),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(3),
                                  child: LinearProgressIndicator(
                                    value: prob.clamp(0.0, 1.0),
                                    backgroundColor: AppColors.g100,
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(
                                            clsColor),
                                    minHeight: 6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ]),
                      ),
                    );
                  }),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statBox(
      IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.bdr),
      ),
      child: Column(children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(
                fontSize: 10,
                color: AppColors.textMuted),
            textAlign: TextAlign.center),
      ]),
    );
  }

  Widget _metricBox(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 6),
        Text(value,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: color)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(
                fontSize: 10, color: AppColors.textMuted)),
      ]),
    );
  }
}

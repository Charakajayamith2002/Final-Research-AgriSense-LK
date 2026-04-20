import 'package:flutter/material.dart';
import '../services/language_service.dart';
import '../widgets/language_switcher.dart';

class CultivationTargetingResultScreen extends StatefulWidget {
  final Map<String, dynamic> data;
  const CultivationTargetingResultScreen({super.key, required this.data});

  @override
  State<CultivationTargetingResultScreen> createState() =>
      _CultivationTargetingResultScreenState();
}

class _CultivationTargetingResultScreenState
    extends State<CultivationTargetingResultScreen> with LangMixin {
  static const Color _green  = Color(0xFF1B5E20);
  static const Color _green2 = Color(0xFF2E7D32);
  static const Color _green3 = Color(0xFF388E3C);
  static const Color _bg     = Color(0xFFF1F8E9);

  List<Map<String, dynamic>> get _recs =>
      List<Map<String, dynamic>>.from(
          (widget.data['recommendations'] as List? ?? [])
              .map((e) => Map<String, dynamic>.from(e as Map)));

  Map<String, dynamic> get _weather =>
      Map<String, dynamic>.from(
          widget.data['weather'] as Map? ?? {});

  List<Map<String, dynamic>> get _forecast =>
      List<Map<String, dynamic>>.from(
          (widget.data['forecast'] as List? ?? [])
              .map((e) => Map<String, dynamic>.from(e as Map)));

  int get _month =>
      (widget.data['optimal_month'] as num? ?? 1).toInt();

  String get _season =>
      widget.data['season'] as String? ?? '';

  int get _totalRecs =>
      (widget.data['total_recommendations'] as num? ?? _recs.length).toInt();

  double get _avgProfit {
    if (_recs.isEmpty) return 0;
    return _recs.fold<double>(
            0, (s, r) => s + ((r['profitability_score'] as num? ?? 0).toDouble())) /
        _recs.length;
  }

  double get _avgRisk {
    if (_recs.isEmpty) return 0;
    return _recs.fold<double>(
            0, (s, r) => s + ((r['risk_score'] as num? ?? 0).toDouble())) /
        _recs.length;
  }

  // WMO weather code → description
  String _weatherDesc(int code) {
    if (code == 0) return 'Clear sky with mild conditions';
    if (code <= 3) return 'Partly cloudy conditions';
    if (code <= 49) return 'Foggy conditions';
    if (code <= 67) return 'Rainy conditions';
    if (code <= 77) return 'Snowy conditions';
    if (code <= 82) return 'Showery conditions';
    if (code <= 99) return 'Thunderstorm conditions';
    return 'Mixed conditions';
  }

  // Forecast condition from weather code
  String _forecastCond(int code, double humMax) {
    if (humMax >= 95) return 'Very Humid';
    if (humMax >= 85) return 'High Humidity';
    if (code >= 51 && code <= 82) return 'Rainy';
    if (code >= 95) return 'Thunderstorm';
    if (code == 0) return 'Excellent';
    if (code <= 3) return 'Good';
    return 'Monitor';
  }

  Color _condColor(String cond) {
    switch (cond) {
      case 'Excellent': return const Color(0xFF2E7D32);
      case 'Good':      return const Color(0xFF388E3C);
      case 'Monitor':   return const Color(0xFFF57C00);
      case 'Rainy':     return const Color(0xFF1565C0);
      case 'High Humidity':
      case 'Very Humid':return const Color(0xFF7B1FA2);
      default:          return const Color(0xFFC62828);
    }
  }

  List<String> _cultivationImpact(double temp, int humidity) {
    final items = <String>[];
    if (temp >= 18 && temp <= 28) {
      items.add('favorable|Favorable: Ideal temperature for most crops');
    } else if (temp < 15) {
      items.add('warning|Warning: Low temperatures may slow growth');
    } else if (temp > 32) {
      items.add('alert|Heat Alert: High temperatures may stress plants');
    }
    if (humidity > 80) {
      items.add('monitor|Monitor: High humidity may increase fungal risk');
    } else if (humidity < 40) {
      items.add('caution|Irrigation: Low humidity increases water requirements');
    }
    items.add('good|Good: Low wind speed protects young plants');
    return items;
  }

  String _weatherTips(double temp, int humidity) {
    if (humidity > 80 && temp >= 20 && temp <= 30) {
      return 'Focus on leafy vegetables like cabbage.\nReduce water-intensive crops.';
    }
    if (temp > 30) {
      return 'Plant drought-tolerant crops. Ensure adequate irrigation.';
    }
    if (temp < 18) {
      return 'Focus on cool-season crops. Protect young plants from cold.';
    }
    return 'Consistent temperatures ideal for most crops. Maintain regular irrigation.';
  }

  @override
  Widget build(BuildContext context) {
    final lang = LanguageService();
    final recs = _recs;
    final weather = _weather;
    final forecast = _forecast;
    final topPick = recs.isNotEmpty ? recs[0] : null;

    final temp = (weather['temperature'] as num? ?? 25).toDouble();
    final humidity = (weather['humidity'] as num? ?? 70).toInt();
    final precip = (weather['precipitation'] as num? ?? 0).toDouble();
    final wind = (weather['wind_speed'] as num? ?? 10).toDouble();
    final soilTemp = (weather['soil_temp'] as num? ?? 24).toDouble();
    final lat = (weather['latitude'] as num? ?? 7.75).toDouble();
    final lon = (weather['longitude'] as num? ?? 80.75).toDouble();
    final code = (weather['weather_code'] as num? ?? 0).toInt();

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: Text(lang.t('ct_result_title')),
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
            // ── Current Weather card ───────────────────
            _weatherCard(lang, temp, humidity, precip, wind, soilTemp, lat, lon, code),
            const SizedBox(height: 16),

            // ── Recommendation Summary ─────────────────
            _summaryCard(lang, topPick, temp, humidity),
            const SizedBox(height: 16),

            // ── All Crop Recommendations ───────────────
            _allCropsCard(lang, recs),
            const SizedBox(height: 16),

            // ── 7-Day Forecast ─────────────────────────
            if (forecast.isNotEmpty) _forecastCard(lang, forecast),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── Weather card ──────────────────────────────────────────
  Widget _weatherCard(LanguageService lang, double temp, int humidity,
      double precip, double wind, double soilTemp, double lat, double lon, int code) {
    final impacts = _cultivationImpact(temp, humidity);
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A3A1A), Color(0xFF1B5E20), Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: _green.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label + icon
          Row(children: [
            const Icon(Icons.wb_sunny_outlined, color: Colors.amber, size: 22),
            const SizedBox(width: 8),
            Text(lang.t('ct_res_weather'),
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1)),
          ]),
          const SizedBox(height: 8),

          // Temperature
          Text('${temp.toStringAsFixed(1)}°C',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  height: 1)),
          const SizedBox(height: 4),
          Text(_weatherDesc(code),
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
          Text('Lat: ${lat.toStringAsFixed(2)}°N, Lon: ${lon.toStringAsFixed(2)}°E',
              style: const TextStyle(color: Colors.white54, fontSize: 11)),
          const SizedBox(height: 14),

          // Metrics grid
          Row(children: [
            Expanded(child: _WeatherMetric(
                label: lang.t('ct_res_humidity'),
                value: '$humidity%')),
            Expanded(child: _WeatherMetric(
                label: lang.t('ct_res_wind'),
                value: '${wind.toStringAsFixed(1)} km/h')),
            Expanded(child: _WeatherMetric(
                label: lang.t('ct_res_precip'),
                value: '${precip.toStringAsFixed(2)} mm')),
            Expanded(child: _WeatherMetric(
                label: lang.t('ct_res_soil_temp'),
                value: '${soilTemp.toStringAsFixed(1)}°C')),
          ]),
          const SizedBox(height: 16),

          // Cultivation impact
          Row(children: [
            const Icon(Icons.trending_up, color: Colors.white70, size: 14),
            const SizedBox(width: 6),
            Text(lang.t('ct_res_impact'),
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8)),
          ]),
          const SizedBox(height: 8),
          ...impacts.map((item) {
            final parts = item.split('|');
            final type = parts[0];
            final text = parts.length > 1 ? parts[1] : item;
            Color bar;
            switch (type) {
              case 'favorable':
              case 'good':
                bar = const Color(0xFF66BB6A); break;
              case 'monitor':
              case 'caution':
                bar = const Color(0xFFFFB300); break;
              default:
                bar = const Color(0xFFEF5350);
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(children: [
                Container(
                    width: 3, height: 28,
                    decoration: BoxDecoration(
                        color: bar,
                        borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 8),
                Expanded(child: Text(text,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 12, height: 1.3))),
              ]),
            );
          }).toList(),
        ],
      ),
    );
  }

  // ── Recommendation Summary ────────────────────────────────
  Widget _summaryCard(LanguageService lang,
      Map<String, dynamic>? topPick, double temp, int humidity) {
    if (topPick == null) return const SizedBox.shrink();
    final crop = topPick['crop'] as String? ?? '';
    final profit = (topPick['profitability_score'] as num? ?? 0).toDouble();
    final risk = (topPick['risk_score'] as num? ?? 0).toDouble();
    final timeline = topPick['planting_timeline'] as String? ?? '';
    final revenue = (topPick['expected_revenue'] as num? ?? 0).toDouble();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.bar_chart, color: _green2, size: 18),
              const SizedBox(width: 8),
              Text(lang.t('ct_res_rec_summary'),
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: _green2)),
            ]),
            const Divider(height: 16),

            // Season + month hero
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    vertical: 14, horizontal: 24),
                decoration: BoxDecoration(
                  color: _bg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFC8E6C9)),
                ),
                child: Column(children: [
                  Text('$_season Season'.toUpperCase(),
                      style: const TextStyle(
                          color: _green2,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0)),
                  const SizedBox(height: 4),
                  Text('$_month',
                      style: const TextStyle(
                          color: _green,
                          fontSize: 32,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text('$_totalRecs ${lang.t('ct_res_crops_rec')}',
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 12)),
                ]),
              ),
            ),
            const SizedBox(height: 14),

            // Top pick card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFFF57C00).withOpacity(0.5)),
                boxShadow: [
                  BoxShadow(
                      color: const Color(0xFFF57C00).withOpacity(0.1),
                      blurRadius: 6)
                ],
              ),
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF57C00),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.emoji_events,
                              color: Colors.white, size: 12),
                          const SizedBox(width: 4),
                          Text(lang.t('ct_res_top_pick'),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold)),
                        ]),
                  ),
                  const SizedBox(height: 10),
                  Text(crop,
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF212121))),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(lang.t('ct_res_profitability'),
                            style: const TextStyle(
                                fontSize: 10, color: Colors.grey)),
                        Text('${profit.toStringAsFixed(2)} / 1.0',
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: _green2)),
                      ],
                    )),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(lang.t('ct_res_risk'),
                            style: const TextStyle(
                                fontSize: 10, color: Colors.grey)),
                        Text('${risk.toStringAsFixed(2)} / 1.0',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: risk > 0.5
                                    ? Colors.red.shade600
                                    : const Color(0xFFF57C00))),
                      ],
                    )),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    const Icon(Icons.grass, color: _green2, size: 13),
                    const SizedBox(width: 5),
                    Expanded(child: Text(timeline,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF424242)))),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Avg stats
            Row(children: [
              Expanded(child: _AvgStat(
                  label: lang.t('ct_res_avg_profit'),
                  value: _avgProfit.toStringAsFixed(2))),
              const SizedBox(width: 12),
              Expanded(child: _AvgStat(
                  label: lang.t('ct_res_avg_risk'),
                  value: _avgRisk.toStringAsFixed(2))),
            ]),
            const SizedBox(height: 12),

            // Weather tips
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F8E9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFA5D6A7)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.wb_cloudy_outlined,
                      color: _green2, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(lang.t('ct_res_weather_tips'),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: _green2)),
                      const SizedBox(height: 4),
                      Text(_weatherTips(temp, humidity),
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF424242),
                              height: 1.5)),
                    ],
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── All Crops grid ────────────────────────────────────────
  Widget _allCropsCard(
      LanguageService lang, List<Map<String, dynamic>> recs) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            child: Row(children: [
              const Icon(Icons.list_alt, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(lang.t('ct_res_all_crops'),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 0.85,
              children: recs.map((rec) {
                final rank = (rec['rank'] as num? ?? 0).toInt();
                final isTop = rank == 1;
                return _CropCard(rec: rec, isTop: isTop, lang: lang);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ── 7-Day Forecast ────────────────────────────────────────
  Widget _forecastCard(
      LanguageService lang, List<Map<String, dynamic>> forecast) {
    final insights = [
      ('check', const Color(0xFF2E7D32),
          'Consistent temperatures ideal for most crops'),
      ('water_drop', const Color(0xFFF59E0B),
          'Monitor precipitation — plan irrigation accordingly'),
      ('warning', const Color(0xFFF97316),
          'Check humidity towards end of week — monitor for fungal diseases'),
      ('grass', const Color(0xFF2E7D32),
          'Soil temperature stable — good for root development'),
    ];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            color: const Color(0xFF2D3748),
            child: Row(children: [
              const Icon(Icons.cloud_outlined,
                  color: Colors.white70, size: 18),
              const SizedBox(width: 8),
              Text(lang.t('ct_res_forecast'),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold)),
            ]),
          ),

          // Table header
          Container(
            color: const Color(0xFFF9FBE7),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(children: [
              _fTh(lang.t('ct_res_date'), 90),
              _fTh(lang.t('ct_res_max'), 55),
              _fTh(lang.t('ct_res_min'), 55),
              _fTh('HUM.', 55),
              _fTh('PRECIP.', 60),
              Expanded(child: _fTh(lang.t('ct_res_cond'), 0)),
            ]),
          ),
          const Divider(height: 1),

          // Table rows
          ...forecast.map((day) {
            final date = day['date'] as String? ?? '';
            final tmax = (day['temp_max'] as num? ?? 0).toDouble();
            final tmin = (day['temp_min'] as num? ?? 0).toDouble();
            final humMax =
                (day['humidity_max'] as num? ?? 0).toDouble();
            final humMin =
                (day['humidity_min'] as num? ?? 0).toDouble();
            final pr = (day['precipitation'] as num? ?? 0).toDouble();
            final wc = (day['weather_code'] as num? ?? 0).toInt();
            final cond = _forecastCond(wc, humMax);
            final condColor = _condColor(cond);

            return Column(children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 9),
                child: Row(children: [
                  SizedBox(
                    width: 90,
                    child: Text(date,
                        style: const TextStyle(fontSize: 11)),
                  ),
                  SizedBox(
                    width: 55,
                    child: Text('${tmax.toStringAsFixed(1)}°C',
                        style: const TextStyle(fontSize: 11)),
                  ),
                  SizedBox(
                    width: 55,
                    child: Text('${tmin.toStringAsFixed(1)}°C',
                        style: const TextStyle(
                            fontSize: 11, color: Colors.blueGrey)),
                  ),
                  SizedBox(
                    width: 55,
                    child: Text(
                        '${humMin.toStringAsFixed(0)}–${humMax.toStringAsFixed(0)}%',
                        style: const TextStyle(
                            fontSize: 10, color: Colors.grey)),
                  ),
                  SizedBox(
                    width: 60,
                    child: Text('${pr.toStringAsFixed(2)} mm',
                        style: const TextStyle(fontSize: 10)),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: condColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: condColor.withOpacity(0.3)),
                      ),
                      child: Text(cond,
                          style: TextStyle(
                              color: condColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ]),
              ),
              const Divider(height: 1),
            ]);
          }).toList(),

          // Insights
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.lightbulb_outline,
                      color: _green3, size: 15),
                  const SizedBox(width: 6),
                  Text(lang.t('ct_res_insights'),
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: _green3,
                          letterSpacing: 0.8)),
                ]),
                const SizedBox(height: 8),
                ...insights.map((ins) => Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.circle, color: ins.$2, size: 8),
                      const SizedBox(width: 6),
                      Expanded(child: Text(ins.$3,
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF424242),
                              height: 1.4))),
                    ],
                  ),
                )).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fTh(String label, double width) {
    final child = Text(label,
        style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2E7D32),
            letterSpacing: 0.3));
    if (width == 0) return Expanded(child: child);
    return SizedBox(width: width, child: child);
  }
}

// ── Weather metric box ────────────────────────────────────────
class _WeatherMetric extends StatelessWidget {
  final String label, value;
  const _WeatherMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 9)),
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

// ── Average stat box ──────────────────────────────────────────
class _AvgStat extends StatelessWidget {
  final String label, value;
  const _AvgStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8E9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFC8E6C9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
                  const TextStyle(fontSize: 10, color: Color(0xFF9E9E9E))),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B5E20))),
        ],
      ),
    );
  }
}

// ── Crop card in grid ─────────────────────────────────────────
class _CropCard extends StatelessWidget {
  final Map<String, dynamic> rec;
  final bool isTop;
  final LanguageService lang;
  const _CropCard({required this.rec, required this.isTop, required this.lang});

  @override
  Widget build(BuildContext context) {
    final rank = (rec['rank'] as num? ?? 0).toInt();
    final crop = rec['crop'] as String? ?? '';
    final profit =
        (rec['profitability_score'] as num? ?? 0).toDouble();
    final risk = (rec['risk_score'] as num? ?? 0).toDouble();
    final timeline = rec['planting_timeline'] as String? ?? '';
    final revenue =
        (rec['expected_revenue'] as num? ?? 0).toDouble();

    // Rank badge colour
    final badgeColors = [
      const Color(0xFFF57C00),
      const Color(0xFF546E7A),
      const Color(0xFF795548),
      const Color(0xFF388E3C),
    ];
    final badgeColor =
        rank <= badgeColors.length ? badgeColors[rank - 1] : const Color(0xFF90A4AE);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isTop
                ? const Color(0xFFF57C00).withOpacity(0.5)
                : const Color(0xFFE0E0E0)),
        boxShadow: isTop
            ? [BoxShadow(
                color: const Color(0xFFF57C00).withOpacity(0.1),
                blurRadius: 6)]
            : null,
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rank + crop name
          Row(children: [
            Container(
              width: 24, height: 24,
              decoration: BoxDecoration(
                  color: badgeColor, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Text('$rank',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11)),
            ),
            const SizedBox(width: 6),
            Expanded(child: Text(crop,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14),
                overflow: TextOverflow.ellipsis)),
          ]),
          const SizedBox(height: 6),

          // Scores
          Row(children: [
            _ScoreBadge(
                label: '★ ${profit.toStringAsFixed(2)}',
                color: const Color(0xFF2E7D32)),
            const SizedBox(width: 5),
            _ScoreBadge(
                label: 'Risk: ${risk.toStringAsFixed(2)}',
                color: risk > 0.4
                    ? const Color(0xFFF57C00)
                    : const Color(0xFF388E3C)),
          ]),
          const SizedBox(height: 6),

          // Adaptability
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
                vertical: 4, horizontal: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F8E9),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Row(children: [
              const Icon(Icons.grass,
                  color: Color(0xFF2E7D32), size: 11),
              const SizedBox(width: 4),
              const Expanded(
                child: Text('Adaptable to Most Conditions',
                    style: TextStyle(
                        fontSize: 9.5, color: Color(0xFF2E7D32))),
              ),
            ]),
          ),
          const SizedBox(height: 6),

          // Profitability bar
          _BarRow(
              label: lang.t('ct_res_profitability'),
              value: profit,
              color: const Color(0xFF388E3C)),
          const SizedBox(height: 4),
          _BarRow(
              label: lang.t('ct_res_risk_level'),
              value: risk,
              color: risk > 0.4
                  ? const Color(0xFFF57C00)
                  : const Color(0xFF66BB6A)),
          const Spacer(),

          // Timeline + Revenue
          Row(children: [
            const Icon(Icons.calendar_today,
                color: Color(0xFF9E9E9E), size: 11),
            const SizedBox(width: 4),
            Expanded(child: Text(
                timeline.replaceAll('Plant in month', 'Plant m.'),
                style: const TextStyle(
                    fontSize: 9.5, color: Color(0xFF424242)),
                maxLines: 2,
                overflow: TextOverflow.ellipsis)),
          ]),
          const SizedBox(height: 3),
          Row(children: [
            const Icon(Icons.monetization_on,
                color: Color(0xFF9E9E9E), size: 11),
            const SizedBox(width: 4),
            Text('Rs. ${revenue.toStringAsFixed(1)}',
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32))),
          ]),
        ],
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _ScoreBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color,
              fontSize: 9.5,
              fontWeight: FontWeight.bold)),
    );
  }
}

class _BarRow extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _BarRow(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 9, color: Color(0xFF9E9E9E))),
                Text('${(value * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                        fontSize: 9, color: Color(0xFF9E9E9E))),
              ],
            ),
            const SizedBox(height: 2),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: value.clamp(0.0, 1.0),
                backgroundColor: const Color(0xFFE0E0E0),
                valueColor:
                    AlwaysStoppedAnimation<Color>(color),
                minHeight: 5,
              ),
            ),
          ],
        ),
      ),
    ]);
  }
}

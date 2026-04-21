import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/language_service.dart';
import '../widgets/language_switcher.dart';

class MarketRankingResultScreen extends StatefulWidget {
  final Map<String, dynamic> data;
  const MarketRankingResultScreen({super.key, required this.data});

  @override
  State<MarketRankingResultScreen> createState() =>
      _MarketRankingResultScreenState();
}

class _MarketRankingResultScreenState
    extends State<MarketRankingResultScreen> with LangMixin {
  static const Color _green  = Color(0xFF1B5E20);
  static const Color _green2 = Color(0xFF2E7D32);
  static const Color _green4 = Color(0xFF66BB6A);
  static const Color _bg     = Color(0xFFF1F8E9);

  // Rank badge colours matching Flask (gold / grey / copper)
  static const List<Color> _rankColors = [
    Color(0xFFF57C00), // #1 orange-gold
    Color(0xFF546E7A), // #2 grey-blue
    Color(0xFF795548), // #3 brown
  ];

  List<Map<String, dynamic>> get _recs =>
      List<Map<String, dynamic>>.from(
          (widget.data['recommendations'] as List? ?? [])
              .map((e) => Map<String, dynamic>.from(e as Map)));

  String get _bestMarket =>
      widget.data['best_market'] as String? ?? '';

  int get _totalMarkets =>
      (widget.data['total_markets'] as num? ?? 0).toInt();

  double get _quantityKg =>
      (widget.data['quantity_kg'] as num? ?? 0).toDouble();

  String get _userRole =>
      widget.data['user_role'] as String? ?? '';

  double get _avgPrice {
    if (_recs.isEmpty) return 0;
    final sum = _recs.fold<double>(
        0, (s, r) => s + ((r['predicted_price'] as num? ?? 0).toDouble()));
    return sum / _recs.length;
  }

  double get _avgDistance {
    if (_recs.isEmpty) return 0;
    final sum = _recs.fold<double>(
        0, (s, r) => s + ((r['distance_km'] as num? ?? r['distance'] as num? ?? 0).toDouble()));
    return sum / _recs.length;
  }

  @override
  Widget build(BuildContext context) {
    final lang = LanguageService();
    final recs = _recs;
    final topRecs = recs.take(3).toList();

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: Text(lang.t('mr_result_title')),
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
            // ── Top Recommendations card ───────────────
            _topRecsCard(lang, topRecs),
            const SizedBox(height: 16),

            // ── Summary stats ─────────────────────────
            _summaryCard(lang),
            const SizedBox(height: 16),

            // ── All markets table ─────────────────────
            _allMarketsCard(lang, recs),
            const SizedBox(height: 16),

            // ── Map ────────────────────────────────────
            _mapCard(lang, recs),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── Top 3 recommendations ─────────────────────────────────
  Widget _topRecsCard(LanguageService lang, List<Map<String, dynamic>> recs) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            child: Row(children: [
              const Icon(Icons.emoji_events, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              Text(
                '${lang.t('mr_res_top_recs')} — ${_userRole == 'seller' ? 'Sellers' : 'Buyers'}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold),
              ),
            ]),
          ),

          // Best market hero
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(14),
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFC8E6C9)),
              boxShadow: [
                BoxShadow(
                  color: _green2.withOpacity(0.08),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Column(
              children: [
                Text(lang.t('mr_res_best_market'),
                    style: const TextStyle(
                        color: _green2,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1)),
                const SizedBox(height: 4),
                Text(_bestMarket,
                    style: const TextStyle(
                        color: _green,
                        fontSize: 28,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('${lang.t('mr_res_analyzed')} — $_totalMarkets',
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),

          // Top 3 ranked cards
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Column(
              children: recs.asMap().entries.map((entry) {
                final idx = entry.key;
                final rec = entry.value;
                return _RankedCard(
                  rec: rec,
                  rank: idx + 1,
                  rankColor: idx < _rankColors.length
                      ? _rankColors[idx]
                      : const Color(0xFF90A4AE),
                  lang: lang,
                  userRole: _userRole,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ── Summary stats row ─────────────────────────────────────
  Widget _summaryCard(LanguageService lang) {
    return Row(children: [
      Expanded(child: _StatBox(
        label: lang.t('mr_res_avg_price'),
        value: 'Rs. ${_avgPrice.toStringAsFixed(2)}/kg',
        icon: Icons.monetization_on_outlined,
      )),
      const SizedBox(width: 10),
      Expanded(child: _StatBox(
        label: lang.t('mr_res_avg_dist'),
        value: '${_avgDistance.toStringAsFixed(1)} km',
        icon: Icons.route,
      )),
      const SizedBox(width: 10),
      Expanded(child: _StatBox(
        label: lang.t('mr_res_qty'),
        value: '${_quantityKg.toStringAsFixed(0)} kg',
        icon: Icons.scale,
      )),
    ]);
  }

  // ── All markets table ─────────────────────────────────────
  Widget _allMarketsCard(
      LanguageService lang, List<Map<String, dynamic>> recs) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  const Icon(Icons.list_alt, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    '${lang.t('mr_res_all_recs')} — ${_userRole == 'seller' ? 'Sellers' : 'Buyers'}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold),
                  ),
                ]),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('$_totalMarkets Markets',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 11)),
                ),
              ],
            ),
          ),

          // Column headers
          Container(
            color: const Color(0xFFF9FBE7),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(children: [
              _th('RANK', 40),
              _th('MARKET', 80),
              _th('PRICE\n(RS/KG)', 70),
              _th('DIST.', 55),
              _th('TRANSPORT\n(RS)', 80),
              Expanded(child: _th('NET REV. (RS)', 0)),
            ]),
          ),
          const Divider(height: 1),

          // Rows
          ...recs.map((rec) {
            final rank = (rec['rank'] as num? ?? 0).toInt();
            final price = (rec['predicted_price'] as num? ?? 0).toDouble();
            final dist = (rec['distance_km'] as num? ??
                    rec['distance'] as num? ?? 0)
                .toDouble();
            final transport =
                (rec['transport_cost'] as num? ?? 0).toDouble();
            final netRev =
                (rec['net_advantage'] as num? ?? 0).toDouble();
            final market = rec['market'] as String? ?? '';
            final isTop = rank == 1;
            final explanation = rec['explanation'] as String? ?? '';

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  color: isTop
                      ? const Color(0xFFFFF8E1)
                      : Colors.transparent,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  child: Row(children: [
                    SizedBox(
                      width: 40,
                      child: _RankBadge(
                        rank: rank,
                        color: rank <= _rankColors.length
                            ? _rankColors[rank - 1]
                            : const Color(0xFF90A4AE),
                      ),
                    ),
                    SizedBox(
                      width: 80,
                      child: Text(market,
                          style: TextStyle(
                              fontWeight: isTop
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 12)),
                    ),
                    SizedBox(
                      width: 70,
                      child: Text('Rs. ${price.toStringAsFixed(2)}',
                          style: const TextStyle(
                              color: _green2,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ),
                    SizedBox(
                      width: 55,
                      child: Text(
                          '${dist.toStringAsFixed(1)} km',
                          style: const TextStyle(
                              fontSize: 11, color: Colors.grey)),
                    ),
                    SizedBox(
                      width: 80,
                      child: Text(
                          'Rs. ${transport.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 11)),
                    ),
                    Expanded(
                      child: Text(
                          'Rs. ${netRev.toStringAsFixed(2)}',
                          style: TextStyle(
                              color: netRev >= 0
                                  ? _green2
                                  : Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 11)),
                    ),
                  ]),
                ),
                if (explanation.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(
                        left: 12, right: 12, bottom: 8),
                    child: Text(explanation,
                        style: const TextStyle(
                            fontSize: 10.5,
                            color: Color(0xFF757575),
                            height: 1.4)),
                  ),
                const Divider(height: 1),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _th(String label, double width) {
    final child = Text(label,
        style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2E7D32),
            letterSpacing: 0.3));
    if (width == 0) return Expanded(child: child);
    return SizedBox(width: width, child: child);
  }

  // ── Map ───────────────────────────────────────────────────
  Widget _mapCard(LanguageService lang, List<Map<String, dynamic>> recs) {
    final userLat = 7.2906;
    final userLon = 80.6337;

    final markers = <Marker>[
      Marker(
        point: LatLng(userLat, userLon),
        width: 50,
        height: 50,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red.shade700,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('You',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold)),
            ),
            Icon(Icons.location_on, color: Colors.red.shade700, size: 26),
          ],
        ),
      ),
    ];

    for (final rec in recs) {
      final lat = (rec['market_lat'] as num?)?.toDouble();
      final lon = (rec['market_lon'] as num?)?.toDouble();
      final market = rec['market'] as String? ?? '';
      final rank = (rec['rank'] as num? ?? 0).toInt();
      if (lat == null || lon == null) continue;

      final color = rank <= _rankColors.length
          ? _rankColors[rank - 1]
          : const Color(0xFF2E7D32);

      markers.add(Marker(
        point: LatLng(lat, lon),
        width: 90,
        height: 50,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text('#$rank $market',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold)),
            ),
            Icon(Icons.store, color: color, size: 24),
          ],
        ),
      ));
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: Column(
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
              const Icon(Icons.map_outlined, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(lang.t('mr_res_map'),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold)),
            ]),
          ),
          SizedBox(
            height: 320,
            child: FlutterMap(
              options: const MapOptions(
                initialCenter: LatLng(7.2906, 80.6337),
                initialZoom: 8.0,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.agrisense.app',
                ),
                MarkerLayer(markers: markers),
              ],
            ),
          ),
          // Legend
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _legendDot(Colors.red, lang.t('mr_your_location')),
                const SizedBox(width: 20),
                _legendDot(_green2, 'Market Locations'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) => Row(children: [
        Icon(Icons.location_on, color: color, size: 15),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF616161))),
      ]);
}

// ─── Ranked card (top 3) ──────────────────────────────────────
class _RankedCard extends StatelessWidget {
  final Map<String, dynamic> rec;
  final int rank;
  final Color rankColor;
  final LanguageService lang;
  final String userRole;
  const _RankedCard(
      {required this.rec,
      required this.rank,
      required this.rankColor,
      required this.lang,
      required this.userRole});

  @override
  Widget build(BuildContext context) {
    final market = rec['market'] as String? ?? '';
    final price =
        (rec['predicted_price'] as num? ?? 0).toDouble();
    final dist =
        (rec['distance_km'] as num? ?? rec['distance'] as num? ?? 0)
            .toDouble();
    final transport =
        (rec['transport_cost'] as num? ?? 0).toDouble();
    final netRev =
        (rec['net_advantage'] as num? ?? 0).toDouble();
    final explanation = rec['explanation'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: rank == 1
                ? const Color(0xFFF57C00).withOpacity(0.5)
                : const Color(0xFFE0E0E0)),
        boxShadow: rank == 1
            ? [
                BoxShadow(
                    color:
                        const Color(0xFFF57C00).withOpacity(0.12),
                    blurRadius: 6)
              ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Market name + rank badge
            Row(
              children: [
                _RankBadge(rank: rank, color: rankColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(market,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Price + Distance tags
            Row(children: [
              _Tag(
                  icon: Icons.monetization_on,
                  label:
                      'Rs.${price.toStringAsFixed(2)}/kg',
                  color: const Color(0xFF2E7D32)),
              const SizedBox(width: 8),
              _Tag(
                  icon: Icons.route,
                  label:
                      '${dist.toStringAsFixed(2)} km',
                  color: const Color(0xFF1565C0)),
            ]),
            const SizedBox(height: 8),

            // Explanation
            if (explanation.isNotEmpty)
              Text(explanation,
                  style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF616161),
                      height: 1.4)),
            const SizedBox(height: 8),

            // Transport | Net Revenue
            Row(
              children: [
                Expanded(
                  child: _ValueLabel(
                    label: lang.t('mr_res_transport'),
                    value: 'Rs. ${transport.toStringAsFixed(2)}',
                    valueColor: const Color(0xFF424242),
                  ),
                ),
                Expanded(
                  child: _ValueLabel(
                    label: lang.t('mr_res_net_rev'),
                    value: 'Rs. ${netRev.toStringAsFixed(2)}',
                    valueColor: netRev >= 0
                        ? const Color(0xFF2E7D32)
                        : Colors.red,
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

// ─── Rank badge circle ────────────────────────────────────────
class _RankBadge extends StatelessWidget {
  final int rank;
  final Color color;
  const _RankBadge({required this.rank, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text('$rank',
          style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13)),
    );
  }
}

// ─── Price / Distance tag chip ────────────────────────────────
class _Tag extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _Tag({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

// ─── Transport / Net revenue label ────────────────────────────
class _ValueLabel extends StatelessWidget {
  final String label, value;
  final Color valueColor;
  const _ValueLabel(
      {required this.label,
      required this.value,
      required this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 10, color: Color(0xFF9E9E9E))),
        Text(value,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: valueColor)),
      ],
    );
  }
}

// ─── Summary stat box ─────────────────────────────────────────
class _StatBox extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _StatBox(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFF2E7D32), size: 16),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(
                    fontSize: 10, color: Color(0xFF9E9E9E))),
            const SizedBox(height: 2),
            Text(value,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20))),
          ],
        ),
      ),
    );
  }
}

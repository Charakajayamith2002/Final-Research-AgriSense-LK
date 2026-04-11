import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/gps_service.dart';
import '../widgets/result_webview.dart';
import '../theme/app_theme.dart';

class ProfitableStrategyScreen extends StatefulWidget {
  const ProfitableStrategyScreen({super.key});

  @override
  State<ProfitableStrategyScreen> createState() => _ProfitableStrategyScreenState();
}

class _ProfitableStrategyScreenState extends State<ProfitableStrategyScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  // ── Profile ───────────────────────────────────────
  String _role         = 'farmer';
  String _profession   = 'farming';
  String _purpose      = 'crop_selection';
  String _incomeSource = 'both';
  String _budgetSource = 'savings';
  final _monthlyIncomeCtrl = TextEditingController(text: '85000');
  final _budgetCtrl        = TextEditingController(text: '250000');

  // ── Cultivation Targeting ─────────────────────────
  String _cultivationItem = '';
  String _optimalMonth    = 'January';
  String _season          = 'Spring';
  final _cultivationProfitCtrl = TextEditingController(text: '0');
  final _cultivationRiskCtrl   = TextEditingController(text: '0');

  // ── Market Information ────────────────────────────
  String _marketName = '';
  final _marketItemCtrl     = TextEditingController();
  final _predictedPriceCtrl = TextEditingController(text: '0');
  final _distanceCtrl       = TextEditingController();
  final _transportCtrl      = TextEditingController();
  final _netAdvantageCtrl   = TextEditingController();

  // ── Location ──────────────────────────────────────
  final _latCtrl = TextEditingController(text: '7.2906');
  final _lonCtrl = TextEditingController(text: '80.6337');
  bool _gpsLoading = false;
  String _locationName = '';

  static const List<String> _purposes = [
    'crop_selection', 'market_timing', 'price_negotiation',
    'input_procurement', 'export_planning', 'storage_decision',
  ];

  static const List<String> _cultivationItems = [
    'Tomato', 'Carrot', 'Cabbage', 'Beans', 'Potato', 'Onion', 'Leeks',
    'Mango', 'Banana', 'Papaya', 'Pineapple',
    'White Rice', 'Red Rice', 'Coconut', 'Ginger',
  ];

  static const List<String> _markets = [
    'Pettah', 'Dambulla', 'Narahenpita',
    'Marandagahamula', 'Peliyagoda', 'Negombo',
  ];

  static const List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  Future<void> _predict() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final data = {
      'role':                      _role,
      'profession':                _profession,
      'purpose':                   _purpose,
      'monthly_income':            _monthlyIncomeCtrl.text,
      'income_source':             _incomeSource,
      'available_budget':          _budgetCtrl.text,
      'budget_source':             _budgetSource,
      'season':                    _season,
      'cultivation_item':          _cultivationItem,
      'optimal_month':             _optimalMonth,
      'cultivation_profitability': _cultivationProfitCtrl.text,
      'cultivation_risk':          _cultivationRiskCtrl.text,
      'market_item':               _marketItemCtrl.text,
      'market_name':               _marketName,
      'predicted_price':           _predictedPriceCtrl.text,
      'distance_km':               _distanceCtrl.text,
      'transport_cost':            _transportCtrl.text,
      'net_advantage':             _netAdvantageCtrl.text,
      'latitude':                  _latCtrl.text,
      'longitude':                 _lonCtrl.text,
    };

    final result = await ApiService().predictProfitableStrategy(data);
    setState(() => _loading = false);

    if (!mounted) return;
    if (result['success'] == true) {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => ResultWebView(title: 'Profitable Strategy', html: result['html']),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Failed'), backgroundColor: Colors.red),
      );
    }
  }

  bool _fetchingCultivation = false;
  bool _fetchingMarket      = false;

  // ── Fetch from Cultivation Targeting (Component 3) ──
  Future<void> _fetchFromCultivation() async {
    final monthNum = _months.indexOf(_optimalMonth) + 1; // "January"→1
    setState(() => _fetchingCultivation = true);

    final result = await ApiService().fetchCultivationRecommendation(
      month: monthNum,
      category: 'All',
      riskTolerance: 'medium',
    );

    setState(() => _fetchingCultivation = false);
    if (!mounted) return;

    if (result['success'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result['message'] ?? 'Failed'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    final data = result['data'] as Map<String, dynamic>;
    final recs = data['recommendations'] as List<dynamic>?;
    if (recs == null || recs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('No recommendations returned'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    final top = recs[0] as Map<String, dynamic>;

    setState(() {
      // cultivation_item
      final crop = top['crop']?.toString() ?? '';
      if (crop.isNotEmpty) _cultivationItem = crop;

      // profitability score (0–1)
      final profit = top['profitability_score'];
      if (profit != null) {
        _cultivationProfitCtrl.text =
            (profit as num).toDouble().toStringAsFixed(2);
      }

      // risk score (0–1)
      final risk = top['risk_score'];
      if (risk != null) {
        _cultivationRiskCtrl.text =
            (risk as num).toDouble().toStringAsFixed(2);
      }

      // season from API
      final apiSeason = data['season']?.toString() ?? '';
      if (apiSeason.isNotEmpty &&
          ['Spring', 'Summer', 'Autumn', 'Winter'].contains(apiSeason)) {
        _season = apiSeason;
      }

      // optimal_month from API
      final apiMonth = data['optimal_month'];
      if (apiMonth != null) {
        final idx = ((apiMonth as num).toInt() - 1).clamp(0, 11);
        _optimalMonth = _months[idx];
      }

      // also pre-fill market_item with same crop
      if (crop.isNotEmpty) _marketItemCtrl.text = crop;
    });

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Cultivation recommendations fetched!'),
      backgroundColor: Color(0xFF2A7525),
    ));
  }

  // ── Fetch from Market Ranking (Component 2) ──────────
  Future<void> _fetchFromMarket() async {
    final item = _marketItemCtrl.text.trim().isEmpty
        ? 'Tomato'
        : _marketItemCtrl.text.trim();

    // map role: farmer→seller, consumer→buyer, others as-is
    String marketRole = _role;
    if (_role == 'farmer') marketRole = 'seller';
    if (_role == 'consumer') marketRole = 'buyer';

    final lat = double.tryParse(_latCtrl.text) ?? 7.2906;
    final lon = double.tryParse(_lonCtrl.text) ?? 80.6337;
    final profitability =
        double.tryParse(_cultivationProfitCtrl.text) ?? 0.7;
    final predictedPrice =
        double.tryParse(_predictedPriceCtrl.text) ?? 185.5;

    setState(() => _fetchingMarket = true);

    final result = await ApiService().fetchMarketRecommendation(
      item: item,
      userRole: marketRole,
      latitude: lat,
      longitude: lon,
      profitability: profitability,
      predictedPrice: predictedPrice,
      priceType: marketRole == 'seller' ? 'Wholesale' : 'Retail',
    );

    setState(() => _fetchingMarket = false);
    if (!mounted) return;

    if (result['success'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result['message'] ?? 'Failed'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    final data = result['data'] as Map<String, dynamic>;
    final recs = data['recommendations'] as List<dynamic>?;
    if (recs == null || recs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('No market recommendations returned'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    final top = recs[0] as Map<String, dynamic>;

    setState(() {
      final market = top['market']?.toString() ?? '';
      if (market.isNotEmpty && _markets.contains(market)) {
        _marketName = market;
      }

      final price = top['predicted_price'];
      if (price != null) {
        _predictedPriceCtrl.text =
            (price as num).toDouble().toStringAsFixed(2);
      }

      final dist = top['distance_km'] ?? top['distance'];
      if (dist != null) {
        _distanceCtrl.text = (dist as num).toDouble().toStringAsFixed(2);
      }

      final transport = top['transport_cost'];
      if (transport != null) {
        _transportCtrl.text =
            (transport as num).toDouble().toStringAsFixed(2);
      }

      final netAdv = top['net_advantage'];
      if (netAdv != null) {
        _netAdvantageCtrl.text =
            (netAdv as num).toDouble().toStringAsFixed(2);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Market recommendations fetched!'),
      backgroundColor: Color(0xFF2A7525),
    ));
  }

  @override
  void dispose() {
    _monthlyIncomeCtrl.dispose(); _budgetCtrl.dispose();
    _cultivationProfitCtrl.dispose(); _cultivationRiskCtrl.dispose();
    _marketItemCtrl.dispose(); _predictedPriceCtrl.dispose();
    _distanceCtrl.dispose(); _transportCtrl.dispose();
    _netAdvantageCtrl.dispose(); _latCtrl.dispose(); _lonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.g50,
      appBar: AppBar(
        title: const Text('Profitable Strategy'),
        backgroundColor: AppColors.g600,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // ── Profile, Family & Financial Information ──
              FlaskCard(
                icon: Icons.person_outline,
                title: 'Profile, Family & Financial Information',
                children: [
                  _SectionLabel(Icons.person, 'BASIC INFORMATION'),
                  const SizedBox(height: 12),
                  // Role | Profession | Purpose
                  Row(children: [
                    Expanded(child: _drop('Role', _role,
                        ['farmer', 'buyer', 'seller', 'consumer'],
                        (v) => setState(() => _role = v!))),
                    const SizedBox(width: 10),
                    Expanded(child: _drop('Profession', _profession,
                        ['farming', 'business', 'government', 'private'],
                        (v) => setState(() => _profession = v!))),
                    const SizedBox(width: 10),
                    Expanded(child: _drop('Purpose', _purpose, _purposes,
                        (v) => setState(() => _purpose = v!))),
                  ]),
                  const SizedBox(height: 14),
                  // Monthly Income | Income Source
                  Row(children: [
                    Expanded(child: TextFormField(
                      controller: _monthlyIncomeCtrl,
                      keyboardType: TextInputType.number,
                      decoration: flaskInput('Monthly Income (LKR)'),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: _drop('Income Source', _incomeSource,
                        ['both', 'profession', 'business'],
                        (v) => setState(() => _incomeSource = v!))),
                  ]),
                  const SizedBox(height: 20),

                  _SectionLabel(Icons.attach_money, 'FINANCIAL INFORMATION'),
                  const SizedBox(height: 12),
                  // Budget | Budget Source
                  Row(children: [
                    Expanded(child: TextFormField(
                      controller: _budgetCtrl,
                      keyboardType: TextInputType.number,
                      decoration: flaskInput('Available Budget (LKR)'),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: _drop('Budget Source', _budgetSource,
                        ['savings', 'bank_loan', 'microfinance', 'family', 'other'],
                        (v) => setState(() => _budgetSource = v!))),
                  ]),
                ],
              ),
              const SizedBox(height: 16),

              // ── Cultivation Targeting ────────────────────
              FlaskCard(
                icon: Icons.grass,
                title: 'Cultivation Targeting',
                action: _FetchButton(
                  label: 'Fetch from Component 3',
                  loading: _fetchingCultivation,
                  onTap: _fetchingCultivation ? null : _fetchFromCultivation,
                ),
                children: [
                  // Cultivation Item | Optimal Month | Season
                  Row(children: [
                    Expanded(child: DropdownButtonFormField<String>(
                      value: _cultivationItem.isEmpty ? null : _cultivationItem,
                      decoration: flaskInput('Cultivation Item'),
                      isExpanded: true,
                      hint: const Text('Select an item',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                      items: _cultivationItems.map((i) => DropdownMenuItem(
                          value: i, child: Text(i, overflow: TextOverflow.ellipsis))).toList(),
                      onChanged: (v) => setState(() => _cultivationItem = v ?? ''),
                    )),
                    const SizedBox(width: 10),
                    Expanded(child: _drop('Optimal Month', _optimalMonth, _months,
                        (v) => setState(() => _optimalMonth = v!))),
                    const SizedBox(width: 10),
                    Expanded(child: _drop('Season', _season,
                        ['Spring', 'Summer', 'Autumn', 'Winter'],
                        (v) => setState(() => _season = v!))),
                  ]),
                  const SizedBox(height: 14),
                  // Profitability | Risk
                  Row(children: [
                    Expanded(child: TextFormField(
                      controller: _cultivationProfitCtrl,
                      keyboardType: TextInputType.number,
                      decoration: flaskInput('Profitability (0–1)', hint: '0.00 – 1.00'),
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: TextFormField(
                      controller: _cultivationRiskCtrl,
                      keyboardType: TextInputType.number,
                      decoration: flaskInput('Risk (0–1)', hint: '0.00 – 1.00'),
                    )),
                  ]),
                ],
              ),
              const SizedBox(height: 16),

              // ── Market Information ───────────────────────
              FlaskCard(
                icon: Icons.store_outlined,
                title: 'Market Information',
                action: _FetchButton(
                  label: 'Fetch from Component 2',
                  loading: _fetchingMarket,
                  onTap: _fetchingMarket ? null : _fetchFromMarket,
                ),
                children: [
                  // Item | Market Name | Predicted Price
                  Row(children: [
                    Expanded(child: TextFormField(
                      controller: _marketItemCtrl,
                      decoration: flaskInput('Item', hint: 'e.g. Tomato'),
                    )),
                    const SizedBox(width: 10),
                    Expanded(child: DropdownButtonFormField<String>(
                      value: _marketName.isEmpty ? null : _marketName,
                      decoration: flaskInput('Market Name'),
                      isExpanded: true,
                      hint: const Text('Select a market',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                      items: _markets.map((m) => DropdownMenuItem(
                          value: m, child: Text(m, overflow: TextOverflow.ellipsis))).toList(),
                      onChanged: (v) => setState(() => _marketName = v ?? ''),
                    )),
                    const SizedBox(width: 10),
                    Expanded(child: TextFormField(
                      controller: _predictedPriceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: flaskInput('Predicted Price (Rs/kg)'),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    )),
                  ]),
                  const SizedBox(height: 14),
                  // Distance | Transport Cost | Net Advantage
                  Row(children: [
                    Expanded(child: TextFormField(
                      controller: _distanceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: flaskInput('Distance (km)'),
                    )),
                    const SizedBox(width: 10),
                    Expanded(child: TextFormField(
                      controller: _transportCtrl,
                      keyboardType: TextInputType.number,
                      decoration: flaskInput('Transport Cost (Rs)'),
                    )),
                    const SizedBox(width: 10),
                    Expanded(child: TextFormField(
                      controller: _netAdvantageCtrl,
                      keyboardType: TextInputType.number,
                      decoration: flaskInput('Net Advantage (Rs)'),
                    )),
                  ]),
                ],
              ),
              const SizedBox(height: 16),

              // ── Location Information ─────────────────────
              FlaskCard(
                icon: Icons.location_on_outlined,
                title: 'Location Information',
                children: [
                  // GPS dark sub-panel
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.g600,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          const Icon(Icons.my_location, color: Colors.white70, size: 13),
                          const SizedBox(width: 6),
                          Text('GPS COORDINATES',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white.withOpacity(0.75),
                                  letterSpacing: 0.8)),
                        ]),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _gpsLoading ? null : () => GpsService.getLocation(
                              context,
                              onLoadingStart: () => setState(() => _gpsLoading = true),
                              onLoadingEnd:   () => setState(() => _gpsLoading = false),
                              onSuccess: (lat, lon, name) => setState(() {
                                _latCtrl.text = lat.toStringAsFixed(4);
                                _lonCtrl.text = lon.toStringAsFixed(4);
                                _locationName = name;
                              }),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(color: Colors.white.withValues(alpha: 0.5)),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            icon: _gpsLoading
                                ? const SizedBox(
                                    width: 14, height: 14,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 1.5))
                                : const Icon(Icons.navigation, size: 15),
                            label: Text(
                                _gpsLoading ? 'Locating…' : 'Use My Current Location',
                                style: const TextStyle(fontSize: 13)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(children: [
                          Expanded(child: TextFormField(
                            controller: _latCtrl,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: _darkInput('Latitude'),
                          )),
                          const SizedBox(width: 12),
                          Expanded(child: TextFormField(
                            controller: _lonCtrl,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: _darkInput('Longitude'),
                          )),
                        ]),
                        if (_locationName.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Row(children: [
                            const Icon(Icons.location_on, color: Colors.white70, size: 14),
                            const SizedBox(width: 6),
                            Flexible(child: Text(_locationName,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600))),
                          ]),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              SubmitButton(
                loading: _loading,
                label: 'Predict My Strategy',
                loadingLabel: 'Generating Strategy…',
                icon: Icons.lightbulb_outline,
                onPressed: _predict,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _drop(String label, String value, List<String> items, ValueChanged<String?> cb) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: flaskInput(label),
      isExpanded: true,
      items: items.map((i) => DropdownMenuItem(
          value: i, child: Text(i, overflow: TextOverflow.ellipsis))).toList(),
      onChanged: cb,
    );
  }

  InputDecoration _darkInput(String label) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: Colors.white70, fontSize: 12),
    filled: true,
    fillColor: Colors.white.withOpacity(0.12),
    contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Colors.white, width: 1.5),
    ),
  );
}

// ── Fetch button shown in FlaskCard header ────────────
class _FetchButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback? onTap;
  const _FetchButton({required this.label, required this.onTap, this.loading = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: Colors.white.withValues(alpha: 0.45), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            loading
                ? const SizedBox(
                    width: 12, height: 12,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 1.5))
                : const Icon(Icons.sync, color: Colors.white, size: 13),
            const SizedBox(width: 5),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ── Section header label (inside card) ───────────────
class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String text;
  const _SectionLabel(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 14, height: 14,
        decoration: BoxDecoration(
          color: AppColors.g600,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
      const SizedBox(width: 7),
      Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.g600,
          letterSpacing: 0.8,
        ),
      ),
    ]);
  }
}

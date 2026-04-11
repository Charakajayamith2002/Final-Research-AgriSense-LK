import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/app_cache.dart';
import '../services/gps_service.dart';
import '../widgets/result_webview.dart';
import '../theme/app_theme.dart';

class CultivationTargetingScreen extends StatefulWidget {
  const CultivationTargetingScreen({super.key});

  @override
  State<CultivationTargetingScreen> createState() => _CultivationTargetingScreenState();
}

class _CultivationTargetingScreenState extends State<CultivationTargetingScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  // ── Location ──────────────────────────────────────
  final _latCtrl = TextEditingController(text: '7.75');
  final _lonCtrl = TextEditingController(text: '80.75');
  bool _gpsLoading = false;
  String _locationName = '';

  // ── Core Parameters ───────────────────────────────
  String _month         = 'January';
  String _category      = 'All Categories';
  String _riskTolerance = 'Low (Conservative)';

  final _prevProfitabilityCtrl = TextEditingController(text: '20');
  final _budgetCtrl            = TextEditingController(text: '10000');

  // ── Field Conditions ──────────────────────────────
  final _landSizeCtrl   = TextEditingController(text: '1');
  String _waterAvailability = 'High';
  String _soilType          = 'Clay';

  // ── Display → API value maps ──────────────────────
  static const _monthValues = {
    'January': '1', 'February': '2', 'March': '3', 'April': '4',
    'May': '5', 'June': '6', 'July': '7', 'August': '8',
    'September': '9', 'October': '10', 'November': '11', 'December': '12',
  };
  static const _categoryValues = {
    'All Categories': 'All',
    'Vegetables': 'Vegetables',
    'Fruits': 'Fruits',
    'Rice': 'Rice',
  };
  static const _riskValues = {
    'Low (Conservative)': 'low',
    'Medium (Balanced)': 'medium',
    'High (Aggressive)': 'high',
  };
  static const _waterValues = {
    'High': 'high', 'Medium': 'medium', 'Low': 'low',
  };
  static const _soilValues = {
    'Clay': 'clay', 'Loam': 'loam', 'Sandy': 'sandy', 'Clay Loam': 'clay_loam',
  };

  Future<void> _predict() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final data = {
      'latitude':               _latCtrl.text,
      'longitude':              _lonCtrl.text,
      'month':                  _monthValues[_month] ?? '1',
      'category':               _categoryValues[_category] ?? 'All',
      'risk_tolerance':         _riskValues[_riskTolerance] ?? 'medium',
      'previous_profitability': _prevProfitabilityCtrl.text,
      'budget':                 _budgetCtrl.text,
      'land_size':              _landSizeCtrl.text,
      'water_availability':     _waterValues[_waterAvailability] ?? 'medium',
      'soil_type':              _soilValues[_soilType] ?? 'loam',
    };

    // Cache data so Profitable Strategy can fetch from it
    AppCache.lastCultivationData = Map<String, String>.from(data);

    final result = await ApiService().predictCultivation(data);
    setState(() => _loading = false);

    if (!mounted) return;
    if (result['success'] == true) {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => ResultWebView(title: 'Cultivation Recommendations', html: result['html']),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Failed'), backgroundColor: Colors.red),
      );
    }
  }

  void _clear() {
    setState(() {
      _month = 'January';
      _category = 'All Categories';
      _riskTolerance = 'Low (Conservative)';
      _waterAvailability = 'High';
      _soilType = 'Clay';
    });
    _latCtrl.text = '7.75';
    _lonCtrl.text = '80.75';
    _prevProfitabilityCtrl.text = '20';
    _budgetCtrl.text = '10000';
    _landSizeCtrl.text = '1';
  }

  @override
  void dispose() {
    _latCtrl.dispose(); _lonCtrl.dispose();
    _prevProfitabilityCtrl.dispose(); _budgetCtrl.dispose();
    _landSizeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.g50,
      appBar: AppBar(
        title: const Text('Cultivation Targeting'),
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
              FlaskCard(
                icon: Icons.eco_outlined,
                title: 'Cultivation Parameters',
                children: [

                  // ── LOCATION ──────────────────────────
                  _SecLabel(Icons.location_on_outlined, 'LOCATION'),
                  const SizedBox(height: 12),

                  // Info banner with "Use My Location" button
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.g50,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: AppColors.bdr, width: 1.5),
                    ),
                    child: Row(children: [
                      const Icon(Icons.info_outline, color: AppColors.g600, size: 16),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Enter coordinates for accurate weather-based recommendations.',
                          style: TextStyle(fontSize: 12, color: AppColors.textMedium),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 34,
                        child: ElevatedButton.icon(
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
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.g600,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(7)),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            elevation: 0,
                          ),
                          icon: _gpsLoading
                              ? const SizedBox(
                                  width: 12, height: 12,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 1.5))
                              : const Icon(Icons.my_location, size: 13),
                          label: Text(_gpsLoading ? 'Locating…' : 'Use My Location',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 14),

                  // Latitude | Longitude
                  Row(children: [
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _latCtrl,
                          keyboardType: TextInputType.number,
                          decoration: flaskInput('Latitude *'),
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 4),
                        const Text('e.g. 7.75 for central Sri Lanka',
                            style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      ],
                    )),
                    const SizedBox(width: 14),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _lonCtrl,
                          keyboardType: TextInputType.number,
                          decoration: flaskInput('Longitude *'),
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 4),
                        const Text('e.g. 80.75 for central Sri Lanka',
                            style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      ],
                    )),
                  ]),
                  if (_locationName.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _LocationBadge(_locationName),
                  ],
                  const SizedBox(height: 22),

                  // ── CORE PARAMETERS ───────────────────
                  _SecLabel(Icons.tune, 'CORE PARAMETERS'),
                  const SizedBox(height: 12),

                  // Month | Category | Risk Tolerance
                  Row(children: [
                    Expanded(child: _drop('Month *', _month, _monthValues.keys.toList(),
                        (v) => setState(() => _month = v!))),
                    const SizedBox(width: 10),
                    Expanded(child: _drop('Category *', _category, _categoryValues.keys.toList(),
                        (v) => setState(() => _category = v!))),
                    const SizedBox(width: 10),
                    Expanded(child: _drop('Risk Tolerance *', _riskTolerance, _riskValues.keys.toList(),
                        (v) => setState(() => _riskTolerance = v!))),
                  ]),
                  const SizedBox(height: 14),

                  // Previous Profitability | Available Budget
                  Row(children: [
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _prevProfitabilityCtrl,
                          keyboardType: TextInputType.number,
                          decoration: flaskInput('Previous Profitability (%)'),
                        ),
                        const SizedBox(height: 4),
                        const Text('Your average profitability from previous crops',
                            style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      ],
                    )),
                    const SizedBox(width: 14),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _budgetCtrl,
                          keyboardType: TextInputType.number,
                          decoration: flaskInput('Available Budget (Rs.)'),
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 4),
                        const Text('Your cultivation budget for the season',
                            style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      ],
                    )),
                  ]),
                  const SizedBox(height: 22),

                  // ── FIELD CONDITIONS ──────────────────
                  _SecLabel(Icons.grass, 'FIELD CONDITIONS'),
                  const SizedBox(height: 12),

                  // Land Size | Water Availability | Soil Type
                  Row(children: [
                    Expanded(child: TextFormField(
                      controller: _landSizeCtrl,
                      keyboardType: TextInputType.number,
                      decoration: flaskInput('Land Size (Acres)'),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    )),
                    const SizedBox(width: 10),
                    Expanded(child: _drop('Water Availability', _waterAvailability,
                        _waterValues.keys.toList(),
                        (v) => setState(() => _waterAvailability = v!))),
                    const SizedBox(width: 10),
                    Expanded(child: _drop('Soil Type', _soilType,
                        _soilValues.keys.toList(),
                        (v) => setState(() => _soilType = v!))),
                  ]),
                ],
              ),
              const SizedBox(height: 20),

              // ── Buttons row ──────────────────────────
              Row(children: [
                Expanded(
                  flex: 4,
                  child: SubmitButton(
                    loading: _loading,
                    label: 'Get Recommendations',
                    loadingLabel: 'Analyzing…',
                    icon: Icons.search,
                    onPressed: _predict,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: SizedBox(
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: _loading ? null : _clear,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.g600,
                        side: const BorderSide(color: AppColors.bdr, width: 1.5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Clear',
                          style: TextStyle(fontSize: 13)),
                    ),
                  ),
                ),
              ]),
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
      items: items
          .map((i) => DropdownMenuItem(
              value: i, child: Text(i, overflow: TextOverflow.ellipsis)))
          .toList(),
      onChanged: cb,
    );
  }
}

// ── Location name badge shown after GPS fix ───────────
class _LocationBadge extends StatelessWidget {
  final String name;
  const _LocationBadge(this.name);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.g600,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.location_on, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Flexible(
            child: Text(name,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ),
        ]),
      );
}

// ── Section label inside a card ───────────────────────
class _SecLabel extends StatelessWidget {
  final IconData icon;
  final String text;
  const _SecLabel(this.icon, this.text);

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
      Text(text,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.g600,
            letterSpacing: 0.8,
          )),
    ]);
  }
}

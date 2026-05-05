import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/app_cache.dart';
import '../services/gps_service.dart';
import '../services/language_service.dart';
import '../widgets/language_switcher.dart';
import '../theme/app_theme.dart';
import 'cultivation_targeting_result_screen.dart';

class CultivationTargetingScreen extends StatefulWidget {
  const CultivationTargetingScreen({super.key});

  @override
  State<CultivationTargetingScreen> createState() => _CultivationTargetingScreenState();
}

class _CultivationTargetingScreenState extends State<CultivationTargetingScreen>
    with LangMixin {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  // ── Location ──────────────────────────────────────
  final _latCtrl = TextEditingController(text: '7.75');
  final _lonCtrl = TextEditingController(text: '80.75');
  bool _gpsLoading = false;
  String _locationName = '';

  // ── Core Parameters ───────────────────────────────
  String _month    = 'January';
  String _category = 'All Categories';

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
      'risk_tolerance':         'medium',
      'previous_profitability': _prevProfitabilityCtrl.text,
      'budget':                 _budgetCtrl.text,
      'land_size':              _landSizeCtrl.text,
      'water_availability':     _waterValues[_waterAvailability] ?? 'medium',
      'soil_type':              _soilValues[_soilType] ?? 'loam',
    };

    AppCache.lastCultivationData = Map<String, String>.from(data);

    final result = await ApiService().predictCultivation(data);
    setState(() => _loading = false);

    if (!mounted) return;
    if (result['success'] == true) {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => CultivationTargetingResultScreen(
            data: result['data'] as Map<String, dynamic>),
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
      _waterAvailability = 'High';
      _soilType = 'Clay';
      _locationName = '';
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
    final lang = LanguageService();
    return Scaffold(
      backgroundColor: AppColors.g50,
      appBar: AppBar(
        title: Text(lang.t('ct_title')),
        backgroundColor: AppColors.g600,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: const [LanguageSwitcher()],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              FlaskCard(
                icon: Icons.eco_outlined,
                title: lang.t('ct_card'),
                children: [

                  // ── LOCATION ──────────────────────────
                  _SecLabel(Icons.location_on_outlined, lang.t('ct_location')),
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
                      Expanded(
                        child: Text(
                          lang.t('ct_location_info'),
                          style: const TextStyle(fontSize: 12, color: AppColors.textMedium),
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
                          label: Text(
                            _gpsLoading ? lang.t('locating') : lang.t('use_my_location'),
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                          ),
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
                          decoration: flaskInput('${lang.t('latitude')} *'),
                          validator: (v) => v == null || v.isEmpty ? lang.t('required') : null,
                        ),
                        const SizedBox(height: 4),
                        Text(lang.t('ct_lat_hint'),
                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      ],
                    )),
                    const SizedBox(width: 14),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _lonCtrl,
                          keyboardType: TextInputType.number,
                          decoration: flaskInput('${lang.t('longitude')} *'),
                          validator: (v) => v == null || v.isEmpty ? lang.t('required') : null,
                        ),
                        const SizedBox(height: 4),
                        Text(lang.t('ct_lon_hint'),
                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      ],
                    )),
                  ]),
                  if (_locationName.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _LocationBadge(_locationName),
                  ],
                  const SizedBox(height: 22),

                  // ── CORE PARAMETERS ───────────────────
                  _SecLabel(Icons.tune, lang.t('ct_core_params')),
                  const SizedBox(height: 12),

                  Row(children: [
                    Expanded(child: _drop(lang.t('ct_month'), _month, _monthValues.keys.toList(),
                        (v) => setState(() => _month = v!))),
                    const SizedBox(width: 10),
                    Expanded(child: _drop(lang.t('ct_category'), _category, _categoryValues.keys.toList(),
                        (v) => setState(() => _category = v!))),
                  ]),
                  const SizedBox(height: 14),

                  Row(children: [
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _prevProfitabilityCtrl,
                          keyboardType: TextInputType.number,
                          decoration: flaskInput(lang.t('ct_prev_profit')),
                        ),
                        const SizedBox(height: 4),
                        Text(lang.t('ct_prev_hint'),
                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      ],
                    )),
                    const SizedBox(width: 14),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _budgetCtrl,
                          keyboardType: TextInputType.number,
                          decoration: flaskInput(lang.t('ct_budget')),
                          validator: (v) => v == null || v.isEmpty ? lang.t('required') : null,
                        ),
                        const SizedBox(height: 4),
                        Text(lang.t('ct_budget_hint'),
                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      ],
                    )),
                  ]),
                  const SizedBox(height: 22),

                  // ── FIELD CONDITIONS ──────────────────
                  _SecLabel(Icons.grass, lang.t('ct_field_cond')),
                  const SizedBox(height: 12),

                  Row(children: [
                    Expanded(child: TextFormField(
                      controller: _landSizeCtrl,
                      keyboardType: TextInputType.number,
                      decoration: flaskInput(lang.t('ct_land_size')),
                      validator: (v) => v == null || v.isEmpty ? lang.t('required') : null,
                    )),
                    const SizedBox(width: 10),
                    Expanded(child: _drop(lang.t('ct_water'), _waterAvailability,
                        _waterValues.keys.toList(),
                        (v) => setState(() => _waterAvailability = v!))),
                    const SizedBox(width: 10),
                    Expanded(child: _drop(lang.t('ct_soil'), _soilType,
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
                    label: lang.t('ct_get_rec'),
                    loadingLabel: lang.t('ct_analyzing'),
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
                      label: Text(lang.t('clear'),
                          style: const TextStyle(fontSize: 13)),
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

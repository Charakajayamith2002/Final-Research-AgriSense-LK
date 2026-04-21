import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/api_service.dart';
import '../services/gps_service.dart';
import '../services/language_service.dart';
import '../widgets/language_switcher.dart';
import '../widgets/location_dropdowns.dart';
import 'market_ranking_result_screen.dart';
import '../theme/app_theme.dart';

class MarketRankingScreen extends StatefulWidget {
  const MarketRankingScreen({super.key});

  @override
  State<MarketRankingScreen> createState() => _MarketRankingScreenState();
}

class _MarketRankingScreenState extends State<MarketRankingScreen> with LangMixin {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  // ── Role ──────────────────────────────────────────
  String _role = '';   // starts empty → hint "Select Role"

  // ── Costs ─────────────────────────────────────────
  final _transportCostCtrl   = TextEditingController(text: '160');
  final _addTransportCtrl    = TextEditingController(text: '0');
  final _cultivationCostCtrl = TextEditingController(text: '0');
  final _referencePriceCtrl  = TextEditingController();

  // ── Item & Quantity ───────────────────────────────
  String _item         = '';          // starts empty → hint "Select Item"
  String _priceType    = 'Wholesale';
  String _quantityUnit = 'kg';
  final _quantityCtrl  = TextEditingController(text: '1');

  // ── Location ──────────────────────────────────────
  String _province   = '';
  String _district   = '';
  String _dsDivision = '';
  final _latCtrl = TextEditingController(text: '7.2906');
  final _lonCtrl = TextEditingController(text: '80.6337');
  bool _gpsLoading = false;
  String _locationName = '';

  // ── Map ───────────────────────────────────────────
  final _mapController = MapController();

  // Known market coordinates (matches Flask backend)
  static const Map<String, List<double>> _marketCoords = {
    'Pettah':            [6.9344, 79.8428],
    'Dambulla':          [7.8731, 80.6518],
    'Narahenpita':       [6.9013, 79.8757],
    'Marandagahamula':   [7.3333, 80.3833],
    'Peliyagoda':        [6.9600, 79.8900],
    'Negombo':           [7.2096, 79.8378],
  };

  static const List<String> _items = [
    'Tomato', 'Carrot', 'Cabbage', 'Beans', 'Potato', 'Onion', 'Leeks',
    'Mango', 'Banana', 'Papaya', 'Pineapple',
    'White Rice', 'Red Rice',
    'Coconut', 'Ginger',
    'Tuna', 'Seer Fish', 'Sardine', 'Prawn',
  ];

  @override
  void initState() {
    super.initState();
    _latCtrl.addListener(_refreshMap);
    _lonCtrl.addListener(_refreshMap);
  }

  void _refreshMap() {
    final lat = double.tryParse(_latCtrl.text);
    final lon = double.tryParse(_lonCtrl.text);
    if (lat != null && lon != null) {
      setState(() {}); // triggers map rebuild with new coords
    }
  }

  LatLng get _userLocation => LatLng(
        double.tryParse(_latCtrl.text) ?? 7.2906,
        double.tryParse(_lonCtrl.text) ?? 80.6337,
      );

  // Formula hint shown based on role
  String get _formulaHint {
    final lang = LanguageService();
    if (_role == 'seller') return lang.t('mr_formula_seller');
    if (_role == 'buyer')  return lang.t('mr_formula_buyer');
    return lang.t('mr_formula_default');
  }

  Future<void> _predict() async {
    if (!_formKey.currentState!.validate()) return;
    final lang = LanguageService();
    if (_role.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(lang.t('mr_select_role_err')),
        backgroundColor: Colors.red,
      ));
      return;
    }
    if (_item.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(lang.t('mr_select_item_err')),
        backgroundColor: Colors.red,
      ));
      return;
    }
    setState(() => _loading = true);

    final data = {
      'user_role':               _role,
      'transport_cost':          _transportCostCtrl.text,
      'additional_transport_cost': _addTransportCtrl.text,
      'cultivation_cost':        _cultivationCostCtrl.text,
      'reference_price':         _referencePriceCtrl.text,
      'item':                    _item,
      'price_type':              _priceType,
      'quantity_unit':           _quantityUnit,
      'quantity':                _quantityCtrl.text,
      'province':                _province,
      'district':                _district,
      'ds_division':             _dsDivision,
      'latitude':                _latCtrl.text,
      'longitude':               _lonCtrl.text,
    };

    final result = await ApiService().predictMarketRanking(data);
    setState(() => _loading = false);

    if (!mounted) return;
    if (result['success'] == true) {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => MarketRankingResultScreen(
            data: result['data'] as Map<String, dynamic>),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Failed'), backgroundColor: Colors.red),
      );
    }
  }

  void _reset() {
    setState(() {
      _role = '';
      _item = '';
      _priceType = 'Wholesale';
      _quantityUnit = 'kg';
      _province = '';
      _district = '';
      _dsDivision = '';
    });
    _transportCostCtrl.text = '160';
    _addTransportCtrl.text  = '0';
    _cultivationCostCtrl.text = '0';
    _referencePriceCtrl.clear();
    _quantityCtrl.text = '1';
    _latCtrl.text = '7.2906';
    _lonCtrl.text = '80.6337';
  }

  @override
  void dispose() {
    _latCtrl.removeListener(_refreshMap);
    _lonCtrl.removeListener(_refreshMap);
    _mapController.dispose();
    _transportCostCtrl.dispose(); _addTransportCtrl.dispose();
    _cultivationCostCtrl.dispose(); _referencePriceCtrl.dispose();
    _quantityCtrl.dispose(); _latCtrl.dispose(); _lonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = LanguageService();
    return Scaffold(
      backgroundColor: AppColors.g50,
      appBar: AppBar(
        title: Text(lang.t('mr_title')),
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
              // ── Market Search Parameters ─────────────
              FlaskCard(
                icon: Icons.tune,
                title: lang.t('mr_card'),
                children: [
                  // ── ROLE SELECTION ──────────────────
                  _SecLabel(Icons.person_outline, lang.t('mr_role_section')),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: 220,
                    child: _dropNullable(
                      '${lang.t('select_role')} *', _role, ['buyer', 'seller'],
                      (v) => setState(() => _role = v ?? ''),
                      hint: lang.t('select_role'),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── COST INFORMATION ────────────────
                  _SecLabel(Icons.attach_money, lang.t('mr_cost_section')),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _transportCostCtrl,
                          keyboardType: TextInputType.number,
                          decoration: flaskInput('${lang.t('mr_transport')} *'),
                          validator: (v) => v == null || v.isEmpty ? lang.t('required') : null,
                        ),
                        const SizedBox(height: 4),
                        const Text('Default: Rs.160 per km',
                            style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      ],
                    )),
                    const SizedBox(width: 14),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _addTransportCtrl,
                          keyboardType: TextInputType.number,
                          decoration: flaskInput(lang.t('mr_add_transport')),
                        ),
                        const SizedBox(height: 4),
                        const Text('Fixed extra charge (e.g. refrigerated vehicle)',
                            style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      ],
                    )),
                  ]),
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _cultivationCostCtrl,
                          keyboardType: TextInputType.number,
                          decoration: flaskInput(lang.t('mr_cult_cost')),
                        ),
                        const SizedBox(height: 4),
                        const Text('Required only for Sellers',
                            style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      ],
                    )),
                    const SizedBox(width: 14),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _referencePriceCtrl,
                          keyboardType: TextInputType.number,
                          decoration: flaskInput(lang.t('mr_ref_price'),
                              hint: 'Optional — improves accuracy'),
                        ),
                        const SizedBox(height: 4),
                        const Text("Enter today's price if you know it",
                            style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      ],
                    )),
                  ]),
                  const SizedBox(height: 20),

                  // ── TARGET ITEM & QUANTITY ───────────
                  _SecLabel(Icons.inventory_2_outlined, lang.t('mr_item_section')),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _dropNullable(
                      '${lang.t('mr_item')}', _item, _items,
                      (v) => setState(() => _item = v ?? ''),
                      hint: lang.t('mr_select_item'),
                    )),
                    const SizedBox(width: 14),
                    Expanded(child: _drop('${lang.t('mr_price_type')} *', _priceType,
                        ['Wholesale', 'Retail'],
                        (v) => setState(() => _priceType = v!))),
                  ]),
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(child: _drop('${lang.t('mr_unit')} *', _quantityUnit,
                        ['kg', 'g'],
                        (v) => setState(() => _quantityUnit = v!))),
                    const SizedBox(width: 14),
                    Expanded(child: TextFormField(
                      controller: _quantityCtrl,
                      keyboardType: TextInputType.number,
                      decoration: flaskInput('${lang.t('mr_quantity')} *'),
                      validator: (v) => v == null || v.isEmpty ? lang.t('required') : null,
                    )),
                  ]),
                  const SizedBox(height: 14),

                  // Formula hint box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
                    decoration: BoxDecoration(
                      color: AppColors.g50,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: AppColors.bdr, width: 1.5),
                    ),
                    child: Text(
                      _formulaHint,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textMedium),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── YOUR LOCATION ────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: AppColors.bdr),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1234912F),
                      blurRadius: 24,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SecLabel(Icons.location_on_outlined, lang.t('mr_your_location')),
                    const SizedBox(height: 8),
                    const Text(
                      'Select your location using the dropdowns below, or use GPS to auto-fill coordinates.',
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 14),

                    // Province | District | DS Division (horizontal)
                    LocationDropdowns(
                      horizontal: true,
                      onChanged: (p, d, ds) => setState(() {
                        _province   = p;
                        _district   = d;
                        _dsDivision = ds;
                      }),
                      onCoordinatesResolved: (lat, lon) {
                        setState(() {
                          _latCtrl.text = lat.toStringAsFixed(4);
                          _lonCtrl.text = lon.toStringAsFixed(4);
                        });
                      },
                    ),
                    const SizedBox(height: 14),

                    // GPS dark panel
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
                            const Icon(Icons.my_location,
                                color: Colors.white70, size: 13),
                            const SizedBox(width: 6),
                            Text(lang.t('mr_gps_coords'),
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white.withValues(alpha: 0.75),
                                    letterSpacing: 0.8)),
                          ]),
                          const SizedBox(height: 10),
                          // Use My Current Location button
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
                                side: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.5)),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              icon: _gpsLoading
                                  ? const SizedBox(
                                      width: 14, height: 14,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 1.5))
                                  : const Icon(Icons.navigation, size: 15),
                              label: Text(
                                  _gpsLoading ? lang.t('locating') : lang.t('use_my_location'),
                                  style: const TextStyle(fontSize: 13)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(children: [
                            Expanded(child: TextFormField(
                              controller: _latCtrl,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Colors.white),
                              decoration: _darkInput(lang.t('latitude')),
                            )),
                            const SizedBox(width: 12),
                            Expanded(child: TextFormField(
                              controller: _lonCtrl,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Colors.white),
                              decoration: _darkInput(lang.t('longitude')),
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
              ),
              const SizedBox(height: 20),

              // ── Submit + Reset row ───────────────────
              Row(children: [
                Expanded(
                  flex: 3,
                  child: SubmitButton(
                    loading: _loading,
                    label: lang.t('mr_find'),
                    loadingLabel: lang.t('analyzing'),
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
                      onPressed: _loading ? null : _reset,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.g600,
                        side: const BorderSide(color: AppColors.bdr, width: 1.5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.refresh, size: 16),
                      label: Text(lang.t('mr_reset'),
                          style: const TextStyle(fontSize: 13)),
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 20),

              // ── Market Locations Map ─────────────────
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: AppColors.bdr),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1234912F),
                      blurRadius: 24,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Header
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.g600, AppColors.g400],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      child: Row(children: [
                        Container(
                          width: 30, height: 30,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.map_outlined, color: Colors.white, size: 16),
                        ),
                        const SizedBox(width: 10),
                        const Text('Market Locations Map',   // map section header — kept in English
                            style: TextStyle(color: Colors.white, fontSize: 14,
                                fontWeight: FontWeight.w600)),
                      ]),
                    ),
                    // Map body
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                      child: SizedBox(
                        height: 340,
                        child: FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: _userLocation,
                            initialZoom: 8.5,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.agrisense.app',
                            ),
                            MarkerLayer(markers: _buildMarkers()),
                          ],
                        ),
                      ),
                    ),
                    // Legend
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _legendItem(Icons.location_on, Colors.red, lang.t('mr_your_location')),
                          const SizedBox(width: 24),
                          _legendItem(Icons.location_on, Colors.blue, 'Market Locations'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];

    // User location — red pin
    markers.add(Marker(
      point: _userLocation,
      width: 40,
      height: 50,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.red.shade700,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text('You',
                style: TextStyle(color: Colors.white, fontSize: 9,
                    fontWeight: FontWeight.bold)),
          ),
          Icon(Icons.location_on, color: Colors.red.shade700, size: 28),
        ],
      ),
    ));

    // Market pins — green
    for (final entry in _marketCoords.entries) {
      markers.add(Marker(
        point: LatLng(entry.value[0], entry.value[1]),
        width: 80,
        height: 54,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.g600,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(entry.key,
                  style: const TextStyle(color: Colors.white, fontSize: 9,
                      fontWeight: FontWeight.bold)),
            ),
            const Icon(Icons.store, color: AppColors.g600, size: 26),
          ],
        ),
      ));
    }
    return markers;
  }

  Widget _legendItem(IconData icon, Color color, String label) {
    return Row(children: [
      Icon(icon, color: color, size: 16),
      const SizedBox(width: 5),
      Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMedium)),
    ]);
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

  Widget _dropNullable(
    String label,
    String value,
    List<String> items,
    ValueChanged<String?> cb, {
    String? hint,
  }) {
    return DropdownButtonFormField<String>(
      value: value.isEmpty ? null : value,
      decoration: flaskInput(label),
      isExpanded: true,
      hint: hint != null
          ? Text(hint,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13))
          : null,
      items: items
          .map((i) => DropdownMenuItem(
              value: i, child: Text(i, overflow: TextOverflow.ellipsis)))
          .toList(),
      onChanged: cb,
    );
  }

  InputDecoration _darkInput(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70, fontSize: 12),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.12),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              BorderSide(color: Colors.white.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              BorderSide(color: Colors.white.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.white, width: 1.5),
        ),
      );
}

// ── Section label inside a card body ─────────────────
class _SecLabel extends StatelessWidget {
  final IconData icon;
  final String text;
  const _SecLabel(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 14,
        height: 14,
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

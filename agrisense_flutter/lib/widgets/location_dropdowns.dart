import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

/// Cascading Province → District → DS Division dropdowns.
/// Matches Flask's location panel design.
/// When a DS Division is selected, lat/lon are auto-filled if available.
class LocationDropdowns extends StatefulWidget {
  /// Called whenever any value changes; all three strings passed together.
  final void Function(String province, String district, String dsDivision) onChanged;

  /// Optional: called with auto-resolved coordinates when DS Division is chosen.
  final void Function(double lat, double lon)? onCoordinatesResolved;

  /// When true, renders Province | District | DS Division in a single Row.
  final bool horizontal;

  const LocationDropdowns({
    super.key,
    required this.onChanged,
    this.onCoordinatesResolved,
    this.horizontal = false,
  });

  @override
  State<LocationDropdowns> createState() => _LocationDropdownsState();
}

class _LocationDropdownsState extends State<LocationDropdowns> {
  static const List<String> _provinces = [
    'Western Province',
    'Central Province',
    'Southern Province',
    'Northern Province',
    'Eastern Province',
    'North Western Province',
    'North Central Province',
    'Uva Province',
    'Sabaragamuwa Province',
  ];

  String _province   = '';
  String _district   = '';
  String _dsDivision = '';

  List<String> _districts   = [];
  List<String> _dsDivisions = [];

  bool _loadingDistricts   = false;
  bool _loadingDsDivisions = false;

  // ── province changed ─────────────────────────────────────────
  Future<void> _onProvinceChanged(String? value) async {
    final province = value ?? '';
    setState(() {
      _province     = province;
      _district     = '';
      _dsDivision   = '';
      _districts    = [];
      _dsDivisions  = [];
    });
    widget.onChanged(province, '', '');
    if (province.isEmpty) return;

    setState(() => _loadingDistricts = true);
    final districts = await ApiService().getDistricts(province);
    if (mounted) {
      setState(() {
        _districts        = districts;
        _loadingDistricts = false;
      });
    }
  }

  // ── district changed ─────────────────────────────────────────
  Future<void> _onDistrictChanged(String? value) async {
    final district = value ?? '';
    setState(() {
      _district     = district;
      _dsDivision   = '';
      _dsDivisions  = [];
    });
    widget.onChanged(_province, district, '');
    if (district.isEmpty || _province.isEmpty) return;

    setState(() => _loadingDsDivisions = true);
    final divs = await ApiService().getDsDivisions(_province, district);
    if (mounted) {
      setState(() {
        _dsDivisions          = divs;
        _loadingDsDivisions   = false;
      });
    }
  }

  // ── DS division changed ──────────────────────────────────────
  Future<void> _onDsDivisionChanged(String? value) async {
    final ds = value ?? '';
    setState(() => _dsDivision = ds);
    widget.onChanged(_province, _district, ds);
    if (ds.isEmpty) return;

    // Auto-resolve coordinates
    if (widget.onCoordinatesResolved != null) {
      final coords = await ApiService().getDsCoordinates(_province, _district, ds);
      if (coords != null && mounted) {
        widget.onCoordinatesResolved!(coords['lat']!, coords['lon']!);
      }
    }
  }

  Widget _provinceWidget() => DropdownButtonFormField<String>(
        value: _province.isEmpty ? null : _province,
        decoration: flaskInput('Province'),
        isExpanded: true,
        hint: const Text('Select Province',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
        items: _provinces
            .map((p) => DropdownMenuItem(
                value: p, child: Text(p, overflow: TextOverflow.ellipsis)))
            .toList(),
        onChanged: _onProvinceChanged,
      );

  Widget _districtWidget() => _province.isEmpty
      ? _DisabledField(label: 'District', hint: 'Select Province first')
      : _loadingDistricts
          ? _LoadingField(label: 'District')
          : _districts.isEmpty
              ? _DisabledField(label: 'District', hint: 'No districts found')
              : DropdownButtonFormField<String>(
                  value: _district.isEmpty ? null : _district,
                  decoration: flaskInput('District'),
                  isExpanded: true,
                  hint: const Text('Select District',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                  items: _districts
                      .map((d) => DropdownMenuItem(
                          value: d, child: Text(d, overflow: TextOverflow.ellipsis)))
                      .toList(),
                  onChanged: _onDistrictChanged,
                );

  Widget _dsDivisionWidget() => _district.isEmpty
      ? _DisabledField(label: 'DS Division', hint: 'Select District first')
      : _loadingDsDivisions
          ? _LoadingField(label: 'DS Division')
          : _dsDivisions.isEmpty
              ? _DisabledField(label: 'DS Division', hint: 'No DS Divisions found')
              : DropdownButtonFormField<String>(
                  value: _dsDivision.isEmpty ? null : _dsDivision,
                  decoration: flaskInput('DS Division'),
                  isExpanded: true,
                  hint: const Text('Select DS Division',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                  items: _dsDivisions
                      .map((ds) => DropdownMenuItem(
                          value: ds, child: Text(ds, overflow: TextOverflow.ellipsis)))
                      .toList(),
                  onChanged: _onDsDivisionChanged,
                );

  @override
  Widget build(BuildContext context) {
    if (widget.horizontal) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _provinceWidget()),
          const SizedBox(width: 10),
          Expanded(child: _districtWidget()),
          const SizedBox(width: 10),
          Expanded(child: _dsDivisionWidget()),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _provinceWidget(),
        const SizedBox(height: 14),
        _districtWidget(),
        const SizedBox(height: 14),
        _dsDivisionWidget(),
      ],
    );
  }
}

// ── Disabled placeholder field ────────────────────────────────
class _DisabledField extends StatelessWidget {
  final String label;
  final String hint;
  const _DisabledField({required this.label, required this.hint});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
        const SizedBox(height: 5),
        Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 13),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: AppColors.bdr, width: 1.5),
          ),
          alignment: Alignment.centerLeft,
          child: Text(hint,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
        ),
      ],
    );
  }
}

// ── Loading placeholder field ─────────────────────────────────
class _LoadingField extends StatelessWidget {
  final String label;
  const _LoadingField({required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMedium)),
        const SizedBox(height: 5),
        Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 13),
          decoration: BoxDecoration(
            color: AppColors.g50,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: AppColors.bdr, width: 1.5),
          ),
          child: const Row(children: [
            SizedBox(
              width: 16, height: 16,
              child: CircularProgressIndicator(color: AppColors.g400, strokeWidth: 2),
            ),
            SizedBox(width: 10),
            Text('Loading…', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
          ]),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/result_webview.dart';

class CultivationTargetingScreen extends StatefulWidget {
  const CultivationTargetingScreen({super.key});

  @override
  State<CultivationTargetingScreen> createState() => _CultivationTargetingScreenState();
}

class _CultivationTargetingScreenState extends State<CultivationTargetingScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  String _province = 'Western Province';
  String _district = 'Colombo District';
  String _dsDivision = 'Colombo';
  String _cropType = 'Vegetables';
  String _soilType = 'Loamy';
  String _season = 'Maha';
  final _rainfallCtrl = TextEditingController(text: '1500');
  final _tempCtrl = TextEditingController(text: '28');
  final _areaCtrl = TextEditingController(text: '1.0');

  final List<String> _provinces = [
    'Western Province', 'Central Province', 'Southern Province',
    'Northern Province', 'Eastern Province', 'North Western Province',
    'North Central Province', 'Uva Province', 'Sabaragamuwa Province'
  ];
  final List<String> _cropTypes = ['Vegetables', 'Fruits', 'Grains', 'Spices', 'Root Crops'];
  final List<String> _soilTypes = ['Loamy', 'Sandy', 'Clay', 'Silty', 'Peaty'];
  final List<String> _seasons = ['Maha', 'Yala', 'Off-season'];

  Future<void> _predict() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final data = {
      'province': _province,
      'district': _district,
      'ds_division': _dsDivision,
      'crop_type': _cropType,
      'soil_type': _soilType,
      'season': _season,
      'rainfall': _rainfallCtrl.text,
      'temperature': _tempCtrl.text,
      'area': _areaCtrl.text,
    };

    final result = await ApiService().predictCultivation(data);
    setState(() => _loading = false);

    if (result['success'] == true && mounted) {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => ResultWebView(title: 'Cultivation Recommendations', html: result['html']),
      ));
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Failed'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8E9),
      appBar: AppBar(title: const Text('Cultivation Targeting')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _card('Location', Icons.location_on, [
                _dropdown('Province', _province, _provinces, (v) => setState(() => _province = v!)),
                _textInput('District', _district, (v) => _district = v),
                _textInput('DS Division', _dsDivision, (v) => _dsDivision = v),
              ]),
              const SizedBox(height: 12),
              _card('Crop & Soil', Icons.grass, [
                _dropdown('Crop Type', _cropType, _cropTypes, (v) => setState(() => _cropType = v!)),
                _dropdown('Soil Type', _soilType, _soilTypes, (v) => setState(() => _soilType = v!)),
                _dropdown('Season', _season, _seasons, (v) => setState(() => _season = v!)),
              ]),
              const SizedBox(height: 12),
              _card('Climate & Land', Icons.wb_sunny, [
                _field('Annual Rainfall (mm)', _rainfallCtrl),
                _field('Average Temperature (°C)', _tempCtrl),
                _field('Land Area (acres)', _areaCtrl),
              ]),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _predict,
                  icon: _loading
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.agriculture),
                  label: Text(_loading ? 'Analyzing...' : 'Get Recommendations',
                      style: const TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card(String title, IconData icon, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, color: const Color(0xFF2E7D32), size: 20),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ]),
            const Divider(),
            ...children.map((w) => Padding(padding: const EdgeInsets.only(bottom: 12), child: w)),
          ],
        ),
      ),
    );
  }

  Widget _dropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(labelText: label),
      items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _textInput(String label, String value, ValueChanged<String> onChanged) {
    return TextFormField(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      onChanged: onChanged,
      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
    );
  }

  Widget _field(String label, TextEditingController ctrl) {
    return TextFormField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label),
      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
    );
  }

}

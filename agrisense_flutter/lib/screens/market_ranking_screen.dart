import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/result_webview.dart';

class MarketRankingScreen extends StatefulWidget {
  const MarketRankingScreen({super.key});

  @override
  State<MarketRankingScreen> createState() => _MarketRankingScreenState();
}

class _MarketRankingScreenState extends State<MarketRankingScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  String _category = 'Vegetables';
  String _item = 'Tomato';
  String _province = 'Western Province';
  String _season = 'Maha';
  final _quantityCtrl = TextEditingController(text: '100');
  final _priceCtrl = TextEditingController(text: '200');

  final List<String> _categories = ['Vegetables', 'Fruits', 'Grains', 'Spices'];
  final List<String> _provinces = [
    'Western Province', 'Central Province', 'Southern Province',
    'Northern Province', 'Eastern Province', 'North Western Province',
    'North Central Province', 'Uva Province', 'Sabaragamuwa Province'
  ];
  final List<String> _seasons = ['Maha', 'Yala', 'Off-season'];

  Future<void> _predict() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final data = {
      'category': _category,
      'item': _item,
      'province': _province,
      'season': _season,
      'quantity': _quantityCtrl.text,
      'price': _priceCtrl.text,
    };

    final result = await ApiService().predictMarketRanking(data);
    setState(() => _loading = false);

    if (result['success'] == true && mounted) {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => ResultWebView(title: 'Market Ranking Result', html: result['html']),
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
      appBar: AppBar(title: const Text('Market Ranking')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _sectionCard('Crop Details', Icons.grass, [
                _dropdown('Category', _category, _categories, (v) => setState(() => _category = v!)),
                _field('Crop / Item Name', _item, (v) => _item = v),
                _dropdown('Province', _province, _provinces, (v) => setState(() => _province = v!)),
                _dropdown('Season', _season, _seasons, (v) => setState(() => _season = v!)),
              ]),
              const SizedBox(height: 12),
              _sectionCard('Quantity & Price', Icons.attach_money, [
                _textField('Quantity (kg)', _quantityCtrl),
                _textField('Expected Price (Rs.)', _priceCtrl),
              ]),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6A1B9A)),
                  onPressed: _loading ? null : _predict,
                  icon: _loading
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.store),
                  label: Text(_loading ? 'Analyzing...' : 'Find Best Markets',
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

  Widget _sectionCard(String title, IconData icon, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, color: const Color(0xFF6A1B9A), size: 20),
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

  Widget _field(String label, String value, ValueChanged<String> onChanged) {
    return TextFormField(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      onChanged: onChanged,
      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
    );
  }

  Widget _textField(String label, TextEditingController ctrl) {
    return TextFormField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label),
      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
    );
  }
}

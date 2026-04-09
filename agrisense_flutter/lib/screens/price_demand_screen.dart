import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/result_webview.dart';

class PriceDemandScreen extends StatefulWidget {
  const PriceDemandScreen({super.key});

  @override
  State<PriceDemandScreen> createState() => _PriceDemandScreenState();
}

class _PriceDemandScreenState extends State<PriceDemandScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  String? _resultHtml;

  // Form fields
  String _category = 'Vegetables';
  String _originType = 'local';
  String _priceType = 'wholesale';
  String _market = 'Colombo';
  String _season = 'Maha';
  String _marketSentiment = 'neutral';
  String _supplyStatus = 'adequate';
  final _previousPriceCtrl = TextEditingController(text: '250');
  final _yearCtrl = TextEditingController(text: '2024');
  final _monthCtrl = TextEditingController(text: '1');
  final _dayCtrl = TextEditingController(text: '1');
  final _rollingMean7Ctrl = TextEditingController(text: '245');
  final _rollingStd7Ctrl = TextEditingController(text: '8');
  final _rollingMean3Ctrl = TextEditingController(text: '248');
  final _volatilityCtrl = TextEditingController(text: '1.2');

  final List<String> _categories = ['Vegetables', 'Fruits', 'Grains', 'Spices'];
  final List<String> _markets = ['Colombo', 'Kandy', 'Galle', 'Jaffna', 'Matara', 'Kurunegala'];
  final List<String> _seasons = ['Maha', 'Yala', 'Off-season'];
  final List<String> _sentiments = ['positive', 'neutral', 'negative'];
  final List<String> _supplyStatuses = ['adequate', 'scarce', 'surplus'];

  Future<void> _predict() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _resultHtml = null; });

    final data = {
      'category': _category,
      'item_standard': _category,
      'origin_type': _originType,
      'price_type': _priceType,
      'market': _market,
      'previous_price': _previousPriceCtrl.text,
      'year': _yearCtrl.text,
      'month': _monthCtrl.text,
      'day': _dayCtrl.text,
      'dayofweek': '0',
      'week': '1',
      'quarter': '1',
      'season': _season,
      'rolling_mean_7': _rollingMean7Ctrl.text,
      'rolling_std_7': _rollingStd7Ctrl.text,
      'rolling_mean_3': _rollingMean3Ctrl.text,
      'volatility_index': _volatilityCtrl.text,
      'market_sentiment': _marketSentiment,
      'supply_status': _supplyStatus,
    };

    final result = await ApiService().predictPriceDemand(data);
    setState(() { _loading = false; });

    if (result['success'] == true) {
      if (mounted) {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => ResultWebView(title: 'Price & Demand Result', html: result['html']),
        ));
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Prediction failed'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8E9),
      appBar: AppBar(
        title: const Text('Price & Demand Prediction'),
        leading: const BackButton(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildCard('Crop Information', Icons.grass, [
                _buildDropdown('Category', _category, _categories, (v) => setState(() => _category = v!)),
                _buildDropdown('Market', _market, _markets, (v) => setState(() => _market = v!)),
                _buildDropdown('Origin Type', _originType, ['local', 'imported'],
                    (v) => setState(() => _originType = v!)),
                _buildDropdown('Price Type', _priceType, ['wholesale', 'retail'],
                    (v) => setState(() => _priceType = v!)),
              ]),
              const SizedBox(height: 12),
              _buildCard('Date & Season', Icons.calendar_today, [
                Row(children: [
                  Expanded(child: _buildTextField('Year', _yearCtrl)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildTextField('Month (1-12)', _monthCtrl)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildTextField('Day', _dayCtrl)),
                ]),
                _buildDropdown('Season', _season, _seasons, (v) => setState(() => _season = v!)),
              ]),
              const SizedBox(height: 12),
              _buildCard('Price Data', Icons.attach_money, [
                _buildTextField('Previous Price (Rs.)', _previousPriceCtrl),
                Row(children: [
                  Expanded(child: _buildTextField('Rolling Mean 7d', _rollingMean7Ctrl)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildTextField('Rolling Std 7d', _rollingStd7Ctrl)),
                ]),
                _buildTextField('Rolling Mean 3d', _rollingMean3Ctrl),
                _buildTextField('Volatility Index', _volatilityCtrl),
              ]),
              const SizedBox(height: 12),
              _buildCard('Market Conditions', Icons.store, [
                _buildDropdown('Market Sentiment', _marketSentiment, _sentiments,
                    (v) => setState(() => _marketSentiment = v!)),
                _buildDropdown('Supply Status', _supplyStatus, _supplyStatuses,
                    (v) => setState(() => _supplyStatus = v!)),
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
                      : const Icon(Icons.trending_up),
                  label: Text(_loading ? 'Predicting...' : 'Predict Price & Demand',
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

  Widget _buildCard(String title, IconData icon, List<Widget> children) {
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

  Widget _buildDropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(labelText: label),
      items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildTextField(String label, TextEditingController ctrl) {
    return TextFormField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label),
      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
    );
  }
}

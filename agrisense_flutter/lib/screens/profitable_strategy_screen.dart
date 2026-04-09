import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/result_webview.dart';

class ProfitableStrategyScreen extends StatefulWidget {
  const ProfitableStrategyScreen({super.key});

  @override
  State<ProfitableStrategyScreen> createState() => _ProfitableStrategyScreenState();
}

class _ProfitableStrategyScreenState extends State<ProfitableStrategyScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  String _cropType = 'Vegetables';
  String _farmSize = 'small';
  String _region = 'Western Province';
  String _experience = 'beginner';
  String _marketAccess = 'local';
  final _budgetCtrl = TextEditingController(text: '50000');
  final _landAreaCtrl = TextEditingController(text: '1.0');

  final List<String> _cropTypes = ['Vegetables', 'Fruits', 'Grains', 'Spices', 'Mixed'];
  final List<String> _farmSizes = ['small', 'medium', 'large'];
  final List<String> _regions = [
    'Western Province', 'Central Province', 'Southern Province',
    'Northern Province', 'Eastern Province', 'North Western Province',
    'North Central Province', 'Uva Province', 'Sabaragamuwa Province'
  ];
  final List<String> _experiences = ['beginner', 'intermediate', 'expert'];
  final List<String> _marketAccesses = ['local', 'regional', 'national', 'export'];

  Future<void> _predict() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final data = {
      'crop_type': _cropType,
      'farm_size': _farmSize,
      'region': _region,
      'experience_level': _experience,
      'market_access': _marketAccess,
      'budget': _budgetCtrl.text,
      'land_area': _landAreaCtrl.text,
    };

    final result = await ApiService().predictProfitableStrategy(data);
    setState(() => _loading = false);

    if (result['success'] == true && mounted) {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => ResultWebView(title: 'Profitable Strategy', html: result['html']),
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
      appBar: AppBar(
        title: const Text('Profitable Strategy'),
        backgroundColor: const Color(0xFFF9A825),
        foregroundColor: Colors.black87,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Info banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9A825).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFF9A825).withOpacity(0.5)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lightbulb, color: Color(0xFFF9A825)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Get AI-powered business strategy recommendations for maximum profit',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _card('Farm Profile', Icons.agriculture, [
                _dropdown('Crop Type', _cropType, _cropTypes, (v) => setState(() => _cropType = v!)),
                _dropdown('Farm Size', _farmSize, _farmSizes, (v) => setState(() => _farmSize = v!)),
                _dropdown('Region', _region, _regions, (v) => setState(() => _region = v!)),
                _textField('Land Area (acres)', _landAreaCtrl),
              ]),
              const SizedBox(height: 12),
              _card('Farmer Profile', Icons.person, [
                _dropdown('Experience Level', _experience, _experiences,
                    (v) => setState(() => _experience = v!)),
                _dropdown('Market Access', _marketAccess, _marketAccesses,
                    (v) => setState(() => _marketAccess = v!)),
                _textField('Available Budget (Rs.)', _budgetCtrl),
              ]),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF9A825),
                    foregroundColor: Colors.black87,
                  ),
                  onPressed: _loading ? null : _predict,
                  icon: _loading
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.lightbulb),
                  label: Text(_loading ? 'Generating Strategy...' : 'Get Profitable Strategy',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
              Icon(icon, color: const Color(0xFFF9A825), size: 20),
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

  Widget _textField(String label, TextEditingController ctrl) {
    return TextFormField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label),
      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
    );
  }

}

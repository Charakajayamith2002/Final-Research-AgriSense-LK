import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/language_service.dart';
import '../widgets/language_switcher.dart';
import '../widgets/result_webview.dart';
import '../theme/app_theme.dart';

class PriceDemandScreen extends StatefulWidget {
  const PriceDemandScreen({super.key});

  @override
  State<PriceDemandScreen> createState() => _PriceDemandScreenState();
}

class _PriceDemandScreenState extends State<PriceDemandScreen> with LangMixin {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  // ── Product Information ────────────────────────────
  String _category   = 'Vegetables';
  String _item       = 'Tomato';
  String _originType = 'Local';
  String _priceType  = 'Wholesale';
  String _market     = 'Pettah';
  final _previousPriceCtrl = TextEditingController(text: '250');

  // ── Date Information ───────────────────────────────
  final _yearCtrl  = TextEditingController(text: '2025');
  String _month    = '1';
  final _dayCtrl   = TextEditingController(text: '15');
  String _dayOfWeek = '0';
  final _weekCtrl  = TextEditingController(text: '3');
  String _quarter  = '1';
  String _season   = 'Maha';

  // ── Historical Statistics ──────────────────────────
  final _rollingMean7Ctrl = TextEditingController(text: '245');
  final _rollingStd7Ctrl  = TextEditingController(text: '8');
  final _rollingMean3Ctrl = TextEditingController(text: '248');
  final _volatilityCtrl   = TextEditingController(text: '1.2');

  // ── Market Conditions ─────────────────────────────
  String _marketSentiment = 'neutral';
  String _supplyStatus    = 'adequate';

  // ── Static lists ──────────────────────────────────
  final _categories = ['Vegetables', 'Fruits', 'Rice', 'Other', 'Fish'];
  final _markets    = ['Pettah', 'Dambulla', 'Narahenpita', 'Marandagahamula', 'Peliyagoda', 'Negombo'];
  final _months     = ['1','2','3','4','5','6','7','8','9','10','11','12'];
  final _monthNames = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
  final _daysOfWeek = ['Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday'];
  final _quarters   = ['1 (Jan–Mar)', '2 (Apr–Jun)', '3 (Jul–Sep)', '4 (Oct–Dec)'];
  final _sentiments = ['positive', 'neutral', 'negative'];
  final _supplies   = ['adequate', 'scarce', 'surplus'];

  final Map<String, List<String>> _itemsByCategory = {
    'Vegetables': ['Tomato', 'Carrot', 'Cabbage', 'Beans', 'Potato', 'Onion', 'Leeks', 'Capsicum'],
    'Fruits':     ['Mango', 'Banana', 'Papaya', 'Pineapple', 'Watermelon', 'Avocado'],
    'Rice':       ['White Rice', 'Red Rice', 'Basmati'],
    'Other':      ['Coconut', 'Ginger', 'Garlic', 'Turmeric'],
    'Fish':       ['Tuna', 'Seer Fish', 'Sardine', 'Prawn', 'Crab'],
  };

  List<String> get _items => _itemsByCategory[_category] ?? [];

  Future<void> _predict() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final data = {
      'category':         _category,
      'item_standard':    _item,
      'origin_type':      _originType,
      'price_type':       _priceType,
      'market':           _market,
      'previous_price':   _previousPriceCtrl.text,
      'year':             _yearCtrl.text,
      'month':            _month,
      'day':              _dayCtrl.text,
      'dayofweek':        _dayOfWeek,
      'week':             _weekCtrl.text,
      'quarter':          _quarter,
      'season':           _season,
      'rolling_mean_7':   _rollingMean7Ctrl.text,
      'rolling_std_7':    _rollingStd7Ctrl.text,
      'rolling_mean_3':   _rollingMean3Ctrl.text,
      'volatility_index': _volatilityCtrl.text,
      'market_sentiment': _marketSentiment,
      'supply_status':    _supplyStatus,
    };

    final result = await ApiService().predictPriceDemand(data);
    setState(() => _loading = false);

    if (!mounted) return;
    final lang = LanguageService();
    if (result['success'] == true) {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => ResultWebView(title: lang.t('pd_result_title'), html: result['html']),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Prediction failed'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void dispose() {
    _previousPriceCtrl.dispose();
    _yearCtrl.dispose(); _dayCtrl.dispose(); _weekCtrl.dispose();
    _rollingMean7Ctrl.dispose(); _rollingStd7Ctrl.dispose();
    _rollingMean3Ctrl.dispose(); _volatilityCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = LanguageService();
    return Scaffold(
      backgroundColor: AppColors.g50,
      appBar: AppBar(
        title: Text(lang.t('pd_title')),
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
              // ── Product Information ──────────────────
              FlaskCard(
                icon: Icons.info_outline,
                title: lang.t('pd_product_info'),
                children: [
                  Row(children: [
                    Expanded(child: _drop(lang.t('category'), _category, _categories, (v) {
                      setState(() { _category = v!; _item = _itemsByCategory[v]!.first; });
                    })),
                    const SizedBox(width: 12),
                    Expanded(child: _drop(lang.t('pd_item'), _item, _items,
                        (v) => setState(() => _item = v!))),
                  ]),
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(child: _drop(lang.t('pd_origin_type'), _originType,
                        ['Local', 'Imported'],
                        (v) => setState(() => _originType = v!))),
                    const SizedBox(width: 12),
                    Expanded(child: _drop(lang.t('pd_price_type'), _priceType,
                        ['Wholesale', 'Retail'],
                        (v) => setState(() => _priceType = v!))),
                  ]),
                  const SizedBox(height: 14),
                  _drop(lang.t('market'), _market, _markets,
                      (v) => setState(() => _market = v!)),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _previousPriceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: flaskInput(lang.t('pd_prev_price'),
                        prefix: const Icon(Icons.monetization_on, size: 18)),
                    validator: (v) => v == null || v.isEmpty ? lang.t('required') : null,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Date Information ─────────────────────
              FlaskCard(
                icon: Icons.calendar_today,
                title: lang.t('pd_date_info'),
                children: [
                  Row(children: [
                    Expanded(child: TextFormField(
                      controller: _yearCtrl,
                      keyboardType: TextInputType.number,
                      decoration: flaskInput(lang.t('pd_year')),
                      validator: (v) => v == null || v.isEmpty ? lang.t('required') : null,
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: DropdownButtonFormField<String>(
                      value: _month,
                      decoration: flaskInput(lang.t('pd_month')),
                      items: List.generate(12, (i) => DropdownMenuItem(
                        value: _months[i],
                        child: Text('${_months[i]} - ${_monthNames[i]}'),
                      )),
                      onChanged: (v) => setState(() => _month = v!),
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: TextFormField(
                      controller: _dayCtrl,
                      keyboardType: TextInputType.number,
                      decoration: flaskInput(lang.t('pd_day')),
                      validator: (v) => v == null || v.isEmpty ? lang.t('required') : null,
                    )),
                  ]),
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(child: DropdownButtonFormField<String>(
                      value: _dayOfWeek,
                      decoration: flaskInput(lang.t('pd_day_of_week')),
                      items: List.generate(7, (i) => DropdownMenuItem(
                        value: '$i',
                        child: Text(_daysOfWeek[i]),
                      )),
                      onChanged: (v) => setState(() => _dayOfWeek = v!),
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: TextFormField(
                      controller: _weekCtrl,
                      keyboardType: TextInputType.number,
                      decoration: flaskInput(lang.t('pd_week_num')),
                    )),
                  ]),
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(child: DropdownButtonFormField<String>(
                      value: _quarter,
                      decoration: flaskInput(lang.t('pd_quarter')),
                      items: List.generate(4, (i) => DropdownMenuItem(
                        value: '${i + 1}',
                        child: Text(_quarters[i]),
                      )),
                      onChanged: (v) => setState(() => _quarter = v!),
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: _drop(lang.t('season'), _season,
                        ['Maha', 'Yala', 'Off'],
                        (v) => setState(() => _season = v!))),
                  ]),
                ],
              ),
              const SizedBox(height: 16),

              // ── Historical Statistics ─────────────────
              FlaskCard(
                icon: Icons.bar_chart,
                title: lang.t('pd_hist_stats'),
                children: [
                  Row(children: [
                    Expanded(child: TextFormField(
                      controller: _rollingMean7Ctrl,
                      keyboardType: TextInputType.number,
                      decoration: flaskInput(lang.t('pd_rolling_7')),
                      validator: (v) => v == null || v.isEmpty ? lang.t('required') : null,
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: TextFormField(
                      controller: _rollingStd7Ctrl,
                      keyboardType: TextInputType.number,
                      decoration: flaskInput(lang.t('pd_std_7')),
                      validator: (v) => v == null || v.isEmpty ? lang.t('required') : null,
                    )),
                  ]),
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(child: TextFormField(
                      controller: _rollingMean3Ctrl,
                      keyboardType: TextInputType.number,
                      decoration: flaskInput(lang.t('pd_rolling_3')),
                      validator: (v) => v == null || v.isEmpty ? lang.t('required') : null,
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: TextFormField(
                      controller: _volatilityCtrl,
                      keyboardType: TextInputType.number,
                      decoration: flaskInput(lang.t('pd_volatility')),
                      validator: (v) => v == null || v.isEmpty ? lang.t('required') : null,
                    )),
                  ]),
                ],
              ),
              const SizedBox(height: 16),

              // ── Market Conditions ─────────────────────
              FlaskCard(
                icon: Icons.store,
                title: lang.t('pd_market_cond'),
                children: [
                  Row(children: [
                    Expanded(child: _drop(lang.t('pd_sentiment'), _marketSentiment,
                        _sentiments,
                        (v) => setState(() => _marketSentiment = v!))),
                    const SizedBox(width: 12),
                    Expanded(child: _drop(lang.t('pd_supply'), _supplyStatus,
                        _supplies,
                        (v) => setState(() => _supplyStatus = v!))),
                  ]),
                ],
              ),
              const SizedBox(height: 20),

              SubmitButton(
                loading: _loading,
                label: lang.t('pd_predict_btn'),
                loadingLabel: lang.t('pd_predicting'),
                icon: Icons.trending_up,
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
      items: items.map((i) => DropdownMenuItem(value: i,
          child: Text(i, overflow: TextOverflow.ellipsis))).toList(),
      onChanged: cb,
    );
  }
}

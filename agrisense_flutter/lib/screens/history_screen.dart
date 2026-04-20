import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/language_service.dart';
import '../widgets/language_switcher.dart';
import '../widgets/result_webview.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with LangMixin {
  bool _loading = true;
  String? _html;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() { _loading = true; _error = null; });
    final result = await ApiService().getHistory();
    setState(() {
      _loading = false;
      if (result['success'] == true) {
        _html = result['html'];
      } else {
        _error = result['message'];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = LanguageService();
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8E9),
      appBar: AppBar(
        title: Text(lang.t('hist_title')),
        actions: [
          const LanguageSwitcher(),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadHistory),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 60, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_error!, textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _loadHistory,
                        icon: const Icon(Icons.refresh),
                        label: Text(lang.t('retry')),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E7D32).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.history, size: 48, color: Color(0xFF2E7D32)),
                            const SizedBox(height: 8),
                            Text(lang.t('hist_header'),
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                                    color: Color(0xFF2E7D32))),
                            const SizedBox(height: 4),
                            Text(lang.t('hist_saved'),
                                style: const TextStyle(color: Colors.grey, fontSize: 13)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.open_in_browser, color: Color(0xFF2E7D32)),
                          title: Text(lang.t('hist_view_full')),
                          subtitle: Text(lang.t('hist_view_sub')),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                          onTap: () => Navigator.push(context, MaterialPageRoute(
                            builder: (_) => ResultWebView(
                              title: lang.t('hist_title'),
                              html: _html ?? '',
                            ),
                          )),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(lang.t('hist_export'),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () {},
                                      icon: const Icon(Icons.table_chart, size: 18),
                                      label: const Text('CSV'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () {},
                                      icon: const Icon(Icons.code, size: 18),
                                      label: const Text('JSON'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

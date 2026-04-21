import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ResultWebView extends StatefulWidget {
  final String title;
  final String html;

  const ResultWebView({super.key, required this.title, required this.html});

  @override
  State<ResultWebView> createState() => _ResultWebViewState();
}

class _ResultWebViewState extends State<ResultWebView> {
  WebViewController? _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _controller = WebViewController()
        ..setNavigationDelegate(NavigationDelegate(
          onPageFinished: (_) => setState(() => _loading = false),
        ))
        ..loadHtmlString(widget.html);
    } else {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: kIsWeb ? _buildWebResult() : _buildNativeWebView(),
    );
  }

  Widget _buildNativeWebView() {
    return Stack(
      children: [
        if (_controller != null) WebViewWidget(controller: _controller!),
        if (_loading)
          const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32))),
      ],
    );
  }

  Widget _buildWebResult() {
    final items = _parseResults(widget.html);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Success header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF2E7D32).withOpacity(0.4)),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 32),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Prediction Complete!',
                          style: TextStyle(fontWeight: FontWeight.bold,
                              fontSize: 18, color: Color(0xFF2E7D32))),
                      Text('AI model processed your data successfully.',
                          style: TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Results cards
          if (items['highlights']!.isNotEmpty) ...[
            const Text('Key Results',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16,
                    color: Color(0xFF2E7D32))),
            const SizedBox(height: 8),
            ...items['highlights']!.map((item) => _resultCard(item)),
            const SizedBox(height: 16),
          ],

          if (items['details']!.isNotEmpty) ...[
            const Text('Details',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: items['details']!
                      .map((item) => _detailRow(item))
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          if (items['highlights']!.isEmpty && items['details']!.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(Icons.analytics, size: 48, color: Color(0xFF2E7D32)),
                    const SizedBox(height: 12),
                    const Text('Prediction Saved',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    Text('${(widget.html.length / 1024).toStringAsFixed(1)} KB received from server',
                        style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 8),
                    const Text('Check History for full results',
                        style: TextStyle(color: Color(0xFF2E7D32))),
                  ],
                ),
              ),
            ),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to Predictions'),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _resultCard(String text) {
    return Card(
      color: const Color(0xFF2E7D32).withOpacity(0.05),
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(Icons.insights, color: Color(0xFF2E7D32), size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(text,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.circle, size: 8, color: Color(0xFF2E7D32)),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, height: 1.4))),
        ],
      ),
    );
  }

  Map<String, List<String>> _parseResults(String html) {
    final highlights = <String>[];
    final details = <String>[];

    // Remove scripts and styles
    String clean = html
        .replaceAll(RegExp(r'<script[^>]*>.*?</script>', dotAll: true), '')
        .replaceAll(RegExp(r'<style[^>]*>.*?</style>', dotAll: true), '');

    // Extract highlight values - numbers with labels
    final numPattern = RegExp(
        r'(?:predicted|price|demand|grade|score|rank|profit|yield|quality|revenue|income|recommendation)[^<]{0,50}?(\d[\d.,\s%]+(?:Rs|LKR|kg|%)?)',
        caseSensitive: false);
    for (final m in numPattern.allMatches(clean)) {
      final txt = m.group(0)
          ?.replaceAll(RegExp(r'<[^>]+>'), '')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      if (txt != null && txt.length > 5 && txt.length < 150) {
        highlights.add(txt);
        if (highlights.length >= 6) break;
      }
    }

    // Extract table rows for details
    final tdPattern = RegExp(r'<tr[^>]*>(.*?)</tr>', dotAll: true);
    for (final row in tdPattern.allMatches(clean)) {
      final cells = RegExp(r'<t[dh][^>]*>(.*?)</t[dh]>', dotAll: true)
          .allMatches(row.group(1) ?? '')
          .map((c) => c.group(1)
              ?.replaceAll(RegExp(r'<[^>]+>'), '')
              .replaceAll(RegExp(r'\s+'), ' ')
              .trim() ?? '')
          .where((c) => c.isNotEmpty)
          .join(' : ');
      if (cells.length > 5 && cells.length < 200) {
        details.add(cells);
        if (details.length >= 10) break;
      }
    }

    // Fallback: extract list items
    if (details.isEmpty) {
      final liPattern = RegExp(r'<li[^>]*>(.*?)</li>', dotAll: true);
      for (final m in liPattern.allMatches(clean)) {
        final txt = m.group(1)
            ?.replaceAll(RegExp(r'<[^>]+>'), '')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
        if (txt != null && txt.length > 5 && txt.length < 200) {
          details.add(txt);
          if (details.length >= 8) break;
        }
      }
    }

    return {'highlights': highlights, 'details': details};
  }
}

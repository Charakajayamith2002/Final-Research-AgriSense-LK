import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../widgets/result_webview.dart';
import '../theme/app_theme.dart';

class YieldQualityScreen extends StatefulWidget {
  const YieldQualityScreen({super.key});

  @override
  State<YieldQualityScreen> createState() => _YieldQualityScreenState();
}

class _YieldQualityScreenState extends State<YieldQualityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _priceCtrl = TextEditingController();
  final _picker = ImagePicker();
  List<XFile> _selectedImages = [];
  bool _loading = false;

  Future<void> _pickImages() async {
    final picked = await _picker.pickMultiImage(imageQuality: 80);
    if (picked.isNotEmpty) setState(() => _selectedImages = picked);
  }

  Future<void> _pickFromCamera() async {
    final picked = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (picked != null) setState(() => _selectedImages.add(picked));
  }

  void _removeImage(int index) => setState(() => _selectedImages.removeAt(index));

  Future<void> _predict() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one crop image'), backgroundColor: Colors.orange),
      );
      return;
    }
    setState(() => _loading = true);

    final result = await ApiService().predictYieldQualityXFile(
      _selectedImages,
      double.parse(_priceCtrl.text),
    );
    setState(() => _loading = false);

    if (!mounted) return;
    if (result['success'] == true) {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => ResultWebView(title: 'Yield & Quality Result', html: result['html']),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Prediction failed'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.g50,
      appBar: AppBar(
        title: const Text('Yield & Quality Analysis'),
        backgroundColor: AppColors.g600,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Info banner
              Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: AppColors.g50,
                  border: Border(
                    left: const BorderSide(color: AppColors.g400, width: 3),
                    top: BorderSide(color: AppColors.g200),
                    right: BorderSide(color: AppColors.g200),
                    bottom: BorderSide(color: AppColors.g200),
                  ),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.g500, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Upload crop images for AI quality grading — Grade A, B, C or Rotten.',
                        style: TextStyle(fontSize: 12.5, color: AppColors.textMedium),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Pricing ───────────────────────────────
              FlaskCard(
                icon: Icons.attach_money,
                title: 'Pricing',
                children: [
                  TextFormField(
                    controller: _priceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: flaskInput('Best Unit Price (Rs. per kg) *',
                        prefix: const Icon(Icons.monetization_on, size: 18, color: AppColors.g500)),
                    validator: (v) => v == null || v.isEmpty ? 'Enter price' : null,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Crop Images ───────────────────────────
              FlaskCard(
                icon: Icons.photo_camera_outlined,
                title: 'Crop Images',
                children: [
                  Row(children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickImages,
                        icon: const Icon(Icons.photo_library_outlined, size: 18),
                        label: const Text('Gallery'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.g600,
                          side: const BorderSide(color: AppColors.bdr, width: 1.5),
                          backgroundColor: AppColors.g50,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: kIsWeb ? null : _pickFromCamera,
                        icon: const Icon(Icons.camera_alt_outlined, size: 18),
                        label: const Text('Camera'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: kIsWeb ? AppColors.textMuted : AppColors.g600,
                          side: BorderSide(
                            color: kIsWeb ? AppColors.bdr.withOpacity(0.5) : AppColors.bdr,
                            width: 1.5,
                          ),
                          backgroundColor: AppColors.g50,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                        ),
                      ),
                    ),
                  ]),
                  if (kIsWeb)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text('Camera not available on web — use Gallery.',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                    ),
                  if (_selectedImages.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Row(children: [
                      const Icon(Icons.check_circle, color: AppColors.g500, size: 16),
                      const SizedBox(width: 6),
                      Text('${_selectedImages.length} image(s) selected',
                          style: const TextStyle(color: AppColors.g600, fontSize: 12, fontWeight: FontWeight.w600)),
                    ]),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _selectedImages.length,
                        itemBuilder: (context, index) => Stack(
                          children: [
                            FutureBuilder<dynamic>(
                              future: _selectedImages[index].readAsBytes(),
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  return Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(9),
                                      border: Border.all(color: AppColors.bdr, width: 1.5),
                                      image: DecorationImage(
                                        image: MemoryImage(snapshot.data!),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  );
                                }
                                return Container(
                                  width: 100, height: 100,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    color: AppColors.g100,
                                    borderRadius: BorderRadius.circular(9),
                                  ),
                                  child: const Center(
                                    child: CircularProgressIndicator(color: AppColors.g400, strokeWidth: 2),
                                  ),
                                );
                              },
                            ),
                            Positioned(
                              top: 4, right: 12,
                              child: GestureDetector(
                                onTap: () => _removeImage(index),
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                  child: const Icon(Icons.close, size: 13, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 20),
                    Center(
                      child: Column(children: [
                        Icon(Icons.add_photo_alternate_outlined, size: 48, color: AppColors.g300),
                        const SizedBox(height: 8),
                        Text('No images selected',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                        const SizedBox(height: 4),
                        Text('Tap Gallery or Camera above',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                      ]),
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
              const SizedBox(height: 20),

              SubmitButton(
                loading: _loading,
                label: 'Analyze Yield & Quality',
                loadingLabel: 'Analyzing Images…',
                icon: Icons.analytics_outlined,
                onPressed: _predict,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

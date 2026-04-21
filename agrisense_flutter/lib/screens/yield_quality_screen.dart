import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../services/language_service.dart';
import '../widgets/language_switcher.dart';
import '../theme/app_theme.dart';
import 'yield_quality_result_screen.dart';

class YieldQualityScreen extends StatefulWidget {
  const YieldQualityScreen({super.key});

  @override
  State<YieldQualityScreen> createState() => _YieldQualityScreenState();
}

class _YieldQualityScreenState extends State<YieldQualityScreen> with LangMixin {
  final _formKey = GlobalKey<FormState>();
  final _priceCtrl = TextEditingController();
  final _picker = ImagePicker();
  List<XFile> _selectedImages = [];
  bool _loading = false;

  Future<void> _pickImages() async {
    final picked = await _picker.pickMultiImage(imageQuality: 80);
    if (picked.isEmpty) return;
    setState(() {
      for (final img in picked) {
        final alreadyAdded = _selectedImages.any(
          (e) => e.name == img.name && e.path == img.path,
        );
        if (!alreadyAdded) _selectedImages.add(img);
      }
    });
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

    final images = List<XFile>.from(_selectedImages);
    final result = await ApiService().predictYieldQualityXFile(
      images,
      double.parse(_priceCtrl.text),
    );
    setState(() => _loading = false);

    if (!mounted) return;
    if (result['success'] == true) {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => YieldQualityResultScreen(
            data: result['data'] as Map<String, dynamic>,
            images: images),
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
    final lang = LanguageService();
    return Scaffold(
      backgroundColor: AppColors.g50,
      appBar: AppBar(
        title: Text(lang.t('yq_title')),
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
                        lang.t('yq_info'),
                        style: const TextStyle(fontSize: 12.5, color: AppColors.textMedium),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Pricing ───────────────────────────────
              FlaskCard(
                icon: Icons.attach_money,
                title: lang.t('yq_pricing'),
                children: [
                  TextFormField(
                    controller: _priceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: flaskInput(lang.t('yq_price_label'),
                        prefix: const Icon(Icons.monetization_on, size: 18, color: AppColors.g500)),
                    validator: (v) => v == null || v.isEmpty ? lang.t('yq_enter_price') : null,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Crop Images ───────────────────────────
              FlaskCard(
                icon: Icons.photo_camera_outlined,
                title: lang.t('yq_images'),
                children: [
                  Row(children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickImages,
                        icon: const Icon(Icons.photo_library_outlined, size: 18),
                        label: Text(lang.t('gallery')),
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
                        label: Text(lang.t('camera')),
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
                      child: Text(lang.t('yq_camera_web'),
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                    ),
                  if (_selectedImages.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Row(children: [
                      const Icon(Icons.check_circle, color: AppColors.g500, size: 16),
                      const SizedBox(width: 6),
                      Text('${_selectedImages.length} ${lang.t('yq_images_count')}',
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
                        const Icon(Icons.add_photo_alternate_outlined, size: 48, color: AppColors.g300),
                        const SizedBox(height: 8),
                        Text(lang.t('yq_no_images'),
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                        const SizedBox(height: 4),
                        Text(lang.t('yq_tap_hint'),
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                      ]),
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
              const SizedBox(height: 20),

              SubmitButton(
                loading: _loading,
                label: lang.t('yq_analyze'),
                loadingLabel: lang.t('yq_analyzing'),
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

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/app_service.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_button.dart';

class VerifyIdentityScreen extends StatefulWidget {
  const VerifyIdentityScreen({super.key});

  @override
  State<VerifyIdentityScreen> createState() => _VerifyIdentityScreenState();
}

class _VerifyIdentityScreenState extends State<VerifyIdentityScreen> {
  final _nationalIdCtrl = TextEditingController();
  File? _idImage;
  File? _selfieImage;
  bool _isLoading = false;

  Future<void> _pickImage(ImageSource source, bool isSelfie) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 80);
    if (picked != null) {
      setState(() {
        if (isSelfie) {
          _selfieImage = File(picked.path);
        } else {
          _idImage = File(picked.path);
        }
      });
    }
  }

  void _showImageSourceSheet(bool isSelfie) {
    if (isSelfie) {
      _pickImage(ImageSource.camera, true);
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4,
                decoration: BoxDecoration(color: AppTheme.textSecondary, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              const Text('اختر مصدر صورة الهوية',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: AppTheme.primary),
                title: const Text('الكاميرا', style: TextStyle(color: Colors.white)),
                onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera, false); },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppTheme.primary),
                title: const Text('معرض الصور', style: TextStyle(color: Colors.white)),
                onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery, false); },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() async {
    if (_nationalIdCtrl.text.trim().isEmpty) {
      _showError('الرجاء إدخال الرقم الوطني');
      return;
    }
    if (_idImage == null) {
      _showError('الرجاء إرفاق صورة الهوية');
      return;
    }
    if (_selfieImage == null) {
      _showError('الرجاء إرفاق صورة شخصية');
      return;
    }
    setState(() => _isLoading = true);
    final error = await AppService().submitVerificationRequest(
      nationalId: _nationalIdCtrl.text.trim(),
      imageFile: _idImage!,
      selfieFile: _selfieImage!,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (error != null) {
      _showError(error);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إرسال طلب التوثيق بنجاح، سيتم مراجعته قريباً'),
          backgroundColor: AppTheme.success,
        ),
      );
      Navigator.pop(context, true);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppTheme.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text('توثيق الهوية',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.info_outline, color: AppTheme.primary, size: 20),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'أدخل رقمك الوطني وأرفق صورة هويتك وصورة شخصية. سيتم مراجعة الطلب من قبل الإدارة.',
                                  style: TextStyle(color: Colors.white70, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),

                        const Text('الرقم الوطني',
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _nationalIdCtrl,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'أدخل الرقم الوطني',
                            prefixIcon: Icon(Icons.badge_outlined),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // صورتان جنباً إلى جنب
                        Row(
                          children: [
                            Expanded(child: _imagePicker(
                              label: 'صورة الهوية',
                              icon: Icons.credit_card_outlined,
                              image: _idImage,
                              isSelfie: false,
                            )),
                            const SizedBox(width: 12),
                            Expanded(child: _imagePicker(
                              label: 'صورة شخصية',
                              icon: Icons.face_outlined,
                              image: _selfieImage,
                              isSelfie: true,
                            )),
                          ],
                        ),
                        const SizedBox(height: 36),

                        GradientButton(
                          label: 'إرسال طلب التوثيق',
                          isLoading: _isLoading,
                          onTap: _submit,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _imagePicker({
    required String label,
    required IconData icon,
    required File? image,
    required bool isSelfie,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _showImageSourceSheet(isSelfie),
          child: Container(
            height: 140,
            decoration: BoxDecoration(
              color: AppTheme.bgSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: image != null ? AppTheme.success : AppTheme.primary.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: image != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(image, fit: isSelfie ? BoxFit.cover : BoxFit.contain),
                        Positioned(
                          top: 6, left: 6,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(color: AppTheme.success, shape: BoxShape.circle),
                            child: const Icon(Icons.check, color: Colors.white, size: 12),
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, color: AppTheme.primary, size: 32),
                      const SizedBox(height: 8),
                      Text(label, textAlign: TextAlign.center,
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

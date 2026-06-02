import 'package:flutter/material.dart';
import '../services/app_service.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_button.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl    = TextEditingController();
  final _phoneCtrl   = TextEditingController();
  final _pinCtrl     = TextEditingController();
  final _pinConfCtrl = TextEditingController();
  bool _isLoading = false;
  String? _pinError;

  void _onPinConfirmChanged(String _) {
    setState(() {
      _pinError = _pinConfCtrl.text.isNotEmpty && _pinCtrl.text != _pinConfCtrl.text
          ? 'رمزا PIN غير متطابقَين'
          : null;
    });
  }

  void _sendOtp() async {
    if (_nameCtrl.text.trim().isEmpty || _phoneCtrl.text.trim().isEmpty ||
        _pinCtrl.text.isEmpty || _pinConfCtrl.text.isEmpty) {
      _showError('الرجاء إدخال جميع الحقول');
      return;
    }
    if (_pinCtrl.text != _pinConfCtrl.text) {
      _showError('رمزا PIN غير متطابقَين');
      return;
    }

    setState(() => _isLoading = true);
    final result = await AppService().requestRegisterOtp(
      fullName: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      pin: _pinCtrl.text,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.error != null) {
      _showError(result.error!);
      return;
    }

    final otp = result.otp!;
    final phone = _phoneCtrl.text.trim();

    // Show OTP overlay before navigation
    _showOtpOverlay(otp);

    // Navigate to OTP screen
    if (!mounted) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _OtpVerifyScreen(phone: phone, otp: otp),
    ));
  }

  void _showOtpOverlay(String otp) {
    final overlay = OverlayEntry(
      builder: (_) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 16, right: 16,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF1E2044),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.5)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 12)],
            ),
            child: Row(children: [
              const Icon(Icons.lock_outline, color: AppTheme.primary, size: 20),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('رمز التحقق للتسجيل', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                Text(otp, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 6)),
                const Text('صالح لمدة 5 دقائق', style: TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
              ])),
            ]),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(overlay);
    Future.delayed(const Duration(seconds: 30), overlay.remove);
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(height: 24),
                const Text('إنشاء حساب جديد',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 8),
                const Text('انضم إلينا وابدأ بإدارة أموالك بسهولة',
                    style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
                const SizedBox(height: 48),

                TextField(
                  controller: _nameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(hintText: 'الاسم الكامل', prefixIcon: Icon(Icons.person)),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(hintText: 'رقم الهاتف', prefixIcon: Icon(Icons.phone)),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _pinCtrl,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  onChanged: (_) => _onPinConfirmChanged(''),
                  decoration: const InputDecoration(hintText: 'رمز PIN', prefixIcon: Icon(Icons.lock)),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _pinConfCtrl,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  onChanged: _onPinConfirmChanged,
                  decoration: InputDecoration(
                    hintText: 'تأكيد رمز PIN',
                    prefixIcon: const Icon(Icons.lock_outline),
                    errorText: _pinError,
                    suffixIcon: _pinConfCtrl.text.isNotEmpty
                        ? Icon(_pinError == null ? Icons.check_circle : Icons.cancel,
                            color: _pinError == null ? AppTheme.success : AppTheme.error)
                        : null,
                  ),
                ),
                const SizedBox(height: 48),

                GradientButton(
                  label: 'إرسال رمز التحقق',
                  isLoading: _isLoading,
                  onTap: _sendOtp,
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

// ── OTP Verification Screen ────────────────────────────────
class _OtpVerifyScreen extends StatefulWidget {
  final String phone;
  final String otp;
  const _OtpVerifyScreen({required this.phone, required this.otp});

  @override
  State<_OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends State<_OtpVerifyScreen> {
  final _otpCtrl = TextEditingController();
  bool _isLoading = false;

  void _verify() async {
    if (_otpCtrl.text.trim().length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال رمز مكوّن من 6 أرقام'), backgroundColor: AppTheme.error),
      );
      return;
    }
    setState(() => _isLoading = true);
    final error = await AppService().register(phone: widget.phone, otp: _otpCtrl.text.trim());
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppTheme.error),
      );
    } else {
      // Show success then go to login
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: AppTheme.bgCard,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 64),
              const SizedBox(height: 16),
              const Text('تم إنشاء الحساب بنجاح!',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              const Text('يمكنك الآن تسجيل الدخول برقم هاتفك ورمز PIN',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  ),
                  child: const Text('تسجيل الدخول', style: TextStyle(fontSize: 16)),
                ),
              ),
            ]),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(24, 0, 24, MediaQuery.of(context).viewInsets.bottom + 24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(height: 32),
                const Icon(Icons.sms_outlined, color: AppTheme.primary, size: 64),
                const SizedBox(height: 20),
                const Text('أدخل رمز التحقق',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                    textAlign: TextAlign.center),
                const SizedBox(height: 8),
                const Text('الرمز ظاهر في الإشعار أعلى الشاشة\nصالح لمدة 5 دقائق',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                    textAlign: TextAlign.center),
                const SizedBox(height: 40),
                TextField(
                  controller: _otpCtrl,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 6,
                  style: const TextStyle(color: Colors.white, fontSize: 28, letterSpacing: 8, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(hintText: '------', counterText: ''),
                ),
                const SizedBox(height: 32),
                GradientButton(
                  label: 'تأكيد وإنشاء الحساب',
                  isLoading: _isLoading,
                  onTap: _verify,
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

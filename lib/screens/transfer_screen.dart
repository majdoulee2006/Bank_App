import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/app_service.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_button.dart';
import 'receive_screen.dart';

class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _accountCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  bool _isLoading = false;

  // Scanner state
  final MobileScannerController _scanCtrl = MobileScannerController();
  bool _scanned = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _tabCtrl.addListener(() async {
      if (_tabCtrl.index == 0) {
        _scanCtrl.stop();
      } else {
        _scanned = false;
        final status = await Permission.camera.request();
        if (status.isGranted) {
          _scanCtrl.start();
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('يرجى السماح بالوصول للكاميرا من الإعدادات')),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _scanCtrl.dispose();
    super.dispose();
  }

  void _onQrDetected(BarcodeCapture capture) {
    if (_scanned) return;
    final value = capture.barcodes.firstOrNull?.rawValue;
    if (value != null && value.isNotEmpty) {
      _scanned = true;
      _accountCtrl.text = value;
      _tabCtrl.animateTo(0);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم قراءة الرقم: $value'),
          backgroundColor: AppTheme.success,
        ),
      );
    }
  }

  Future<void> _transfer() async {
    final account = _accountCtrl.text.trim();
    final amountStr = _amountCtrl.text.trim();

    if (account.isEmpty || amountStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال رقم الحساب والمبلغ')),
      );
      return;
    }
    final amount = double.tryParse(amountStr);
    if (amount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('المبلغ غير صحيح')),
      );
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 800));

    final error = await AppService().transfer(
      toAccountNumber: account,
      amount: amount,
      note: _noteCtrl.text.isNotEmpty ? _noteCtrl.text : null,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppTheme.error),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('تم التحويل بنجاح!'),
            backgroundColor: AppTheme.success),
      );
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تحويل رصيد'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code, color: AppTheme.primary),
            tooltip: 'رمز QR الخاص بي',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ReceiveScreen()),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: AppTheme.primary,
          labelColor: Colors.white,
          unselectedLabelColor: AppTheme.textSecondary,
          tabs: const [
            Tab(icon: Icon(Icons.keyboard_alt_outlined), text: 'يدوي'),
            Tab(icon: Icon(Icons.qr_code_scanner), text: 'مسح QR'),
          ],
        ),
      ),
      backgroundColor: AppTheme.bgDark,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: TabBarView(
          controller: _tabCtrl,
          children: [
            _buildManualTab(),
            _buildScannerTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildManualTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Balance chip
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppTheme.cardGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.account_balance_wallet,
                    color: AppTheme.secondary, size: 22),
                const SizedBox(width: 10),
                Text(
                  'الرصيد: ${AppService().currentUser?.balance.toStringAsFixed(2)} ل.س',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          TextField(
            controller: _accountCtrl,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'رقم حساب المستلم (9 أرقام)',
              prefixIcon: Icon(Icons.account_circle_outlined),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'المبلغ',
              suffixText: _amountCtrl.text.isNotEmpty
                  ? 'عمولة: ${AppService().calcFee(double.tryParse(_amountCtrl.text) ?? 0).toStringAsFixed(2)} ل.س'
                  : null,
              suffixStyle: const TextStyle(color: AppTheme.warning, fontSize: 11),
              prefixIcon: const Icon(Icons.attach_money),
            ),
          ),
          if (_amountCtrl.text.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppTheme.warning, size: 14),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'تنبيه: سيتم اقتطاع عمولة قدرها 1% تذهب لحساب الإدارة.',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          TextField(
            controller: _noteCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'ملاحظة (اختياري)',
              prefixIcon: Icon(Icons.note),
            ),
          ),
          const SizedBox(height: 40),
          GradientButton(
            label: 'تحويل',
            icon: Icons.send,
            isLoading: _isLoading,
            onTap: _transfer,
          ),
        ],
      ),
    );
  }

  Widget _buildScannerTab() {
    return Stack(
      children: [
        MobileScanner(
          controller: _scanCtrl,
          onDetect: _onQrDetected,
        ),
        // Frame overlay
        Center(
          child: Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.primary, width: 3),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        // Hint text
        Positioned(
          bottom: 48,
          left: 0,
          right: 0,
          child: Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'وجّه الكاميرا نحو رمز QR الخاص بالمستلم',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
              const SizedBox(height: 12),
              IconButton(
                icon: const Icon(Icons.flash_on, color: Colors.white, size: 32),
                onPressed: () => _scanCtrl.toggleTorch(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

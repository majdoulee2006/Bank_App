import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../services/app_service.dart';

class MobileTopupScreen extends StatefulWidget {
  const MobileTopupScreen({super.key});

  @override
  State<MobileTopupScreen> createState() => _MobileTopupScreenState();
}

class _MobileTopupScreenState extends State<MobileTopupScreen>
    with TickerProviderStateMixin {
  int _step = 0;
  bool _loading = false;

  final _phoneCtrl  = TextEditingController();
  final _customCtrl = TextEditingController();

  String _operator    = 'syriatel'; // 'syriatel' | 'mtn'
  int?   _selectedAmt;              // null = custom
  bool   _showCustom  = false;

  late AnimationController _checkCtrl;
  late Animation<double>   _checkScale;
  late Animation<double>   _checkOpacity;

  static const _bgColor   = Color(0xFF1A1A2E);
  static const _purple    = Color(0xFF6C63FF);
  static const _green     = Color(0xFF00C853);
  static const _cardColor = Color(0xFF16213E);

  static const _amounts = [500, 1000, 2000, 5000];

  late String _refNo;
  late String _payTime;

  int get _finalAmount =>
      _showCustom ? (int.tryParse(_customCtrl.text.trim()) ?? 0) : (_selectedAmt ?? 0);

  @override
  void initState() {
    super.initState();
    _checkCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _checkScale = CurvedAnimation(parent: _checkCtrl, curve: Curves.elasticOut)
        .drive(Tween(begin: 0.0, end: 1.0));
    _checkOpacity = CurvedAnimation(parent: _checkCtrl, curve: Curves.easeIn)
        .drive(Tween(begin: 0.0, end: 1.0));
  }

  @override
  void dispose() {
    _checkCtrl.dispose();
    _phoneCtrl.dispose();
    _customCtrl.dispose();
    super.dispose();
  }

  void _goNext() {
    if (_phoneCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الرجاء إدخال رقم الموبايل')));
      return;
    }
    if (_finalAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الرجاء اختيار أو إدخال قيمة الشحن')));
      return;
    }
    setState(() => _step = 1);
  }

  Future<void> _pay() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    final error = await AppService().payBill(
      amount: _finalAmount.toDouble(),
      billType: 'mobile_topup',
      billRef: _phoneCtrl.text.trim(),
    );
    if (!mounted) return;
    if (error != null) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red));
      return;
    }
    _refNo   = 'REF${DateTime.now().millisecondsSinceEpoch}';
    _payTime = DateFormat('yyyy/MM/dd  HH:mm:ss').format(DateTime.now());
    setState(() { _loading = false; _step = 2; });
    _checkCtrl.forward();
  }

  // ── PDF ───────────────────────────────────────────────────
  Future<void> _downloadPdf() async {
    try {
      final fontRegular = await PdfGoogleFonts.cairoRegular();
      final fontBold    = await PdfGoogleFonts.cairoBold();

      pw.TextStyle txt({double size = 12,
          pw.FontWeight weight = pw.FontWeight.normal,
          PdfColor color = PdfColors.black}) =>
          pw.TextStyle(
              font: weight == pw.FontWeight.bold ? fontBold : fontRegular,
              fontSize: size, color: color, fontWeight: weight);

      final pdf = pw.Document();
      pdf.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        textDirection: pw.TextDirection.rtl,
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: pw.BoxDecoration(
                color: const PdfColor(0.42, 0.39, 1.0),
                borderRadius: pw.BorderRadius.circular(12),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('إيصال شحن رصيد موبايل',
                      style: txt(size: 16, weight: pw.FontWeight.bold, color: PdfColors.white)),
                  pw.Text('MQ Cash', style: txt(size: 12, color: PdfColors.grey300)),
                ],
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: pw.BoxDecoration(
                  color: const PdfColor(0.0, 0.78, 0.33, 0.15),
                  borderRadius: pw.BorderRadius.circular(20),
                  border: pw.Border.all(color: const PdfColor(0.0, 0.78, 0.33)),
                ),
                child: pw.Text('تم الشحن ✓',
                    style: txt(size: 11, weight: pw.FontWeight.bold,
                        color: const PdfColor(0.0, 0.78, 0.33))),
              ),
            ),
            pw.SizedBox(height: 16),
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                  color: PdfColors.grey100, borderRadius: pw.BorderRadius.circular(8)),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('قيمة الشحن', style: txt(size: 13, color: PdfColors.grey700)),
                  pw.Text('$_finalAmount ل.س',
                      style: txt(size: 18, weight: pw.FontWeight.bold,
                          color: const PdfColor(0.0, 0.78, 0.33))),
                ],
              ),
            ),
            pw.SizedBox(height: 16),
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(8)),
              child: pw.Column(children: [
                _pdfRow('الرقم المرجعي',   _refNo,                    txt),
                _pdfDiv(),
                _pdfRow('رقم الموبايل',    _phoneCtrl.text.trim(),    txt),
                _pdfDiv(),
                _pdfRow('شركة الاتصالات', _operator == 'syriatel' ? 'سيريتل' : 'MTN', txt),
                _pdfDiv(),
                _pdfRow('قيمة الشحن',     '$_finalAmount ل.س',       txt),
                _pdfDiv(),
                _pdfRow('التاريخ والوقت', _payTime,                   txt),
              ]),
            ),
            pw.SizedBox(height: 24),
            pw.Center(
              child: pw.Text('شكراً لاستخدامكم MQ Cash',
                  style: txt(size: 11, color: PdfColors.grey500)),
            ),
          ],
        ),
      ));

      final bytes = await pdf.save();
      final dir = await _getDownloadsDir();
      final fileName = 'topup_receipt_$_refNo.pdf';
      await File('${dir.path}/$fileName').writeAsBytes(bytes);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('تم الحفظ: $fileName'),
          backgroundColor: _green,
          duration: const Duration(seconds: 3)));
      await Printing.sharePdf(bytes: bytes, filename: fileName);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red));
    }
  }

  Future<Directory> _getDownloadsDir() async {
    if (Platform.isAndroid) {
      final dir = Directory('/storage/emulated/0/Download');
      if (await dir.exists()) return dir;
    }
    return await getApplicationDocumentsDirectory();
  }

  pw.Widget _pdfRow(String label, String value,
      pw.TextStyle Function({double size, pw.FontWeight weight, PdfColor color}) txt) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 9),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(label, style: txt(size: 12, color: PdfColors.grey700)),
            pw.Text(value, style: txt(size: 12, weight: pw.FontWeight.bold)),
          ],
        ),
      );

  pw.Widget _pdfDiv() => pw.Divider(color: PdfColors.grey200, height: 1);

  // ── Build ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bgColor,
        appBar: AppBar(
          backgroundColor: _bgColor,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
            onPressed: () {
              if (_step > 0) {
                setState(() {
                  _step--;
                  if (_step < 2) _checkCtrl.reset();
                });
              } else {
                Navigator.pop(context);
              }
            },
          ),
          title: const Text('شحن رصيد موبايل',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          centerTitle: true,
        ),
        body: Column(
          children: [
            _buildStepper(),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                            begin: const Offset(0.06, 0), end: Offset.zero)
                        .animate(anim),
                    child: child,
                  ),
                ),
                child: _step == 0
                    ? _buildStep1(key: const ValueKey(0))
                    : _step == 1
                        ? _buildStep2(key: const ValueKey(1))
                        : _buildStep3(key: const ValueKey(2)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Stepper ───────────────────────────────────────────────
  Widget _buildStepper() {
    const labels = ['إدخال البيانات', 'تأكيد العملية', 'إيصال الشحن'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: List.generate(3, (i) {
          final done    = i < _step;
          final current = i == _step;
          return Expanded(
            child: Row(
              children: [
                Column(children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: done ? _green : current ? _purple : Colors.white12,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: done
                          ? const Icon(Icons.check, color: Colors.white, size: 16)
                          : Text('${i + 1}',
                              style: TextStyle(
                                  color: current ? Colors.white : Colors.white38,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(labels[i],
                      style: TextStyle(
                          color: current ? Colors.white : Colors.white38,
                          fontSize: 9)),
                ]),
                if (i < 2)
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 2,
                      margin: const EdgeInsets.only(bottom: 16),
                      color: done ? _green : Colors.white12,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ── Step 1 ────────────────────────────────────────────────
  Widget _buildStep1({required Key key}) {
    return SingleChildScrollView(
      key: key,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _purple.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _purple.withValues(alpha: 0.3)),
            ),
            child: Row(children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: _purple.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.phone_android, color: _purple, size: 28),
              ),
              const SizedBox(width: 14),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('شحن رصيد',
                      style: TextStyle(color: Colors.white,
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  Text('شحن رصيد موبايل فوري',
                      style: TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ]),
          ),
          const SizedBox(height: 28),

          // رقم الموبايل
          const Text('رقم الموبايل',
              style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 10),
          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 18, letterSpacing: 2),
            decoration: InputDecoration(
              hintText: '09X XXX XXXX',
              hintStyle: const TextStyle(color: Colors.white24, letterSpacing: 1),
              filled: true,
              fillColor: _cardColor,
              prefixIcon: const Icon(Icons.phone_outlined, color: _purple),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: _purple.withValues(alpha: 0.6)),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // شركة الاتصالات
          const Text('شركة الاتصالات',
              style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _operatorBtn('syriatel', 'سيريتل', const Color(0xFFE53935))),
            const SizedBox(width: 12),
            Expanded(child: _operatorBtn('mtn', 'MTN', const Color(0xFFFDD835))),
          ]),
          const SizedBox(height: 24),

          // قيمة الشحن
          const Text('قيمة الشحن',
              style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.4,
            children: [
              ..._amounts.map((amt) => _amountCard(amt)),
              _customCard(),
            ],
          ),
          if (_showCustom) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _customCtrl,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                hintText: 'أدخل المبلغ بالليرة السورية',
                hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
                filled: true,
                fillColor: _cardColor,
                suffixText: 'ل.س',
                suffixStyle: const TextStyle(color: Colors.white54),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: _purple.withValues(alpha: 0.6)),
                ),
              ),
            ),
          ],
          const SizedBox(height: 40),

          SizedBox(
            width: double.infinity,
            height: 64,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _purple,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _goNext,
              child: const Text('متابعة',
                  textDirection: TextDirection.rtl,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _operatorBtn(String val, String label, Color color) {
    final selected = _operator == val;
    return GestureDetector(
      onTap: () => setState(() => _operator = val),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.2) : _cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? color : Colors.white12,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.signal_cellular_alt, color: selected ? color : Colors.white38, size: 18),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    color: selected ? Colors.white : Colors.white54,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 15)),
          ],
        ),
      ),
    );
  }

  Widget _amountCard(int amt) {
    final selected = !_showCustom && _selectedAmt == amt;
    return GestureDetector(
      onTap: () => setState(() { _selectedAmt = amt; _showCustom = false; }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: selected ? _purple.withValues(alpha: 0.2) : _cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? _purple : Colors.white12,
            width: selected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            '${NumberFormat('#,###').format(amt)} ل.س',
            style: TextStyle(
                color: selected ? Colors.white : Colors.white60,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                fontSize: 15),
          ),
        ),
      ),
    );
  }

  Widget _customCard() {
    return GestureDetector(
      onTap: () => setState(() { _showCustom = true; _selectedAmt = null; }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: _showCustom ? _purple.withValues(alpha: 0.2) : _cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _showCustom ? _purple : Colors.white12,
            width: _showCustom ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.edit_outlined,
                color: _showCustom ? _purple : Colors.white38, size: 16),
            const SizedBox(width: 6),
            Text('مبلغ آخر',
                style: TextStyle(
                    color: _showCustom ? Colors.white : Colors.white54,
                    fontWeight: _showCustom ? FontWeight.bold : FontWeight.normal,
                    fontSize: 14)),
          ],
        ),
      ),
    );
  }

  // ── Step 2 ────────────────────────────────────────────────
  Widget _buildStep2({required Key key}) {
    final opName = _operator == 'syriatel' ? 'سيريتل' : 'MTN';
    final opColor = _operator == 'syriatel' ? const Color(0xFFE53935) : const Color(0xFFFDD835);

    return SingleChildScrollView(
      key: key,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Header card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3A3CC8), Color(0xFF6C63FF)],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.phone_android, color: Colors.white70, size: 20),
                  const SizedBox(width: 8),
                  const Text('شحن رصيد موبايل',
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: opColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: opColor.withValues(alpha: 0.6)),
                    ),
                    child: Text(opName,
                        style: TextStyle(color: opColor, fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  ),
                ]),
                const SizedBox(height: 16),
                const Text('قيمة الشحن',
                    style: TextStyle(color: Colors.white60, fontSize: 13)),
                const SizedBox(height: 4),
                Text('$_finalAmount ل.س',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // تفاصيل
          Container(
            decoration: BoxDecoration(
                color: _cardColor, borderRadius: BorderRadius.circular(20)),
            child: Column(children: [
              _detailRow('رقم الموبايل',      _phoneCtrl.text.trim(), Icons.phone_outlined),
              _divider(),
              _detailRow('شركة الاتصالات',   opName,                  Icons.signal_cellular_alt),
              _divider(),
              _detailRow('قيمة الشحن',       '$_finalAmount ل.س',    Icons.attach_money),
            ]),
          ),
          const SizedBox(height: 16),
          // الحساب المصدر
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
                color: _cardColor, borderRadius: BorderRadius.circular(20)),
            child: Row(children: [
              const Icon(Icons.account_balance_wallet_outlined,
                  color: Colors.white38, size: 18),
              const SizedBox(width: 12),
              const Text('الحساب المصدر',
                  style: TextStyle(color: Colors.white54, fontSize: 13)),
              const Spacer(),
              Text(
                AppService().currentUser != null
                    ? 'الرصيد: ${AppService().currentUser!.balance.toStringAsFixed(0)} ل.س'
                    : 'الرصيد: 50,000 ل.س',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ]),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 64,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _loading ? null : _pay,
              child: _loading
                  ? const SizedBox(
                      width: 24, height: 24,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5))
                  : Text('شحن الآن — $_finalAmount ل.س',
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => setState(() => _step = 0),
            child: const Text('تعديل البيانات',
                style: TextStyle(color: Colors.white38)),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, IconData icon) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Icon(icon, color: _purple, size: 18),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
        ]),
      );

  Widget _divider() => Divider(
      height: 1,
      color: Colors.white.withValues(alpha: 0.06),
      indent: 16,
      endIndent: 16);

  // ── Step 3 ────────────────────────────────────────────────
  Widget _buildStep3({required Key key}) {
    final opName = _operator == 'syriatel' ? 'سيريتل' : 'MTN';
    return SingleChildScrollView(
      key: key,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: _checkCtrl,
            builder: (ctx2, _) => Opacity(
              opacity: _checkOpacity.value,
              child: Transform.scale(
                scale: _checkScale.value,
                child: Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(
                    color: _green.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: _green.withValues(alpha: 0.4), width: 2),
                  ),
                  child: const Icon(Icons.check_circle_rounded, color: _green, size: 60),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('تم الشحن بنجاح!',
              style: TextStyle(
                  color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('تم شحن رصيد ${_phoneCtrl.text.trim()}',
              style: const TextStyle(color: Colors.white54, fontSize: 13)),
          const SizedBox(height: 28),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _green.withValues(alpha: 0.2)),
            ),
            child: Column(children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('إيصال الشحن',
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('مكتمل',
                        style: TextStyle(color: _green, fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(color: Colors.white.withValues(alpha: 0.08)),
              const SizedBox(height: 8),
              _receiptRow('قيمة الشحن',      '$_finalAmount ل.س', highlight: true),
              const SizedBox(height: 10),
              _receiptRow('الرقم المرجعي',   _refNo),
              const SizedBox(height: 10),
              _receiptRow('رقم الموبايل',    _phoneCtrl.text.trim()),
              const SizedBox(height: 10),
              _receiptRow('شركة الاتصالات',  opName),
              const SizedBox(height: 10),
              _receiptRow('التاريخ والوقت',  _payTime),
            ]),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 64,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _purple,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _downloadPdf,
              child: const Text('تحميل الإيصال PDF',
                  textDirection: TextDirection.rtl,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('العودة للرئيسية',
                  style: TextStyle(color: Colors.white70)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _receiptRow(String label, String value, {bool highlight = false}) =>
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
          Text(value,
              style: TextStyle(
                  color: highlight ? _green : Colors.white,
                  fontSize: highlight ? 16 : 13,
                  fontWeight: highlight ? FontWeight.w900 : FontWeight.w500)),
        ],
      );
}

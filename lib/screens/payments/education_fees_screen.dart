import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../services/app_service.dart';

class EducationFeesScreen extends StatefulWidget {
  const EducationFeesScreen({super.key});

  @override
  State<EducationFeesScreen> createState() => _EducationFeesScreenState();
}

class _EducationFeesScreenState extends State<EducationFeesScreen>
    with TickerProviderStateMixin {
  int _step = 0;
  String? _selectedUniversity;
  final _studentIdCtrl = TextEditingController();
  bool _loading = false;
  bool _paying = false;
  String _payMode = 'installment';
  String _refNumber = '';

  late AnimationController _checkCtrl;
  late Animation<double> _checkAnim;

  static const _bgColor  = Color(0xFF1A1A2E);
  static const _orange   = Color(0xFFFFA726);
  static const _green    = Color(0xFF00C853);
  static const _red      = Color(0xFFE53935);
  static const _cardBg   = Color(0xFF16213E);

  final _universities = [
    'جامعة دمشق',
    'جامعة حلب',
    'جامعة تشرين',
    'جامعة البعث',
    'جامعة الفرات',
    'الجامعة الافتراضية السورية',
    'الجامعة العربية الدولية الخاصة',
    'جامعة المنارة',
    'جامعة قاسيون',
    'جامعة الشام الخاصة',
  ];

  final _studentName  = 'محمد علي الحسن';
  final _totalFees    = 2500000.0;
  final _paidAmount   = 1250000.0;

  double get _remaining        => _totalFees - _paidAmount;
  double get _paidRatio        => _paidAmount / _totalFees;
  double get _installmentAmount => 250000.0;
  double get _payAmount        => _payMode == 'full' ? _remaining : _installmentAmount;
  double get _afterPay         => (_remaining - _payAmount).clamp(0.0, _totalFees);

  final _fmt = NumberFormat('#,###');

  @override
  void initState() {
    super.initState();
    _checkCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _checkAnim = CurvedAnimation(parent: _checkCtrl, curve: Curves.elasticOut);
  }

  @override
  void dispose() {
    _checkCtrl.dispose();
    _studentIdCtrl.dispose();
    super.dispose();
  }

  void _goStep(int s) => setState(() => _step = s);

  Future<void> _query() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _loading = false);
    _goStep(1);
  }

  Future<void> _pay() async {
    setState(() => _paying = true);
    final err = await AppService().payBill(
      amount: _payAmount,
      billType: 'education',
      billRef: _studentIdCtrl.text,
    );
    setState(() => _paying = false);
    if (err != null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    _refNumber = 'EDU${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    _goStep(2);
    _checkCtrl.forward();
  }

  Future<void> _downloadPdf() async {
    final pdf = pw.Document();
    final font     = await PdfGoogleFonts.cairoRegular();
    final fontBold = await PdfGoogleFonts.cairoBold();
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      textDirection: pw.TextDirection.rtl,
      build: (_) => pw.Directionality(
        textDirection: pw.TextDirection.rtl,
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text('إيصال دفع رسوم تعليمية', style: pw.TextStyle(font: fontBold, fontSize: 24)),
          pw.SizedBox(height: 20),
          pw.Text('الرقم المرجعي: $_refNumber',        style: pw.TextStyle(font: font)),
          pw.Text('اسم الطالب: $_studentName',          style: pw.TextStyle(font: font)),
          pw.Text('الجامعة: $_selectedUniversity',       style: pw.TextStyle(font: font)),
          pw.Text('الرقم الجامعي: ${_studentIdCtrl.text}', style: pw.TextStyle(font: font)),
          pw.Text('المبلغ المدفوع: ${_fmt.format(_payAmount)} ل.س', style: pw.TextStyle(font: font)),
          pw.Text('التاريخ: ${DateFormat('yyyy/MM/dd – HH:mm').format(DateTime.now())}', style: pw.TextStyle(font: font)),
        ]),
      ),
    ));
    await Printing.layoutPdf(onLayout: (_) => pdf.save());
  }

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
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => _step == 1 ? _goStep(0) : Navigator.pop(context),
          ),
          title: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: _orange.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.school, color: _orange),
            ),
            const SizedBox(width: 12),
            const Text('الرسوم التعليمية',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ]),
        ),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0.05, 0), end: Offset.zero).animate(anim),
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
    );
  }

  Widget _buildStep1({Key? key}) {
    final valid = _selectedUniversity != null && _studentIdCtrl.text.trim().isNotEmpty;
    return SingleChildScrollView(
      key: key,
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _stepIndicator(0),
        const SizedBox(height: 28),

        // University number field
        const Text('الرقم الجامعي',
            style: TextStyle(color: Colors.white70, fontSize: 14)),
        const SizedBox(height: 8),
        TextField(
          controller: _studentIdCtrl,
          style: const TextStyle(color: Colors.white),
          keyboardType: TextInputType.number,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'أدخل رقمك الجامعي',
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: _cardBg,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            prefixIcon: const Icon(Icons.badge_outlined, color: Colors.white38),
          ),
        ),
        const SizedBox(height: 24),

        // University selector
        const Text('اختر الجامعة',
            style: TextStyle(color: Colors.white70, fontSize: 14)),
        const SizedBox(height: 12),
        ...List.generate(_universities.length, (i) {
          final uni = _universities[i];
          final selected = _selectedUniversity == uni;
          return GestureDetector(
            onTap: () => setState(() => _selectedUniversity = uni),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: selected ? _orange.withOpacity(0.15) : _cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected ? _orange : Colors.white12,
                  width: selected ? 1.5 : 1,
                ),
              ),
              child: Row(children: [
                Icon(Icons.account_balance,
                    color: selected ? _orange : Colors.white38, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text(uni,
                    style: TextStyle(
                        color: selected ? Colors.white : Colors.white70,
                        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 14))),
                if (selected)
                  Icon(Icons.check_circle, color: _orange, size: 20),
              ]),
            ),
          );
        }),
        const SizedBox(height: 28),

        SizedBox(
          width: double.infinity,
          height: 64,
          child: ElevatedButton(
            onPressed: (valid && !_loading) ? _query : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _orange,
              disabledBackgroundColor: _orange.withOpacity(0.3),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: _loading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('استعلام',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 20),
      ]),
    );
  }

  Widget _buildStep2({Key? key}) {
    final balance = AppService().currentUser?.balance ?? 0;
    return SingleChildScrollView(
      key: key,
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _stepIndicator(1),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_orange.withOpacity(0.3), _orange.withOpacity(0.1)],
              begin: Alignment.topRight, end: Alignment.bottomLeft,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _orange.withOpacity(0.4)),
          ),
          child: Column(children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: _orange.withOpacity(0.2), shape: BoxShape.circle),
                child: const Icon(Icons.school, color: _orange, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_studentName,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                Text(_selectedUniversity ?? '',
                    style: const TextStyle(color: Colors.white70, fontSize: 12)),
                Text('رقم: ${_studentIdCtrl.text}',
                    style: const TextStyle(color: Colors.white54, fontSize: 11)),
              ])),
            ]),
            const SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('نسبة المدفوع', style: TextStyle(color: Colors.white70, fontSize: 12)),
              Text('${(_paidRatio * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _paidRatio,
                backgroundColor: Colors.white12,
                valueColor: const AlwaysStoppedAnimation(_green),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _miniStat('المدفوع', '${_fmt.format(_paidAmount)} ل.س', _green)),
              const SizedBox(width: 12),
              Expanded(child: _miniStat('المتبقي', '${_fmt.format(_remaining)} ل.س', _red)),
              const SizedBox(width: 12),
              Expanded(child: _miniStat('الإجمالي', '${_fmt.format(_totalFees)} ل.س', Colors.white70)),
            ]),
          ]),
        ),
        const SizedBox(height: 20),
        const Text('خيار الدفع',
            style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(color: _cardBg, borderRadius: BorderRadius.circular(16)),
          child: Column(children: [
            _radioOption(value: 'installment', title: 'دفع قسط',
                subtitle: '${_fmt.format(_installmentAmount)} ل.س',
                icon: Icons.payments, color: _orange),
            Divider(color: Colors.white12, height: 1),
            _radioOption(value: 'full', title: 'دفع المبلغ كاملاً',
                subtitle: '${_fmt.format(_remaining)} ل.س',
                icon: Icons.done_all, color: _green),
          ]),
        ),
        const SizedBox(height: 16),
        _sourceAccount(balance),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _green.withOpacity(0.3)),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('المبلغ الواجب دفعه', style: TextStyle(color: Colors.white70, fontSize: 14)),
            Text('${_fmt.format(_payAmount)} ل.س',
                style: const TextStyle(color: _green, fontSize: 18, fontWeight: FontWeight.bold)),
          ]),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 64,
          child: ElevatedButton(
            onPressed: _paying ? null : _pay,
            style: ElevatedButton.styleFrom(
              backgroundColor: _green,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: _paying
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('دفع الآن',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 20),
      ]),
    );
  }

  Widget _buildStep3({Key? key}) {
    return SingleChildScrollView(
      key: key,
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        const SizedBox(height: 20),
        ScaleTransition(
          scale: _checkAnim,
          child: Container(
            width: 100, height: 100,
            decoration: BoxDecoration(color: _green.withOpacity(0.15), shape: BoxShape.circle),
            child: const Icon(Icons.check_circle_rounded, color: _green, size: 70),
          ),
        ),
        const SizedBox(height: 20),
        const Text('تم الدفع بنجاح!',
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('الرقم المرجعي: $_refNumber',
            style: const TextStyle(color: Colors.white54, fontSize: 13)),
        const SizedBox(height: 24),
        _detailCard([
          _detailRow('اسم الطالب', _studentName),
          _detailRow('الجامعة', _selectedUniversity ?? ''),
          _detailRow('الرقم الجامعي', _studentIdCtrl.text),
          _detailRow('المبلغ المدفوع', '${_fmt.format(_payAmount)} ل.س'),
          _detailRow('المبلغ المتبقي',
              _afterPay == 0 ? 'مدفوع بالكامل ✓' : '${_fmt.format(_afterPay)} ل.س',
              valueColor: _afterPay == 0 ? _green : _red),
          _detailRow('التاريخ', DateFormat('yyyy/MM/dd – HH:mm').format(DateTime.now())),
        ]),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 64,
          child: ElevatedButton.icon(
            onPressed: _downloadPdf,
            icon: const Icon(Icons.download, color: Colors.white),
            label: const Text('تحميل الإيصال',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _orange,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('العودة للرئيسية', style: TextStyle(color: Colors.white54)),
        ),
        const SizedBox(height: 20),
      ]),
    );
  }

  Widget _radioOption({required String value, required String title,
      required String subtitle, required IconData icon, required Color color}) {
    final selected = _payMode == value;
    return InkWell(
      onTap: () => setState(() => _payMode = value),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Radio<String>(value: value, groupValue: _payMode,
              onChanged: (v) => setState(() => _payMode = v!), activeColor: color),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(
                color: selected ? Colors.white : Colors.white70,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
            Text(subtitle, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
          ])),
        ]),
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color) => Column(children: [
    Text(value, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
    const SizedBox(height: 2),
    Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10), textAlign: TextAlign.center),
  ]);

  Widget _stepIndicator(int active) {
    const labels = ['إدخال البيانات', 'تفاصيل الرسوم', 'الإيصال'];
    return Row(
      children: List.generate(3, (i) {
        final done = i < active;
        final current = i == active;
        return Expanded(child: Row(children: [
          Column(children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 28, height: 28,
              decoration: BoxDecoration(
                  color: done ? _green : current ? _orange : Colors.white12, shape: BoxShape.circle),
              child: Center(child: done
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : Text('${i + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
            ),
            const SizedBox(height: 4),
            Text(labels[i], style: TextStyle(color: current ? _orange : Colors.white38, fontSize: 10)),
          ]),
          if (i < 2) Expanded(child: Container(
              height: 1, color: i < active ? _green : Colors.white12,
              margin: const EdgeInsets.only(bottom: 16))),
        ]));
      }),
    );
  }

  Widget _detailCard(List<Widget> rows) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: _cardBg, borderRadius: BorderRadius.circular(16)),
    child: Column(children: rows),
  );

  Widget _detailRow(String label, String value, {Color? valueColor}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(color: Colors.white54, fontSize: 14)),
      Flexible(child: Text(value,
          style: TextStyle(color: valueColor ?? Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
          textAlign: TextAlign.end)),
    ]),
  );

  Widget _sourceAccount(double balance) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: _cardBg, borderRadius: BorderRadius.circular(16)),
    child: Row(children: [
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: _orange.withOpacity(0.2), shape: BoxShape.circle),
        child: const Icon(Icons.account_balance_wallet, color: _orange),
      ),
      const SizedBox(width: 12),
      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('الحساب المصدر', style: TextStyle(color: Colors.white54, fontSize: 12)),
        Text('الحساب الرئيسي', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ])),
      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        const Text('الرصيد المتاح', style: TextStyle(color: Colors.white54, fontSize: 11)),
        Text('${NumberFormat('#,###').format(balance)} ل.س',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ]),
    ]),
  );
}

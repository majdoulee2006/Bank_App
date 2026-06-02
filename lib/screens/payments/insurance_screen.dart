import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../services/app_service.dart';

class InsuranceScreen extends StatefulWidget {
  const InsuranceScreen({super.key});

  @override
  State<InsuranceScreen> createState() => _InsuranceScreenState();
}

class _InsuranceScreenState extends State<InsuranceScreen>
    with TickerProviderStateMixin {
  int _step = 0;
  int _selectedType = -1;
  final _policyCtrl = TextEditingController();
  bool _loading = false;
  bool _paying = false;
  String _refNumber = '';

  late AnimationController _checkCtrl;
  late Animation<double> _checkAnim;

  static const _bgColor = Color(0xFF1A1A2E);
  static const _cyan = Color(0xFF00BCD4);
  static const _green = Color(0xFF00C853);
  static const _red = Color(0xFFE53935);
  static const _cardBg = Color(0xFF16213E);

  final _types = <Map<String, dynamic>>[
    {'name': 'تأمين صحي', 'icon': Icons.local_hospital, 'color': const Color(0xFF00BCD4)},
    {'name': 'تأمين سيارة', 'icon': Icons.directions_car, 'color': const Color(0xFF4CAF50)},
    {'name': 'تأمين منزل', 'icon': Icons.home, 'color': const Color(0xFFFFA726)},
    {'name': 'تأمين الحياة', 'icon': Icons.favorite, 'color': const Color(0xFFE53935)},
  ];

  // Mock policy data
  final _insuredName = 'أحمد محمد السعيد';
  final _company = 'شركة سورية للتأمين';
  final _startDate = DateTime(2024, 3, 1);
  final _endDate = DateTime(2025, 2, 28);
  final _premium = 75000.0;
  final _dueDate = DateTime(2025, 6, 15);

  double get _validity {
    final now = DateTime.now();
    if (now.isAfter(_endDate)) return 0.0;
    final total = _endDate.difference(_startDate).inDays;
    final remaining = _endDate.difference(now).inDays;
    return (remaining / total).clamp(0.0, 1.0);
  }

  bool get _isActive => _endDate.isAfter(DateTime.now());
  DateTime get _newEnd => _endDate.add(const Duration(days: 365));

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
    _policyCtrl.dispose();
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
      amount: _premium,
      billType: 'insurance',
      billRef: _policyCtrl.text,
    );
    setState(() => _paying = false);
    if (err != null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    _refNumber = 'INS${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    _goStep(2);
    _checkCtrl.forward();
  }

  Future<void> _downloadPdf() async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.cairoRegular();
    final fontBold = await PdfGoogleFonts.cairoBold();
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      textDirection: pw.TextDirection.rtl,
      build: (_) => pw.Directionality(
        textDirection: pw.TextDirection.rtl,
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text('إيصال دفع قسط تأمين', style: pw.TextStyle(font: fontBold, fontSize: 24)),
          pw.SizedBox(height: 20),
          pw.Text('الرقم المرجعي: $_refNumber', style: pw.TextStyle(font: font)),
          pw.Text('رقم الوثيقة: ${_policyCtrl.text}', style: pw.TextStyle(font: font)),
          pw.Text('نوع التأمين: ${_types[_selectedType]['name']}', style: pw.TextStyle(font: font)),
          pw.Text('المؤمَّن عليه: $_insuredName', style: pw.TextStyle(font: font)),
          pw.Text('المبلغ المدفوع: ${_fmt.format(_premium)} ل.س', style: pw.TextStyle(font: font)),
          pw.Text('انتهاء الوثيقة الجديد: ${DateFormat('yyyy/MM/dd').format(_newEnd)}', style: pw.TextStyle(font: font)),
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
            onPressed: () {
              if (_step == 1) {
                _goStep(0);
              } else {
                Navigator.pop(context);
              }
            },
          ),
          title: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: _cyan.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.health_and_safety, color: _cyan),
            ),
            const SizedBox(width: 12),
            const Text('صحة وتأمين', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
    final valid = _selectedType >= 0 && _policyCtrl.text.trim().isNotEmpty;
    return SingleChildScrollView(
      key: key,
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _stepIndicator(0),
        const SizedBox(height: 24),
        const Text('نوع التأمين', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.5,
          ),
          itemCount: _types.length,
          itemBuilder: (_, i) {
            final t = _types[i];
            final selected = _selectedType == i;
            final color = t['color'] as Color;
            return GestureDetector(
              onTap: () => setState(() => _selectedType = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: selected ? color.withOpacity(0.25) : _cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: selected ? color : Colors.white12, width: selected ? 2 : 1),
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(t['icon'] as IconData, color: color, size: 32),
                  const SizedBox(height: 8),
                  Text(t['name'] as String,
                      style: TextStyle(
                          color: selected ? Colors.white : Colors.white70,
                          fontWeight: FontWeight.bold, fontSize: 13),
                      textAlign: TextAlign.center),
                ]),
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        const Text('رقم وثيقة التأمين', style: TextStyle(color: Colors.white70, fontSize: 14)),
        const SizedBox(height: 8),
        TextField(
          controller: _policyCtrl,
          style: const TextStyle(color: Colors.white),
          keyboardType: TextInputType.number,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'أدخل رقم الوثيقة',
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: _cardBg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            prefixIcon: const Icon(Icons.policy, color: Colors.white38),
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: (valid && !_loading) ? _query : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _cyan,
              disabledBackgroundColor: _cyan.withOpacity(0.3),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: _loading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('استعلام',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    textDirection: TextDirection.rtl),
          ),
        ),
        const SizedBox(height: 20),
      ]),
    );
  }

  Widget _buildStep2({Key? key}) {
    final t = _types[_selectedType];
    final color = t['color'] as Color;
    final balance = AppService().currentUser?.balance ?? 0;
    final validityColor = _validity > 0.5 ? _green : _validity > 0.25 ? Colors.orange : _red;
    return SingleChildScrollView(
      key: key,
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _stepIndicator(1),
        const SizedBox(height: 24),
        // Policy header card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.3), color.withOpacity(0.1)],
              begin: Alignment.topRight, end: Alignment.bottomLeft,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.4)),
          ),
          child: Column(children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withOpacity(0.2), shape: BoxShape.circle),
                child: Icon(t['icon'] as IconData, color: color, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_insuredName,
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                Text(_company, style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (_isActive ? _green : _red).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _isActive ? _green : _red),
                ),
                child: Text(_isActive ? 'سارية' : 'منتهية',
                    style: TextStyle(
                        color: _isActive ? _green : _red, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ]),
            const SizedBox(height: 16),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(t['name'] as String,
                    style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ]),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('صلاحية الوثيقة', style: TextStyle(color: Colors.white70, fontSize: 12)),
              Text('${(_validity * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _validity,
                backgroundColor: Colors.white12,
                valueColor: AlwaysStoppedAnimation(validityColor),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(DateFormat('yyyy/MM/dd').format(_startDate),
                  style: const TextStyle(color: Colors.white54, fontSize: 11)),
              Text(DateFormat('yyyy/MM/dd').format(_endDate),
                  style: const TextStyle(color: Colors.white54, fontSize: 11)),
            ]),
          ]),
        ),
        const SizedBox(height: 16),
        _detailCard([
          _detailRow('رقم الوثيقة', _policyCtrl.text),
          _detailRow('القسط المستحق', '${_fmt.format(_premium)} ل.س'),
          _detailRow('تاريخ الاستحقاق', DateFormat('yyyy/MM/dd').format(_dueDate)),
          _detailRow('انتهاء الوثيقة الجديد', DateFormat('yyyy/MM/dd').format(_newEnd)),
        ]),
        const SizedBox(height: 16),
        _sourceAccount(balance),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _paying ? null : _pay,
            style: ElevatedButton.styleFrom(
              backgroundColor: _green,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: _paying
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('دفع القسط',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    textDirection: TextDirection.rtl),
          ),
        ),
        const SizedBox(height: 20),
      ]),
    );
  }

  Widget _buildStep3({Key? key}) {
    final t = _types[_selectedType];
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
        const Text('تم دفع القسط بنجاح!',
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('الرقم المرجعي: $_refNumber',
            style: const TextStyle(color: Colors.white54, fontSize: 13)),
        const SizedBox(height: 24),
        _detailCard([
          _detailRow('رقم الوثيقة', _policyCtrl.text),
          _detailRow('نوع التأمين', t['name'] as String),
          _detailRow('المبلغ المدفوع', '${_fmt.format(_premium)} ل.س'),
          _detailRow('انتهاء الوثيقة الجديد', DateFormat('yyyy/MM/dd').format(_newEnd)),
          _detailRow('التاريخ', DateFormat('yyyy/MM/dd – HH:mm').format(DateTime.now())),
        ]),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton.icon(
            onPressed: _downloadPdf,
            icon: const Icon(Icons.download, color: Colors.white),
            label: const Text('تحميل الإيصال',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                textDirection: TextDirection.rtl),
            style: ElevatedButton.styleFrom(
              backgroundColor: _cyan,
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

  Widget _stepIndicator(int active) {
    const labels = ['إدخال البيانات', 'تفاصيل الوثيقة', 'الإيصال'];
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
                color: done ? _green : current ? _cyan : Colors.white12,
                shape: BoxShape.circle,
              ),
              child: Center(child: done
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : Text('${i + 1}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
            ),
            const SizedBox(height: 4),
            Text(labels[i], style: TextStyle(color: current ? _cyan : Colors.white38, fontSize: 10)),
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

  Widget _detailRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(color: Colors.white54, fontSize: 14)),
      Flexible(child: Text(value,
          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
          textAlign: TextAlign.end)),
    ]),
  );

  Widget _sourceAccount(double balance) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: _cardBg, borderRadius: BorderRadius.circular(16)),
    child: Row(children: [
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: _cyan.withOpacity(0.2), shape: BoxShape.circle),
        child: const Icon(Icons.account_balance_wallet, color: _cyan),
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

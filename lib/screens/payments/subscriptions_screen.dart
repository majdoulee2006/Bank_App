import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../services/app_service.dart';

class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen>
    with TickerProviderStateMixin {
  int _step = 0;
  int _selectedService = -1;
  final _accountCtrl = TextEditingController();
  bool _isYearly = false;
  bool _autoRenew = true;
  bool _paying = false;
  String _refNumber = '';

  late AnimationController _checkCtrl;
  late Animation<double> _checkAnim;

  static const _bgColor = Color(0xFF1A1A2E);
  static const _purple = Color(0xFF6C63FF);
  static const _green = Color(0xFF00C853);
  static const _cardBg = Color(0xFF16213E);

  final _services = <Map<String, dynamic>>[
    {'name': 'Netflix', 'icon': Icons.live_tv, 'color': const Color(0xFFE50914), 'monthly': 15000.0, 'yearly': 150000.0},
    {'name': 'Spotify', 'icon': Icons.music_note, 'color': const Color(0xFF1DB954), 'monthly': 8000.0, 'yearly': 80000.0},
    {'name': 'YouTube Premium', 'icon': Icons.play_circle, 'color': const Color(0xFFFF0000), 'monthly': 10000.0, 'yearly': 100000.0},
    {'name': 'iCloud', 'icon': Icons.cloud, 'color': const Color(0xFF147EFB), 'monthly': 6000.0, 'yearly': 60000.0},
    {'name': 'Google One', 'icon': Icons.storage, 'color': const Color(0xFF4285F4), 'monthly': 5000.0, 'yearly': 50000.0},
    {'name': 'Microsoft 365', 'icon': Icons.window, 'color': const Color(0xFF0078D4), 'monthly': 20000.0, 'yearly': 200000.0},
    {'name': 'OSN', 'icon': Icons.satellite_alt, 'color': const Color(0xFFD4AF37), 'monthly': 25000.0, 'yearly': 250000.0},
    {'name': 'Shahid', 'icon': Icons.movie, 'color': const Color(0xFF00827F), 'monthly': 12000.0, 'yearly': 120000.0},
  ];

  double get _price {
    if (_selectedService < 0) return 0;
    return _isYearly
        ? _services[_selectedService]['yearly'] as double
        : _services[_selectedService]['monthly'] as double;
  }

  int get _savingPercent {
    if (_selectedService < 0) return 17;
    final monthly = _services[_selectedService]['monthly'] as double;
    final yearly = _services[_selectedService]['yearly'] as double;
    return ((monthly * 12 - yearly) / (monthly * 12) * 100).round();
  }

  DateTime get _nextRenewal =>
      DateTime.now().add(_isYearly ? const Duration(days: 365) : const Duration(days: 30));

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
    _accountCtrl.dispose();
    super.dispose();
  }

  void _goStep(int s) => setState(() => _step = s);

  Future<void> _pay() async {
    setState(() => _paying = true);
    final err = await AppService().payBill(
      amount: _price,
      billType: 'subscription',
      billRef: _accountCtrl.text,
    );
    setState(() => _paying = false);
    if (err != null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    _refNumber = 'SUB${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    _goStep(2);
    _checkCtrl.forward();
  }

  Future<void> _downloadPdf() async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.cairoRegular();
    final fontBold = await PdfGoogleFonts.cairoBold();
    final svc = _services[_selectedService];
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      textDirection: pw.TextDirection.rtl,
      build: (_) => pw.Directionality(
        textDirection: pw.TextDirection.rtl,
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text('إيصال اشتراك', style: pw.TextStyle(font: fontBold, fontSize: 24)),
          pw.SizedBox(height: 20),
          pw.Text('الرقم المرجعي: $_refNumber', style: pw.TextStyle(font: font)),
          pw.Text('الخدمة: ${svc['name']}', style: pw.TextStyle(font: font)),
          pw.Text('الحساب: ${_accountCtrl.text}', style: pw.TextStyle(font: font)),
          pw.Text('الدورية: ${_isYearly ? "سنوي" : "شهري"}', style: pw.TextStyle(font: font)),
          pw.Text('المبلغ المدفوع: ${_fmt.format(_price)} ل.س', style: pw.TextStyle(font: font)),
          pw.Text('التجديد التلقائي: ${_autoRenew ? "مفعّل" : "غير مفعّل"}', style: pw.TextStyle(font: font)),
          pw.Text('التجديد القادم: ${DateFormat('yyyy/MM/dd').format(_nextRenewal)}', style: pw.TextStyle(font: font)),
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
              if (_step > 0 && _step < 2) _goStep(_step - 1);
              else Navigator.pop(context);
            },
          ),
          title: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: _purple.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.subscriptions, color: _purple),
            ),
            const SizedBox(width: 12),
            const Text('الاشتراكات', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
    final valid = _selectedService >= 0 && _accountCtrl.text.trim().isNotEmpty;
    return SingleChildScrollView(
      key: key,
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _stepIndicator(0),
        const SizedBox(height: 24),
        const Text('اختر الخدمة', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.5,
          ),
          itemCount: _services.length,
          itemBuilder: (_, i) {
            final svc = _services[i];
            final selected = _selectedService == i;
            final color = svc['color'] as Color;
            return GestureDetector(
              onTap: () => setState(() => _selectedService = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: selected ? color.withOpacity(0.25) : _cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: selected ? color : Colors.white12, width: selected ? 2 : 1),
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(svc['icon'] as IconData, color: color, size: 28),
                  const SizedBox(height: 6),
                  Text(svc['name'] as String,
                      style: TextStyle(color: selected ? Colors.white : Colors.white70, fontWeight: FontWeight.bold, fontSize: 12),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 2),
                  Text('${_fmt.format(svc['monthly'])} ل.س/شهر',
                      style: const TextStyle(color: Colors.white54, fontSize: 10)),
                ]),
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        const Text('إيميل أو رقم الحساب', style: TextStyle(color: Colors.white70, fontSize: 14)),
        const SizedBox(height: 8),
        TextField(
          controller: _accountCtrl,
          style: const TextStyle(color: Colors.white),
          textDirection: TextDirection.ltr,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'example@email.com',
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: _cardBg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            prefixIcon: const Icon(Icons.alternate_email, color: Colors.white38),
          ),
        ),
        const SizedBox(height: 24),
        const Text('دورية الدفع', style: TextStyle(color: Colors.white70, fontSize: 14)),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(color: _cardBg, borderRadius: BorderRadius.circular(14)),
          child: Row(children: [
            Expanded(child: GestureDetector(
              onTap: () => setState(() => _isYearly = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(4),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !_isYearly ? _purple : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('شهري', textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            )),
            Expanded(child: GestureDetector(
              onTap: () => setState(() => _isYearly = true),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(4),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _isYearly ? _purple : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Text('سنوي', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: _green, borderRadius: BorderRadius.circular(8)),
                    child: Text('وفّر $_savingPercent%',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ]),
              ),
            )),
          ]),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(color: _cardBg, borderRadius: BorderRadius.circular(14)),
          child: Row(children: [
            const Icon(Icons.autorenew, color: _purple),
            const SizedBox(width: 12),
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('التجديد التلقائي', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              Text('يتجدد الاشتراك تلقائياً عند انتهائه', style: TextStyle(color: Colors.white54, fontSize: 12)),
            ])),
            Switch(value: _autoRenew, onChanged: (v) => setState(() => _autoRenew = v), activeColor: _purple),
          ]),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: valid ? () => _goStep(1) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _purple,
              disabledBackgroundColor: _purple.withOpacity(0.3),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('متابعة', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                textDirection: TextDirection.rtl),
          ),
        ),
        const SizedBox(height: 20),
      ]),
    );
  }

  Widget _buildStep2({Key? key}) {
    final svc = _services[_selectedService];
    final color = svc['color'] as Color;
    final balance = AppService().currentUser?.balance ?? 0;
    return SingleChildScrollView(
      key: key,
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        _stepIndicator(1),
        const SizedBox(height: 24),
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
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.2), shape: BoxShape.circle),
              child: Icon(svc['icon'] as IconData, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(svc['name'] as String,
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              Text(_isYearly ? 'اشتراك سنوي' : 'اشتراك شهري',
                  style: TextStyle(color: color, fontSize: 13)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('${_fmt.format(_price)} ل.س',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              Text(_isYearly ? 'سنوياً' : 'شهرياً',
                  style: const TextStyle(color: Colors.white54, fontSize: 11)),
            ]),
          ]),
        ),
        const SizedBox(height: 16),
        _detailCard([
          _detailRow('الحساب', _accountCtrl.text),
          _detailRow('الدورية', _isYearly ? 'سنوي' : 'شهري'),
          _detailRow('المبلغ المستحق', '${_fmt.format(_price)} ل.س'),
          _detailRow('تاريخ التجديد القادم', DateFormat('yyyy/MM/dd').format(_nextRenewal)),
          _detailRow('التجديد التلقائي', _autoRenew ? 'مفعّل ✓' : 'غير مفعّل'),
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
                : const Text('اشترك الآن', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    textDirection: TextDirection.rtl),
          ),
        ),
        const SizedBox(height: 20),
      ]),
    );
  }

  Widget _buildStep3({Key? key}) {
    final svc = _services[_selectedService];
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
        const Text('تم الاشتراك بنجاح!',
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('الرقم المرجعي: $_refNumber',
            style: const TextStyle(color: Colors.white54, fontSize: 13)),
        const SizedBox(height: 24),
        _detailCard([
          _detailRow('الخدمة', svc['name'] as String),
          _detailRow('الحساب', _accountCtrl.text),
          _detailRow('المبلغ المدفوع', '${_fmt.format(_price)} ل.س'),
          _detailRow('الدورية', _isYearly ? 'سنوي' : 'شهري'),
          _detailRow('التجديد القادم', DateFormat('yyyy/MM/dd').format(_nextRenewal)),
          _detailRow('التجديد التلقائي', _autoRenew ? 'مفعّل' : 'غير مفعّل'),
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
              backgroundColor: _purple,
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
    const labels = ['اختيار الخدمة', 'التأكيد', 'الإيصال'];
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
                color: done ? _green : current ? _purple : Colors.white12,
                shape: BoxShape.circle,
              ),
              child: Center(child: done
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : Text('${i + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
            ),
            const SizedBox(height: 4),
            Text(labels[i], style: TextStyle(color: current ? _purple : Colors.white38, fontSize: 10)),
          ]),
          if (i < 2) Expanded(child: Container(height: 1,
              color: i < active ? _green : Colors.white12, margin: const EdgeInsets.only(bottom: 16))),
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
        decoration: BoxDecoration(color: _purple.withOpacity(0.2), shape: BoxShape.circle),
        child: const Icon(Icons.account_balance_wallet, color: _purple),
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

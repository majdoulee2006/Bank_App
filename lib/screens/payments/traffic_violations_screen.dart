import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../services/app_service.dart';

class _Violation {
  final String id;
  final String type;
  final IconData icon;
  final Color color;
  final String date;
  final String location;
  final double amount;
  final bool alreadyPaid;
  bool selected;

  _Violation({
    required this.id,
    required this.type,
    required this.icon,
    required this.color,
    required this.date,
    required this.location,
    required this.amount,
    this.alreadyPaid = false,
    this.selected = false,
  });
}

class TrafficViolationsScreen extends StatefulWidget {
  const TrafficViolationsScreen({super.key});

  @override
  State<TrafficViolationsScreen> createState() => _TrafficViolationsScreenState();
}

class _TrafficViolationsScreenState extends State<TrafficViolationsScreen>
    with TickerProviderStateMixin {
  int _step = 0;
  bool _usePlate = true; // true = plate, false = license
  final _inputCtrl = TextEditingController();
  bool _loading = false;
  bool _paying = false;
  String _refNumber = '';

  late AnimationController _checkCtrl;
  late Animation<double> _checkAnim;

  static const _bgColor = Color(0xFF1A1A2E);
  static const _purple = Color(0xFF6C63FF);
  static const _green = Color(0xFF00C853);
  static const _red = Color(0xFFE53935);
  static const _cardBg = Color(0xFF16213E);

  final _violations = [
    _Violation(
      id: 'MV-2024-1823',
      type: 'تجاوز السرعة',
      icon: Icons.speed,
      color: const Color(0xFFE53935),
      date: '2024/11/03',
      location: 'طريق المطار – كيلو 5',
      amount: 50000,
    ),
    _Violation(
      id: 'MV-2024-1756',
      type: 'ركن ممنوع',
      icon: Icons.local_parking,
      color: const Color(0xFFFFA726),
      date: '2024/10/18',
      location: 'شارع بغداد – مركز المدينة',
      amount: 25000,
    ),
    _Violation(
      id: 'MV-2024-1690',
      type: 'تجاوز إشارة حمراء',
      icon: Icons.traffic,
      color: const Color(0xFFE53935),
      date: '2024/09/25',
      location: 'تقاطع السبع بحرات',
      amount: 75000,
    ),
    _Violation(
      id: 'MV-2024-1531',
      type: 'موبايل أثناء القيادة',
      icon: Icons.phone_android,
      color: const Color(0xFF9C27B0),
      date: '2024/08/14',
      location: 'أوتوستراد المزة',
      amount: 30000,
      alreadyPaid: true,
    ),
    _Violation(
      id: 'MV-2024-1442',
      type: 'حزام الأمان',
      icon: Icons.airline_seat_recline_normal,
      color: const Color(0xFF26C6DA),
      date: '2024/07/30',
      location: 'شارع الثلاثين',
      amount: 15000,
    ),
  ];

  List<_Violation> get _unpaid => _violations.where((v) => !v.alreadyPaid).toList();
  List<_Violation> get _selected => _unpaid.where((v) => v.selected).toList();
  double get _selectedTotal => _selected.fold(0, (sum, v) => sum + v.amount);
  double get _unpaidTotal => _unpaid.fold(0, (sum, v) => sum + v.amount);

  bool get _allSelected => _unpaid.isNotEmpty && _unpaid.every((v) => v.selected);

  final _fmt = NumberFormat('#,###');

  // Mock car info
  final _carInfo = {
    'plate': 'دمشق أ – 12345',
    'type': 'تويوتا كورولا 2019',
    'color': 'أبيض',
    'owner': 'خالد سمير العلي',
  };

  @override
  void initState() {
    super.initState();
    _checkCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _checkAnim = CurvedAnimation(parent: _checkCtrl, curve: Curves.elasticOut);
  }

  @override
  void dispose() {
    _checkCtrl.dispose();
    _inputCtrl.dispose();
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
    if (_selected.isEmpty) return;
    setState(() => _paying = true);
    final err = await AppService().payBill(
      amount: _selectedTotal,
      billType: 'traffic_violation',
      billRef: _inputCtrl.text,
    );
    setState(() => _paying = false);
    if (err != null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    for (final v in _selected) {
      v.selected = false;
    }
    _refNumber = 'TRF${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    _goStep(2);
    _checkCtrl.forward();
  }

  Future<void> _downloadPdf() async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.cairoRegular();
    final fontBold = await PdfGoogleFonts.cairoBold();
    // violations that were paid in this session (selected before clearing)
    // We capture them before payment so we track them separately
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      textDirection: pw.TextDirection.rtl,
      build: (_) => pw.Directionality(
        textDirection: pw.TextDirection.rtl,
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text('إيصال دفع مخالفات مرور', style: pw.TextStyle(font: fontBold, fontSize: 22)),
          pw.SizedBox(height: 20),
          pw.Text('الرقم المرجعي: $_refNumber', style: pw.TextStyle(font: font)),
          pw.Text('رقم اللوحة: ${_carInfo['plate']}', style: pw.TextStyle(font: font)),
          pw.Text('صاحب السيارة: ${_carInfo['owner']}', style: pw.TextStyle(font: font)),
          pw.Text('المبلغ الإجمالي المدفوع: ${_fmt.format(_paidInSession)} ل.س', style: pw.TextStyle(font: font)),
          pw.Text('التاريخ: ${DateFormat('yyyy/MM/dd – HH:mm').format(DateTime.now())}', style: pw.TextStyle(font: font)),
        ]),
      ),
    ));
    await Printing.layoutPdf(onLayout: (_) => pdf.save());
  }

  // Keep track of what was paid in this session
  List<_Violation> _paidViolations = [];
  double _paidInSession = 0;

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
              decoration: BoxDecoration(
                  color: _red.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.directions_car, color: _red),
            ),
            const SizedBox(width: 12),
            const Text('مخالفات المرور',
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
    final valid = _inputCtrl.text.trim().isNotEmpty;
    return SingleChildScrollView(
      key: key,
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _stepIndicator(0),
        const SizedBox(height: 32),
        // Toggle
        Container(
          decoration: BoxDecoration(color: _cardBg, borderRadius: BorderRadius.circular(14)),
          child: Row(children: [
            Expanded(child: GestureDetector(
              onTap: () => setState(() { _usePlate = true; _inputCtrl.clear(); }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(4),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _usePlate ? _purple : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.directions_car, color: _usePlate ? Colors.white : Colors.white54, size: 18),
                  const SizedBox(width: 6),
                  Text('رقم اللوحة',
                      style: TextStyle(
                          color: _usePlate ? Colors.white : Colors.white54,
                          fontWeight: FontWeight.bold)),
                ]),
              ),
            )),
            Expanded(child: GestureDetector(
              onTap: () => setState(() { _usePlate = false; _inputCtrl.clear(); }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(4),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: !_usePlate ? _purple : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.credit_card, color: !_usePlate ? Colors.white : Colors.white54, size: 18),
                  const SizedBox(width: 6),
                  Text('رخصة القيادة',
                      style: TextStyle(
                          color: !_usePlate ? Colors.white : Colors.white54,
                          fontWeight: FontWeight.bold)),
                ]),
              ),
            )),
          ]),
        ),
        const SizedBox(height: 24),
        Text(
          _usePlate ? 'رقم لوحة السيارة' : 'رقم رخصة القيادة',
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _inputCtrl,
          style: const TextStyle(color: Colors.white, letterSpacing: 2),
          textDirection: TextDirection.rtl,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: _usePlate ? 'مثال: دمشق أ – 12345' : 'مثال: 1234567',
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: _cardBg,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            prefixIcon: Icon(_usePlate ? Icons.directions_car : Icons.credit_card,
                color: Colors.white38),
          ),
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          height: 64,
          child: ElevatedButton(
            onPressed: (valid && !_loading) ? _query : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _red,
              disabledBackgroundColor: _red.withOpacity(0.3),
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
    final balance = AppService().currentUser?.balance ?? 0;
    return Column(
      key: key,
      children: [
        // Car info header
        Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_red.withOpacity(0.3), _red.withOpacity(0.1)],
              begin: Alignment.topRight, end: Alignment.bottomLeft,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _red.withOpacity(0.4)),
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: _red.withOpacity(0.2), shape: BoxShape.circle),
              child: const Icon(Icons.directions_car, color: _red, size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_carInfo['plate']!,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              Text('${_carInfo['type']} – ${_carInfo['color']}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
              Text(_carInfo['owner']!, style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              const Text('إجمالي غير المدفوع', style: TextStyle(color: Colors.white54, fontSize: 10)),
              Text('${_fmt.format(_unpaidTotal)} ل.س',
                  style: const TextStyle(color: _red, fontSize: 15, fontWeight: FontWeight.bold)),
            ]),
          ]),
        ),
        const SizedBox(height: 12),
        // Select all + total row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            GestureDetector(
              onTap: () => setState(() {
                final val = !_allSelected;
                for (final v in _unpaid) v.selected = val;
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: _allSelected ? _purple : _cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _allSelected ? _purple : Colors.white24),
                ),
                child: Row(children: [
                  Icon(_allSelected ? Icons.check_box : Icons.check_box_outline_blank,
                      color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  const Text('تحديد الكل', style: TextStyle(color: Colors.white, fontSize: 13)),
                ]),
              ),
            ),
            const Spacer(),
            if (_selected.isNotEmpty)
              Text('المحدد: ${_fmt.format(_selectedTotal)} ل.س',
                  style: const TextStyle(color: _green, fontWeight: FontWeight.bold, fontSize: 13)),
          ]),
        ),
        const SizedBox(height: 8),
        // Violations list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _violations.length,
            itemBuilder: (_, i) {
              final v = _violations[i];
              return _violationCard(v);
            },
          ),
        ),
        // Bottom section
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(children: [
            // Source account
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: _purple.withOpacity(0.2), shape: BoxShape.circle),
                child: const Icon(Icons.account_balance_wallet, color: _purple, size: 18),
              ),
              const SizedBox(width: 10),
              const Expanded(child: Text('الحساب الرئيسي',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
              Text('${_fmt.format(balance)} ل.س',
                  style: const TextStyle(color: Colors.white70, fontSize: 13)),
            ]),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: (_selected.isNotEmpty && !_paying) ? () async {
                  _paidViolations = List.from(_selected);
                  _paidInSession = _selectedTotal;
                  await _pay();
                } : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  disabledBackgroundColor: _green.withOpacity(0.3),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _paying
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        _selected.isEmpty
                            ? 'اختر مخالفة للدفع'
                            : 'دفع ${_selected.length} مخالفة – ${_fmt.format(_selectedTotal)} ل.س',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        textDirection: TextDirection.rtl),
              ),
            ),
          ]),
        ),
      ],
    );
  }

  Widget _violationCard(_Violation v) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: v.alreadyPaid ? _cardBg.withOpacity(0.6) : _cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: v.alreadyPaid
              ? Colors.white12
              : v.selected
                  ? _purple
                  : Colors.white12,
          width: v.selected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: v.alreadyPaid ? null : () => setState(() => v.selected = !v.selected),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            if (!v.alreadyPaid)
              Checkbox(
                value: v.selected,
                onChanged: (val) => setState(() => v.selected = val ?? false),
                activeColor: _purple,
                side: const BorderSide(color: Colors.white38),
                visualDensity: VisualDensity.compact,
              )
            else
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(Icons.check_circle, color: _green, size: 22),
              ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: v.color.withOpacity(0.15), shape: BoxShape.circle),
              child: Icon(v.icon, color: v.color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(v.type,
                  style: TextStyle(
                      color: v.alreadyPaid ? Colors.white54 : Colors.white,
                      fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 2),
              Text(v.date, style: const TextStyle(color: Colors.white54, fontSize: 11)),
              Text(v.location, style: const TextStyle(color: Colors.white38, fontSize: 10)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('${_fmt.format(v.amount)} ل.س',
                  style: TextStyle(
                      color: v.alreadyPaid ? Colors.white38 : Colors.white,
                      fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: (v.alreadyPaid ? _green : _red).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  v.alreadyPaid ? 'مدفوعة' : 'غير مدفوعة',
                  style: TextStyle(
                      color: v.alreadyPaid ? _green : _red, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ]),
          ]),
        ),
      ),
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
        const Text('تم دفع المخالفات بنجاح!',
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('الرقم المرجعي: $_refNumber',
            style: const TextStyle(color: Colors.white54, fontSize: 13)),
        const SizedBox(height: 24),
        // Summary card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: _cardBg, borderRadius: BorderRadius.circular(16)),
          child: Column(children: [
            _detailRow('رقم اللوحة', _carInfo['plate']!),
            _detailRow('صاحب السيارة', _carInfo['owner']!),
            _detailRow('عدد المخالفات المدفوعة', '${_paidViolations.length} مخالفة'),
            _detailRow('المبلغ الإجمالي', '${_fmt.format(_paidInSession)} ل.س'),
            _detailRow('التاريخ', DateFormat('yyyy/MM/dd – HH:mm').format(DateTime.now())),
          ]),
        ),
        const SizedBox(height: 16),
        // Violations breakdown
        if (_paidViolations.isNotEmpty) ...[
          Align(
            alignment: Alignment.centerRight,
            child: const Text('تفاصيل المخالفات المدفوعة',
                style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(color: _cardBg, borderRadius: BorderRadius.circular(16)),
            child: Column(children: _paidViolations.map((v) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: _paidViolations.last != v
                    ? const Border(bottom: BorderSide(color: Colors.white12))
                    : null,
              ),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: v.color.withOpacity(0.15), shape: BoxShape.circle),
                  child: Icon(v.icon, color: v.color, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(v.type, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                  Text('${v.date} – ${v.location}',
                      style: const TextStyle(color: Colors.white54, fontSize: 11)),
                ])),
                Text('${_fmt.format(v.amount)} ل.س',
                    style: const TextStyle(color: _green, fontWeight: FontWeight.bold)),
              ]),
            )).toList()),
          ),
        ],
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 64,
          child: ElevatedButton.icon(
            onPressed: _downloadPdf,
            icon: const Icon(Icons.download, color: Colors.white),
            label: const Text('تحميل الإيصال',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                textDirection: TextDirection.rtl),
            style: ElevatedButton.styleFrom(
              backgroundColor: _red,
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
    const labels = ['إدخال البيانات', 'المخالفات', 'الإيصال'];
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
                color: done ? _green : current ? _red : Colors.white12,
                shape: BoxShape.circle,
              ),
              child: Center(child: done
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : Text('${i + 1}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
            ),
            const SizedBox(height: 4),
            Text(labels[i], style: TextStyle(color: current ? _red : Colors.white38, fontSize: 10)),
          ]),
          if (i < 2) Expanded(child: Container(
              height: 1, color: i < active ? _green : Colors.white12,
              margin: const EdgeInsets.only(bottom: 16))),
        ]));
      }),
    );
  }

  Widget _detailRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(color: Colors.white54, fontSize: 14)),
      Flexible(child: Text(value,
          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
          textAlign: TextAlign.end)),
    ]),
  );
}

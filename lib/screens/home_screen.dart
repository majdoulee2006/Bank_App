import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../services/app_service.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';
import 'transfer_screen.dart';
import 'receive_screen.dart';
import 'admin_users_screen.dart';
import 'admin_home_screen.dart';
import 'verify_identity_screen.dart';
import '../models/user_model.dart';
import 'bills/electricity_bill_screen.dart';
import 'bills/water_bill_screen.dart';
import 'bills/landline_bill_screen.dart';
import 'bills/internet_bill_screen.dart';
import 'payments/mobile_topup_screen.dart';
import 'payments/loan_repayment_screen.dart';
import 'payments/subscriptions_screen.dart';
import 'payments/insurance_screen.dart';
import 'payments/education_fees_screen.dart';
import 'payments/traffic_violations_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;
  bool _balanceHidden = false;

  void _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: AppTheme.bgCard,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('تسجيل الخروج',
              style: TextStyle(color: Colors.white)),
          content: const Text('هل تريد تسجيل الخروج من حسابك؟',
              style: TextStyle(color: AppTheme.textSecondary)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.error),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('خروج'),
            ),
          ],
        ),
      ),
    );
    if (confirm != true) return;
    await AppService().logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _goToTransfer() async {
    final user = AppService().currentUser;
    if (user != null && !user.isVerified) {
      _showVerifyRequired();
      return;
    }
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TransferScreen()),
    );
    if (result == true) setState(() {});
  }

  void _showVerifyRequired() {
    final user = AppService().currentUser;
    final isPending = user?.nationalId != null;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(isPending
          ? 'طلب التوثيق قيد المراجعة، يرجى الانتظار'
          : 'يجب توثيق حسابك أولاً قبل إجراء أي عملية'),
      backgroundColor: AppTheme.warning,
      duration: const Duration(seconds: 3),
    ));
  }

  bool _checkVerified() {
    final user = AppService().currentUser;
    if (user == null || user.isVerified) return true;
    _showVerifyRequired();
    return false;
  }

  void _goToReceive() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ReceiveScreen()),
    );
  }

  void _showUsersScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AdminUsersScreen()),
    ).then((_) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final user = AppService().currentUser;
    if (user == null) return const SizedBox();

    // Admin gets dedicated dashboard
    if (user.phone == 'admin') return const AdminHomeScreen();

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: _navIndex == 0
              ? _buildHome(user)
              : _buildProfilePage(user),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ── Home Tab ──────────────────────────────────────────────
  Widget _buildHome(UserModel user) {
    return Column(
      children: [
        _buildTopBar(user),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildBalanceSection(user),
                const SizedBox(height: 20),
                _buildActionsGrid(),
                const SizedBox(height: 24),
                _buildRecentTransactions(user),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar(UserModel user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Notifications
          GestureDetector(
            onTap: () => _showNotificationsSheet(user),
            child: Stack(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppTheme.bgSurface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.notifications_outlined,
                      color: Colors.white, size: 22),
                ),
                if (user.transactions.any((t) => t.type == 'received'))
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppTheme.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Name
          Column(
            children: [
              Text(
                'أهلاً، ${user.fullName}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
              Text(
                user.phone,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 12),
              ),
            ],
          ),
          // Avatar + Logout
          GestureDetector(
            onLongPress: _logout,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  user.fullName.isNotEmpty
                      ? user.fullName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceSection(UserModel user) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3A3CC8), Color(0xFF6C63FF)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('الرصيد المتاح',
                    style: TextStyle(color: Colors.white70, fontSize: 14)),
                Text('# ${user.accountNumber}',
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 11, letterSpacing: 1)),
              ],
            ),
              GestureDetector(
                onTap: () => setState(() => _balanceHidden = !_balanceHidden),
                child: Icon(
                  _balanceHidden
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Colors.white70,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _balanceHidden
                ? '••••••'
                : '${user.balance.toStringAsFixed(2)} ل.س',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _actionButton(
                  label: 'استقبال',
                  icon: Icons.call_received_rounded,
                  color: const Color(0xFF00BFA5),
                  onTap: _goToReceive,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _actionButton(
                  label: 'إرسال',
                  icon: Icons.send_rounded,
                  color: const Color(0xFF7C4DFF),
                  onTap: _goToTransfer,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsGrid() {
    final isAdmin = AppService().currentUser?.phone == 'admin';
    final items = [
      if (isAdmin) {'icon': Icons.people_outline, 'label': 'المستخدمين', 'onTap': 'users'},
      if (!isAdmin) {'icon': Icons.receipt_long_outlined, 'label': 'فواتير', 'onTap': 'bills'},
      if (!isAdmin) {'icon': Icons.payments_outlined, 'label': 'مدفوعات', 'onTap': 'payments'},
      if (!isAdmin) {'icon': Icons.calculate_outlined, 'label': 'حاسبة العمولة', 'onTap': 'calculator'},
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: items.length,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: isAdmin ? 1.5 : 0.85,
        ),
        itemBuilder: (_, i) {
          final item = items[i];
          return GestureDetector(
            onTap: () {
              switch (item['onTap']) {
                case 'users': _showUsersScreen(); break;
                case 'bills': _showBillsSheet(); break;
                case 'payments': _showPaymentsSheet(); break;
                case 'calculator': _showFeeCalculator(); break;
              }
            },
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.bgSurface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(item['icon'] as IconData,
                      color: AppTheme.primary, size: 26),
                  const SizedBox(height: 6),
                  Text(item['label'] as String,
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 11)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecentTransactions(UserModel user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'آخر التحويلات',
            style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          user.transactions.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('لا توجد حركات بعد',
                        style: TextStyle(color: AppTheme.textSecondary)),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: user.transactions.length,
                  itemBuilder: (_, i) =>
                      _buildTxItem(user.transactions[i]),
                ),
        ],
      ),
    );
  }

  Widget _buildTxItem(TransactionModel tx) {
    final isSent = tx.type == 'sent';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isSent
                  ? AppTheme.error.withValues(alpha: 0.12)
                  : AppTheme.success.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isSent ? Icons.arrow_upward : Icons.arrow_downward,
              color: isSent ? AppTheme.error : AppTheme.success,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.counterPartyName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
                const SizedBox(height: 3),
                if (tx.note != null && tx.note!.isNotEmpty)
                  Text(tx.note!,
                      style: const TextStyle(
                          color: AppTheme.secondary,
                          fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                Text(
                  DateFormat('yyyy/MM/dd HH:mm').format(tx.date),
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
          Text(
            '${isSent ? "−" : "+"} ${tx.amount.toStringAsFixed(2)}',
            style: TextStyle(
              color: isSent ? AppTheme.error : AppTheme.success,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  // ── Transactions Tab ──────────────────────────────────────
  Widget _buildTransactionsPage(UserModel user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(20),
          child: Text('جميع الحركات',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: user.transactions.isEmpty
              ? const Center(
                  child: Text('لا توجد حركات',
                      style: TextStyle(color: AppTheme.textSecondary)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: user.transactions.length,
                  itemBuilder: (_, i) => _buildTxItem(user.transactions[i]),
                ),
        ),
      ],
    );
  }

  // ── Profile Tab ───────────────────────────────────────────
  Widget _buildProfilePage(UserModel user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Avatar
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    shape: BoxShape.circle),
                child: Center(
                  child: Text(
                    user.fullName.isNotEmpty
                        ? user.fullName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              if (user.isVerified)
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                      color: AppTheme.success, shape: BoxShape.circle),
                  child: const Icon(Icons.verified,
                      color: Colors.white, size: 16),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(user.fullName,
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              if (user.isVerified) ...[
                const SizedBox(width: 6),
                const Icon(Icons.verified, color: AppTheme.success, size: 20),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(user.phone, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          const SizedBox(height: 4),
          // Account number chip
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.bgSurface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.tag, color: AppTheme.primary, size: 14),
                const SizedBox(width: 4),
                Text(user.accountNumber,
                    style: const TextStyle(
                        color: Colors.white,
                        letterSpacing: 1.5,
                        fontSize: 14)),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Settings
          _profileTile(Icons.qr_code, 'رمز QR الخاص بي', () {
            Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ReceiveScreen()));
          }),
          const SizedBox(height: 10),
          if (user.phone != 'admin') ...[
            if (user.isVerified)
              // Verified
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: AppTheme.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.success.withValues(alpha: 0.3)),
                ),
                child: const Row(children: [
                  Icon(Icons.verified, color: AppTheme.success, size: 22),
                  SizedBox(width: 12),
                  Text('تم توثيق الحساب',
                      style: TextStyle(color: AppTheme.success, fontSize: 15, fontWeight: FontWeight.bold)),
                ]),
              )
            else if (user.nationalId != null)
              // Pending
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.warning.withValues(alpha: 0.3)),
                ),
                child: const Row(children: [
                  Icon(Icons.hourglass_top_rounded, color: AppTheme.warning, size: 22),
                  SizedBox(width: 12),
                  Text('طلب التوثيق قيد المراجعة',
                      style: TextStyle(color: AppTheme.warning, fontSize: 15, fontWeight: FontWeight.bold)),
                ]),
              )
            else ...[
              // Not submitted yet
              _profileTile(Icons.verified_user_outlined, 'توثيق الحساب (رقم وطني)', _showVerifyDialog),
              const SizedBox(height: 10),
            ],
          ],
          _profileTile(Icons.lock_outline, 'تغيير رمز PIN',
              _showChangePinDialog),
          const SizedBox(height: 10),
          _profileTile(Icons.phone_android, 'تغيير رقم الجوال',
              _showChangePhoneDialog),
          const SizedBox(height: 24),
          _profileTile(Icons.logout, 'تسجيل الخروج', _logout,
              color: AppTheme.error),
        ],
      ),
    );
  }

  Widget _profileTile(IconData icon, String label, VoidCallback onTap,
      {Color? color}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.bgSurface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: color ?? AppTheme.primary),
            const SizedBox(width: 14),
            Expanded(
                child: Text(label,
                    style:
                        TextStyle(color: color ?? Colors.white, fontSize: 15))),
            if (color == null || color == AppTheme.success)
              const Icon(Icons.arrow_forward_ios,
                  color: AppTheme.textSecondary, size: 16),
          ],
        ),
      ),
    );
  }

  // ── Setting Dialogs ───────────────────────────────────────
  void _showVerifyDialog() {
    final user = AppService().currentUser;
    if (user?.isVerified == true) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const VerifyIdentityScreen()),
    ).then((sent) { if (sent == true) setState(() {}); });
  }

  void _showChangePinDialog() {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: AppTheme.bgCard,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('تغيير رمز PIN',
              style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dialogField(oldCtrl, 'رمز PIN الحالي', obscure: true),
              const SizedBox(height: 12),
              _dialogField(newCtrl, 'رمز PIN الجديد', obscure: true),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () async {
                final err = await AppService().changePin(
                    oldPin: oldCtrl.text, newPin: newCtrl.text);
                if (!mounted) return;
                Navigator.pop(context);
                if (err != null) {
                  _showError(err);
                } else {
                  _showSuccess('تم تغيير رمز PIN بنجاح');
                }
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePhoneDialog() {
    final phoneCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: AppTheme.bgCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('تغيير رقم الجوال', style: TextStyle(color: Colors.white)),
          content: _dialogField(phoneCtrl, 'رقم الجوال الجديد', keyboardType: TextInputType.phone),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () async {
                final phone = phoneCtrl.text.trim();
                if (phone.isEmpty) return;
                Navigator.pop(context);
                final result = await AppService().requestPhoneOtp(phone);
                if (!mounted) return;
                if (result.error != null) { _showError(result.error!); return; }
                // Show OTP overlay
                _showOtpOverlay(result.otp!);
                // Show OTP entry dialog
                _showOtpDialog(phone, result.otp!);
              },
              child: const Text('إرسال الرمز'),
            ),
          ],
        ),
      ),
    );
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
                const Text('رمز التحقق الخاص بك', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                Text(otp, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 6)),
              ])),
            ]),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(overlay);
    Future.delayed(const Duration(seconds: 30), overlay.remove);
  }

  void _showOtpDialog(String phone, String generatedOtp) {
    final otpCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: AppTheme.bgCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('أدخل رمز التحقق', style: TextStyle(color: Colors.white)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('الرمز ظاهر في الإشعار أعلى الشاشة',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            const SizedBox(height: 12),
            _dialogField(otpCtrl, 'رمز OTP المكوّن من 6 أرقام', keyboardType: TextInputType.number),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                final err = await AppService().changePhone(phone, otpCtrl.text.trim());
                if (!mounted) return;
                if (err != null) { _showError(err); } else { setState(() {}); _showSuccess('تم تغيير رقم الجوال بنجاح'); }
              },
              child: const Text('تأكيد'),
            ),
          ],
        ),
      ),
    );
  }

  void _showInputDialog({
    required String title,
    required String hint,
    required IconData icon,
    required TextInputType keyboardType,
    required TextEditingController controller,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: AppTheme.bgCard,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title:
              Text(title, style: const TextStyle(color: Colors.white)),
          content: _dialogField(controller, hint,
              keyboardType: keyboardType),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                onConfirm();
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dialogField(TextEditingController ctrl, String hint,
      {bool obscure = false,
      TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(hintText: hint),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppTheme.error));
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppTheme.success));
  }

  // ── Notifications Sheet ───────────────────────────────────
  void _showNotificationsSheet(UserModel user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _NotificationsSheet(user: user),
    );
  }

  // ignore: unused_element
  void _showNotificationsSheetOld(UserModel user) {
    final received = user.transactions.where((t) => t.type == 'received').toList();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textSecondary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Icon(Icons.notifications_active, color: AppTheme.primary),
                  SizedBox(width: 10),
                  Text('الإشعارات',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            received.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('لا توجد إشعارات', style: TextStyle(color: AppTheme.textSecondary)),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: received.length > 10 ? 10 : received.length,
                    itemBuilder: (_, i) {
                      final tx = received[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.bgSurface,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(
                                color: AppTheme.success.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.arrow_downward, color: AppTheme.success, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('استلمت من ${tx.counterPartyName}',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                  Text('${tx.amount.toStringAsFixed(2)} ل.س',
                                      style: const TextStyle(color: AppTheme.success, fontSize: 12)),
                                ],
                              ),
                            ),
                            Text(
                              DateFormat('MM/dd HH:mm').format(tx.date),
                              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ── Banks Sheet ───────────────────────────────────────────
  void _showBanksSheet() {
    const banks = [
      {'name': 'بنك سورية الدولي الإسلامي', 'icon': Icons.account_balance, 'phone': '011-9911', 'hours': '9:00 - 17:00', 'branches': '12'},
      {'name': 'البنك العربي السوري', 'icon': Icons.account_balance, 'phone': '011-2213300', 'hours': '8:30 - 15:30', 'branches': '24'},
      {'name': 'بنك بيمو السعودي الفرنسي', 'icon': Icons.account_balance, 'phone': '011-3327700', 'hours': '9:00 - 16:00', 'branches': '8'},
      {'name': 'بنك الشام', 'icon': Icons.account_balance, 'phone': '011-3737373', 'hours': '9:00 - 15:00', 'branches': '18'},
      {'name': 'بنك سورية والمهجر', 'icon': Icons.account_balance, 'phone': '011-2242424', 'hours': '8:30 - 15:30', 'branches': '15'},
      {'name': 'البنك التجاري السوري', 'icon': Icons.account_balance, 'phone': '011-2219600', 'hours': '8:00 - 15:00', 'branches': '30'},
      {'name': 'بنك التوفير المصرفي', 'icon': Icons.savings, 'phone': '011-3310000', 'hours': '9:00 - 14:00', 'branches': '10'},
      {'name': 'بنك قطر الوطني سورية', 'icon': Icons.account_balance, 'phone': '011-9990000', 'hours': '9:00 - 16:00', 'branches': '6'},
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.55,
          maxChildSize: 0.85,
          minChildSize: 0.4,
          builder: (_, scrollCtrl) => Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textSecondary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Icon(Icons.account_balance_outlined, color: AppTheme.primary),
                    SizedBox(width: 10),
                    Text('البنوك المتاحة',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: banks.length,
                  itemBuilder: (_, i) {
                    final bank = banks[i];
                    return GestureDetector(
                      onTap: () => _showBankDetail(bank),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppTheme.bgSurface,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(bank['icon'] as IconData, color: AppTheme.primary, size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(bank['name'] as String,
                                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                            ),
                            const Icon(Icons.arrow_forward_ios, color: AppTheme.textSecondary, size: 14),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ── Bank Detail ───────────────────────────────────────────
  void _showBankDetail(Map<String, Object> bank) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4,
                decoration: BoxDecoration(color: AppTheme.textSecondary, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(bank['icon'] as IconData, color: AppTheme.primary, size: 30),
              ),
              const SizedBox(height: 14),
              Text(bank['name'] as String,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              _bankInfoRow(Icons.phone_outlined, 'الهاتف', bank['phone'] as String),
              const SizedBox(height: 12),
              _bankInfoRow(Icons.access_time_outlined, 'أوقات العمل', bank['hours'] as String),
              const SizedBox(height: 12),
              _bankInfoRow(Icons.location_on_outlined, 'عدد الفروع', '${bank['branches']} فرع'),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: const Text('تحويل لهذا البنك', style: TextStyle(fontSize: 15)),
                  onPressed: () {
                    Navigator.pop(context);
                    _goToTransfer();
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bankInfoRow(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: AppTheme.bgSurface, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primary, size: 20),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          const Spacer(),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ── Bills Sheet ───────────────────────────────────────────
  void _showFeeCalculator() {
    final amountCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(
          builder: (ctx, setS) {
            double amount = double.tryParse(amountCtrl.text.replaceAll(',', '')) ?? 0;
            double fee = (amount / 1000) * 10;
            double total = amount + fee;
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: AppTheme.textSecondary, borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 16),
                const Row(children: [
                  Icon(Icons.calculate_outlined, color: AppTheme.primary),
                  SizedBox(width: 10),
                  Text('حاسبة العمولة', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 20),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  onChanged: (_) => setS(() {}),
                  decoration: const InputDecoration(
                    hintText: 'أدخل المبلغ بالليرة السورية',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                ),
                const SizedBox(height: 20),
                if (amount > 0) ...[
                  _calcRow('المبلغ الأصلي', '${amount.toStringAsFixed(0)} ل.س', Colors.white),
                  const SizedBox(height: 10),
                  _calcRow('العمولة (1٪)', '${fee.toStringAsFixed(2)} ل.س', AppTheme.warning),
                  const Divider(color: Colors.white12, height: 24),
                  _calcRow('الإجمالي المخصوم', '${total.toStringAsFixed(2)} ل.س', AppTheme.primary, bold: true),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'مقابل كل 1000 ل.س يُخصم 10 ل.س عمولة',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
              ]),
            );
          },
        ),
      ),
    );
  }

  Widget _calcRow(String label, String value, Color color, {bool bold = false}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
      Text(value, style: TextStyle(color: color, fontSize: 15, fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
    ]);
  }

  void _showBillsSheet() {
    if (!_checkVerified()) return;
    final bills = [
      {'icon': Icons.electric_bolt_outlined, 'label': 'كهرباء',    'color': const Color(0xFFFFC107), 'action': 'electricity'},
      {'icon': Icons.water_drop_outlined,    'label': 'مياه',       'color': const Color(0xFF00BCD4), 'action': 'water'},
      {'icon': Icons.phone_outlined,         'label': 'هاتف أرضي', 'color': const Color(0xFF4CAF50), 'action': 'landline'},
      {'icon': Icons.wifi_outlined,          'label': 'إنترنت',    'color': const Color(0xFF9C27B0), 'action': 'internet'},
    ];
    _showBillsServiceSheet(bills);
  }

  void _showBillsServiceSheet(List<Map<String, Object>> bills) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: AppTheme.textSecondary,
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              const Row(children: [
                Icon(Icons.receipt_long_outlined, color: AppTheme.primary),
                SizedBox(width: 10),
                Text('الفواتير', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85,
                children: bills.map((item) => GestureDetector(
                  onTap: () async {
                    if (item['action'] == 'electricity') {
                      Navigator.pop(context);
                      await Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => const ElectricityBillScreen()));
                      setState(() {});
                    } else if (item['action'] == 'water') {
                      Navigator.pop(context);
                      await Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => const WaterBillScreen()));
                      setState(() {});
                    } else if (item['action'] == 'landline') {
                      Navigator.pop(context);
                      await Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => const LandlineBillScreen()));
                      setState(() {});
                    } else if (item['action'] == 'internet') {
                      Navigator.pop(context);
                      await Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => const InternetBillScreen()));
                      setState(() {});
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${item['label']} — قريباً')));
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(color: AppTheme.bgSurface,
                        borderRadius: BorderRadius.circular(14)),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: (item['color'] as Color).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(item['icon'] as IconData, color: item['color'] as Color, size: 22),
                      ),
                      const SizedBox(height: 8),
                      Text(item['label'] as String,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontSize: 11)),
                    ]),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ── Payments Sheet ────────────────────────────────────────
  void _showPaymentsSheet() {
    if (!_checkVerified()) return;
    final payments = [
      {'icon': Icons.phone_android_outlined,  'label': 'شحن رصيد',     'color': const Color(0xFF6C63FF), 'action': 'topup'},
      {'icon': Icons.credit_card_outlined,    'label': 'سداد قرض',     'color': const Color(0xFFEF5350), 'action': 'loan'},
      {'icon': Icons.school_outlined,         'label': 'رسوم تعليمية', 'color': const Color(0xFFFFA726), 'action': 'education'},
      {'icon': Icons.directions_car_outlined, 'label': 'مخالفات مرور', 'color': const Color(0xFFFF7043), 'action': 'violations'},
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: AppTheme.textSecondary,
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              const Row(children: [
                Icon(Icons.payments_outlined, color: AppTheme.primary),
                SizedBox(width: 10),
                Text('المدفوعات', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1,
                children: payments.map((item) => GestureDetector(
                  onTap: () async {
                    if (item['action'] == 'topup') {
                      Navigator.pop(context);
                      await Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => const MobileTopupScreen()));
                      setState(() {});
                    } else if (item['action'] == 'loan') {
                      Navigator.pop(context);
                      await Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => const LoanRepaymentScreen()));
                      setState(() {});
                    } else if (item['action'] == 'subscriptions') {
                      Navigator.pop(context);
                      await Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => const SubscriptionsScreen()));
                      setState(() {});
                    } else if (item['action'] == 'insurance') {
                      Navigator.pop(context);
                      await Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => const InsuranceScreen()));
                      setState(() {});
                    } else if (item['action'] == 'education') {
                      Navigator.pop(context);
                      await Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => const EducationFeesScreen()));
                      setState(() {});
                    } else if (item['action'] == 'violations') {
                      Navigator.pop(context);
                      await Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => const TrafficViolationsScreen()));
                      setState(() {});
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${item['label']} — قريباً')));
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(color: AppTheme.bgSurface,
                        borderRadius: BorderRadius.circular(14)),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: (item['color'] as Color).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(item['icon'] as IconData,
                            color: item['color'] as Color, size: 22),
                      ),
                      const SizedBox(height: 8),
                      Text(item['label'] as String,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontSize: 11)),
                    ]),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ── Transfers Sheet ───────────────────────────────────────
  void _showTransfersSheet() {
    final options = [
      {'icon': Icons.person_outline, 'label': 'تحويل داخلي', 'color': AppTheme.primary},
      {'icon': Icons.account_balance_outlined, 'label': 'تحويل بنكي', 'color': const Color(0xFF29B6F6)},
      {'icon': Icons.public_outlined, 'label': 'تحويل دولي', 'color': const Color(0xFF66BB6A)},
      {'icon': Icons.qr_code_outlined, 'label': 'تحويل بـ QR', 'color': const Color(0xFFAB47BC)},
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
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
              const Row(children: [
                Icon(Icons.swap_horiz_rounded, color: AppTheme.primary),
                SizedBox(width: 10),
                Text('الحوالات', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 16),
              ...options.map((o) => GestureDetector(
                onTap: () { Navigator.pop(context); _goToTransfer(); },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(color: AppTheme.bgSurface, borderRadius: BorderRadius.circular(14)),
                  child: Row(children: [
                    Container(
                      width: 42, height: 42,
                      decoration: BoxDecoration(
                        color: (o['color'] as Color).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(o['icon'] as IconData, color: o['color'] as Color, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: Text(o['label'] as String, style: const TextStyle(color: Colors.white, fontSize: 14))),
                    const Icon(Icons.arrow_forward_ios, color: AppTheme.textSecondary, size: 14),
                  ]),
                ),
              )),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showServiceSheet(String title, IconData titleIcon, List<Map<String, Object>> items) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
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
              Row(children: [
                Icon(titleIcon, color: AppTheme.primary),
                const SizedBox(width: 10),
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1,
                children: items.map((item) => GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${item['label']} — قريباً')));
                  },
                  child: Container(
                    decoration: BoxDecoration(color: AppTheme.bgSurface, borderRadius: BorderRadius.circular(14)),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: (item['color'] as Color).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(item['icon'] as IconData, color: item['color'] as Color, size: 22),
                      ),
                      const SizedBox(height: 8),
                      Text(item['label'] as String,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontSize: 11)),
                    ]),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ── Services Page ─────────────────────────────────────────
  Widget _buildServicesPage() {
    final isAdmin = AppService().currentUser?.phone == 'admin';
    final services = [
      if (isAdmin) {'icon': Icons.people_outline, 'label': 'المستخدمين', 'color': AppTheme.primary, 'action': 'users'},
      if (!isAdmin) {'icon': Icons.receipt_long_outlined, 'label': 'الفواتير', 'color': const Color(0xFFFFC107), 'action': 'bills'},
      if (!isAdmin) {'icon': Icons.payments_outlined, 'label': 'المدفوعات', 'color': const Color(0xFF66BB6A), 'action': 'payments'},
      {'icon': Icons.account_balance_outlined, 'label': 'البنوك', 'color': AppTheme.primary, 'action': 'banks'},
      {'icon': Icons.swap_horiz_rounded, 'label': 'الحوالات', 'color': const Color(0xFF29B6F6), 'action': 'transfers'},
      {'icon': Icons.qr_code_scanner, 'label': 'مسح QR', 'color': const Color(0xFFAB47BC), 'action': 'qr'},
      {'icon': Icons.savings_outlined, 'label': 'ادخار', 'color': const Color(0xFF26C6DA), 'action': 'soon'},
      {'icon': Icons.card_giftcard_outlined, 'label': 'العروض', 'color': const Color(0xFFFF7043), 'action': 'soon'},
      {'icon': Icons.support_agent_outlined, 'label': 'الدعم', 'color': const Color(0xFFFFA726), 'action': 'soon'},
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Text('الخدمات', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: GridView.count(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 1.4,
            children: services.map((s) {
              final color = s['color'] as Color;
              return GestureDetector(
                onTap: () {
                  switch (s['action']) {
                    case 'users': _showUsersScreen(); break;
                    case 'bills': _showBillsSheet(); break;
                    case 'payments': _showPaymentsSheet(); break;
                    case 'banks': _showBanksSheet(); break;
                    case 'transfers': _showTransfersSheet(); break;
                    case 'qr': _goToReceive(); break;
                    default:
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('قريباً...')));
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.bgSurface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: color.withValues(alpha: 0.2)),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 42, height: 42,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(s['icon'] as IconData, color: color, size: 22),
                      ),
                      Text(s['label'] as String,
                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ── Bottom Nav ────────────────────────────────────────────
  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.bgCard,
        border: Border(top: BorderSide(color: Color(0xFF2A2D50), width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          children: [
            _navItem(0, Icons.home_rounded, 'الرئيسية'),
            // Center QR button
            Expanded(
              child: GestureDetector(
                onTap: _goToReceive,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.5),
                        blurRadius: 12,
                      )
                    ],
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(14),
                    child: Icon(Icons.qr_code_scanner,
                        color: Colors.white, size: 26),
                  ),
                ),
              ),
            ),
            _navItem(1, Icons.person_outline_rounded, 'حسابي'),
          ],
        ),
      ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final isSelected = _navIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _navIndex = index),
        child: Container(
          color: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                  size: 24),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  color:
                      isSelected ? AppTheme.primary : AppTheme.textSecondary,
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationsSheet extends StatefulWidget {
  final dynamic user;
  const _NotificationsSheet({required this.user});
  @override
  State<_NotificationsSheet> createState() => _NotificationsSheetState();
}

class _NotificationsSheetState extends State<_NotificationsSheet> {
  List<Map<String, dynamic>>? _dbNotifs;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    AppService().getUserNotifications().then((list) {
      if (mounted) setState(() { _dbNotifs = list; _loading = false; });
    });
  }

  @override
  Widget build(BuildContext context) {
    final received = (widget.user.transactions as List).where((t) => (t as dynamic).type == 'received').toList();
    final allNotifs = <Map<String, dynamic>>[];
    if (_dbNotifs != null) allNotifs.addAll(_dbNotifs!);
    for (final tx in received) {
      allNotifs.add({
        'title': 'استلمت تحويلاً',
        'message': 'استلمت ${(tx as dynamic).amount.toStringAsFixed(2)} ل.س من ${tx.counterPartyName}',
        'isSystem': false,
      });
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (_, ctrl) => Column(children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4,
            decoration: BoxDecoration(color: AppTheme.textSecondary, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              Icon(Icons.notifications_active, color: AppTheme.primary),
              SizedBox(width: 10),
              Text('الإشعارات', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ]),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                : allNotifs.isEmpty
                    ? const Center(child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text('لا توجد إشعارات', style: TextStyle(color: AppTheme.textSecondary))))
                    : ListView.builder(
                        controller: ctrl,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: allNotifs.length,
                        itemBuilder: (_, i) {
                          final n = allNotifs[i];
                          final isSystem = n['isSystem'] != false;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(color: AppTheme.bgSurface, borderRadius: BorderRadius.circular(14)),
                            child: Row(children: [
                              Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(
                                  color: isSystem ? AppTheme.primary.withValues(alpha: 0.15) : AppTheme.success.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(isSystem ? Icons.notifications_outlined : Icons.arrow_downward,
                                  color: isSystem ? AppTheme.primary : AppTheme.success, size: 18),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(n['title'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                Text(n['message'] ?? '', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                              ])),
                            ]),
                          );
                        },
                      ),
          ),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }
}

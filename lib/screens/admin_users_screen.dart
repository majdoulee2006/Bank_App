import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../models/user_model.dart';
import '../services/app_service.dart';
import '../theme/app_theme.dart';

class AdminUsersScreen extends StatefulWidget {
  final String? highlightUserId;
  const AdminUsersScreen({super.key, this.highlightUserId});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> with SingleTickerProviderStateMixin {
  List<UserModel>? _allUsers;
  List<UserModel>? _displayedUsers;
  List<Map<String, dynamic>>? _pendingVerifications;
  bool _isLoading = true;
  bool _isPendingLoading = true;
  bool _badgeCleared = false;
  bool _showFrozenOnly = false;
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 1 && !_tabController.indexIsChanging) {
        setState(() => _badgeCleared = true);
      }
    });
    _loadUsers().then((_) {
      if (widget.highlightUserId != null && mounted) {
        final target = _allUsers?.where((u) => u.id == widget.highlightUserId).firstOrNull;
        if (target != null) _showUserDetailSheet(target);
      }
    });
    _loadPendingVerifications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPendingVerifications() async {
    setState(() => _isPendingLoading = true);
    final list = await AppService().getPendingVerifications();
    if (mounted) setState(() { _pendingVerifications = list; _isPendingLoading = false; });
  }

  Future<void> _handleVerification(String userId, bool approve) async {
    final err = await AppService().approveVerification(userId: userId, approve: approve);
    if (!mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), backgroundColor: AppTheme.error));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(approve ? 'تم توثيق الحساب بنجاح' : 'تم رفض الطلب'),
        backgroundColor: approve ? AppTheme.success : AppTheme.error,
      ));
      _loadPendingVerifications();
    }
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    final list = await AppService().getUsersList();
    if (mounted) {
      setState(() {
        _allUsers = list;
        _applyFilter();
        _isLoading = false;
      });
    }
  }

  void _applyFilter() {
    var list = _allUsers ?? [];
    if (_showFrozenOnly) list = list.where((u) => u.isFrozen).toList();
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase().trim();
      list = list.where((u) =>
        u.fullName.toLowerCase().contains(q) ||
        u.phone.contains(q) ||
        u.accountNumber.contains(q)
      ).toList();
    }
    _displayedUsers = list;
  }

  void _onSearch(String query) {
    setState(() { _searchQuery = query; _applyFilter(); });
  }

  Future<void> _toggleFreeze(UserModel user) async {
    final freeze = !user.isFrozen;
    final err = await AppService().freezeUser(userId: user.id, freeze: freeze);
    if (!mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: AppTheme.error));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(freeze ? 'تم تجميد حساب ${user.fullName}' : 'تم إلغاء تجميد حساب ${user.fullName}'),
        backgroundColor: freeze ? AppTheme.error : AppTheme.success,
      ));
      _loadUsers();
    }
  }

  void _showUserDetailSheet(UserModel user) {
    String formattedDate = 'غير معروف';
    if (user.createdAt != null) {
      try {
        formattedDate = DateFormat('yyyy/MM/dd').format(DateTime.parse(user.createdAt!));
      } catch (_) {}
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) => SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: AppTheme.textSecondary.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(
                        gradient: user.isFrozen
                            ? const LinearGradient(colors: [Color(0xFF7f1d1d), Color(0xFFef4444)])
                            : AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(child: Text(
                        user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                      )),
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Text(user.fullName,
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          if (user.isFrozen) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: AppTheme.error, borderRadius: BorderRadius.circular(8)),
                              child: const Text('مجمّد', style: TextStyle(color: Colors.white, fontSize: 10)),
                            ),
                          ],
                        ]),
                        const SizedBox(height: 4),
                        Text('حساب: ${user.accountNumber} | جوال: ${user.phone}',
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                      ],
                    )),
                  ],
                ),
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(child: _infoCard('الرصيد', '${user.balance.toStringAsFixed(2)} ل.س',
                    Icons.account_balance_wallet_outlined, AppTheme.success)),
                  const SizedBox(width: 12),
                  Expanded(child: _infoCard('تاريخ الإنشاء', formattedDate,
                    Icons.calendar_month_outlined, AppTheme.secondary)),
                ]),
                const SizedBox(height: 16),
                // Freeze button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: user.isFrozen ? AppTheme.success : AppTheme.error,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: Icon(user.isFrozen ? Icons.lock_open : Icons.lock_outline, size: 18),
                    label: Text(user.isFrozen ? 'إلغاء تجميد الحساب' : 'تجميد الحساب',
                        style: const TextStyle(fontSize: 15)),
                    onPressed: () { Navigator.pop(context); _toggleFreeze(user); },
                  ),
                ),
                const SizedBox(height: 20),
                const Text('حركات الحساب',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                user.transactions.isEmpty
                    ? const Center(child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Text('لا توجد حركات', style: TextStyle(color: AppTheme.textSecondary))))
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: user.transactions.length,
                        itemBuilder: (_, i) {
                          final tx = user.transactions[i];
                          final isSent = tx.type == 'sent';
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(color: AppTheme.bgSurface, borderRadius: BorderRadius.circular(14)),
                            child: Row(children: [
                              Container(
                                width: 36, height: 36,
                                decoration: BoxDecoration(
                                  color: isSent ? AppTheme.error.withValues(alpha: 0.1) : AppTheme.success.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(isSent ? Icons.arrow_upward : Icons.arrow_downward,
                                  color: isSent ? AppTheme.error : AppTheme.success, size: 16),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(tx.counterPartyName,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                  Text(DateFormat('yyyy/MM/dd HH:mm').format(tx.date),
                                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                                ],
                              )),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('${isSent ? "−" : "+"} ${tx.amount.toStringAsFixed(2)}',
                                    style: TextStyle(color: isSent ? AppTheme.error : AppTheme.success,
                                      fontWeight: FontWeight.bold, fontSize: 14)),
                                  if (isSent && tx.fee > 0)
                                    Text('عمولة: ${tx.fee.toStringAsFixed(2)}',
                                      style: const TextStyle(color: AppTheme.warning, fontSize: 10)),
                                ],
                              ),
                            ]),
                          );
                        },
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: AppTheme.bgSurface, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
          ]),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildPendingTab() {
    if (_isPendingLoading) return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    if (_pendingVerifications == null || _pendingVerifications!.isEmpty) {
      return const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.verified_user_outlined, color: AppTheme.textSecondary, size: 48),
        SizedBox(height: 12),
        Text('لا توجد طلبات توثيق معلقة', style: TextStyle(color: AppTheme.textSecondary)),
      ]));
    }
    return RefreshIndicator(
      onRefresh: _loadPendingVerifications,
      color: AppTheme.primary,
      backgroundColor: AppTheme.bgCard,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pendingVerifications!.length,
        itemBuilder: (_, i) {
          final req = _pendingVerifications![i];
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(16)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(12)),
                    child: Center(child: Text(
                      (req['fullName'] as String).isNotEmpty ? (req['fullName'] as String)[0].toUpperCase() : '?',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                    )),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(req['fullName'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    Text('هاتف: ${req['phone']}  |  هوية: ${req['nationalId'] ?? '-'}',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  ])),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(children: [
                  if (req['imagePath'] != null)
                    Expanded(child: _imageCard('صورة الهوية', req['imagePath'])),
                  if (req['imagePath'] != null && req['selfiePath'] != null)
                    const SizedBox(width: 10),
                  if (req['selfiePath'] != null)
                    Expanded(child: _imageCard('صورة شخصية', req['selfiePath'])),
                ]),
              ),
              if (req['isVerified'] == true)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.success.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.success.withValues(alpha: 0.4)),
                    ),
                    child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.verified, color: AppTheme.success, size: 18),
                      SizedBox(width: 8),
                      Text('تم التوثيق', style: TextStyle(color: AppTheme.success, fontWeight: FontWeight.bold)),
                    ]),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(children: [
                    Expanded(child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(foregroundColor: AppTheme.error,
                        side: const BorderSide(color: AppTheme.error),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12)),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('رفض'),
                      onPressed: () => _handleVerification(req['id'], false),
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12)),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('قبول'),
                      onPressed: () => _handleVerification(req['id'], true),
                    )),
                  ]),
                ),
            ]),
          );
        },
      ),
    );
  }

  Widget _imageCard(String label, String imagePath) {
    return GestureDetector(
      onTap: () => showDialog(context: context, builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(borderRadius: BorderRadius.circular(16),
          child: Image.network('${_imageBaseUrl()}$imagePath', fit: BoxFit.contain,
            errorBuilder: (_, __, e) => const Icon(Icons.broken_image, color: Colors.white, size: 64))),
      )),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
        const SizedBox(height: 4),
        Container(
          height: 130,
          decoration: BoxDecoration(
            color: AppTheme.bgSurface,
            borderRadius: BorderRadius.circular(10),
            image: DecorationImage(image: NetworkImage('${_imageBaseUrl()}$imagePath'), fit: BoxFit.cover),
          ),
          child: Align(alignment: Alignment.bottomRight,
            child: Container(
              margin: const EdgeInsets.all(6),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(6)),
              child: const Text('تكبير', style: TextStyle(color: Colors.white, fontSize: 9)),
            )),
        ),
      ]),
    );
  }

  String _imageBaseUrl() => 'http://localhost:8080/uploads/identity/';

  @override
  Widget build(BuildContext context) {
    final frozenCount = _allUsers?.where((u) => u.isFrozen).length ?? 0;
    final pendingCount = _pendingVerifications?.length ?? 0;

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        title: const Text('إدارة المستخدمين'),
        backgroundColor: AppTheme.bgCard,
        elevation: 0,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primary,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
          tabs: [
            const Tab(text: 'المستخدمون'),
            Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Text('طلبات التوثيق'),
              if (pendingCount > 0 && !_badgeCleared) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: AppTheme.error, borderRadius: BorderRadius.circular(10)),
                  child: Text('$pendingCount', style: const TextStyle(color: Colors.white, fontSize: 11)),
                ),
              ],
            ])),
          ],
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: TabBarView(
          controller: _tabController,
          children: [
            // Tab 1: Users
            Column(
          children: [
            // Search
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: _searchCtrl,
                onChanged: _onSearch,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'البحث بالاسم أو الهاتف أو رقم الحساب...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white54),
                          onPressed: () { _searchCtrl.clear(); _onSearch(''); })
                      : null,
                ),
              ),
            ),
            // Filter buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  _filterChip('الكل', !_showFrozenOnly, () {
                    setState(() { _showFrozenOnly = false; _applyFilter(); });
                  }),
                  const SizedBox(width: 10),
                  _filterChip(
                    'المجمّدون${frozenCount > 0 ? " ($frozenCount)" : ""}',
                    _showFrozenOnly,
                    () { setState(() { _showFrozenOnly = true; _applyFilter(); }); },
                    activeColor: AppTheme.error,
                  ),
                ],
              ),
            ),
            // List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                  : _displayedUsers == null || _displayedUsers!.isEmpty
                      ? Center(child: Text(
                          _showFrozenOnly ? 'لا توجد حسابات مجمّدة' : 'لا يوجد مستخدمون',
                          style: const TextStyle(color: AppTheme.textSecondary)))
                      : RefreshIndicator(
                          onRefresh: _loadUsers,
                          color: AppTheme.primary,
                          backgroundColor: AppTheme.bgCard,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: _displayedUsers!.length,
                            itemBuilder: (_, i) {
                              final user = _displayedUsers![i];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: AppTheme.bgCard,
                                  borderRadius: BorderRadius.circular(16),
                                  border: user.isFrozen
                                      ? Border.all(color: AppTheme.error.withValues(alpha: 0.6), width: 1.5)
                                      : user.balance >= 200000
                                          ? Border.all(color: AppTheme.warning.withValues(alpha: 0.5), width: 1.5)
                                          : null,
                                ),
                                child: ListTile(
                                  onTap: () => _showUserDetailSheet(user),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                  leading: CircleAvatar(
                                    radius: 22,
                                    backgroundColor: user.isFrozen
                                        ? AppTheme.error.withValues(alpha: 0.2)
                                        : user.balance >= 200000
                                            ? AppTheme.warning.withValues(alpha: 0.2)
                                            : AppTheme.bgSurface,
                                    child: Text(
                                      user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
                                      style: TextStyle(
                                        color: user.isFrozen ? AppTheme.error : user.balance >= 200000 ? AppTheme.warning : Colors.white,
                                        fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                  ),
                                  title: Row(children: [
                                    Expanded(child: Text(user.fullName,
                                      style: TextStyle(
                                        color: user.isFrozen ? AppTheme.error : user.balance >= 200000 ? AppTheme.warning : Colors.white,
                                        fontWeight: FontWeight.bold, fontSize: 15))),
                                    if (user.isFrozen)
                                      const Icon(Icons.lock, color: AppTheme.error, size: 14),
                                    if (!user.isFrozen && user.balance >= 200000)
                                      const Icon(Icons.warning_amber_rounded, color: AppTheme.warning, size: 14),
                                  ]),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text('حساب: ${user.accountNumber} | هاتف: ${user.phone}',
                                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                                  ),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('${user.balance.toStringAsFixed(2)} ل.س',
                                        style: const TextStyle(color: AppTheme.success, fontWeight: FontWeight.bold, fontSize: 13)),
                                      const SizedBox(height: 4),
                                      GestureDetector(
                                        onTap: () => _toggleFreeze(user),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: user.isFrozen
                                                ? AppTheme.success.withValues(alpha: 0.15)
                                                : AppTheme.error.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            user.isFrozen ? 'إلغاء تجميد' : 'تجميد',
                                            style: TextStyle(
                                              color: user.isFrozen ? AppTheme.success : AppTheme.error,
                                              fontSize: 11, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
        // Tab 2: Pending verifications
        _buildPendingTab(),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap, {Color? activeColor}) {
    final color = activeColor ?? AppTheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.15) : AppTheme.bgSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? color : Colors.transparent),
        ),
        child: Text(label, style: TextStyle(
          color: selected ? color : AppTheme.textSecondary,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          fontSize: 13,
        )),
      ),
    );
  }
}

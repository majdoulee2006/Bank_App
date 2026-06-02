import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../services/app_service.dart';
import '../services/api_service.dart';
import '../services/api_config.dart';
import '../theme/app_theme.dart';
import '../screens/login_screen.dart';
import 'admin_users_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _totalUsers = 0;
  int _frozenUsers = 0;
  int _pendingVerifications = 0;
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final users = await AppService().getUsersList();
      final pending = await AppService().getPendingVerifications();
      final notifs = await _loadNotifications();
      if (mounted) {
        setState(() {
          _totalUsers = users?.length ?? 0;
          _frozenUsers = users?.where((u) => u.isFrozen).length ?? 0;
          _pendingVerifications = pending?.length ?? 0;
          _notifications = notifs;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<List<Map<String, dynamic>>> _loadNotifications() async {
    try {
      final res = await ApiService().get(ApiConfig.notifications);
      return (res['notifications'] as List? ?? []).map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {
      return [];
    }
  }

  void _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: AppTheme.bgCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('تسجيل الخروج', style: TextStyle(color: Colors.white)),
          content: const Text('هل تريد تسجيل الخروج؟', style: TextStyle(color: AppTheme.textSecondary)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
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
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadData,
            color: AppTheme.primary,
            backgroundColor: AppTheme.bgCard,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('لوحة التحكم', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                            Text('مرحباً، أدمن', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                          ],
                        ),
                        GestureDetector(
                          onTap: _logout,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: AppTheme.bgSurface, borderRadius: BorderRadius.circular(12)),
                            child: const Icon(Icons.logout, color: AppTheme.error, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Stats row
                  if (_isLoading)
                    const Center(child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(color: AppTheme.primary),
                    ))
                  else ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(child: _statCard('إجمالي المستخدمين', '$_totalUsers', Icons.people_outline, AppTheme.primary)),
                          const SizedBox(width: 12),
                          Expanded(child: _statCard('حسابات مجمّدة', '$_frozenUsers', Icons.lock_outline, AppTheme.error)),
                          const SizedBox(width: 12),
                          Expanded(child: _statCard('طلبات توثيق', '$_pendingVerifications', Icons.verified_user_outlined, AppTheme.warning)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Quick actions
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const AdminUsersScreen()),
                        ).then((_) => _loadData()),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(14)),
                                child: const Icon(Icons.manage_accounts, color: Colors.white, size: 28),
                              ),
                              const SizedBox(width: 16),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('إدارة المستخدمين', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                                    SizedBox(height: 4),
                                    Text('تجميد، توثيق، عرض التحويلات', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_back_ios, color: Colors.white70, size: 16),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Notifications
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          const Icon(Icons.notifications_active_outlined, color: AppTheme.primary, size: 20),
                          const SizedBox(width: 8),
                          const Text('آخر الإشعارات', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                          const Spacer(),
                          GestureDetector(
                            onTap: _loadData,
                            child: const Icon(Icons.refresh, color: AppTheme.textSecondary, size: 18),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _notifications.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 32),
                              child: Text('لا توجد إشعارات', style: TextStyle(color: AppTheme.textSecondary)),
                            ))
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: _notifications.length > 20 ? 20 : _notifications.length,
                            itemBuilder: (_, i) {
                              final n = _notifications[i];
                              final isRead = n['isRead'] == true;
                              DateTime? date;
                              try { date = DateTime.parse(n['date'].toString().replaceFirst(' ', 'T')); } catch (_) {}
                              final relatedUserId = n['relatedUserId']?.toString();
                              return GestureDetector(
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => AdminUsersScreen(highlightUserId: relatedUserId)),
                                ).then((_) => _loadData()),
                                child: Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: isRead ? AppTheme.bgSurface : AppTheme.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(14),
                                  border: isRead ? null : Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 36, height: 36,
                                      decoration: BoxDecoration(
                                        color: AppTheme.primary.withValues(alpha: 0.15),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.notifications_outlined, color: AppTheme.primary, size: 18),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(n['title'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                          const SizedBox(height: 3),
                                          Text(n['message'] ?? '', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                                          if (date != null) ...[
                                            const SizedBox(height: 4),
                                            Text(DateFormat('yyyy/MM/dd HH:mm').format(date),
                                              style: const TextStyle(color: AppTheme.textHint, fontSize: 10)),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ));
                            },
                          ),
                    const SizedBox(height: 20),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
        ],
      ),
    );
  }
}

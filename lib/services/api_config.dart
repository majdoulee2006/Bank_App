import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  static const _ipKey = 'server_ip_v2';
  static const _defaultIp = 'localhost:8080';

  static String _serverIp = _defaultIp;

  static String get serverIp => _serverIp;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _serverIp = prefs.getString(_ipKey) ?? _defaultIp;
  }

  static Future<void> saveServerIp(String ip) async {
    _serverIp = ip;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_ipKey, ip);
  }

  static String get baseUrl {
    if (kIsWeb) return 'http://localhost/bank_api';
    return 'http://$_serverIp/bank_api';
  }

  static String get register           => '$baseUrl/auth/register.php';
  static String get requestRegisterOtp => '$baseUrl/auth/request_register_otp.php';
  static String get login       => '$baseUrl/auth/login.php';
  static String get logout      => '$baseUrl/auth/logout.php';
  static String get profile     => '$baseUrl/user/profile.php';
  static String get userList    => '$baseUrl/user/list.php';
  static String get changePin   => '$baseUrl/user/change_pin.php';
  static String get changePhone => '$baseUrl/user/change_phone.php';
  static String get requestPhoneOtp => '$baseUrl/user/request_phone_otp.php';
  static String get verify      => '$baseUrl/user/verify.php';
  static String get transfer    => '$baseUrl/transfer/send.php';
  static String get payBill     => '$baseUrl/transfer/pay_bill.php';
  static String get freezeUser  => '$baseUrl/admin/freeze_user.php';
  static String get verifyIdentity => '$baseUrl/user/verify_identity.php';
  static String get pendingUsers => '$baseUrl/admin/get_pending_verifications.php';
  static String get frozenUsers  => '$baseUrl/admin/get_frozen_users.php';
  static String get notifications => '$baseUrl/admin/get_notifications.php';
  static String get userNotifications => '$baseUrl/user/get_notifications.php';
  static String get approveVerification => '$baseUrl/admin/verify_user.php';
}

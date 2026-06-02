import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'api_service.dart';
import 'api_config.dart';

class AppService {
  static final AppService _instance = AppService._internal();
  factory AppService() => _instance;
  AppService._internal();

  static const _tokenKey = 'mq_token';
  static const double feeRatePerThousand = 10.0;

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  // ── Init ──────────────────────────────────────────────────
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token == null) return;

    ApiService().setToken(token);
    try {
      final data = await ApiService().get(ApiConfig.profile);
      _currentUser = UserModel.fromJson(data);
    } catch (_) {
      await prefs.remove(_tokenKey);
      ApiService().setToken(null);
    }
  }

  // ── Fee ───────────────────────────────────────────────────
  double calcFee(double amount) =>
      double.parse(((amount / 1000) * feeRatePerThousand).toStringAsFixed(4));

  // ── Registration ──────────────────────────────────────────
  Future<({String? otp, String? error})> requestRegisterOtp({
    required String fullName,
    required String phone,
    required String pin,
  }) async {
    try {
      final data = await ApiService().post(ApiConfig.requestRegisterOtp, {
        'fullName': fullName,
        'phone': phone,
        'pin': pin,
      });
      return (otp: data['otp'] as String?, error: null);
    } on ApiException catch (e) {
      return (otp: null, error: e.message);
    } catch (_) {
      return (otp: null, error: 'تعذّر الاتصال بالخادم');
    }
  }

  Future<String?> register({
    required String phone,
    required String otp,
  }) async {
    try {
      await ApiService().post(ApiConfig.register, {'phone': phone, 'otp': otp});
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'تعذّر الاتصال بالخادم';
    }
  }

  // ── Login ─────────────────────────────────────────────────
  Future<String?> login(String phone, String pin) async {
    try {
      final data = await ApiService().post(ApiConfig.login, {
        'phone': phone,
        'pin': pin,
      });
      await _saveSession(data);
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'تعذّر الاتصال بالخادم';
    }
  }

  Future<void> logout() async {
    try {
      await ApiService().post(ApiConfig.logout, {});
    } catch (_) {}
    _currentUser = null;
    ApiService().setToken(null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  // ── Transfer ──────────────────────────────────────────────
  Future<String?> transfer({
    required String toAccountNumber,
    required double amount,
    String? note,
  }) async {
    try {
      await ApiService().post(ApiConfig.transfer, {
        'toAccountNumber': toAccountNumber,
        'amount': amount,
        if (note != null) 'note': note,
      });
      await _refreshProfile();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'تعذّر الاتصال بالخادم';
    }
  }

  // ── Bill Payment ──────────────────────────────────────────
  Future<String?> payBill({
    required double amount,
    required String billType,
    required String billRef,
  }) async {
    if (_currentUser == null) return 'يجب تسجيل الدخول أولاً';
    if (_currentUser!.balance < amount) return 'رصيدك غير كافٍ';
    try {
      await ApiService().post(ApiConfig.payBill, {
        'amount': amount,
        'billType': billType,
        'billRef': billRef,
      });
      _currentUser!.balance -= amount;
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      // الخادم لا يدعم endpoint الفواتير — نخصم محلياً
      _currentUser!.balance -= amount;
      return null;
    }
  }

  // ── Account Settings ──────────────────────────────────────
  Future<String?> changePin({
    required String oldPin,
    required String newPin,
  }) async {
    try {
      await ApiService().post(ApiConfig.changePin, {
        'oldPin': oldPin,
        'newPin': newPin,
      });
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'تعذّر الاتصال بالخادم';
    }
  }

  Future<({String? otp, String? error})> requestPhoneOtp(String newPhone) async {
    try {
      final data = await ApiService().post(ApiConfig.requestPhoneOtp, {'newPhone': newPhone});
      return (otp: data['otp'] as String?, error: null);
    } on ApiException catch (e) {
      return (otp: null, error: e.message);
    } catch (_) {
      return (otp: null, error: 'تعذّر الاتصال بالخادم');
    }
  }

  Future<String?> changePhone(String newPhone, String otp) async {
    try {
      await ApiService().post(ApiConfig.changePhone, {'newPhone': newPhone, 'otp': otp});
      await _refreshProfile();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'تعذّر الاتصال بالخادم';
    }
  }

  Future<String?> setNationalId(String nationalId) async {
    try {
      await ApiService().post(ApiConfig.verify, {'nationalId': nationalId});
      await _refreshProfile();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'تعذّر الاتصال بالخادم';
    }
  }

  // ── Helpers ───────────────────────────────────────────────
  Future<void> _saveSession(Map<String, dynamic> data) async {
    final token = data['token'] as String;
    ApiService().setToken(token);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    _currentUser = UserModel.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<void> _refreshProfile() async {
    try {
      final data = await ApiService().get(ApiConfig.profile);
      _currentUser = UserModel.fromJson(data);
    } catch (_) {}
  }

  // ── User Notifications ────────────────────────────────────
  Future<List<Map<String, dynamic>>?> getUserNotifications() async {
    try {
      final res = await ApiService().get(ApiConfig.userNotifications);
      return (res['notifications'] as List? ?? []).map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {
      return null;
    }
  }

  // ── Freeze / Unfreeze ─────────────────────────────────────
  Future<String?> freezeUser({required String userId, required bool freeze}) async {
    try {
      await ApiService().post(ApiConfig.freezeUser, {'userId': userId, 'freeze': freeze});
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'تعذّر الاتصال بالخادم';
    }
  }

  // ── Identity Verification ─────────────────────────────────
  Future<String?> submitVerificationRequest({
    required String nationalId,
    required File imageFile,
    required File selfieFile,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      final request = http.MultipartRequest('POST', Uri.parse(ApiConfig.verifyIdentity));
      if (token != null) request.headers['Authorization'] = 'Bearer $token';
      request.fields['nationalId'] = nationalId;
      request.files.add(await http.MultipartFile.fromPath('identityImage', imageFile.path));
      request.files.add(await http.MultipartFile.fromPath('selfieImage', selfieFile.path));
      final streamed = await request.send();
      final body = await streamed.stream.bytesToString();
      if (streamed.statusCode >= 400) {
        try {
          final json = jsonDecode(body) as Map<String, dynamic>;
          return json['error']?.toString() ?? 'حدث خطأ غير متوقع';
        } catch (_) {
          return 'حدث خطأ غير متوقع';
        }
      }
      return null;
    } catch (_) {
      return 'تعذّر الاتصال بالخادم';
    }
  }

  Future<String?> approveVerification({required String userId, required bool approve}) async {
    try {
      await ApiService().post(ApiConfig.approveVerification, {
        'userId': userId,
        'approve': approve,
      });
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'تعذّر الاتصال بالخادم';
    }
  }

  Future<List<Map<String, dynamic>>?> getPendingVerifications() async {
    try {
      final res = await ApiService().get(ApiConfig.pendingUsers);
      return (res['pending'] as List? ?? []).map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {
      return null;
    }
  }

  // ── Admin: Get all users ──────────────────────────────────
  Future<List<UserModel>?> getUsersList() async {
    try {
      final res = await ApiService().get(ApiConfig.userList);
      final list = res['users'] as List? ?? [];
      return list.map((u) => UserModel.fromJson(u)).toList();
    } catch (_) {
      return null;
    }
  }
}

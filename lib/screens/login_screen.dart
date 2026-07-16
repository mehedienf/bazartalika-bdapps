
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const String _baseUrl = "https://bdapps.flicksize.com/krishix/api/";

bool _isSupportedRobiAirtelNumber(String phone) {
  return RegExp(r'^01(?:6|8)\d{8}$').hasMatch(phone);
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;

  Future<bool> _checkAlreadySubscribed(String phone) async {
    try {
      final response = await http
          .post(
            Uri.parse('${_baseUrl}check_subscription.php'),
            body: {'user_mobile': phone},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        return false;
      }

      final decoded = jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        return false;
      }

      final status =
          decoded['subscriptionStatus']?.toString().trim().toUpperCase() ?? '';
      final isSubscribed = status == 'REGISTERED';

      return isSubscribed;
    } catch (e) {
      return false;
    }
  }

  Future<void> _onContinue() async {
    final phone = _phoneController.text.trim();

    if (phone.isEmpty) {
      _showError('মোবাইল নম্বর দিন');
      return;
    }
    if (!_isSupportedRobiAirtelNumber(phone)) {
      _showError('সঠিক Robi/Airtel নম্বর দিন');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Check if already subscribed
      final isSubscribed = await _checkAlreadySubscribed(phone);

      if (isSubscribed) {
        _showSuccess('স্বাগতম! লগইন হচ্ছে...');
        await Future.delayed(const Duration(milliseconds: 800));

        try {
          await _saveAndGoHome(phone);
        } catch (e) {
          if (mounted) {
            _showError('লগইন করতে সমস্যা হয়েছে। আবার চেষ্টা করুন।');
            setState(() => _isLoading = false);
          }
        }
        return;
      }

      // Send OTP request
      final otpResponse = await http
          .post(
            Uri.parse('${_baseUrl}send_otp.php'),
            body: {'user_mobile': phone},
          )
          .timeout(const Duration(seconds: 15));

      final otpData = jsonDecode(otpResponse.body);
      if (otpData is! Map<String, dynamic>) {
        _showError('সার্ভার থেকে ভুল তথ্য এসেছে');
        return;
      }

      final success = otpData['success'] == true;
      final referenceNo = otpData['referenceNo']?.toString().trim() ?? '';
      final message = otpData['message']?.toString() ?? '';
      final statusDetail = otpData['statusDetail']?.toString() ?? '';
      final statusCode = otpData['statusCode']?.toString().trim() ?? '';

      if (success && referenceNo.isNotEmpty) {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                OtpVerifyPage(phone: phone, referenceNo: referenceNo),
          ),
        );
      } else if (statusCode == 'E1351' ||
          message.toLowerCase().contains('already registered')) {
        // User is already registered but check_subscription returned false
        // This can happen due to BDApps server inconsistency
        _showSuccess('ইতিমধ্যে রেজিস্টার করা! লগইন হচ্ছে...');
        await Future.delayed(const Duration(milliseconds: 800));

        try {
          await _saveAndGoHome(phone);
        } catch (e) {
          if (mounted) {
            _showError(
              'লগইন করতে সমস্যা হয়েছে। কিছুক্ষণ পর আবার চেষ্টা করুন।',
            );
            setState(() => _isLoading = false);
          }
        }
      } else {
        final errorMsg = message.isNotEmpty
            ? message
            : (statusDetail.isNotEmpty ? statusDetail : 'OTP পাঠানো যায়নি');
        _showError(errorMsg);
      }
    } catch (e) {
      _showError('নেটওয়ার্ক সমস্যা হয়েছে। আবার চেষ্টা করুন।');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveAndGoHome(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('userPhone', phone);
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Image.asset('assets/app_icon.png', width: 100, height: 100, ),
              const SizedBox(height: 20),
              Text(
                'SmartList',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade500
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              // const Text('Robi/Airtel নম্বর দিন', textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                'Daily charge is 2.78 BDT (including VAT, SD & SC). For Robi and Airtel users only.',
                // '2.78 BDT including (Vat+SC+SD) For Robi and Airtel Users only.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                enabled: !_isLoading,
                decoration: InputDecoration(
                  labelText: 'মোবাইল নম্বর',
                  hintText: '018********',
                  prefixIcon: const Icon(Icons.phone_android_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : FilledButton(
                      onPressed: _onContinue,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('পরবর্তী'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class OtpVerifyPage extends StatefulWidget {
  final String phone;
  final String referenceNo;

  const OtpVerifyPage({
    super.key,
    required this.phone,
    required this.referenceNo,
  });

  @override
  State<OtpVerifyPage> createState() => _OtpVerifyPageState();
}

class _OtpVerifyPageState extends State<OtpVerifyPage> {
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;
  late Timer _timer;
  int _remainingSeconds = 240; // 4 minutes = 240 seconds

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _timer.cancel();
        }
      });
    });
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Color _getTimerColor() {
    if (_remainingSeconds > 120) return Colors.green;
    if (_remainingSeconds > 60) return Colors.orange;
    return Colors.red;
  }

  String _readString(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value != null) {
        final text = value.toString().trim();
        if (text.isNotEmpty) return text;
      }
    }
    return '';
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.isEmpty || otp.length < 4) {
      _showError('OTP সঠিকভাবে দাও');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http
          .post(
            Uri.parse('${_baseUrl}verify_otp.php'),
            body: {
              'Otp': otp,
              'otp': otp,
              'referenceNo': widget.referenceNo,
              'reference_no': widget.referenceNo,
              'user_mobile': widget.phone,
            },
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      if (data is! Map<String, dynamic>) {
        _showError('সার্ভার থেকে ভুল তথ্য এসেছে');
        return;
      }

      final statusCode = _readString(data, [
        'statusCode',
        'StatusCode',
        'status_code',
      ]).toUpperCase();
      final successFlag =
          data['success'] == true ||
          _readString(data, ['status', 'result']).toLowerCase() == 'success';

      if (statusCode == 'S1000' || successFlag) {
        // OTP verified successfully - save credentials immediately
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('userPhone', widget.phone);

        // Wait briefly for subscription sync, then continue to home.
        final subscribed = await _waitForSubscriptionSync();

        if (!mounted) return;
        if (!subscribed) {
          _showWarning('সাবস্ক্রিপশন চলছে। অ্যাপ লোড হচ্ছে...');
          await Future.delayed(const Duration(seconds: 1));
          if (!mounted) return;
        }

        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      } else {
        final message = _readString(data, [
          'message',
          'statusDetail',
          'error',
          'errorMessage',
        ]);
        _showError(message.isNotEmpty ? message : 'OTP ভুল হয়েছে');
      }
    } catch (e) {
      _showError('নেটওয়ার্ক সমস্যা হয়েছে। আবার চেষ্টা করুন।');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Wait for subscription to sync - reduced to 5 checks for faster UX.
  Future<bool> _waitForSubscriptionSync() async {
    for (var i = 0; i < 5; i++) {
      await Future.delayed(const Duration(seconds: 1));

      try {
        final response = await http
            .post(
              Uri.parse('${_baseUrl}check_subscription.php'),
              body: {'user_mobile': widget.phone},
            )
            .timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data is Map<String, dynamic>) {
            final status =
                data['subscriptionStatus']?.toString().trim().toUpperCase() ??
                '';
            // Only accept REGISTERED (means charging succeeded)
            if (status == 'REGISTERED') {
              return true;
            }
          }
        }
      } catch (e) {
        // Continue checking
      }
    }

    return false;
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showWarning(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  void dispose() {
    _otpController.dispose();
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('যাচাই'), centerTitle: true),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                const Icon(
                  Icons.sms_outlined,
                  size: 64,
                  color: Color(0xFF6C63FF),
                ),
                const SizedBox(height: 16),
                Text(
                  'OTP দিন',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '${widget.phone} নম্বরে কোড পাঠানো হয়েছে',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                // const SizedBox(height: 8),
                // Text(
                //   'RefNo: ${widget.referenceNo}',
                //   textAlign: TextAlign.center,
                //   style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                // ),
                const SizedBox(height: 32),
                // Countdown timer display
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _getTimerColor().withValues(alpha: 0.1),
                    border: Border.all(color: _getTimerColor(), width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'OTP এর সময় বাকি',
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatTime(_remainingSeconds),
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: _getTimerColor(),
                        ),
                      ),
                      if (_remainingSeconds <= 60)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            'সময় শেষ হয়ে যাচ্ছে!',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 6,
                  enabled: !_isLoading && _remainingSeconds > 0,
                  style: const TextStyle(fontSize: 28, letterSpacing: 12),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: '******',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _remainingSeconds > 0
                    ? FilledButton(
                        onPressed: _verifyOtp,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('যাচাই করুন'),
                      )
                    : FilledButton.tonalIcon(
                        onPressed: null,
                        icon: const Icon(Icons.schedule_rounded),
                        label: const Text('সময় শেষ হয়েছে'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  child: const Text('ভুল নম্বর? আবার চেষ্টা করুন'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

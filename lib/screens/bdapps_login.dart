import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../services/app_settings.dart';

const String _baseUrl = 'https://www.olivosoft.com/bazartalika';
// const String _baseUrl = 'https://www.flicksize.com/denapaona';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _phoneController = TextEditingController();
  final AppSettings _appSettings = AppSettings();
  bool _isLoading = false;

  Future<void> _onContinue() async {
    final phone = _phoneController.text.trim();

    if (phone.isEmpty) {
      _showError(_appSettings.get('enterrobi_airtel_number'));
      return;
    }
    if (!RegExp(r'^01[3-9]\d{8}$').hasMatch(phone)) {
      _showError(_appSettings.get('enterValidPhoneNumber'));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final otpRes = await http
          .post(
            Uri.parse('$_baseUrl/send_otp.php'),
            body: {'user_mobile': phone},
          )
          .timeout(const Duration(seconds: 15));
      final otpData = jsonDecode(otpRes.body);
      final referenceNo = otpData['referenceNo']?.toString();
      final statusCode = otpData['statusCode']?.toString();
      final statusDetail = otpData['statusDetail']?.toString();

      // E1851 = already subscribed, E1351 = user already registered
      if (statusCode == 'E1851' || statusCode == 'E1351') {
        await _saveAndGoHome(phone);
        return;
      }

      if (referenceNo != null &&
          referenceNo.isNotEmpty &&
          referenceNo != 'null') {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                OtpVerifyPage(phone: phone, referenceNo: referenceNo),
          ),
        );
      } else {
        if (statusCode == 'E1343') {
          _showError(_appSettings.get('notWhitelisted'));
        } else if (statusCode == 'E1853') {
          _showError(_appSettings.get('maxLimitReached'));
        } else if (statusDetail != null && statusDetail.isNotEmpty) {
          _showError('OTP Error: $statusDetail');
        } else {
          _showError(_appSettings.get('otpSendFailed'));
        }
        // print('OTP Fail Response: ${otpRes.body}');
      }
    } on TimeoutException catch (_) {
      _showError(_appSettings.get('timeoutError'));
    } catch (e) {
      _showError(_appSettings.get('networkError'));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveAndGoHome(String phone) async {
    final prefs = await SharedPreferences.getInstance();

    final lastUserPhone = prefs.getString('lastUserPhone');
    if (lastUserPhone != null && lastUserPhone != phone) {
      // If a different user logs in, remove the old user's data from SharedPreferences
      await prefs.remove('persons_$lastUserPhone');
      await prefs.remove('notes_$lastUserPhone');
      await prefs.remove('budgets_$lastUserPhone');
      await prefs.remove('transactions_$lastUserPhone');
      await prefs.remove('lastUserPhone');
    }

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
    return AnimatedBuilder(
      animation: _appSettings,
      builder: (context, _) => Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              // Main content (behind the lang button)
              SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight:
                        MediaQuery.of(context).size.height -
                        MediaQuery.of(context).padding.vertical -
                        48,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 40), // space for the lang button
                      Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.asset(
                            'assets/logo.png',
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // App name
                      Text(
                        _appSettings.get('bazartalika'),
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.color
                                  ?.withValues(alpha: 0.4),
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _appSettings.get('trackExpensesWithEase'),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 100),
                      // Phone input
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        enabled: !_isLoading,
                        decoration: InputDecoration(
                          labelText: _appSettings.get('robi_airtel_number'),
                          hintText: '018XXXXXXXX',
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
                                backgroundColor:
                                    // Theme.of(context).colorScheme.primary,
                                    Colors.blue.shade600,
                                foregroundColor: Theme.of(
                                  context,
                                ).colorScheme.onPrimary,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _appSettings.get('nextButton'),
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                      const SizedBox(height: 24),
                      // Demo button for developer testing (debug builds only)
                      // if (kDebugMode)
                      //   FilledButton(
                      //     onPressed: () async {
                      //       final prefs = await SharedPreferences.getInstance();
                      //       await prefs.setBool('isLoggedIn', true);
                      //       await prefs.setString(
                      //         'userPhone',
                      //         _phoneController.text.trim(),
                      //       );
                      //       if (!context.mounted) return;
                      //       Navigator.pushNamedAndRemoveUntil(
                      //         context,
                      //         '/home',
                      //         (route) => false,
                      //       );
                      //     },
                      //     style: FilledButton.styleFrom(
                      //       backgroundColor: Colors.green.shade600,
                      //       foregroundColor: Theme.of(
                      //         context,
                      //       ).colorScheme.onPrimary,
                      //       padding: const EdgeInsets.symmetric(vertical: 14),
                      //       shape: RoundedRectangleBorder(
                      //         borderRadius: BorderRadius.circular(12),
                      //       ),
                      //     ),
                      //     child: const Text('Demo: Go Home (dev)'),
                      //   ),
                      // const SizedBox(height: 24),
                      // Subtitle note
                      Text(
                        _appSettings.get('robiAirtelSubscribersOnly'),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      // Pricing information
                      Text(
                        _appSettings.get('dailyChargeInfo'),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              // Language toggle — on top, fixed top-right corner
              Positioned(
                top: 4,
                right: 4,
                child: TextButton.icon(
                  onPressed: () async {
                    final newLang = _appSettings.currentLanguage == 'en'
                        ? 'bn'
                        : 'en';
                    await _appSettings.setLanguage(newLang);
                  },
                  icon: const Icon(Icons.language, size: 18),
                  label: Text(
                    _appSettings.currentLanguage == 'en' ? 'বাংলা' : 'English',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
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
  final AppSettings _appSettings = AppSettings();
  bool _isLoading = false;
  late Timer _countdownTimer;
  int _secondsRemaining = 240; // 4 minutes in seconds
  bool _canResendOtp = false;

  @override
  void initState() {
    super.initState();
    _startCountdownTimer();
  }

  void _startCountdownTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _canResendOtp = true;
          _countdownTimer.cancel();
        }
      });
    });
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> _resendOtp() async {
    setState(() => _isLoading = true);
    try {
      final otpRes = await http
          .post(
            Uri.parse('$_baseUrl/send_otp.php'),
            body: {'user_mobile': widget.phone},
          )
          .timeout(const Duration(seconds: 15));
      final otpData = jsonDecode(otpRes.body);
      final referenceNo = otpData['referenceNo']?.toString();

      if (referenceNo != null &&
          referenceNo.isNotEmpty &&
          referenceNo != 'null') {
        // Reset timer
        _countdownTimer.cancel();
        setState(() {
          _secondsRemaining = 240;
          _canResendOtp = false;
        });
        _startCountdownTimer();
        _showSuccess('OTP resent successfully');
      } else {
        _showError('Failed to resend OTP');
      }
    } catch (e) {
      _showError(_appSettings.get('networkErrorCheckConnection'));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _clearSessionForOtpFlow() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    await prefs.remove('userPhone');
  }

  Future<void> _backToLoginAndClearSession() async {
    await _clearSessionForOtpFlow();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.isEmpty || otp.length < 4) {
      _showError(_appSettings.get('enterOtpError'));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/verify_otp.php'),
        body: {'Otp': otp, 'referenceNo': widget.referenceNo},
      );
      final data = jsonDecode(res.body);

      final statusCode = data['statusCode']?.toString();
      final subscriptionStatus =
          data['subscriptionStatus']?.toString().toUpperCase() ?? '';

      final isSuccess =
          statusCode == 'S1000' ||
          subscriptionStatus == 'SUBSCRIBED' ||
          subscriptionStatus == 'REGISTERED' ||
          subscriptionStatus == 'ACTIVATED' ||
          subscriptionStatus == 'PENDING' ||
          subscriptionStatus == 'SUSPENDED' ||
          subscriptionStatus == 'INITIAL CHARGING PENDING';

      if (isSuccess) {
        final prefs = await SharedPreferences.getInstance();

        final lastUserPhone = prefs.getString('lastUserPhone');
        if (lastUserPhone != null && lastUserPhone != widget.phone) {
          // If a different user logs in, remove the old user's data from SharedPreferences
          await prefs.remove('persons_$lastUserPhone');
          await prefs.remove('notes_$lastUserPhone');
          await prefs.remove('budgets_$lastUserPhone');
          await prefs.remove('transactions_$lastUserPhone');
          await prefs.remove('lastUserPhone');
        }

        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('userPhone', widget.phone);
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      } else {
        final statusDetail = data['statusDetail']?.toString();
        if (statusDetail != null && statusDetail.isNotEmpty) {
          _showError('Error: $statusDetail');
        } else {
          _showError(_appSettings.get('invalidOrExpiredOtp'));
        }
        // print('OTP Verify Fail Response: ${res.body}');
      }
    } catch (e) {
      _showError(_appSettings.get('networkErrorCheckConnection'));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _countdownTimer.cancel();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_appSettings.get('verifyOtpAppBarTitle')),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
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
                _appSettings.get('verifyOtpTitle'),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '${widget.phone} ${_appSettings.get('otpSentToNumber')}',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 8),
              Text(
                _appSettings.get('subscriptionOtpPrompt'),
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 6,
                enabled: !_isLoading,
                style: const TextStyle(fontSize: 28, letterSpacing: 12),
                decoration: InputDecoration(
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : FilledButton(
                      onPressed: _verifyOtp,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(_appSettings.get('verifyOtpButton')),
                    ),
              const SizedBox(height: 16),
              // Countdown timer and resend button
              if (!_canResendOtp)
                Center(
                  child: Text(
                    'Resend OTP in ${_formatTime(_secondsRemaining)}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              else
                FilledButton(
                  onPressed: _isLoading ? null : _resendOtp,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.orange.shade600,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Resend OTP'),
                ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _isLoading ? null : _backToLoginAndClearSession,
                child: Text(_appSettings.get('wrongNumberGoBack')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

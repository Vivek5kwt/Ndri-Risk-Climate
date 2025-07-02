import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../send_otp_email.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});
  @override
  _AdminLoginPageState createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  static const String _adminEmail = 'admin@riskclimatendri@gmail.com';
  static String _adminPassword = 'RiskClimateNDri@123';

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _loading = true;

  String? _otpSent;
  String? _resetEmail;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 800), () {
      setState(() => _loading = false);
    });
  }

  void _login() {
    if (_formKey.currentState!.validate()) {
      final email = _emailController.text.trim();
      final pass = _passwordController.text;

      if (email == _adminEmail && pass == _adminPassword) {
        context.go('/adminDashboard');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid email or password'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showForgotPasswordSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => ForgotPasswordSheet(
        onRequestOtp: _handleSendOtp,
        onVerifyOtp: _handleVerifyOtp,
        onChangePassword: _handleChangePassword,
      ),
    );
  }

  void _handleSendOtp(String email, void Function(String otp) onSent, void Function(String error)? onError) {
    if (email != _adminEmail) {
      if (onError != null) onError("No admin account found with this email.");
      return;
    }
    String otp = (Random().nextInt(899999) + 100000).toString();
    setState(() {
      _otpSent = otp;
      _resetEmail = email;
    });
    onSent(otp);
  }

  void _handleVerifyOtp(String email, String enteredOtp, void Function()? onSuccess, void Function(String error)? onError) {
    if (email != _resetEmail || enteredOtp != _otpSent) {
      if (onError != null) onError("Invalid OTP. Please try again.");
      return;
    }
    if (onSuccess != null) onSuccess();
  }

  void _handleChangePassword(String email, String newPassword, void Function()? onSuccess, void Function(String error)? onError) {
    if (email != _adminEmail) {
      if (onError != null) onError("Email not recognized.");
      return;
    }
    setState(() {
      _adminPassword = newPassword;
    });
    if (onSuccess != null) onSuccess();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          AnimatedOpacity(
            duration: const Duration(milliseconds: 350),
            opacity: _loading ? 0.0 : 1.0,
            curve: Curves.easeOut,
            child: AbsorbPointer(
              absorbing: _loading,
              child: SafeArea(
                child: SingleChildScrollView(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 35.0, vertical: 60.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.admin_panel_settings, size: 100, color: Colors.blueAccent),
                          const SizedBox(height: 30),
                          const Text(
                            'Admin Login',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 30),
                          const Text(
                            'Log in to view survey submissions.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16, color: Colors.black54),
                          ),
                          const SizedBox(height: 30),
                          Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                SizedBox(
                                  width: 300,
                                  child: TextFormField(
                                    controller: _emailController,
                                    decoration: InputDecoration(
                                      labelText: 'Email address',
                                      labelStyle: const TextStyle(color: Colors.black54),
                                      hintText: 'Enter admin email',
                                      hintStyle: const TextStyle(color: Colors.black38),
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(color: Colors.blueAccent),
                                      ),
                                      prefixIcon: const Icon(Icons.email, color: Colors.black54),
                                    ),
                                    validator: (value) =>
                                    (value == null || value.isEmpty) ? 'Please enter email' : null,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                SizedBox(
                                  width: 300,
                                  child: TextFormField(
                                    controller: _passwordController,
                                    obscureText: true,
                                    decoration: InputDecoration(
                                      labelText: 'Password',
                                      labelStyle: const TextStyle(color: Colors.black54),
                                      hintText: 'Enter admin password',
                                      hintStyle: const TextStyle(color: Colors.black38),
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(color: Colors.blueAccent),
                                      ),
                                      prefixIcon: const Icon(Icons.lock, color: Colors.black54),
                                    ),
                                    validator: (value) =>
                                    (value == null || value.isEmpty) ? 'Please enter password' : null,
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton(
                                      onPressed: _showForgotPasswordSheet,
                                      child: const Text(
                                        "Forgot Password?",
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          color: Colors.blueAccent,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                SizedBox(
                                  width: 300,
                                  child: ElevatedButton(
                                    onPressed: _login,
                                    style: ElevatedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      backgroundColor: Colors.blueAccent,
                                      padding: const EdgeInsets.symmetric(vertical: 15),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text(
                                      'Sign in',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_loading)
            Positioned.fill(
              child: Container(
                color: Colors.white.withOpacity(0.9),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.blueAccent, strokeWidth: 4),
                      SizedBox(height: 30),
                      Text(
                        "Loading admin login...",
                        style: TextStyle(
                          color: Colors.blueGrey,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ForgotPasswordSheet extends StatefulWidget {
  final void Function(String email, void Function(String otp) onSent, void Function(String error)? onError) onRequestOtp;
  final void Function(String email, String otp, void Function()? onSuccess, void Function(String error)? onError) onVerifyOtp;
  final void Function(String email, String newPassword, void Function()? onSuccess, void Function(String error)? onError) onChangePassword;
  const ForgotPasswordSheet({
    required this.onRequestOtp,
    required this.onVerifyOtp,
    required this.onChangePassword,
    super.key,
  });

  @override
  State<ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends State<ForgotPasswordSheet> {
  int _step = 0;
  String _email = '';
  String _otp = '';

  String? _error;

  final emailCtrl = TextEditingController();
  final otpCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  bool _showPassword = false;
  bool _sending = false;

  void _sendOtp() {
    setState(() => _sending = true);
    widget.onRequestOtp(emailCtrl.text.trim(), (otp) async {
      setState(() {
        _email = emailCtrl.text.trim();
        _otp = otp;
        _step = 1;
        _sending = false;
        _error = null;
      });
      await sendOtpToEmail('arjuns5kwt@gmail.com', '123456');


    }, (error) {
      setState(() {
        _error = error;
        _sending = false;
      });
    });
  }

  void _verifyOtp() {
    setState(() => _sending = true);
    widget.onVerifyOtp(_email, otpCtrl.text.trim(), () {
      setState(() {
        _step = 2;
        _sending = false;
        _error = null;
      });
    }, (error) {
      setState(() {
        _error = error;
        _sending = false;
      });
    });
  }

  void _setNewPassword() {
    if (passCtrl.text.length < 6) {
      setState(() => _error = "Password must be at least 6 characters.");
      return;
    }
    setState(() => _sending = true);
    widget.onChangePassword(_email, passCtrl.text.trim(), () {
      setState(() {
        _step = 3;
        _sending = false;
        _error = null;
      });
    }, (error) {
      setState(() {
        _error = error;
        _sending = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPadding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 24,
        left: 24,
        right: 24,
      ),
      duration: const Duration(milliseconds: 300),
      child: Material(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            child: _sending
                ? const SizedBox(
              height: 220,
              child: Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
            )
                : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.withOpacity(0.23),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                if (_step == 0) ...[
                  const Text(
                    "Forgot Password",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: "Enter your admin email",
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        _error!,
                        style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold),
                      ),
                    ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.send_rounded),
                    label: const Text("Send OTP"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 25),
                    ),
                    onPressed: _sendOtp,
                  ),
                  const SizedBox(height: 16),
                ] else if (_step == 1) ...[
                  const Text(
                    "Enter OTP",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "We have sent an OTP to $_email.\n(For demo: $_otp)",
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 15, color: Colors.black54),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: otpCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Enter OTP",
                      prefixIcon: const Icon(Icons.vpn_key_rounded),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        _error!,
                        style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold),
                      ),
                    ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.verified_rounded),
                    label: const Text("Verify OTP"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 25),
                    ),
                    onPressed: _verifyOtp,
                  ),
                  const SizedBox(height: 10),
                ] else if (_step == 2) ...[
                  const Text(
                    "Set New Password",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: passCtrl,
                    obscureText: !_showPassword,
                    decoration: InputDecoration(
                      labelText: "New Password",
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(_showPassword
                            ? Icons.visibility
                            : Icons.visibility_off),
                        onPressed: () => setState(() => _showPassword = !_showPassword),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        _error!,
                        style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold),
                      ),
                    ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle_rounded),
                    label: const Text("Change Password"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 25),
                    ),
                    onPressed: _setNewPassword,
                  ),
                ] else if (_step == 3) ...[
                  const Icon(Icons.check_circle_rounded, color: Colors.green, size: 60),
                  const SizedBox(height: 16),
                  const Text(
                    "Password Changed!",
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    "Your password has been updated successfully.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 26),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 25),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text("Back to Login"),
                  )
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}

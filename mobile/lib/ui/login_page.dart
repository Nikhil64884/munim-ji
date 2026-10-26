import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import 'shell.dart';
import 'ui_kit.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _phone = TextEditingController();
  final _otp = TextEditingController();
  final _otpFocus = FocusNode();
  bool _sent = false;
  bool _loading = false;
  String? _err;
  int _resendTimer = 0;
  Timer? _timer;
  String? _devOtp; // dev mode mein backend se aata hai

  @override
  void dispose() {
    _timer?.cancel();
    _phone.dispose();
    _otp.dispose();
    _otpFocus.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    _timer?.cancel();
    setState(() => _resendTimer = 30);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        _resendTimer--;
        if (_resendTimer <= 0) t.cancel();
      });
    });
  }

  Future<void> _sendOtp() async {
    final p = _phone.text.trim();
    if (p.length != 10) {
      HapticFeedback.mediumImpact();
      setState(() => _err = '10 digit ka mobile number daalein');
      return;
    }
    setState(() { _loading = true; _err = null; });
    final r = await ApiService.sendOtp(p);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (r['success'] == true) {
        _sent = true;
        _devOtp = (r['data'] as Map?)?['otp']?.toString();
        _startResendTimer();
        // Auto-focus OTP field
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) _otpFocus.requestFocus();
        });
        HapticFeedback.lightImpact();
      } else {
        _err = r['error'].toString();
        HapticFeedback.mediumImpact();
      }
    });
  }

  Future<void> _verify() async {
    final otp = _otp.text.trim();
    if (otp.length < 4) {
      HapticFeedback.mediumImpact();
      setState(() => _err = 'OTP daalein');
      return;
    }
    setState(() { _loading = true; _err = null; });
    final r = await ApiService.verifyOtp(_phone.text.trim(), otp);
    if (!mounted) return;
    if (r['success'] == true) {
      HapticFeedback.mediumImpact();
      Navigator.of(context)
          .pushReplacement(MaterialPageRoute(builder: (_) => const Shell()));
    } else {
      HapticFeedback.heavyImpact();
      setState(() { _loading = false; _err = r['error'].toString(); });
    }
  }

  Future<void> _editServerUrl() async {
    final ctrl = TextEditingController(text: ApiService.baseUrl);
    bool testing = false;
    String? testResult;

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogCtx) => StatefulBuilder(
          builder: (sheetCtx, setDialogState) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.dns_rounded, color: C.green),
                SizedBox(width: 8),
                Text('Backend Server IP', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'FastAPI server ka URL daalein:\n(Jaise http://192.168.0.104:8000 ya http://127.0.0.1:8000)',
                  style: TextStyle(fontSize: 12, color: C.muted),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: ctrl,
                  decoration: InputDecoration(
                    hintText: 'http://192.168.0.104:8000',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                if (testResult != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    testResult!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: testResult!.contains('safal') ? C.green : C.red,
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: C.green, foregroundColor: Colors.white),
                onPressed: testing
                    ? null
                    : () async {
                        final url = ApiService.normalizeUrl(ctrl.text);
                        if (url.isEmpty) {
                          setDialogState(() {
                            testResult = 'URL khaali hai';
                          });
                          return;
                        }
                        setDialogState(() {
                          testing = true;
                          testResult = 'Server se connect ho raha hai...';
                        });
                        final ok = await ApiService.checkHealthAt(url);
                        if (ok) {
                          ApiService.setBaseUrl(url);
                          await StorageService.saveServerUrl(url);
                          if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                          if (!mounted) return;
                          toast(context, 'Server se safal jod liya! 🟢');
                        } else {
                          setDialogState(() {
                            testing = false;
                            testResult = 'Connect nahi ho paya. IP aur Port check karein.';
                          });
                        }
                      },
                child: testing
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Connect & Save'),
              ),
            ],
          ),
        ),
      );
    } finally {
      ctrl.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [C.greenDark, C.green],
          ),
        ),
        child: Column(children: [
          SafeArea(
            bottom: false,
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12, top: 4),
                    child: IconButton(
                      icon: const Icon(Icons.dns_rounded, color: Colors.white70, size: 22),
                      tooltip: 'Server IP Settings',
                      onPressed: _editServerUrl,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
                  child: Center(
                    child: Column(children: [
                      Container(
                        width: 72, height: 72,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.menu_book_rounded, size: 38, color: C.green),
                      ),
                      const SizedBox(height: 14),
                      const Text('Munim Ji AI',
                          style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w700)),
                      const Text('Har dukaan ka smart hisaab',
                          style: TextStyle(color: Color(0xFFBFE3D0), fontSize: 15)),
                    ]),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // Phone field
                  const Text('Mobile number',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: C.muted)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _phone,
                    enabled: !_sent,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      counterText: '',
                      prefixText: '+91  ',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 14),

                  if (!_sent)
                    SizedBox(
                      width: double.infinity,
                      child: PBtn(
                        _loading ? 'Bhej rahe hain...' : 'OTP bhejein',
                        icon: Icons.sms_outlined,
                        kind: BK.gold,
                        onPressed: _loading ? null : _sendOtp,
                      ),
                    ),

                  if (_sent) ...[
                    const Text('OTP daalein',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: C.muted)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _otp,
                      focusNode: _otpFocus,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      textAlign: TextAlign.center,
                      autofocus: true,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onSubmitted: (_) => _verify(),
                      style: const TextStyle(
                          fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: 10),
                      decoration: InputDecoration(
                        counterText: '',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),

                    // Dev OTP hint (auto-shows only in dev mode when backend returns it)
                    if (kDebugMode && _devOtp != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: C.gold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: C.gold, width: 1),
                        ),
                        child: Row(children: [
                          const Icon(Icons.info_outline, size: 16, color: Color(0xFF8A6D1F)),
                          const SizedBox(width: 8),
                          Text('Dev OTP: $_devOtp',
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF8A6D1F))),
                        ]),
                      ),

                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: PBtn(
                        _loading ? 'Check kar rahe hain...' : 'Verify karein',
                        icon: Icons.lock_outline,
                        onPressed: _loading ? null : _verify,
                      ),
                    ),

                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(
                        child: PBtn(
                          _resendTimer > 0
                              ? 'Resend in ${_resendTimer}s'
                              : 'OTP dobara bhejein',
                          kind: BK.ghost,
                          icon: Icons.refresh_rounded,
                          onPressed: (_loading || _resendTimer > 0) ? null : _sendOtp,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: PBtn('Number badlein',
                            kind: BK.ghost,
                            onPressed: () {
                              _timer?.cancel();
                              setState(() {
                                _sent = false;
                                _otp.clear();
                                _err = null;
                                _devOtp = null;
                                _resendTimer = 0;
                              });
                            }),
                      ),
                    ]),
                  ],

                  if (_err != null)
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: C.redBg, borderRadius: BorderRadius.circular(12)),
                      child: Row(children: [
                        const Icon(Icons.error_outline, color: C.red, size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_err!,
                            style: const TextStyle(color: C.red, fontSize: 14))),
                      ]),
                    ),

                  const SizedBox(height: 20),
                  Center(
                    child: Text(
                      'Aage badhne par aap hamari Terms & Privacy accept karte hain',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: C.muted.withValues(alpha: 0.7)),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
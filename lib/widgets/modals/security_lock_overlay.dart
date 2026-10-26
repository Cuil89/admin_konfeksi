import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/app_icons.dart';
import '../../core/theme.dart';
import '../../security/auth_state.dart';

class SecurityLockOverlay extends StatefulWidget {
  const SecurityLockOverlay({
    super.key,
    required this.authState,
    required this.child,
  });

  final AuthState authState;
  final Widget child;

  @override
  State<SecurityLockOverlay> createState() => _SecurityLockOverlayState();
}

class _SecurityLockOverlayState extends State<SecurityLockOverlay> {
  String _pin = '';
  String? _error;
  bool _loading = false;
  Timer? _countdownTimer;
  int _secondsLeft = 0;

  @override
  void initState() {
    super.initState();
    _checkLockout();
  }

  void _checkLockout() {
    if (widget.authState.isLockedOut) {
      _secondsLeft = widget.authState.remainingLockoutSeconds;
      _countdownTimer?.cancel();
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;
        setState(() {
          _secondsLeft = widget.authState.remainingLockoutSeconds;
          if (_secondsLeft <= 0) {
            timer.cancel();
          }
        });
      });
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _onKeyPress(String digit) {
    if (_loading || widget.authState.isLockedOut) return;
    if (_pin.length < 6) {
      setState(() {
        _pin += digit;
        _error = null;
      });
      if (_pin.length == 6) {
        _submitPin();
      }
    }
  }

  void _onBackspace() {
    if (_loading || _pin.isEmpty || widget.authState.isLockedOut) return;
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
      _error = null;
    });
  }

  Future<void> _submitPin() async {
    setState(() => _loading = true);
    final ok = await widget.authState.verifyPin(_pin);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (!ok) {
        _pin = '';
        if (widget.authState.isLockedOut) {
          _error = 'Terlalu banyak percobaan salah. Terkunci sementara.';
          _checkLockout();
        } else {
          _error = 'PIN salah. Sisa percobaan: ${5 - widget.authState.failedAttempts}';
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.authState,
      builder: (context, _) {
        if (!widget.authState.isPinRequired || widget.authState.isUnlocked) {
          return widget.child;
        }

        return Stack(
          children: [
            widget.child,
            // Blur / dark overlay
            Container(
              color: Colors.black.withValues(alpha: 0.75),
              alignment: Alignment.center,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 380),
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x33000000),
                          blurRadius: 24,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Shield Icon
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppColors.emerald50,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.emerald200),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            AppIcons.lock,
                            size: 26,
                            color: AppColors.primary,
                          ),
                        ),

                        const SizedBox(height: 16),
                        const Text(
                          'Sesi Diamankan',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textStrong,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Masukkan 6 digit PIN untuk membuka data payroll.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                        ),

                        const SizedBox(height: 24),

                        // PIN Dots
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(6, (i) {
                            final filled = i < _pin.length;
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 6),
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: filled ? AppColors.primary : AppColors.slate100,
                                border: Border.all(
                                  color: filled ? AppColors.primary : AppColors.borderStrong,
                                  width: 1.5,
                                ),
                              ),
                            );
                          }),
                        ),

                        const SizedBox(height: 16),

                        // Error / Lockout Message
                        if (_secondsLeft > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.rose50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Coba lagi dalam $_secondsLeft detik',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.rose700,
                              ),
                            ),
                          )
                        else if (_error != null)
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.rose700,
                            ),
                          ),

                        const SizedBox(height: 20),

                        // Numeric Keypad
                        _buildKeypad(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildKeypad() {
    return Column(
      children: [
        for (var row = 0; row < 3; row++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (var col = 1; col <= 3; col++)
                  _keyButton('${row * 3 + col}'),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const SizedBox(width: 60, height: 60), // spacer
              _keyButton('0'),
              SizedBox(
                width: 60,
                height: 60,
                child: IconButton(
                  icon: const Icon(Icons.backspace_outlined, size: 22),
                  color: AppColors.text2,
                  onPressed: _onBackspace,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _keyButton(String digit) {
    return SizedBox(
      width: 60,
      height: 60,
      child: Material(
        color: AppColors.slate100,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => _onKeyPress(digit),
          child: Center(
            child: Text(
              digit,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textStrong,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

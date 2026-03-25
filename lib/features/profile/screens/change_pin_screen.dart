import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/auth_service.dart';
import '../../auth/providers/auth_provider.dart';

class ChangePinScreen extends ConsumerStatefulWidget {
  const ChangePinScreen({super.key});

  @override
  ConsumerState<ChangePinScreen> createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends ConsumerState<ChangePinScreen> {
  int _step = 0; // 0: Old PIN, 1: New PIN, 2: Confirm New PIN
  String _oldPin = '';
  String _newPin = '';
  String _confirmPin = '';
  String? _error;
  bool _isLoading = false;

  late List<String> _keys;

  @override
  void initState() {
    super.initState();
    _shuffleKeys();
  }

  void _shuffleKeys() {
    final keys = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    keys.shuffle();
    _keys = keys;
  }

  Future<void> _submitOldPin() async {
    // We assume backend validates the old PIN and optionally creates a token or just validates inline.
    // For a real flow, we could either:
    // a) POST /auth/verify-pin to check old pin
    // b) POST /auth/change-pin with {old_pin, new_pin}
    // We'll proceed to step 1 and send them together at the end.
    setState(() {
      _step = 1;
      _error = null;
      _shuffleKeys();
    });
  }

  Future<void> _submitNewPin() async {
    setState(() {
      _step = 2;
      _error = null;
      _shuffleKeys();
    });
  }

  Future<void> _submitConfirmPin() async {
    if (_newPin != _confirmPin) {
      setState(() {
        _error = 'Les PINs ne correspondent pas';
        _step = 1;
        _newPin = '';
        _confirmPin = '';
        _shuffleKeys();
      });
      return;
    }

    setState(() => _isLoading = true);
    try {
      final authService = ref.read(authServiceProvider);
      final res = await authService.changePin(_oldPin, _newPin);
      
      if (res.statusCode == 200 || res.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN modifié avec succès'), backgroundColor: Colors.green));
          context.pop();
        }
      } else {
        setState(() {
          _error = res.data['message'] ?? 'Erreur lors du changement de PIN';
          _step = 0;
          _oldPin = '';
          _newPin = '';
          _confirmPin = '';
          _shuffleKeys();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Impossible de changer le PIN. Vérifiez votre ancien PIN.';
          _step = 0;
          _oldPin = '';
          _newPin = '';
          _confirmPin = '';
          _shuffleKeys();
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onKeyPress(String key) {
    if (_step == 0) {
      if (_oldPin.length < 4) {
        setState(() => _oldPin += key);
        if (_oldPin.length == 4) _submitOldPin();
      }
    } else if (_step == 1) {
      if (_newPin.length < 4) {
        setState(() => _newPin += key);
        if (_newPin.length == 4) _submitNewPin();
      }
    } else if (_step == 2) {
      if (_confirmPin.length < 4) {
        setState(() => _confirmPin += key);
        if (_confirmPin.length == 4) _submitConfirmPin();
      }
    }
  }

  void _onBackspace() {
    if (_step == 0 && _oldPin.isNotEmpty) {
      setState(() => _oldPin = _oldPin.substring(0, _oldPin.length - 1));
    } else if (_step == 1 && _newPin.isNotEmpty) {
      setState(() => _newPin = _newPin.substring(0, _newPin.length - 1));
    } else if (_step == 2 && _confirmPin.isNotEmpty) {
      setState(() => _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1));
    }
  }

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF1B4332);
    
    String title;
    String currentInput;
    
    if (_step == 0) {
      title = 'Saisissez votre ancien PIN';
      currentInput = _oldPin;
    } else if (_step == 1) {
      title = 'Saisissez votre nouveau PIN';
      currentInput = _newPin;
    } else {
      title = 'Confirmez votre nouveau PIN';
      currentInput = _confirmPin;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Sécurité', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            
            Text(title, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 24),

            // PIN Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final isFilled = index < currentInput.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFilled ? green : Colors.grey.shade300,
                  ),
                );
              }),
            ),

            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 14)),
            ],

            const Spacer(),

            if (_isLoading)
              const CircularProgressIndicator(color: green)
            else
              _buildKeyboard(),

            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyboard() {
    return Column(
      children: [
        for (int row = 0; row < 3; row++)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int col = 0; col < 3; col++)
                _keyButton(_keys[row * 3 + col]),
            ],
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 80), // space instead of action
            _keyButton(_keys[9]),
            _keyButton('⌫', isBackspace: true),
          ],
        ),
      ],
    );
  }

  Widget _keyButton(String key, {bool isBackspace = false}) {
    return GestureDetector(
      onTap: isBackspace ? _onBackspace : () => _onKeyPress(key),
      child: Container(
        width: 80,
        height: 72,
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            key,
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: isBackspace ? Colors.red : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}

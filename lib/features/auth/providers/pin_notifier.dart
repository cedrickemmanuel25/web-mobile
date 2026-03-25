import 'package:flutter_riverpod/flutter_riverpod.dart';

class PinState {
  final String enteredPin;
  final String? confirmedPin;
  final bool isConfirming;
  final int failureCount;
  final bool isLockedOut;
  final String? error;

  PinState({
    this.enteredPin = '',
    this.confirmedPin,
    this.isConfirming = false,
    this.failureCount = 0,
    this.isLockedOut = false,
    this.error,
  });

  PinState copyWith({
    String? enteredPin,
    String? confirmedPin,
    bool? isConfirming,
    int? failureCount,
    bool? isLockedOut,
    String? error,
  }) {
    return PinState(
      enteredPin: enteredPin ?? this.enteredPin,
      confirmedPin: confirmedPin ?? this.confirmedPin,
      isConfirming: isConfirming ?? this.isConfirming,
      failureCount: failureCount ?? this.failureCount,
      isLockedOut: isLockedOut ?? this.isLockedOut,
      error: error,
    );
  }
}

class PinNotifier extends Notifier<PinState> {
  @override
  PinState build() {
    return PinState();
  }

  void addDigit(String digit) {
    if (state.isLockedOut || state.enteredPin.length >= 4) return;

    final newPin = state.enteredPin + digit;
    state = state.copyWith(enteredPin: newPin, error: null);
  }

  void removeDigit() {
    if (state.enteredPin.isEmpty) return;
    state = state.copyWith(
      enteredPin: state.enteredPin.substring(0, state.enteredPin.length - 1),
      error: null,
    );
  }

  void reset() {
    state = PinState(failureCount: state.failureCount, isLockedOut: state.isLockedOut);
  }

  void startConfirmation() {
    state = state.copyWith(
      isConfirming: true,
      confirmedPin: state.enteredPin,
      enteredPin: '',
    );
  }

  void incrementFailure() {
    final newCount = state.failureCount + 1;
    state = state.copyWith(
      failureCount: newCount,
      isLockedOut: newCount >= 5,
      enteredPin: '',
      error: newCount >= 5 ? 'Compte suspendu. Contactez le support.' : 'PIN incorrect',
    );
  }
}

final pinProvider = NotifierProvider<PinNotifier, PinState>(() {
  return PinNotifier();
});

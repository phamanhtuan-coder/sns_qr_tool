part of 'scanner_bloc.dart';

abstract class ScannerState extends Equatable {
  const ScannerState();

  @override
  List<Object?> get props => [];
}

class ScannerInitial extends ScannerState {
  const ScannerInitial();
}

class ScannerSuccess extends ScannerState {
  final Map<String, dynamic> result;
  final bool isApiLoading;
  final bool isBluetoothLoading;
  final String? apiError;
  final String? bluetoothError;

  const ScannerSuccess({
    required this.result,
    this.isApiLoading = false,
    this.isBluetoothLoading = false,
    this.apiError,
    this.bluetoothError,
  });

  @override
  List<Object?> get props => [result, isApiLoading, isBluetoothLoading, apiError, bluetoothError];

  ScannerSuccess copyWith({
    Map<String, dynamic>? result,
    bool? isApiLoading,
    bool? isBluetoothLoading,
    String? apiError,
    String? bluetoothError,
  }) {
    return ScannerSuccess(
      result: result ?? this.result,
      isApiLoading: isApiLoading ?? this.isApiLoading,
      isBluetoothLoading: isBluetoothLoading ?? this.isBluetoothLoading,
      apiError: apiError,
      bluetoothError: bluetoothError,
    );
  }
}

class ScannerFailure extends ScannerState {
  final Map<String, dynamic> error;

  const ScannerFailure({required this.error});

  @override
  List<Object?> get props => [error];
}
part of 'scanner_bloc.dart';

abstract class ScannerEvent extends Equatable {
  const ScannerEvent();

  @override
  List<Object> get props => [];
}

class ScanQR extends ScannerEvent {
  final String purpose;
  final String data;
  final Map<String, dynamic>? error;

  const ScanQR(this.purpose, this.data, {this.error});

  @override
  List<Object> get props => [purpose, data, error ?? {}];
}

class SubmitScan extends ScannerEvent {
  final String serialNumber;
  final String functionId;

  const SubmitScan(this.serialNumber, this.functionId);

  @override
  List<Object> get props => [serialNumber, functionId];
}

class RetryScan extends ScannerEvent {
  const RetryScan();

  @override
  List<Object> get props => [];
}

class ResetScanner extends ScannerEvent {}


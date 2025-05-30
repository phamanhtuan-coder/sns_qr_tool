part of 'scanner_bloc.dart';

abstract class ScannerEvent extends Equatable {
  const ScannerEvent();

  @override
  List<Object> get props => [];
}

class ScanQR extends ScannerEvent {
  final String purpose;
  final String data;

  const ScanQR(this.purpose, this.data);

  @override
  List<Object> get props => [purpose, data];
}

class ResetScanner extends ScannerEvent {}
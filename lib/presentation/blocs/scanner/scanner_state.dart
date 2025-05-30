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

  const ScannerSuccess({required this.result});

  @override
  List<Object?> get props => [result];
}

class ScannerFailure extends ScannerState {
  final Map<String, dynamic> error;

  const ScannerFailure({required this.error});

  @override
  List<Object?> get props => [error];
}
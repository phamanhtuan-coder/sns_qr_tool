part of 'dashboard_bloc.dart';

class DashboardState extends Equatable {
  final String? selectedFunction;
  final String? previousFunction;

  const DashboardState({
    this.selectedFunction,
    this.previousFunction,
  });

  DashboardState copyWith({
    String? selectedFunction,
    String? previousFunction,
  }) {
    return DashboardState(
      selectedFunction: selectedFunction ?? this.selectedFunction,
      previousFunction: previousFunction ?? this.previousFunction,
    );
  }

  @override
  List<Object?> get props => [selectedFunction, previousFunction];
}

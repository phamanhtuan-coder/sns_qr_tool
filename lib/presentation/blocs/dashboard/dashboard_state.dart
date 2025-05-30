part of 'dashboard_bloc.dart';

class DashboardState extends Equatable {
  final String? selectedFunction;

  const DashboardState({this.selectedFunction});

  DashboardState copyWith({String? selectedFunction}) {
    return DashboardState(
      selectedFunction: selectedFunction ?? this.selectedFunction,
    );
  }

  @override
  List<Object?> get props => [selectedFunction];
}
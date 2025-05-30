part of 'dashboard_bloc.dart';

abstract class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object> get props => [];
}

class SelectFunction extends DashboardEvent {
  final String functionId;

  const SelectFunction(this.functionId);

  @override
  List<Object> get props => [functionId];
}
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:smart_net_qr_scanner/utils/logger.dart';

part 'dashboard_event.dart';
part 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc() : super(const DashboardState()) {
    on<SelectFunction>((event, emit) {
      try {
        emit(state.copyWith(selectedFunction: event.functionId.isEmpty ? null : event.functionId));
      } catch (e, stackTrace) {
        logError('Lỗi xử lý sự kiện SelectFunction', e, stackTrace);
      }
    });
  }
}
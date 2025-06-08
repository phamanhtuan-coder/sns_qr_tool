import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:smart_net_qr_scanner/utils/logger.dart';

part 'dashboard_event.dart';
part 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc() : super(const DashboardState()) {
    on<SelectFunction>((event, emit) {
      try {
        // If selecting empty string (resetting), just clear the selection
        if (event.functionId.isEmpty) {
          emit(DashboardState(
            previousFunction: state.selectedFunction,
            selectedFunction: '',
          ));
          return;
        }

        // If selecting the same function that was just used (in previousFunction)
        // allow it to be selected again
        if (event.functionId == state.previousFunction) {
          emit(DashboardState(
            selectedFunction: event.functionId,
            previousFunction: null,
          ));
          return;
        }

        // Normal selection of a new function
        emit(DashboardState(
          selectedFunction: event.functionId,
          previousFunction: null,
        ));
      } catch (e, stackTrace) {
        logError('Lỗi xử lý sự kiện SelectFunction', e, stackTrace);
      }
    });
  }
}
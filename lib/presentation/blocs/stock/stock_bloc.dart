import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'dart:convert';
import 'package:smart_net_qr_scanner/data/models/device.dart';
import 'package:smart_net_qr_scanner/data/models/stock_order.dart';
import 'package:smart_net_qr_scanner/data/models/import_order.dart';
import 'package:smart_net_qr_scanner/data/models/import_order_detail.dart';
import 'package:smart_net_qr_scanner/data/models/import_order_process.dart';
import 'package:smart_net_qr_scanner/data/models/export_order.dart';
import 'package:smart_net_qr_scanner/data/services/import_warehouse_service.dart';
import 'package:smart_net_qr_scanner/data/services/export_warehouse_service.dart';
import 'package:smart_net_qr_scanner/presentation/blocs/stock/stock_state.dart';
import 'package:smart_net_qr_scanner/utils/logger.dart';

import '../../../data/models/enhanced_export_item.dart';
import '../../../utils/app_colors.dart';

part 'stock_event.dart';

class StockBloc extends Bloc<StockEvent, StockState> {
  final ImportWarehouseService _importWarehouseService;
  final ExportWarehouseService _exportWarehouseService;

  StockBloc(this._importWarehouseService, this._exportWarehouseService) : super(const StockInitial()) {
    on<LoadImportOrders>(_onLoadImportOrders);
    on<LoadExportOrders>(_onLoadExportOrders);
    on<SelectImportOrder>(_onSelectImportOrder);
    on<StartImportOrder>(_onStartImportOrder);
    on<StartExportOrder>(_onStartExportOrder);
    on<LoadImportProgress>(_onLoadImportProgress);
    on<LoadExportProgress>(_onLoadExportProgress);
    on<ProcessImportItem>(_onProcessImportItem);
    on<ProcessExportItem>(_onProcessExportItem);
    on<RefreshDeviceList>(_onRefreshDeviceList);
    on<ResetStock>(_onResetStock);
  }

  Future<void> _onLoadImportOrders(
      LoadImportOrders event,
      Emitter<StockState> emit,
      ) async {
    try {
      emit(const StockLoading());

      final result = await _importWarehouseService.getImportWarehouseNotFinish();

      if (result['success'] == true) {
        final List<dynamic> ordersData = result['data'] ?? [];
        final importOrders = ordersData.map((data) => ImportOrder.fromJson(data)).toList();
        emit(StockImportLoaded(importOrders: importOrders));
      } else {
        emit(StockError(result['message'] ?? 'Không thể tải danh sách đơn nhập'));
      }
    } catch (e, stackTrace) {
      logError('Error loading import orders', e, stackTrace);
      emit(StockError('Lỗi tải danh sách đơn nhập: ${e.toString()}'));
    }
  }

  Future<void> _onSelectImportOrder(
      SelectImportOrder event,
      Emitter<StockState> emit,
      ) async {
    try {
      emit(const StockLoading());

      // Get order status and progress
      final result = await _importWarehouseService.getOrderStatusAndProgress(event.importId);

      if (result['success'] == true) {
        final data = result['data'];
        final orderStatus = data['order_status'] ?? 0;
        final progressData = data['progress'] ?? [];

        if (orderStatus == 0) {
          // Order not started - show start confirmation
          emit(StockImportOrderNotStarted(
            importId: event.importId,
            orderDetails: data['order_details'] ?? {},
          ));
        } else {
          // Order already started - go directly to progress view
          final items = (progressData as List)
              .map((item) => ImportOrderProcess.fromJson(item))
              .toList();

          emit(StockImportInProgress(
            orderId: event.importId,
            items: items,
          ));
        }
      } else {
        emit(StockError(result['message'] ?? 'Không thể tải thông tin đơn nhập'));
      }
    } catch (e, stackTrace) {
      logError('Error selecting import order', e, stackTrace);
      emit(StockError('Lỗi chọn đơn nhập: ${e.toString()}'));
    }
  }

  Future<void> _onStartImportOrder(
      StartImportOrder event,
      Emitter<StockState> emit,
      ) async {
    try {
      emit(const StockLoading());

      // Start the import order
      final startResult = await _importWarehouseService.startImportOrder(event.importId);

      if (startResult['success'] == true) {
        // After starting, get the progress
        final progressResult = await _importWarehouseService.getImportProgress(event.importId);

        if (progressResult['success'] == true) {
          final List<dynamic> responseData = progressResult['data'] is List
              ? progressResult['data']
              : progressResult['data']?['data'] is List
              ? progressResult['data']['data']
              : [];

          final items = responseData.map((item) => ImportOrderProcess.fromJson(item)).toList();

          emit(StockImportInProgress(
            orderId: event.importId,
            items: items,
          ));
        } else {
          emit(StockError('Không thể tải tiến độ sau khi bắt đầu'));
        }
      } else {
        emit(StockError(startResult['message'] ?? 'Không thể bắt đầu đơn nhập'));
      }
    } catch (e, stackTrace) {
      logError('Error starting import order', e, stackTrace);
      emit(StockError('Lỗi bắt đầu đơn nhập: ${e.toString()}'));
    }
  }

  Future<void> _onLoadImportProgress(
      LoadImportProgress event,
      Emitter<StockState> emit,
      ) async {
    try {
      final result = await _importWarehouseService.getImportProgress(event.importId);

      if (result['success'] == true) {
        final List<dynamic> responseData = result['data'] is List
            ? result['data']
            : result['data']?['data'] is List
            ? result['data']['data']
            : [];

        final items = responseData.map((item) => ImportOrderProcess.fromJson(item)).toList();

        emit(StockImportInProgress(
          orderId: event.importId,
          items: items,
        ));
      } else {
        emit(StockError(result['message'] ?? 'Không thể tải tiến độ nhập'));
      }
    } catch (e, stackTrace) {
      logError('Error loading import progress', e, stackTrace);
      emit(StockError('Lỗi tải tiến độ nhập: ${e.toString()}'));
    }
  }

  Future<void> _onProcessImportItem(
      ProcessImportItem event,
      Emitter<StockState> emit,
      ) async {
    try {
      final result = await _importWarehouseService.importOrderItem(
        importId: event.importId,
        serialNumber: event.serialNumber,
        batchProductionId: event.batchProductionId ?? '',
        templateId: event.templateId ?? '',
      );

      if (result['success'] == true) {
        emit(StockItemProcessed(
          orderId: event.importId,
          serialNumber: event.serialNumber,
          itemData: result['data'] ?? {},
          progress: result['process'] ?? {},
        ));

        // Reload progress after processing item
        add(LoadImportProgress(event.importId));
      } else {
        emit(StockError(result['message'] ?? 'Không thể xử lý thiết bị'));
      }
    } catch (e, stackTrace) {
      logError('Error processing import item', e, stackTrace);
      emit(StockError('Lỗi xử lý thiết bị: ${e.toString()}'));
    }
  }

  Future<void> _onLoadExportOrders(
      LoadExportOrders event,
      Emitter<StockState> emit,
      ) async {
    try {
      emit(const StockLoading());
      // TODO: Implement export orders loading
      emit(const StockExportLoaded(exportOrders: []));
    } catch (e, stackTrace) {
      logError('Error loading export orders', e, stackTrace);
      emit(StockError('Lỗi tải danh sách đơn xuất: ${e.toString()}'));
    }
  }

  Future<void> _onStartExportOrder(
      StartExportOrder event,
      Emitter<StockState> emit,
      ) async {
    try {
      emit(const StockLoading());

      final result = await _exportWarehouseService.startExportOrder(event.exportId);

      if (result['success'] == true) {
        emit(StockExportOrderStarted(
          exportId: event.exportId,
          orderDetails: result['data'] ?? {},
        ));

        add(LoadExportProgress(event.exportId));
      } else {
        emit(StockError(result['message'] ?? 'Không thể bắt đầu đơn xuất'));
      }
    } catch (e, stackTrace) {
      logError('Error starting export order', e, stackTrace);
      emit(StockError('Lỗi bắt đầu đơn xuất: ${e.toString()}'));
    }
  }

  Future<void> _onLoadExportProgress(
      LoadExportProgress event,
      Emitter<StockState> emit,
      ) async {
    try {
      final result = await _exportWarehouseService.getExportProgress(event.exportId);

      if (result['success'] == true) {
        final data = result['data'];
        final scannedCount = data['scanned_count'] ?? 0;
        final totalCount = data['total_count'] ?? 0;
        final canComplete = data['can_complete'] ?? false;

        emit(StockProgressLoaded(
          orderId: event.exportId,
          progressData: data,
          scannedCount: scannedCount,
          totalCount: totalCount,
          canComplete: canComplete,
        ));
      } else {
        emit(StockError(result['message'] ?? 'Không thể tải tiến độ xuất'));
      }
    } catch (e, stackTrace) {
      logError('Error loading export progress', e, stackTrace);
      emit(StockError('Lỗi tải tiến độ xuất: ${e.toString()}'));
    }
  }

  Future<void> _onProcessExportItem(
      ProcessExportItem event,
      Emitter<StockState> emit,
      ) async {
    try {
      final result = await _exportWarehouseService.processExportItem(
        exportId: event.exportId,
        serialNumber: event.serialNumber,
        batchProductionId: event.batchProductionId,
        templateId: event.templateId,
      );

      if (result['success'] == true) {
        emit(StockItemProcessed(
          orderId: event.exportId,
          serialNumber: event.serialNumber,
          itemData: result['data'] ?? {},
          progress: result['data']?['progress'] ?? {},
        ));

        add(LoadExportProgress(event.exportId));
      } else {
        emit(StockError(result['message'] ?? 'Không thể xử lý thiết bị'));
      }
    } catch (e, stackTrace) {
      logError('Error processing export item', e, stackTrace);
      emit(StockError('Lỗi xử lý thiết bị: ${e.toString()}'));
    }
  }

  Future<void> _onRefreshDeviceList(
      RefreshDeviceList event,
      Emitter<StockState> emit,
      ) async {
    try {
      emit(const StockLoading());
      if (state is StockImportInProgress) {
        final currentState = state as StockImportInProgress;
        await _onLoadImportProgress(LoadImportProgress(currentState.orderId), emit);
      } else if (state is StockExportOrderStarted) {
        final currentState = state as StockExportOrderStarted;
        await _onLoadExportProgress(LoadExportProgress(currentState.exportId), emit);
      }
    } catch (e) {
      emit(StockError('Không thể làm mới danh sách thiết bị: ${e.toString()}'));
    }
  }

  Future<void> _onResetStock(
      ResetStock event,
      Emitter<StockState> emit,
      ) async {
    emit(const StockInitial());
  }
}
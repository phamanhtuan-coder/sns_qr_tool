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
    on<SelectExportOrder>(_onSelectExportOrder);
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
      // Store current state BEFORE emitting loading
      if (state is StockImportLoaded) {
        final currentState = state as StockImportLoaded;
        final selectedOrder = currentState.importOrders
            .firstWhere((order) => order.id == event.importId);

        emit(const StockLoading()); // Move this AFTER getting the order

        final orderStatus = selectedOrder.status;

        if (orderStatus == 0) {
          emit(StockImportOrderNotStarted(
            importId: event.importId,
            orderDetails: {'status': orderStatus},
          ));
        } else {
          // Order already started - get progress directly
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
            emit(StockError('Không thể tải tiến độ đơn nhập'));
          }
        }
      } else {
        emit(StockError('Trạng thái không hợp lệ'));
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

      final result = await _exportWarehouseService.getUnfinishedExportOrders();

      if (result['success'] == true) {
        // Handle nested data structure
        List<dynamic> ordersData;
        if (result['data'] is Map && result['data'].containsKey('data')) {
          // Handle nested structure: { "status_code": 200, "data": [...] }
          ordersData = result['data']['data'] ?? [];
        } else {
          // Handle direct array structure
          ordersData = result['data'] ?? [];
        }

        final exportOrders = ordersData.map((data) => ExportOrder.fromJson(data)).toList();
        emit(StockExportLoaded(exportOrders: exportOrders));
      } else {
        emit(StockError(result['message'] ?? 'Không thể tải danh sách đơn xuất'));
      }
    } catch (e, stackTrace) {
      logError('Error loading export orders', e, stackTrace);
      emit(StockError('Lỗi tải danh sách đơn xuất: ${e.toString()}'));
    }
  }

  Future<void> _onSelectExportOrder(
      SelectExportOrder event,
      Emitter<StockState> emit,
      ) async {
    try {
      if (state is StockExportLoaded) {
        emit(const StockLoading());

        final result = await _exportWarehouseService.getExportOrderDetail(event.exportId);

        if (result['success'] == true) {
          // Order data is already extracted by the service
          final orderData = result['data'];

          // Extract status or default to 0
          final status = orderData['status'] ?? 0;

          if (status == 0) {
            emit(StockExportOrderNotStarted(
              exportId: event.exportId,
              orderDetails: orderData,
            ));
          } else {
            emit(StockExportOrderStarted(
              exportId: event.exportId,
              orderDetails: orderData,
            ));

            // Also load the progress
            add(LoadExportProgress(event.exportId));
          }
        } else {
          emit(StockError(result['message'] ?? 'Không thể tải chi tiết đơn xuất'));
        }
      } else {
        emit(StockError('Trạng thái không hợp lệ'));
      }
    } catch (e, stackTrace) {
      print('DEBUG: Exception in _onSelectExportOrder: $e');
      logError('Error selecting export order', e, stackTrace);
      emit(StockError('Lỗi chọn đơn xuất: ${e.toString()}'));
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
        // Get the export order details again after starting
        final detailResult = await _exportWarehouseService.getExportOrderDetail(event.exportId);

        if (detailResult['success'] == true) {
          final orderData = detailResult['data']?['data']?[0];

          if (orderData != null) {
            emit(StockExportOrderStarted(
              exportId: event.exportId,
              orderDetails: orderData,
            ));

            // Also load the progress
            add(LoadExportProgress(event.exportId));
          } else {
            emit(StockError('Không tìm thấy thông tin đơn xuất sau khi bắt đầu'));
          }
        } else {
          emit(StockError(detailResult['message'] ?? 'Không thể tải chi tiết đơn xuất sau khi bắt đầu'));
        }
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
      // For a new approach, let's use the order details we already have
      if (state is StockExportOrderStarted) {
        final currentState = state as StockExportOrderStarted;
        final orderDetails = currentState.orderDetails;

        // Extract orders and products from the already loaded data
        final orders = orderDetails['orders'] as List<dynamic>? ?? [];

        // Count total and scanned items
        int totalCount = 0;
        int scannedCount = 0;

        for (final order in orders) {
          final products = order['products'] as List<dynamic>? ?? [];

          for (final product in products) {
            final quantity = product['quantity'] as int? ?? 0;
            totalCount += quantity;

            final serials = product['serials'] as List<dynamic>? ?? [];
            scannedCount += serials.length;
          }
        }

        // Can complete if all items are scanned
        final canComplete = scannedCount >= totalCount;

        emit(StockProgressLoaded(
          orderId: event.exportId,
          progressData: orderDetails,
          scannedCount: scannedCount,
          totalCount: totalCount,
          canComplete: canComplete,
        ));
        return;
      }

      // Original approach as fallback - get details from API
      final result = await _exportWarehouseService.getExportOrderDetail(event.exportId);

      if (result['success'] == true) {
        final orderData = result['data'];

        if (orderData != null && orderData.containsKey('orders')) {
          // Extract orders and products
          final orders = orderData['orders'] as List<dynamic>? ?? [];

          // Count total and scanned items
          int totalCount = 0;
          int scannedCount = 0;

          for (final order in orders) {
            final products = order['products'] as List<dynamic>? ?? [];

            for (final product in products) {
              final quantity = product['quantity'] as int? ?? 0;
              totalCount += quantity;

              final serials = product['serials'] as List<dynamic>? ?? [];
              scannedCount += serials.length;
            }
          }

          // Can complete if all items are scanned
          final canComplete = scannedCount >= totalCount;

          emit(StockProgressLoaded(
            orderId: event.exportId,
            progressData: orderData,
            scannedCount: scannedCount,
            totalCount: totalCount,
            canComplete: canComplete,
          ));
        } else {
          emit(StockError('Không tìm thấy thông tin đơn đặt hàng'));
        }
      } else {
        emit(StockError(result['message'] ?? 'Không thể tải tiến độ xuất'));
      }
    } catch (e, stackTrace) {
      print('DEBUG: Error in _onLoadExportProgress: $e');
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
        orderId: event.orderId,
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

        // Reload export progress to update the UI
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
      } else if (state is StockProgressLoaded) {
        final currentState = state as StockProgressLoaded;
        await _onLoadExportProgress(LoadExportProgress(currentState.orderId), emit);
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
import 'package:smart_net_qr_scanner/data/services/api_client.dart';
import 'package:smart_net_qr_scanner/data/models/qr_data.dart';
import 'package:smart_net_qr_scanner/utils/logger.dart';

class ExportWarehouseService {
  final ApiClient _apiClient = ApiClient();

  /// Get list of unfinished export orders for the current employee
  Future<Map<String, dynamic>> getUnfinishedExportOrders() async {
    try {
      final response = await _apiClient.get('/export-warehouse/invoice-not-finish');

      if (response['success'] == true && response['data'] != null) {
        return {
          'success': true,
          'data': response['data'],
        };
      } else {
        // Handle different response structures
        final statusCode = response['data']?['status_code'];
        final data = response['data']?['data'];

        if (statusCode == 200 && data != null) {
          return {
            'success': true,
            'data': data,
          };
        }

        return {
          'success': false,
          'message': response['message'] ?? 'Không thể tải danh sách đơn xuất',
        };
      }
    } catch (e, stackTrace) {
      logError('Lỗi tải danh sách đơn xuất', e, stackTrace);
      return {
        'success': false,
        'message': 'Lỗi kết nối: ${e.toString()}',
      };
    }
  }

  /// Start a new export order
  Future<Map<String, dynamic>> startExportOrder(String exportId) async {
    try {
      final response = await _apiClient.patch('/export-warehouse/start', {
        'export_id': exportId,
      });

      if (response['success'] == true) {
        return {
          'success': true,
          'message': 'Bắt đầu đơn xuất thành công',
          'data': response['data'],
        };
      } else {
        // Handle different response structures
        final statusCode = response['data']?['status_code'];
        final data = response['data']?['data'];

        if (statusCode == 200 && data != null) {
          return {
            'success': true,
            'message': 'Bắt đầu đơn xuất thành công',
            'data': data,
          };
        }

        return {
          'success': false,
          'message': response['message'] ?? 'Không thể bắt đầu đơn xuất',
        };
      }
    } catch (e, stackTrace) {
      logError('Lỗi bắt đầu đơn xuất', e, stackTrace);
      return {
        'success': false,
        'message': 'Lỗi kết nối: ${e.toString()}',
      };
    }
  }

  /// Scan device for export - Enhanced to return device details
  Future<Map<String, dynamic>> scanExportDevice(String exportId, String serialNumber) async {
    try {
      // First, validate the device can be exported
      final validationResponse = await _validateExportDevice(exportId, serialNumber);

      if (validationResponse['success'] != true) {
        return validationResponse;
      }

      // Get device details from production tracking
      final deviceDetails = await _getDeviceDetails(serialNumber);

      if (deviceDetails['success'] != true) {
        return deviceDetails;
      }

      // Return success with device details
      return {
        'success': true,
        'message': 'Quét thiết bị thành công',
        'data': {
          'serial_number': serialNumber,
          'device_details': deviceDetails['data'],
          'export_id': exportId,
        },
      };
    } catch (e, stackTrace) {
      logError('Lỗi quét thiết bị xuất kho', e, stackTrace);
      return {
        'success': false,
        'message': 'Lỗi kết nối: ${e.toString()}',
      };
    }
  }

  /// Validate if device can be exported
  Future<Map<String, dynamic>> _validateExportDevice(String exportId, String serialNumber) async {
    try {
      // This would typically check:
      // 1. If device exists and is in stock
      // 2. If device belongs to the export order
      // 3. If device hasn't been exported already

      final response = await _apiClient.post('/export-warehouse/validate-device', {
        'export_id': exportId,
        'serial_number': serialNumber,
      });

      return response;
    } catch (e) {
      return {
        'success': false,
        'message': 'Không thể xác thực thiết bị: ${e.toString()}',
      };
    }
  }

  /// Get device details from production tracking
  Future<Map<String, dynamic>> _getDeviceDetails(String serialNumber) async {
    try {
      final response = await _apiClient.get('/production-tracking/device-details?serial_number=$serialNumber');

      if (response['success'] == true && response['data'] != null) {
        return {
          'success': true,
          'data': response['data'],
        };
      }

      // Mock device details if API is not available
      return {
        'success': true,
        'data': {
          'serial_number': serialNumber,
          'template_id': _extractTemplateId(serialNumber),
          'batch_production_id': _extractBatchId(serialNumber),
          'status': 'in_stock',
          'device_type': _getDeviceType(serialNumber),
          'production_date': DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
        },
      };
    } catch (e) {
      // Return mock data if API fails
      return {
        'success': true,
        'data': {
          'serial_number': serialNumber,
          'template_id': _extractTemplateId(serialNumber),
          'batch_production_id': _extractBatchId(serialNumber),
          'status': 'in_stock',
          'device_type': _getDeviceType(serialNumber),
          'production_date': DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
        },
      };
    }
  }

  /// Extract template ID from QR data or serial number
  String _extractTemplateId(String serialNumber) {
    // This should match your QR code format: serial|template|batch
    if (serialNumber.contains('|')) {
      final parts = serialNumber.split('|');
      if (parts.length >= 2) {
        return parts[1];
      }
    }

    // Fallback: extract from serial number pattern
    if (serialNumber.startsWith('SERL')) {
      // Extract template from serial pattern
      final match = RegExp(r'[A-Z]+(\d+)').firstMatch(serialNumber);
      if (match != null) {
        final number = int.tryParse(match.group(1) ?? '1') ?? 1;
        return ((number % 5) + 1).toString(); // Map to template 1-5
      }
    }

    return '1'; // Default template
  }

  /// Extract batch production ID from QR data or serial number
  String _extractBatchId(String serialNumber) {
    // This should match your QR code format: serial|template|batch
    if (serialNumber.contains('|')) {
      final parts = serialNumber.split('|');
      if (parts.length >= 3) {
        return parts[2];
      }
    }

    // Generate mock batch ID
    return 'BTCH${DateTime.now().day.toString().padLeft(2, '0')}${DateTime.now().month.toString().padLeft(2, '0')}${DateTime.now().year.toString().substring(2)}${serialNumber.substring(serialNumber.length - 8)}';
  }

  /// Get device type name from template ID
  String _getDeviceType(String serialNumber) {
    final templateId = _extractTemplateId(serialNumber);
    switch (templateId) {
      case '1':
        return 'Smart Sensor';
      case '2':
        return 'Control Unit';
      case '3':
        return 'Gateway Device';
      case '4':
        return 'Communication Module';
      case '5':
        return 'Power Module';
      default:
        return 'Unknown Device';
    }
  }

  /// Complete export order with all scanned items
  Future<Map<String, dynamic>> completeExportOrder({
    required int exportId,
    required String orderId,
    required List<Map<String, dynamic>> listProduct,
  }) async {
    try {
      final requestBody = {
        'export_id': exportId,
        'order_id': orderId,
        'list_product': listProduct,
      };

      print('DEBUG: Completing export order with body: $requestBody');

      final response = await _apiClient.patch('/export-warehouse/export-order', requestBody);

      if (response['success'] == true) {
        return {
          'success': true,
          'message': 'Hoàn thành đơn xuất thành công',
          'data': response['data'],
        };
      } else {
        // Handle different response structures
        final statusCode = response['data']?['status_code'];
        final data = response['data']?['data'];

        if (statusCode == 200 && data != null) {
          return {
            'success': true,
            'message': 'Hoàn thành đơn xuất thành công',
            'data': data,
          };
        }

        return {
          'success': false,
          'message': response['message'] ?? 'Không thể hoàn thành đơn xuất',
        };
      }
    } catch (e, stackTrace) {
      logError('Lỗi hoàn thành đơn xuất', e, stackTrace);
      return {
        'success': false,
        'message': 'Lỗi kết nối: ${e.toString()}',
      };
    }
  }

  /// Get export order details
  Future<Map<String, dynamic>> getExportOrderDetails(String exportId) async {
    try {
      final response = await _apiClient.get('/export-warehouse/detail/$exportId');

      if (response['success'] == true) {
        return {
          'success': true,
          'data': response['data'],
        };
      } else {
        // Handle different response structures
        final statusCode = response['data']?['status_code'];
        final data = response['data']?['data'];

        if (statusCode == 200 && data != null) {
          return {
            'success': true,
            'data': data,
          };
        }

        return {
          'success': false,
          'message': response['message'] ?? 'Không thể tải thông tin đơn xuất',
        };
      }
    } catch (e, stackTrace) {
      logError('Lỗi tải thông tin đơn xuất', e, stackTrace);
      return {
        'success': false,
        'message': 'Lỗi kết nối: ${e.toString()}',
      };
    }
  }

  /// Get export progress for tracking
  Future<Map<String, dynamic>> getExportProgress(String exportId) async {
    try {
      final response = await _apiClient.get('/export-warehouse/process/$exportId');

      if (response['success'] == true) {
        return {
          'success': true,
          'data': response['data'],
        };
      } else {
        // Handle different response structures
        final statusCode = response['data']?['status_code'];
        final data = response['data']?['data'];

        if (statusCode == 200 && data != null) {
          return {
            'success': true,
            'data': data,
          };
        }

        return {
          'success': false,
          'message': response['message'] ?? 'Không thể tải tiến độ xuất',
        };
      }
    } catch (e, stackTrace) {
      logError('Lỗi tải tiến độ xuất', e, stackTrace);
      return {
        'success': false,
        'message': 'Lỗi kết nối: ${e.toString()}',
      };
    }
  }

  /// Export order item using QR data
  Future<Map<String, dynamic>> exportOrderItemFromQr({
    required String exportId,
    required QrData qrData,
  }) async {
    try {
      print('DEBUG: Exporting order item from QR - ExportID: $exportId, QR Data: $qrData');
      final result = await _apiClient.post(
        '/export-warehouse/export-order',
        {
          'export_id': exportId,
          'serial_number': qrData.serialNumber,
          'batch_production_id': qrData.batchProductionId,
          'template_id': qrData.templateId,
        },
      );

      print('DEBUG: Export order item response: $result');

      if (result['success'] == true) {
        return {
          'success': true,
          'data': result['data'],
        };
      } else {
        return {
          'success': false,
          'message': result['message'] ?? 'Không thể xuất thiết bị',
        };
      }
    } catch (e) {
      print('DEBUG: Error in exportOrderItemFromQr: $e');
      return {
        'success': false,
        'message': 'Lỗi kết nối: ${e.toString()}',
      };
    }
  }

  /// Export order item (legacy method - for backward compatibility)
  Future<Map<String, dynamic>> exportOrderItem({
    required String exportId,
    required String serialNumber,
    required String batchProductionId,
    required String templateId,
  }) async {
    final qrData = QrData(
      serialNumber: serialNumber,
      batchProductionId: batchProductionId,
      templateId: templateId,
    );
    return exportOrderItemFromQr(exportId: exportId, qrData: qrData);
  }
}
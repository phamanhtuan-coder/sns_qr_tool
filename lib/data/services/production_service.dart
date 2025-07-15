import 'api_client.dart';
import '../models/qr_data.dart';

class ProductionService {
  final ApiClient _apiClient;

  ProductionService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<Map<String, dynamic>> updateDeviceStage(String serialNumber, String stage, String status) async {
    try {
      final result = await _apiClient.patch(
        '/production-tracking/update-serial',
        {
          'device_serial': serialNumber,
          'stage': stage,
          'status': status,
        },
      );

      return result;
    } catch (e) {
      print('DEBUG: Error in updateDeviceStage: $e');
      return {
        'success': false,
        'errorCode': 'UPDATE_ERROR',
        'message': 'Failed to update device stage: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> processScannedSerial(
    String qrRawData,
    {required String functionId}
  ) async {
    if (qrRawData.isEmpty) {
      return {
        'success': false,
        'message': 'QR data cannot be empty',
        'errorCode': 'QR_001',
      };
    }

    // Handle stockin and stockout operations - they should use warehouse services instead
    if (functionId == 'stockin' || functionId == 'stockout') {
      return {
        'success': false,
        'message': 'Tính năng đang phát triển - Sử dụng warehouse services',
        'errorCode': 'FEATURE_001',
        'isFeatureInDevelopment': true,
      };
    }

    // For production modes (identify, firmware, testing, packaging), extract only serial_number
    try {
      final qrData = QrData.fromJsonString(qrRawData);
      final serialNumber = qrData.serialNumber;

      if (serialNumber.isEmpty) {
        return {
          'success': false,
          'message': 'Serial number not found in QR data',
          'errorCode': 'SERIAL_001',
        };
      }

      // All production modes use assembly stage with in_progress status
      final stage = 'assembly';
      final status = 'in_progress';

      print('DEBUG: Processing serial $serialNumber with stage: $stage, status: $status');
      final result = await updateDeviceStage(serialNumber, stage, status);

      // Ensure consistent response format
      if (!result.containsKey('success')) {
        result['success'] = false;
        result['errorCode'] = 'API_001';
        result['message'] = 'Unexpected API response format';
      }

      return result;
    } catch (e) {
      print('DEBUG: Error in processScannedSerial: $e');
      return {
        'success': false,
        'errorCode': 'API_002',
        'message': 'Error processing QR data: ${e.toString()}',
      };
    }
  }

  void dispose() {
    _apiClient.dispose();
  }
}

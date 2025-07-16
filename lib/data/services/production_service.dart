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

    // Handle stockin and stockout as features under development
    if (functionId == 'stockin' || functionId == 'stockout') {
      return {
        'success': false,
        'message': 'Tính năng đang phát triển',
        'errorCode': 'FEATURE_001',
        'isFeatureInDevelopment': true,
      };
    }

    // For production modes (identify, firmware, testing, packaging), extract data from QR
    try {
      // Parse the QR data to extract serial_number, batch_production_id, and template_id
      final qrData = QrData.fromJsonString(qrRawData);
      final serialNumber = qrData.serialNumber;
      final batchProductionId = qrData.batchProductionId;
      final templateId = qrData.templateId;
      final templateName = qrData.templateName;

      if (serialNumber.isEmpty) {
        return {
          'success': false,
          'message': 'Serial number not found in QR data',
          'errorCode': 'SERIAL_001',
        };
      }

      // Define stage and status based on the selected function
      String stage;
      String status;

      switch (functionId) {
        case 'identify':
          stage = 'assembly';
          status = 'in_progress';
          break;
        case 'firmware':
          stage = 'assembly';
          status = 'firmware_upload';
          break;
        case 'testing':
          stage = 'qc';
          status = 'firmware_uploaded';
          break;
        case 'packaging':
          stage = 'completed';
          status = 'pending_packaging';
          break;
        default:
          // Default fallback
          stage = 'qc';
          status = 'pending';
      }

      print('DEBUG: Processing serial $serialNumber with stage: $stage, status: $status');
      final result = await updateDeviceStage(serialNumber, stage, status);

      // Add the extracted fields to the result for display in the dialog
      if (!result.containsKey('data')) {
        result['data'] = {};
      }
      result['data']['serial_number'] = serialNumber;
      result['data']['batch_production_id'] = batchProductionId;
      result['data']['template_id'] = templateId;
      if (templateName != null && templateName.isNotEmpty) {
        result['data']['template_name'] = templateName;
      }

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

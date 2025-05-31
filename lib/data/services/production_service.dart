import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_client.dart';

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
      return {
        'success': false,
        'message': 'Failed to update device stage: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> processScannedSerial(
    String serialNumber,
    {required String functionId}
  ) async {
    if (serialNumber.isEmpty) {
      return {
        'success': false,
        'message': 'Serial number cannot be empty',
      };
    }

    // Handle stockin and stockout as features under development
    if (functionId == 'stockin' || functionId == 'stockout') {
      return {
        'success': false,
        'message': 'Tính năng đang phát triển',
        'isFeatureInDevelopment': true,
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

    try {
      print('DEBUG: Processing serial $serialNumber with stage: $stage, status: $status');
      final result = await updateDeviceStage(serialNumber, stage, status);
      return result;
    } catch (e) {
      return {
        'success': false,
        'message': 'Error processing serial number: ${e.toString()}',
      };
    }
  }

  void dispose() {
    _apiClient.dispose();
  }
}

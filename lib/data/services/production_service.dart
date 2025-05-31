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

  Future<Map<String, dynamic>> processScannedSerial(String serialNumber, {String stage = 'qc', String status = 'pending'}) async {
    if (serialNumber.isEmpty) {
      return {
        'success': false,
        'message': 'Serial number cannot be empty',
      };
    }

    try {
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

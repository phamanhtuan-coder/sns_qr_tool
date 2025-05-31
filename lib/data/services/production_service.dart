import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_client.dart';

class ProductionService {
  final ApiClient _apiClient;

  ProductionService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<Map<String, dynamic>> updateDeviceStage(String serialNumber, String stage, String status) async {
    return _apiClient.patch(
      '/production-tracking/update-serial',
      {
        'device_serial': serialNumber,
        'stage': stage,
        'status': status,
      },
    );
  }

  void dispose() {
    _apiClient.dispose();
  }
}

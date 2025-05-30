import 'package:firmware_deployment_tool/data/models/batch.dart';
import 'package:firmware_deployment_tool/data/models/device.dart';
import 'package:get_it/get_it.dart';

class DeviceService {
  List<Batch> getBatches() => sampleBatches;

  List<Device> getDevices() => sampleDevices;

  List<Device> getDevicesByBatch(int batchId) => sampleDevices.where((d) => d.batchId == batchId).toList();

  void markDeviceDefective(int deviceId, String reason, String? imageUrl) {
    // Simulate updating device status
    // In a real app, update backend or local storage
  }
}

final getIt = GetIt.instance;

void setupDependencies() {
  getIt.registerSingleton<DeviceService>(DeviceService());
}
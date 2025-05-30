import 'package:flutter/material.dart';
import 'package:firmware_deployment_tool/data/models/device.dart';
import 'package:firmware_deployment_tool/data/services/device_service.dart';
import 'package:firmware_deployment_tool/presentation/widgets/error_dialog.dart';

class BatchPanel extends StatefulWidget {
  final int? selectedBatch;
  final int? selectedDevice;
  final ValueChanged<int?> onBatchChanged;
  final ValueChanged<int?> onDeviceSelected;

  const BatchPanel({
    super.key,
    this.selectedBatch,
    this.selectedDevice,
    required this.onBatchChanged,
    required this.onDeviceSelected,
  });

  @override
  _BatchPanelState createState() => _BatchPanelState();
}

class _BatchPanelState extends State<BatchPanel> {
  final DeviceService _deviceService = getIt<DeviceService>();
  Device? _errorDevice;

  @override
  Widget build(BuildContext context) {
    final batches = _deviceService.getBatches();
    final devices = widget.selectedBatch != null ? _deviceService.getDevicesByBatch(widget.selectedBatch!) : [];

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
            ),
            child: DropdownButtonFormField<int>(
              value: widget.selectedBatch,
              decoration: const InputDecoration(
                labelText: 'Chọn lô (Batch)',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<int>(
                  value: null,
                  child: Text('-- Chọn lô --'),
                ),
                ...batches.map((batch) => DropdownMenuItem<int>(
                      value: batch.id,
                      child: Text(batch.name),
                    )),
              ],
              onChanged: widget.onBatchChanged,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Danh sách thiết bị trong lô', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  if (widget.selectedBatch == null)
                    const Center(child: Text('Vui lòng chọn lô để xem danh sách thiết bị', style: TextStyle(color: Colors.grey))),
                  if (widget.selectedBatch != null && devices.isEmpty)
                    const Center(child: Text('Không có thiết bị nào trong lô này', style: TextStyle(color: Colors.grey))),
                  if (devices.isNotEmpty)
                    Expanded(
                      child: SingleChildScrollView(
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('STT')),
                            DataColumn(label: Text('Serial Number')),
                            DataColumn(label: Text('Trạng thái')),
                            DataColumn(label: Text('Thao tác')),
                          ],
                          rows: devices.asMap().entries.map((entry) {
                            final index = entry.key;
                            final device = entry.value;
                            return DataRow(
                              selected: widget.selectedDevice == device.id,
                              cells: [
                                DataCell(Text('${index + 1}')),
                                DataCell(Text(device.serial)),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(device.status).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      _getStatusText(device.status),
                                      style: TextStyle(color: _getStatusColor(device.status)),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  IconButton(
                                    icon: const Icon(Icons.error_outline, color: Colors.red),
                                    onPressed: device.status == 'defective' ? null : () => setState(() => _errorDevice = device),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (_errorDevice != null)
            ErrorDialog(
              device: _errorDevice!,
              onClose: () => setState(() => _errorDevice = null),
              onConfirm: (reason, imageUrl) {
                _deviceService.markDeviceDefective(_errorDevice!.id, reason, imageUrl);
                setState(() => _errorDevice = null);
              },
            ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.yellow.shade700;
      case 'processing':
        return Colors.blue.shade700;
      case 'completed':
        return Colors.green.shade700;
      case 'defective':
        return Colors.red.shade700;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Chờ xử lý';
      case 'processing':
        return 'Đang xử lý';
      case 'completed':
        return 'Hoàn thành';
      case 'defective':
        return 'Hư hỏng';
      default:
        return status;
    }
  }
}
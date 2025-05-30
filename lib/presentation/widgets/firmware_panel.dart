import 'dart:math';

import 'package:flutter/material.dart';

class FirmwarePanel extends StatefulWidget {
  final int? selectedBatch;
  final int? selectedDevice;
  final ValueChanged<int?> onDeviceSelected;

  const FirmwarePanel({
    super.key,
    this.selectedBatch,
    this.selectedDevice,
    required this.onDeviceSelected,
  });

  @override
  _FirmwarePanelState createState() => _FirmwarePanelState();
}

class _FirmwarePanelState extends State<FirmwarePanel> {
  String? _firmwareVersion;
  String? _serialNumber;
  String? _comPort;
  String _activeTab = 'console';
  final List<String> _logs = [];
  final List<String> _serialLogs = [];
  bool _isFlashing = false;
  DateTime? _lastChecked;

  @override
  void initState() {
    super.initState();
    _startLogSimulation();
  }

  void _startLogSimulation() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 5));
      if (_logs.length < 100) {
        setState(() {
          _logs.add('[${DateTime.now().toString().substring(11, 19)}] System: Waiting for command...');
        });
        return true;
      }
      return false;
    });
  }

  void _addLog(String message) {
    setState(() {
      _logs.add('[${DateTime.now().toString().substring(11, 19)}] $message');
    });
  }

  void _handleFlashFirmware() {
    if (_comPort == null || _firmwareVersion == null) {
      _addLog('Error: Please select COM port and firmware version');
      return;
    }
    setState(() => _isFlashing = true);
    _addLog('Starting firmware flash: $_firmwareVersion to device on $_comPort');
    Future.delayed(const Duration(seconds: 3), () {
      setState(() {
        _isFlashing = false;
        _addLog(Random().nextDouble() > 0.2 ? 'Firmware flashed successfully!' : 'Error: Firmware flash failed. Please try again.');
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    const firmwareVersions = ['v1.0.0', 'v1.1.0', 'v2.0.0-beta'];
    const comPorts = ['COM1', 'COM2', 'COM3'];

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
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _firmwareVersion,
                        decoration: const InputDecoration(
                          labelText: 'Phiên bản Firmware',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('-- Chọn phiên bản --'),
                          ),
                          ...firmwareVersions.map((v) => DropdownMenuItem<String>(value: v, child: Text(v))),
                        ],
                        onChanged: (value) => setState(() => _firmwareVersion = value),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Cảnh báo', style: TextStyle(color: Colors.yellow)),
                          content: const Text('Tính năng chọn file local có thể gây ra lỗi không mong muốn. Bạn có chắc chắn muốn tiếp tục?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
                            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tiếp tục')),
                          ],
                        ),
                      ),
                      icon: const Icon(Icons.search, size: 16),
                      label: const Text('Find in file'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Serial Number',
                          hintText: 'Nhập hoặc quét mã serial',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) => setState(() => _serialNumber = value),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Trigger QR scan
                      },
                      icon: const Icon(Icons.qr_code, size: 16),
                      label: const Text('Quét QR'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _comPort,
                        decoration: const InputDecoration(
                          labelText: 'Cổng COM (USB)',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('-- Chọn cổng COM --'),
                          ),
                          ...comPorts.map((p) => DropdownMenuItem<String>(value: p, child: Text(p))),
                        ],
                        onChanged: (value) => setState(() => _comPort = value),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () {
                        setState(() => _lastChecked = DateTime.now());
                        _addLog('Refreshing COM ports...');
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _lastChecked != null ? 'Kiểm tra lần cuối: ${_lastChecked!.toString().substring(11, 19)}' : 'Chưa kiểm tra cổng COM',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    TextButton(
                      onPressed: () => setState(() => _activeTab = 'console'),
                      child: Text(
                        'Console Log',
                        style: TextStyle(
                          color: _activeTab == 'console' ? Theme.of(context).primaryColor : Colors.grey,
                          fontWeight: _activeTab == 'console' ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _activeTab = 'serial'),
                      child: Text(
                        'Serial Monitor',
                        style: TextStyle(
                          color: _activeTab == 'serial' ? Theme.of(context).primaryColor : Colors.grey,
                          fontWeight: _activeTab == 'serial' ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: Container(
                    color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF111827) : const Color(0xFFF3F4F6),
                    padding: const EdgeInsets.all(16),
                    child: _activeTab == 'console' && _logs.isNotEmpty || _activeTab == 'serial' && _serialLogs.isNotEmpty
                        ? ListView.builder(
                            itemCount: _activeTab == 'console' ? _logs.length : _serialLogs.length,
                            itemBuilder: (context, index) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(_activeTab == 'console' ? _logs[index] : _serialLogs[index], style: const TextStyle(fontFamily: 'monospace', fontSize: 14)),
                            ),
                          )
                        : const Center(child: Text('No logs to display', style: TextStyle(color: Colors.grey))),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => setState(() => _activeTab == 'console' ? _logs.clear() : _serialLogs.clear()),
                        icon: const Icon(Icons.clear, size: 16),
                        label: const Text('Clear Log'),
                      ),
                      ElevatedButton.icon(
                        onPressed: _isFlashing || _comPort == null || _firmwareVersion == null ? null : _handleFlashFirmware,
                        icon: _isFlashing ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.bolt, size: 16),
                        label: Text(_isFlashing ? 'Flashing...' : 'Flash Firmware'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isFlashing || _comPort == null || _firmwareVersion == null ? Colors.grey : Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
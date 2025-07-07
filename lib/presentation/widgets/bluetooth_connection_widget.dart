import 'package:flutter/material.dart';
import 'package:smart_net_qr_scanner/data/services/bluetooth_client_service.dart';
import 'package:smart_net_qr_scanner/utils/app_colors.dart';

class BluetoothConnectionWidget extends StatefulWidget {
  final VoidCallback? onConnectionChanged;

  const BluetoothConnectionWidget({
    super.key,
    this.onConnectionChanged,
  });

  @override
  State<BluetoothConnectionWidget> createState() => _BluetoothConnectionWidgetState();
}

class _BluetoothConnectionWidgetState extends State<BluetoothConnectionWidget> {
  final BluetoothClientService _bluetoothService = BluetoothClientService();
  ConnectionStatus _connectionStatus = ConnectionStatus.disconnected;
  AppBluetoothState _bluetoothState = AppBluetoothState.unknown;
  List<AppBluetoothDevice> _devices = [];
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _initializeBluetooth();
    _listenToBluetoothChanges();
  }

  void _initializeBluetooth() async {
    await _bluetoothService.initialize();
  }

  void _listenToBluetoothChanges() {
    _bluetoothService.connectionStatus.listen((status) {
      if (mounted) {
        setState(() {
          _connectionStatus = status;
        });
        widget.onConnectionChanged?.call();
      }
    });

    _bluetoothService.bluetoothState.listen((state) {
      if (mounted) {
        setState(() {
          _bluetoothState = state;
        });
      }
    });

    _bluetoothService.devicesStream.listen((devices) {
      if (mounted) {
        setState(() {
          _devices = devices;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getHeaderColor(isDarkMode),
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(12),
                  bottom: _isExpanded ? Radius.zero : const Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  _buildStatusIcon(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kết nối Bluetooth',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDarkMode ? Colors.white : Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getStatusText(),
                          style: TextStyle(
                            fontSize: 14,
                            color: isDarkMode ? Colors.white70 : Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_bluetoothState == AppBluetoothState.poweredOn)
                    Icon(
                      _isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: isDarkMode ? Colors.white : Colors.white,
                    ),
                ],
              ),
            ),
          ),

          // Expandable content
          if (_isExpanded) _buildExpandedContent(),
        ],
      ),
    );
  }

  Widget _buildStatusIcon() {
    IconData icon;
    Color color;

    switch (_connectionStatus) {
      case ConnectionStatus.connected:
        icon = Icons.bluetooth_connected;
        color = Colors.white;
        break;
      case ConnectionStatus.connecting:
        icon = Icons.bluetooth_searching;
        color = Colors.white;
        break;
      case ConnectionStatus.disconnected:
        icon = Icons.bluetooth_disabled;
        color = Colors.white70;
        break;
      case ConnectionStatus.error:
        icon = Icons.bluetooth_disabled;
        color = Colors.white70;
        break;
    }

    if (_connectionStatus == ConnectionStatus.connecting) {
      return SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      );
    }

    return Icon(icon, color: color, size: 24);
  }

  Color _getHeaderColor(bool isDarkMode) {
    switch (_connectionStatus) {
      case ConnectionStatus.connected:
        return AppColors.success;
      case ConnectionStatus.connecting:
        return AppColors.warning;
      case ConnectionStatus.disconnected:
      case ConnectionStatus.error:
        return Colors.grey[600]!;
    }
  }

  String _getStatusText() {
    if (_bluetoothState == AppBluetoothState.poweredOff) {
      return 'Bluetooth đã tắt';
    }

    switch (_connectionStatus) {
      case ConnectionStatus.connected:
        final device = _bluetoothService.connectedDevice;
        return 'Đã kết nối: ${device?.name ?? 'Unknown'}';
      case ConnectionStatus.connecting:
        return 'Đang kết nối...';
      case ConnectionStatus.disconnected:
        return 'Chưa kết nối';
      case ConnectionStatus.error:
        return 'Lỗi kết nối';
    }
  }

  Widget _buildExpandedContent() {
    if (_bluetoothState == AppBluetoothState.poweredOff) {
      return _buildBluetoothOffContent();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Connected device info
          if (_bluetoothService.connectedDevice != null) ...[
            _buildConnectedDeviceCard(),
            const SizedBox(height: 16),
          ],

          // Device list header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Thiết bị có sẵn',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                children: [
                  if (_bluetoothService.isScanning)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    IconButton(
                      onPressed: _startDiscovery,
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Tìm kiếm thiết bị',
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Device list
          if (_devices.isEmpty)
            _buildEmptyDeviceList()
          else
            _buildDeviceList(),
        ],
      ),
    );
  }

  Widget _buildBluetoothOffContent() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(
            Icons.bluetooth_disabled,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Bluetooth đã tắt',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vui lòng bật Bluetooth để kết nối với thiết bị',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _enableBluetooth,
            icon: const Icon(Icons.bluetooth),
            label: const Text('Bật Bluetooth'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectedDeviceCard() {
    final device = _bluetoothService.connectedDevice!;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.success.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.bluetooth_connected,
              color: AppColors.success,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.success,
                  ),
                ),
                Text(
                  device.address,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _disconnect,
            icon: const Icon(Icons.close, color: AppColors.error),
            tooltip: 'Ngắt kết nối',
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyDeviceList() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.bluetooth_searching,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Không tìm thấy thiết bị',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Nhấn nút làm mới để tìm kiếm thiết bị',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceList() {
    return Column(
      children: _devices.map((device) => _buildDeviceItem(device)).toList(),
    );
  }

  Widget _buildDeviceItem(AppBluetoothDevice device) {
    final isConnected = device.isConnected;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (isConnected ? AppColors.success : AppColors.primary).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isConnected ? Icons.bluetooth_connected : Icons.bluetooth,
            color: isConnected ? AppColors.success : AppColors.primary,
            size: 20,
          ),
        ),
        title: Text(
          device.name,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: isConnected ? AppColors.success : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              device.address,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            if (device.isBonded)
              Text(
                'Đã ghép nối',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        trailing: isConnected
            ? const Icon(Icons.check_circle, color: AppColors.success)
            : ElevatedButton(
                onPressed: () => _connectToDevice(device),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(80, 32),
                ),
                child: const Text('Kết nối'),
              ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        tileColor: Theme.of(context).cardColor,
      ),
    );
  }

  void _enableBluetooth() async {
    final hasPermissions = await _bluetoothService.requestPermissions();
    if (!hasPermissions) {
      _showError('Không có quyền truy cập Bluetooth');
      return;
    }

    final enabled = await _bluetoothService.enableBluetooth();
    if (!enabled) {
      _showError('Không thể bật Bluetooth');
    }
  }

  void _startDiscovery() async {
    final hasPermissions = await _bluetoothService.requestPermissions();
    if (!hasPermissions) {
      _showError('Không có quyền tìm kiếm thiết bị Bluetooth');
      return;
    }

    await _bluetoothService.startDiscovery();
  }

  void _connectToDevice(AppBluetoothDevice device) async {
    final success = await _bluetoothService.connectToDevice(device);
    if (!success) {
      _showError('Không thể kết nối với ${device.name}');
    }
  }

  void _disconnect() async {
    await _bluetoothService.disconnect();
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}

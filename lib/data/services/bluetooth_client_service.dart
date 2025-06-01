import 'dart:io';
import 'dart:convert';
import 'dart:async';

class BluetoothClientService {
  /// The default port used for socket communication with desktop app
  static const int defaultPort = 12345;

  /// Timeout duration for connection attempts in milliseconds
  static const int connectionTimeout = 300;

  /// Maximum number of connection retries
  static const int maxRetries = 2;

  /// Stream controller for connection status updates
  final _connectionStatusController = StreamController<ConnectionStatus>.broadcast();

  /// Stream of connection status updates
  Stream<ConnectionStatus> get connectionStatus => _connectionStatusController.stream;

  /// Finds the desktop server on the local network
  /// Returns the IP address of the server if found, null otherwise
  Future<String?> findDesktopServer({int port = defaultPort}) async {
    _connectionStatusController.add(ConnectionStatus.searching);

    try {
      final interfaces = await NetworkInterface.list();
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          final ip = addr.address;
          // Only check private network ranges
          if (ip.startsWith('192.168.') || ip.startsWith('10.') || ip.startsWith('172.')) {
            final subnet = ip.substring(0, ip.lastIndexOf('.') + 1);
            for (int i = 1; i < 255; i++) {
              if (_connectionStatusController.isClosed) return null; // Stop if disposed

              final host = '$subnet$i';
              try {
                final socket = await Socket.connect(
                  host,
                  port,
                  timeout: Duration(milliseconds: connectionTimeout)
                );
                await socket.close();
                _connectionStatusController.add(ConnectionStatus.found);
                return host;
              } catch (_) {
                // Continue scanning
              }
            }
          }
        }
      }
      _connectionStatusController.add(ConnectionStatus.notFound);
      return null;
    } catch (e) {
      print('Error finding desktop server: $e');
      _connectionStatusController.add(ConnectionStatus.error);
      return null;
    }
  }

  /// Sends serial data to the desktop server
  /// Returns true if successfully sent, false otherwise
  Future<bool> sendSerialToDesktop(String serial, {int port = defaultPort, int retryCount = 0}) async {
    _connectionStatusController.add(ConnectionStatus.connecting);

    try {
      final host = await findDesktopServer(port: port);
      if (host != null) {
        try {
          final socket = await Socket.connect(host, port);

          // Create a structured message with metadata
          final message = jsonEncode({
            'type': 'serial_data',
            'data': serial,
            'timestamp': DateTime.now().toIso8601String(),
          });

          socket.write(message);
          print('Serial $serial sent to $host:$port');

          // Wait for confirmation or timeout
          await Future.delayed(const Duration(milliseconds: 300));
          await socket.close();

          _connectionStatusController.add(ConnectionStatus.sent);
          return true;
        } catch (e) {
          print('Error sending serial: $e');
          _connectionStatusController.add(ConnectionStatus.error);

          // Retry logic
          if (retryCount < maxRetries) {
            print('Retrying (${retryCount + 1}/$maxRetries)...');
            return sendSerialToDesktop(serial, port: port, retryCount: retryCount + 1);
          }
          return false;
        }
      } else {
        print('No desktop server found.');
        _connectionStatusController.add(ConnectionStatus.notFound);
        return false;
      }
    } catch (e) {
      print('Unexpected error: $e');
      _connectionStatusController.add(ConnectionStatus.error);
      return false;
    }
  }

  /// Cleanup resources
  void dispose() {
    _connectionStatusController.close();
  }
}

/// Connection status enum for tracking the state of bluetooth connections
enum ConnectionStatus {
  idle,
  searching,
  connecting,
  found,
  notFound,
  sent,
  error,
}

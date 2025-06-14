import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class BluetoothClientService {
  /// The default port used for socket communication with desktop app
  static const int defaultPort = 12345;

  /// Known desktop server IP - updated based on successful connection logs
  static const String knownDesktopIp = '192.168.1.7';

  /// Timeout duration for connection attempts in milliseconds
  static const int connectionTimeout = 1000;

  /// Maximum number of connection retries
  static const int maxRetries = 3;

  /// Current username (required for desktop pairing)
  String _currentUsername = '';

  /// Set the current username for desktop pairing
  void setUsername(String username) {
    _currentUsername = username;
  }

  /// Stream controller for connection status updates
  final _connectionStatusController = StreamController<ConnectionStatus>.broadcast();

  /// Stream of connection status updates
  Stream<ConnectionStatus> get connectionStatus => _connectionStatusController.stream;

  /// Finds the desktop server on the local network
  /// Returns the IP address of the server if found, null otherwise
  Future<String?> findDesktopServer({int port = defaultPort}) async {
    _connectionStatusController.add(ConnectionStatus.searching);
    print('⚡ DEBUG: Searching for desktop server on port $port...');

    try {
      // Try direct connection to known desktop IP first
      try {
        print('⚡ DEBUG: Attempting direct connection to known desktop IP: $knownDesktopIp:$port');
        final socket = await Socket.connect(
          knownDesktopIp,
          port,
          timeout: const Duration(milliseconds: connectionTimeout)
        );
        await socket.close();
        print('📘 INFO: Desktop server found on $knownDesktopIp:$port');
        _connectionStatusController.add(ConnectionStatus.found);
        return knownDesktopIp;
      } catch (e) {
        print('⚡ DEBUG: Failed to connect to known desktop IP: $e - will try other methods');
      }

      // Try localhost/loopback next (for emulator testing)
      try {
        print('⚡ DEBUG: Checking localhost connections...');
        final loopbackAddresses = ['localhost', '127.0.0.1', '10.0.2.2']; // 10.0.2.2 is host from Android emulator

        for (final address in loopbackAddresses) {
          try {
            print('⚡ DEBUG: Attempting connection to $address:$port');
            final socket = await Socket.connect(
              address,
              port,
              timeout: const Duration(milliseconds: connectionTimeout)
            );
            await socket.close();
            print('📘 INFO: Desktop server found on $address:$port');
            _connectionStatusController.add(ConnectionStatus.found);
            return address;
          } catch (e) {
            print('⚡ DEBUG: Failed to connect to $address:$port - ${e.toString()}');
            // Continue to next address
          }
        }
      } catch (e) {
        print('⚡ DEBUG: Error checking localhost: $e');
      }

      // Then try network interfaces
      final interfaces = await NetworkInterface.list();
      print('⚡ DEBUG: Found ${interfaces.length} network interfaces');

      for (var interface in interfaces) {
        print('⚡ DEBUG: Checking interface: ${interface.name}');

        for (var addr in interface.addresses) {
          final ip = addr.address;
          print('⚡ DEBUG: Address on interface ${interface.name}: $ip');

          // Only check private network ranges
          if (ip.startsWith('192.168.') || ip.startsWith('10.') ||
              (ip.startsWith('172.') && int.parse(ip.split('.')[1]) >= 16 && int.parse(ip.split('.')[1]) <= 31)) {

            final subnet = ip.substring(0, ip.lastIndexOf('.') + 1);
            print('⚡ DEBUG: Scanning subnet: $subnet*');

            // Try direct connection to specific hosts first (common server addresses)
            final commonLastOctets = [1, 2, 100, 101, 254];
            for (final lastOctet in commonLastOctets) {
              final host = '$subnet$lastOctet';
              print('⚡ DEBUG: Checking common host: $host:$port');

              try {
                final socket = await Socket.connect(
                  host,
                  port,
                  timeout: const Duration(milliseconds: connectionTimeout)
                );
                await socket.close();
                print('📘 INFO: Desktop server found on $host:$port');
                _connectionStatusController.add(ConnectionStatus.found);
                return host;
              } catch (_) {
                // Continue to next host
              }
            }

            // Scan the whole subnet (with limited range for performance)
            // Only scan from 1-30 to be faster, most servers would be in this range
            for (int i = 1; i <= 30; i++) {
              if (_connectionStatusController.isClosed) return null; // Stop if disposed

              final host = '$subnet$i';
              try {
                final socket = await Socket.connect(
                  host,
                  port,
                  timeout: const Duration(milliseconds: connectionTimeout)
                );
                await socket.close();
                print('📘 INFO: Desktop server found on $host:$port');
                _connectionStatusController.add(ConnectionStatus.found);
                return host;
              } catch (_) {
                // Continue scanning
              }
            }
          }
        }
      }

      print('⚡ DEBUG: No desktop server found on the network');
      _connectionStatusController.add(ConnectionStatus.notFound);
      return null;
    } catch (e) {
      print('❌ ERROR: Error finding desktop server: $e');
      _connectionStatusController.add(ConnectionStatus.error);
      return null;
    }
  }

  /// Get stored username from SharedPreferences for desktop pairing
  Future<String> _getStoredUsername() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('user_username');
      if (username == null || username.isEmpty) {
        throw Exception('No username found in SharedPreferences');
      }
      print('⚡ DEBUG: Retrieved username from SharedPreferences: $username');
      return username;
    } catch (e) {
      print('❌ ERROR: Failed to get username from SharedPreferences: $e');
      throw Exception('No valid username found');
    }
  }

  /// Sends serial data to the desktop server
  /// Returns true if successfully sent, false otherwise
  Future<bool> sendSerialToDesktop(String serial, {int port = defaultPort, int retryCount = 0}) async {
    _connectionStatusController.add(ConnectionStatus.connecting);
    print('⚡ DEBUG: Attempting to send serial data: $serial to desktop on port $port');

    try {
      // Get username from SharedPreferences
      final username = await _getStoredUsername();
      if (username.isEmpty) {
        print('❌ ERROR: Username not found in SharedPreferences');
        _connectionStatusController.add(ConnectionStatus.error);
        return false;
      }
      _currentUsername = username; // Update the current username

      String? host = await findDesktopServer(port: port);

      if (host != null) {
        try {
          print('⚡ DEBUG: Connecting to $host:$port');
          final socket = await Socket.connect(
            host,
            port,
            timeout: const Duration(milliseconds: connectionTimeout * 2)
          );

          // Create the payload according to the required format
          final message = jsonEncode({
            'username': _currentUsername,
            'serial_number': serial
          });

          print('⚡ DEBUG: Sending message: $message');
          socket.write(message);
          socket.flush();
          print('📘 INFO: Serial $serial sent to $host:$port for user $_currentUsername');

          // Setup a listener for response
          final completer = Completer<bool>();

          // Setup a response timeout
          final responseTimeout = Timer(const Duration(milliseconds: 1000), () {
            if (!completer.isCompleted) {
              print('⚡ DEBUG: No confirmation received from server, assuming data was sent');
              completer.complete(true);
            }
          });

          // Listen for any server response
          socket.listen(
            (data) {
              String response = utf8.decode(data);
              print('📘 INFO: Received response from server: $response');
              if (!completer.isCompleted) {
                completer.complete(true);
              }
            },
            onError: (e) {
              print('❌ ERROR: Socket error: $e');
              if (!completer.isCompleted) {
                completer.complete(false);
              }
            },
            onDone: () {
              print('⚡ DEBUG: Socket connection closed');
            }
          );

          // Wait for completion (either response or timeout)
          final result = await completer.future;

          // Clean up
          responseTimeout.cancel();
          await socket.close();

          if (result) {
            _connectionStatusController.add(ConnectionStatus.sent);
            return true;
          } else {
            _connectionStatusController.add(ConnectionStatus.error);

            if (retryCount < maxRetries) {
              print('⚡ DEBUG: Retrying (${retryCount + 1}/$maxRetries)...');
              return sendSerialToDesktop(serial, port: port, retryCount: retryCount + 1);
            }
            return false;
          }
        } catch (e) {
          print('❌ ERROR: Error sending serial: $e');
          _connectionStatusController.add(ConnectionStatus.error);

          if (retryCount < maxRetries) {
            print('⚡ DEBUG: Retrying (${retryCount + 1}/$maxRetries)...');
            return sendSerialToDesktop(serial, port: port, retryCount: retryCount + 1);
          }
          return false;
        }
      } else {
        print('❌ ERROR: No desktop server found.');
        _connectionStatusController.add(ConnectionStatus.notFound);
        return false;
      }
    } catch (e) {
      print('❌ ERROR: Unexpected error: $e');
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

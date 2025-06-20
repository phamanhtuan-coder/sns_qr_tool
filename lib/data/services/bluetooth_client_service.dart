import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class BluetoothClientService {
  /// The default port used for socket communication with desktop app
  static const int defaultPort = 12345;

  /// Key for storing last successful server IP in SharedPreferences
  static const String _lastServerIpKey = 'last_successful_server_ip';

  /// Fallback server IP if no saved IP is available - could be updated dynamically
  static const String _fallbackDesktopIp = '192.168.51.18'; // Default desktop server IP

  /// Timeout duration for connection attempts in milliseconds
  static const int connectionTimeout = 5000; // Increased from 3000 to 5000ms for better reliability

  /// Maximum number of connection retries
  static const int maxRetries = 5; // Increased from 3 to 5 for more persistence

  /// Scan range for IP addresses - full subnet range to ensure complete coverage
  static const int scanStartRange = 1;
  static const int scanEndRange = 254;

  /// Maximum number of concurrent connection attempts
  static const int maxConcurrentScans = 10;

  /// Common IP last octets to check first (prioritized for faster connection)
  static final List<int> commonLastOctets = [18, 70, 80, 90, 115, 1, 2, 100, 101, 120, 136, 150, 200, 254];

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

  /// Save the server IP address that was successfully connected to
  Future<void> _saveServerIp(String ip) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastServerIpKey, ip);
      print('📘 INFO: Saved server IP to SharedPreferences: $ip');
    } catch (e) {
      print('❌ ERROR: Failed to save server IP: $e');
    }
  }

  /// Finds the desktop server on the local network
  /// Returns the IP address of the server if found, null otherwise
  Future<String?> findDesktopServer({int port = defaultPort}) async {
    _connectionStatusController.add(ConnectionStatus.searching);
    print('⚡ DEBUG: Searching for desktop server on port $port...');

    try {
      // Try direct connection to known desktop IP first
      try {
        final savedIp = await _getSavedServerIp();
        print('⚡ DEBUG: Attempting direct connection to saved desktop IP: $savedIp:$port');
        try {
          final socket = await Socket.connect(
            savedIp,
            port,
            timeout: const Duration(milliseconds: connectionTimeout)
          );
          await socket.close();
          print('📘 INFO: Desktop server found on $savedIp:$port');
          _connectionStatusController.add(ConnectionStatus.found);
          return savedIp;
        } catch (e) {
          print('⚡ DEBUG: Failed to connect to saved desktop IP: $savedIp - ${e.toString()}');
        }
      } catch (e) {
        print('⚡ DEBUG: Failed to get saved IP: $e - will try other methods');
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
            await _saveServerIp(address); // Save successful IP
            return address;
          } catch (e) {
            print('⚡ DEBUG: Failed to connect to $address:$port - ${e.toString()}');
            // Continue to next address
          }
        }
      } catch (e) {
        print('⚡ DEBUG: Error checking localhost: $e');
      }

      // Then try network interfaces with parallel scanning
      final interfaces = await NetworkInterface.list();
      print('⚡ DEBUG: Found ${interfaces.length} network interfaces to scan');

      for (var interface in interfaces) {
        print('⚡ DEBUG: Checking interface: ${interface.name}');

        // Process all IPv4 addresses on the interface
        for (var addr in interface.addresses) {
          final ip = addr.address;
          print('⚡ DEBUG: Address on interface ${interface.name}: $ip');

          // Only check private network ranges
          if (ip.startsWith('192.168.') || ip.startsWith('10.') ||
              (ip.startsWith('172.') && int.parse(ip.split('.')[1]) >= 16 && int.parse(ip.split('.')[1]) <= 31)) {

            final subnet = ip.substring(0, ip.lastIndexOf('.') + 1);
            print('⚡ DEBUG: Scanning subnet: $subnet* for port $port');

            // Try direct connection to specific hosts first (common server addresses)
            // Use a more focused approach first
            final commonFutures = <Future<String?>>[];
            for (final lastOctet in commonLastOctets) {
              commonFutures.add(_tryConnectToHost('$subnet$lastOctet', port));
            }

            // Wait for any success or all failures from common IPs
            print('⚡ DEBUG: Checking ${commonLastOctets.length} common IPs in parallel');
            final results = await Future.wait(commonFutures);
            final foundHost = results.firstWhere((result) => result != null, orElse: () => null);
            if (foundHost != null) {
              await _saveServerIp(foundHost);
              return foundHost;
            }

            if (_connectionStatusController.isClosed) return null; // Stop if disposed

            // Scan the whole subnet in batches (for performance and to prevent overloading)
            print('⚡ DEBUG: Starting full subnet scan from $subnet$scanStartRange to $subnet$scanEndRange');
            int batchNumber = 1;
            int totalBatches = (scanEndRange - scanStartRange + 1) ~/ maxConcurrentScans +
                ((scanEndRange - scanStartRange + 1) % maxConcurrentScans == 0 ? 0 : 1);

            // We'll scan in batches of maxConcurrentScans
            for (int start = scanStartRange; start <= scanEndRange; start += maxConcurrentScans) {
              if (_connectionStatusController.isClosed) return null; // Stop if disposed

              final end = (start + maxConcurrentScans - 1) <= scanEndRange
                  ? (start + maxConcurrentScans - 1)
                  : scanEndRange;

              print('⚡ DEBUG: Scanning batch $batchNumber/$totalBatches: $subnet$start to $subnet$end');

              final batchFutures = <Future<String?>>[];
              for (int i = start; i <= end; i++) {
                // Skip IPs we already checked in the common list
                if (commonLastOctets.contains(i)) {
                  print('⚡ DEBUG: Skipping IP $subnet$i (already checked in common IPs list)');
                  continue;
                }
                batchFutures.add(_tryConnectToHost('$subnet$i', port));
              }

              final batchResults = await Future.wait(batchFutures);
              final batchFoundHost = batchResults.firstWhere((result) => result != null, orElse: () => null);

              if (batchFoundHost != null) {
                await _saveServerIp(batchFoundHost);
                return batchFoundHost;
              }

              batchNumber++;
            }
          }
        }
      }

      print('⚡ DEBUG: No desktop server found on the network after exhaustive search');
      _connectionStatusController.add(ConnectionStatus.notFound);
      return null;
    } catch (e) {
      print('❌ ERROR: Error finding desktop server: $e');
      _connectionStatusController.add(ConnectionStatus.error);
      return null;
    }
  }

  /// Try to connect to a host on the specified port
  /// Returns the host if connection succeeds, null otherwise
  Future<String?> _tryConnectToHost(String host, int port) async {
    try {
      print('⚡ DEBUG: Attempting connection to $host:$port');
      final socket = await Socket.connect(
        host,
        port,
        timeout: Duration(milliseconds: connectionTimeout)
      );
      await socket.close();
      print('📘 INFO: ✓ FOUND SERVER - Desktop server available at $host:$port');
      _connectionStatusController.add(ConnectionStatus.found);
      return host;
    } catch (e) {
      // We'll only log connection refusal errors as they indicate a host responded
      if (e.toString().contains('refused')) {
        print('⚡ DEBUG: Host at $host responded but refused connection on port $port');
      }
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

  /// Get the last saved server IP from SharedPreferences
  Future<String> _getSavedServerIp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ip = prefs.getString(_lastServerIpKey) ?? '';
      if (ip.isEmpty) {
        throw Exception('No saved IP found, using fallback IP');
      }
      print('⚡ DEBUG: Retrieved saved server IP from SharedPreferences: $ip');
      return ip;
    } catch (e) {
      print('❌ ERROR: Failed to get saved server IP: $e');
      return _fallbackDesktopIp; // Return fallback IP on error
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

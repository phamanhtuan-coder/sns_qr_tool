import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:smart_net_qr_scanner/data/models/delivery_order.dart';
import 'package:smart_net_qr_scanner/utils/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';

class GoogleMapsWebView extends StatefulWidget {
  final Position? currentLocation;
  final List<DeliveryOrder> deliveryOrders;
  final DeliveryOrder? selectedOrder;
  final Function(DeliveryOrder)? onMarkerTap;

  const GoogleMapsWebView({
    super.key,
    this.currentLocation,
    this.deliveryOrders = const [],
    this.selectedOrder,
    this.onMarkerTap,
  });

  @override
  State<GoogleMapsWebView> createState() => _GoogleMapsWebViewState();
}

class _GoogleMapsWebViewState extends State<GoogleMapsWebView> {
  WebViewController? _controller;
  bool _isLoading = true;
  String? _error;
  bool _isWebViewSupported = true;

  @override
  void initState() {
    super.initState();
    _checkWebViewSupport();
  }

  void _checkWebViewSupport() {
    // Check if we're on web or if WebView is supported
    if (kIsWeb) {
      setState(() {
        _isWebViewSupported = false;
        _isLoading = false;
      });
      return;
    }

    try {
      _initializeWebView();
    } catch (e) {
      print('WebView initialization failed: $e');
      setState(() {
        _isWebViewSupported = false;
        _isLoading = false;
        _error = 'WebView không được hỗ trợ trên nền tảng này';
      });
    }
  }

  void _initializeWebView() {
    try {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (String url) {
              if (mounted) {
                setState(() {
                  _isLoading = true;
                  _error = null;
                });
              }
            },
            onPageFinished: (String url) {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
              }
              _addMarkersToMap();
            },
            onWebResourceError: (WebResourceError error) {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                  _error = 'Lỗi tải bản đồ: ${error.description}';
                });
              }
            },
          ),
        );

      _loadMap();
    } catch (e) {
      print('Error initializing WebView: $e');
      setState(() {
        _isWebViewSupported = false;
        _isLoading = false;
        _error = 'Không thể khởi tạo WebView';
      });
    }
  }

  void _loadMap() {
    final center = widget.currentLocation != null
        ? '${widget.currentLocation!.latitude}, ${widget.currentLocation!.longitude}'
        : '21.028511, 105.804817'; // Default to Hanoi

    final htmlString = '''
<!DOCTYPE html>
<html>
<head>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        html, body {
            height: 100%;
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
        }
        #map {
            height: 100vh;
            width: 100vw;
        }
        .info-window {
            max-width: 250px;
            padding: 8px;
        }
        .info-title {
            font-weight: bold;
            margin-bottom: 4px;
            color: #1976D2;
        }
        .info-address {
            font-size: 12px;
            color: #666;
            margin-bottom: 4px;
        }
        .info-phone {
            font-size: 12px;
            color: #666;
        }
        .status-badge {
            display: inline-block;
            padding: 2px 8px;
            border-radius: 12px;
            font-size: 10px;
            font-weight: bold;
            margin-top: 4px;
        }
        .status-assigned { background-color: #E3F2FD; color: #1976D2; }
        .status-started { background-color: #FFF3E0; color: #F57C00; }
        .status-inTransit { background-color: #FFF3E0; color: #F57C00; }
        .status-delivered { background-color: #E8F5E8; color: #388E3C; }
        .status-failed { background-color: #FFEBEE; color: #D32F2F; }
    </style>
</head>
<body>
    <div id="map"></div>
    
    <script>
        let map;
        let markers = [];
        let currentLocationMarker;
        
        function initMap() {
            map = new google.maps.Map(document.getElementById("map"), {
                zoom: 13,
                center: { lat: ${center.split(',')[0]}, lng: ${center.split(',')[1]} },
                mapTypeControl: true,
                streetViewControl: true,
                fullscreenControl: false,
                styles: [
                    {
                        featureType: "poi",
                        elementType: "labels",
                        stylers: [{ visibility: "off" }]
                    }
                ]
            });
            
            // Add current location marker if available
            ${widget.currentLocation != null ? '''
            currentLocationMarker = new google.maps.Marker({
                position: { lat: ${widget.currentLocation!.latitude}, lng: ${widget.currentLocation!.longitude} },
                map: map,
                title: "Vị trí hiện tại",
                icon: {
                    url: "data:image/svg+xml;charset=UTF-8," + encodeURIComponent(getCurrentLocationIcon()),
                    scaledSize: new google.maps.Size(30, 30),
                    anchor: new google.maps.Point(15, 15)
                }
            });
            
            const currentInfoWindow = new google.maps.InfoWindow({
                content: '<div class="info-window"><div class="info-title">📍 Vị trí hiện tại</div></div>'
            });
            
            currentLocationMarker.addListener("click", () => {
                currentInfoWindow.open(map, currentLocationMarker);
            });
            ''' : ''}
        }
        
        function getCurrentLocationIcon() {
            return '<svg xmlns="http://www.w3.org/2000/svg" width="30" height="30" viewBox="0 0 24 24" fill="#1976D2"><circle cx="12" cy="12" r="8" fill="#ffffff" stroke="#1976D2" stroke-width="2"/><circle cx="12" cy="12" r="4" fill="#1976D2"/></svg>';
        }
        
        function getDeliveryIcon(status) {
            const colors = {
                'assigned': '#1976D2',
                'started': '#F57C00', 
                'inTransit': '#F57C00',
                'delivered': '#388E3C',
                'failed': '#D32F2F',
                'cancelled': '#757575'
            };
            const color = colors[status] || '#757575';
            
            return '<svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 24 24" fill="' + color + '"><path d="M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7zm0 9.5c-1.38 0-2.5-1.12-2.5-2.5s1.12-2.5 2.5-2.5 2.5 1.12 2.5 2.5-1.12 2.5-2.5 2.5z" fill="' + color + '"/></svg>';
        }
        
        function addDeliveryMarkers(orders) {
            // Clear existing markers
            markers.forEach(marker => marker.setMap(null));
            markers = [];
            
            orders.forEach(order => {
                if (order.latitude && order.longitude) {
                    const marker = new google.maps.Marker({
                        position: { lat: order.latitude, lng: order.longitude },
                        map: map,
                        title: order.customerName,
                        icon: {
                            url: "data:image/svg+xml;charset=UTF-8," + encodeURIComponent(getDeliveryIcon(order.status)),
                            scaledSize: new google.maps.Size(32, 32),
                            anchor: new google.maps.Point(16, 32)
                        }
                    });
                    
                    const statusDisplayNames = {
                        'assigned': 'Chờ giao hàng',
                        'started': 'Đang giao hàng',
                        'inTransit': 'Đang giao hàng',
                        'delivered': 'Đã giao thành công',
                        'failed': 'Giao thất bại',
                        'cancelled': 'Đã hủy'
                    };
                    
                    const infoContent = \`
                        <div class="info-window">
                            <div class="info-title">\${order.id}</div>
                            <div class="info-address">👤 \${order.customerName}</div>
                            <div class="info-address">📍 \${order.customerAddress}</div>
                            <div class="info-phone">📞 \${order.customerPhone}</div>
                            <div class="status-badge status-\${order.status}">\${statusDisplayNames[order.status] || order.status}</div>
                        </div>
                    \`;
                    
                    const infoWindow = new google.maps.InfoWindow({
                        content: infoContent
                    });
                    
                    marker.addListener("click", () => {
                        infoWindow.open(map, marker);
                        // Notify Flutter about marker click
                        if (window.flutter_inappwebview) {
                            window.flutter_inappwebview.callHandler('onMarkerTap', order.id);
                        }
                    });
                    
                    markers.push(marker);
                }
            });
            
            // Adjust map bounds to show all markers
            if (markers.length > 0) {
                const bounds = new google.maps.LatLngBounds();
                markers.forEach(marker => bounds.extend(marker.getPosition()));
                if (currentLocationMarker) {
                    bounds.extend(currentLocationMarker.getPosition());
                }
                map.fitBounds(bounds);
                
                // Ensure minimum zoom level
                const listener = google.maps.event.addListener(map, "idle", function() {
                    if (map.getZoom() > 16) map.setZoom(16);
                    google.maps.event.removeListener(listener);
                });
            }
        }
        
        function focusOnOrder(orderId) {
            const order = orders.find(o => o.id === orderId);
            if (order && order.latitude && order.longitude) {
                map.setCenter({ lat: order.latitude, lng: order.longitude });
                map.setZoom(16);
            }
        }
        
        function getCurrentLocation() {
            if (currentLocationMarker) {
                map.setCenter(currentLocationMarker.getPosition());
                map.setZoom(16);
            }
        }
        
        // Global variable to store orders
        let orders = [];
    </script>
    
    <script async defer
        src="https://maps.googleapis.com/maps/api/js?key=AIzaSyBOti4mM-6x9WDnZIjIeyEU21OpBXqWBgw&callback=initMap">
    </script>
</body>
</html>
    ''';

    _controller?.loadHtmlString(htmlString);
  }

  void _addMarkersToMap() {
    if (widget.deliveryOrders.isNotEmpty) {
      final ordersJson = widget.deliveryOrders.map((order) => {
        'id': order.id,
        'customerName': order.customerName,
        'customerAddress': order.customerAddress,
        'customerPhone': order.customerPhone,
        'latitude': order.latitude,
        'longitude': order.longitude,
        'status': order.status.toString().split('.').last,
      }).toList();

      final jsCode = '''
        orders = ${_listToJsArray(ordersJson)};
        addDeliveryMarkers(orders);
      ''';

      _controller?.runJavaScript(jsCode);
    }
  }

  String _listToJsArray(List<Map<String, dynamic>> list) {
    final items = list.map((item) {
      final entries = item.entries.map((entry) {
        final value = entry.value is String ? '"${entry.value}"' : entry.value;
        return '"${entry.key}": $value';
      }).join(', ');
      return '{$entries}';
    }).join(', ');
    return '[$items]';
  }

  void _focusOnCurrentLocation() {
    _controller?.runJavaScript('getCurrentLocation();');
  }

  void _focusOnOrder(String orderId) {
    _controller?.runJavaScript('focusOnOrder("$orderId");');
  }

  Color _getStatusColor(DeliveryStatus status) {
    switch (status) {
      case DeliveryStatus.assigned:
        return AppColors.primary;
      case DeliveryStatus.started:
      case DeliveryStatus.inTransit:
        return AppColors.warning;
      case DeliveryStatus.delivered:
        return AppColors.success;
      case DeliveryStatus.failed:
        return AppColors.error;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Map controls
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCardBackground : AppColors.cardBackground,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            border: Border.all(
              color: isDark ? AppColors.darkDivider : AppColors.dividerColor,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.map,
                color: isDark ? AppColors.darkIconPrimary : AppColors.iconPrimary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Bản đồ giao hàng',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.text,
                ),
              ),
              const Spacer(),
              if (widget.currentLocation != null)
                IconButton(
                  onPressed: _focusOnCurrentLocation,
                  icon: Icon(
                    Icons.my_location,
                    color: isDark ? AppColors.darkIconPrimary : AppColors.iconPrimary,
                  ),
                  tooltip: 'Vị trí hiện tại',
                ),
              IconButton(
                onPressed: () {
                  _initializeWebView();
                },
                icon: Icon(
                  Icons.refresh,
                  color: isDark ? AppColors.darkIconSecondary : AppColors.iconSecondary,
                ),
                tooltip: 'Làm mới',
              ),
            ],
          ),
        ),

        // Map WebView
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              border: Border.all(
                color: isDark ? AppColors.darkDivider : AppColors.dividerColor,
              ),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              child: Stack(
                children: [
                  if (_isWebViewSupported)
                    WebViewWidget(controller: _controller!),

                  // Loading indicator
                  if (_isLoading)
                    Container(
                      color: isDark ? AppColors.darkSurface : Colors.white,
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Đang tải bản đồ...'),
                          ],
                        ),
                      ),
                    ),

                  // Error state
                  if (_error != null)
                    Container(
                      color: isDark ? AppColors.darkSurface : Colors.white,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 48,
                              color: AppColors.error,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _error = null;
                                });
                                _initializeWebView();
                              },
                              icon: const Icon(Icons.refresh),
                              label: const Text('Thử lại'),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Fallback for unsupported platforms
                  if (!_isWebViewSupported)
                    Container(
                      color: isDark ? AppColors.darkSurface : Colors.white,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.map_outlined,
                              size: 64,
                              color: isDark ? AppColors.darkIconSecondary : AppColors.iconSecondary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Bản đồ không khả dụng',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.text,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'WebView không được hỗ trợ trên nền tảng này',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 24),
                            if (widget.deliveryOrders.isNotEmpty) ...[
                              Text(
                                'Danh sách địa chỉ giao hàng:',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.text,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ...widget.deliveryOrders.take(3).map((order) => Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.darkCardBackground : AppColors.cardBackground,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isDark ? AppColors.darkDivider : AppColors.dividerColor,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      size: 16,
                                      color: _getStatusColor(order.status),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            order.customerName,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                              color: isDark ? AppColors.darkTextPrimary : AppColors.text,
                                            ),
                                          ),
                                          Text(
                                            order.customerAddress,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                              if (widget.deliveryOrders.length > 3)
                                Text(
                                  'Và ${widget.deliveryOrders.length - 3} địa chỉ khác...',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                  ),
                                ),
                            ],
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void didUpdateWidget(GoogleMapsWebView oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update markers when delivery orders change
    if (widget.deliveryOrders != oldWidget.deliveryOrders) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _addMarkersToMap();
      });
    }

    // Focus on selected order
    if (widget.selectedOrder != oldWidget.selectedOrder && widget.selectedOrder != null) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _focusOnOrder(widget.selectedOrder!.id);
      });
    }
  }
}
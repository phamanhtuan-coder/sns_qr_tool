import 'package:equatable/equatable.dart';

class DeliveryOrder extends Equatable {
  final String id;
  final String customerName;
  final String customerPhone;
  final String customerAddress;
  final String pickupAddress;
  final DateTime createdDate;
  final DateTime expectedDeliveryDate;
  final DeliveryStatus status;
  final List<DeliveryItem> items;
  final double totalAmount;
  final String? notes;
  final String? trackingCode;
  final DateTime? startedAt;
  final DateTime? deliveredAt;
  final String? deliveryPhoto;
  final String? deliveryNote;
  final bool isUrgent;
  final double? latitude;
  final double? longitude;

  const DeliveryOrder({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    required this.customerAddress,
    required this.pickupAddress,
    required this.createdDate,
    required this.expectedDeliveryDate,
    required this.status,
    required this.items,
    required this.totalAmount,
    this.notes,
    this.trackingCode,
    this.startedAt,
    this.deliveredAt,
    this.deliveryPhoto,
    this.deliveryNote,
    this.isUrgent = false,
    this.latitude,
    this.longitude,
  });

  factory DeliveryOrder.fromJson(Map<String, dynamic> json) {
    return DeliveryOrder(
      id: json['id'] as String,
      customerName: json['customer_name'] as String,
      customerPhone: json['customer_phone'] as String,
      customerAddress: json['customer_address'] as String,
      pickupAddress: json['pickup_address'] as String,
      createdDate: DateTime.parse(json['created_date'] as String),
      expectedDeliveryDate: DateTime.parse(json['expected_delivery_date'] as String),
      status: DeliveryStatus.values.firstWhere(
        (s) => s.toString().split('.').last == json['status'],
        orElse: () => DeliveryStatus.assigned,
      ),
      items: (json['items'] as List<dynamic>)
          .map((item) => DeliveryItem.fromJson(item))
          .toList(),
      totalAmount: (json['total_amount'] as num).toDouble(),
      notes: json['notes'] as String?,
      trackingCode: json['tracking_code'] as String?,
      startedAt: json['started_at'] != null ? DateTime.parse(json['started_at']) : null,
      deliveredAt: json['delivered_at'] != null ? DateTime.parse(json['delivered_at']) : null,
      deliveryPhoto: json['delivery_photo'] as String?,
      deliveryNote: json['delivery_note'] as String?,
      isUrgent: json['is_urgent'] as bool? ?? false,
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'customer_address': customerAddress,
      'pickup_address': pickupAddress,
      'created_date': createdDate.toIso8601String(),
      'expected_delivery_date': expectedDeliveryDate.toIso8601String(),
      'status': status.toString().split('.').last,
      'items': items.map((item) => item.toJson()).toList(),
      'total_amount': totalAmount,
      'notes': notes,
      'tracking_code': trackingCode,
      'started_at': startedAt?.toIso8601String(),
      'delivered_at': deliveredAt?.toIso8601String(),
      'delivery_photo': deliveryPhoto,
      'delivery_note': deliveryNote,
      'is_urgent': isUrgent,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  DeliveryOrder copyWith({
    String? id,
    String? customerName,
    String? customerPhone,
    String? customerAddress,
    String? pickupAddress,
    DateTime? createdDate,
    DateTime? expectedDeliveryDate,
    DeliveryStatus? status,
    List<DeliveryItem>? items,
    double? totalAmount,
    String? notes,
    String? trackingCode,
    DateTime? startedAt,
    DateTime? deliveredAt,
    String? deliveryPhoto,
    String? deliveryNote,
    bool? isUrgent,
    double? latitude,
    double? longitude,
  }) {
    return DeliveryOrder(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerAddress: customerAddress ?? this.customerAddress,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      createdDate: createdDate ?? this.createdDate,
      expectedDeliveryDate: expectedDeliveryDate ?? this.expectedDeliveryDate,
      status: status ?? this.status,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      notes: notes ?? this.notes,
      trackingCode: trackingCode ?? this.trackingCode,
      startedAt: startedAt ?? this.startedAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      deliveryPhoto: deliveryPhoto ?? this.deliveryPhoto,
      deliveryNote: deliveryNote ?? this.deliveryNote,
      isUrgent: isUrgent ?? this.isUrgent,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  bool get isOverdue => DateTime.now().isAfter(expectedDeliveryDate) &&
                      status != DeliveryStatus.delivered &&
                      status != DeliveryStatus.cancelled;

  Duration get timeUntilDeadline => expectedDeliveryDate.difference(DateTime.now());

  @override
  List<Object?> get props => [
        id,
        customerName,
        customerPhone,
        customerAddress,
        pickupAddress,
        createdDate,
        expectedDeliveryDate,
        status,
        items,
        totalAmount,
        notes,
        trackingCode,
        startedAt,
        deliveredAt,
        deliveryPhoto,
        deliveryNote,
        isUrgent,
        latitude,
        longitude,
      ];
}

class DeliveryItem extends Equatable {
  final String id;
  final String name;
  final int quantity;
  final double price;
  final String? description;

  const DeliveryItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.price,
    this.description,
  });

  factory DeliveryItem.fromJson(Map<String, dynamic> json) {
    return DeliveryItem(
      id: json['id'] as String,
      name: json['name'] as String,
      quantity: json['quantity'] as int,
      price: (json['price'] as num).toDouble(),
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'price': price,
      'description': description,
    };
  }

  @override
  List<Object?> get props => [id, name, quantity, price, description];
}

enum DeliveryStatus {
  assigned,    // Đã giao việc
  started,     // Đã bắt đầu giao
  inTransit,   // Đang vận chuyển
  delivered,   // Đã giao thành công
  failed,      // Giao thất bại
  cancelled,   // Đã hủy
}

extension DeliveryStatusExtension on DeliveryStatus {
  String get displayName {
    switch (this) {
      case DeliveryStatus.assigned:
        return 'Đã giao việc';
      case DeliveryStatus.started:
        return 'Đã bắt đầu';
      case DeliveryStatus.inTransit:
        return 'Đang giao hàng';
      case DeliveryStatus.delivered:
        return 'Đã giao thành công';
      case DeliveryStatus.failed:
        return 'Giao thất bại';
      case DeliveryStatus.cancelled:
        return 'Đã hủy';
    }
  }

  bool get canStart => this == DeliveryStatus.assigned;
  bool get canDeliver => this == DeliveryStatus.started || this == DeliveryStatus.inTransit;
  bool get isCompleted => this == DeliveryStatus.delivered || this == DeliveryStatus.failed || this == DeliveryStatus.cancelled;
}

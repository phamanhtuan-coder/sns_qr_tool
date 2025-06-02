import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_net_qr_scanner/data/models/user.dart';
import 'package:smart_net_qr_scanner/presentation/blocs/dashboard/dashboard_bloc.dart';

class Dashboard extends StatelessWidget {
  final User user;

  const Dashboard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final functions = [
      {
        'id': 'identify',
        'name': 'Xác định thiết bị',
        'description': 'Quét và xác định thiết bị',
        'icon': Icons.qr_code,
        'color': const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF2563EB)]),
        'shadowColor': const Color(0x403B82F6),
      },
      {
        'id': 'firmware',
        'name': 'Cập nhật Firmware',
        'description': 'Nạp firmware cho thiết bị',
        'icon': Icons.bolt,
        'color': const LinearGradient(colors: [Color(0xFFA855F7), Color(0xFF9333EA)]),
        'shadowColor': const Color(0x40A855F7),
      },
      {
        'id': 'testing',
        'name': 'Kiểm tra thiết bị',
        'description': 'Kiểm tra chất lượng',
        'icon': Icons.check_circle,
        'color': const LinearGradient(colors: [Color(0xFF22C55E), Color(0xFF16A34A)]),
        'shadowColor': const Color(0x4022C55E),
      },
      {
        'id': 'packaging',
        'name': 'Đóng gói thiết bị',
        'description': 'Chuẩn bị vận chuyển',
        'icon': Icons.inventory_2,
        'color': const LinearGradient(colors: [Color(0xFFEAB308), Color(0xFFD97706)]),
        'shadowColor': const Color(0x40EAB308),
      },
      {
        'id': 'stockin',
        'name': 'Nhập kho',
        'description': 'Tiếp nhận hàng vào kho',
        'icon': Icons.warehouse,
        'color': const LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF4338CA)]),
        'shadowColor': const Color(0x404F46E5),
      },
      {
        'id': 'stockout',
        'name': 'Xuất kho',
        'description': 'Vận chuyển và giao hàng',
        'icon': Icons.local_shipping,
        'color': const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFDC2626)]),
        'shadowColor': const Color(0x40EF4444),
      },
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: Theme.of(context).cardColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(Icons.person, size: 32, color: Color(0xFF2563EB)),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Xin chào, ${user.name}', style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(user.role, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                          const SizedBox(width: 8),
                          const Text('•', style: TextStyle(color: Colors.grey)),
                          const SizedBox(width: 8),
                          Text(user.department, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Chức năng sản xuất', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    const Text('Chọn một chức năng để quét mã QR', style: TextStyle(fontSize: 14, color: Colors.grey)),
                    const SizedBox(height: 32),
                    Expanded(
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.75,
                        ),
                        itemCount: functions.length,
                        itemBuilder: (context, index) {
                          final func = functions[index];
                          return GestureDetector(
                            onTap: () {
                              context.read<DashboardBloc>().add(SelectFunction(func['id'] as String));
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: func['color'] as LinearGradient,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [BoxShadow(color: func['shadowColor'] as Color, blurRadius: 10)],
                              ),
                              child: Stack(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(func['icon'] as IconData, size: 32, color: Colors.white),
                                        const SizedBox(height: 12),
                                        Text(
                                          func['name'] as String,
                                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          func['description'] as String,
                                          style: const TextStyle(fontSize: 12, color: Colors.white70),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_net_qr_scanner/data/models/user.dart';
import 'package:smart_net_qr_scanner/presentation/blocs/auth/auth_bloc.dart';
import 'package:smart_net_qr_scanner/presentation/blocs/dashboard/dashboard_bloc.dart';
import 'package:smart_net_qr_scanner/utils/app_colors.dart';

class Dashboard extends StatelessWidget {
  final User user;

  const Dashboard({
    Key? key,
    required this.user,
  }) : super(key: key);

  // Helper method to create colors with opacity
  Color _withOpacity(Color color, double opacity) {
    return Color.fromARGB(
      (opacity * 255).round(),
      (color.r * 255.0).round() & 0xff,
      (color.g * 255.0).round() & 0xff,
      (color.b * 255.0).round() & 0xff,
    );
  }

  @override
  Widget build(BuildContext context) {
    print('DEBUG: Building Dashboard with user: $user');

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        // Use the user from AuthState if available, otherwise use the provided user
        final currentUser = authState.user ?? user;
        print('DEBUG: Dashboard using user: $currentUser');

        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
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
          appBar: AppBar(
            backgroundColor: isDarkMode ? AppColors.darkHeaderBackground : AppColors.primary,
            elevation: 4,
            shadowColor: Colors.black26,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            toolbarHeight: 70,
            title: Row(
              children: [
                CircleAvatar(
                  backgroundColor: _withOpacity(Colors.white, 0.2),
                  child: const Icon(Icons.person,
                    size: 24,
                    color: Colors.white
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        currentUser.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white
                        ),
                      ),
                      Text(
                        currentUser.role,
                        style: TextStyle(
                          fontSize: 13,
                          color: _withOpacity(Colors.white, 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                onPressed: () => _showHelpDialog(context),
                icon: const Icon(Icons.help_outline, color: Colors.white),
                tooltip: 'Hướng dẫn sử dụng',
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: _withOpacity(Colors.black, 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDarkMode
                            ? _withOpacity(AppColors.primary, 0.2)
                            : _withOpacity(AppColors.primary, 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.settings_suggest_rounded,
                          color: AppColors.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Quy trình sản xuất',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? AppColors.darkTextPrimary : AppColors.text,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Chọn quy trình bạn muốn thực hiện',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDarkMode
                                  ? AppColors.darkTextSecondary
                                  : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _withOpacity(AppColors.primary, 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${functions.length} quy trình',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.1,
                    ),
                    itemCount: functions.length,
                    itemBuilder: (context, index) {
                      final func = functions[index];
                      return GestureDetector(
                        onTap: () {
                          context.read<DashboardBloc>().add(SelectFunction(func['id'] as String));
                        },
                        child: Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: func['color'] as LinearGradient,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Stack(
                              children: [
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: _withOpacity(Colors.white, 0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      '${index + 1}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        func['icon'] as IconData,
                                        size: 32,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        func['name'] as String,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        func['description'] as String,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: _withOpacity(Colors.white, 0.9),
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Theme.of(dialogContext).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _withOpacity(Theme.of(dialogContext).colorScheme.primary, 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.help_outline,
                color: Theme.of(dialogContext).colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Hướng dẫn sử dụng'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHelpItem(
                context: dialogContext,
                icon: Icons.grid_view_rounded,
                title: '1. Chọn quy trình',
                description: 'Chọn chức năng phù hợp với công việc của bạn'
              ),
              const SizedBox(height: 16),
              _buildHelpItem(
                context: dialogContext,
                icon: Icons.qr_code_scanner,
                title: '2. Quét mã QR',
                description: 'Đưa camera đến vị trí mã QR trên thiết bị'
              ),
              const SizedBox(height: 16),
              _buildHelpItem(
                context: dialogContext,
                icon: Icons.task_alt,
                title: '3. Thực hiện quy trình',
                description: 'Làm theo hướng dẫn trên màn hình để hoàn thành'
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('Đã hiểu',
              style: TextStyle(
                color: Theme.of(dialogContext).colorScheme.primary,
                fontWeight: FontWeight.w600
              )
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _withOpacity(Theme.of(context).colorScheme.primary, 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon,
            size: 24,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(description,
                style: TextStyle(
                  color: _withOpacity(
                    Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black,
                    0.7
                  ),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

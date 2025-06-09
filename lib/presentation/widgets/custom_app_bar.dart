import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_net_qr_scanner/presentation/blocs/auth/auth_bloc.dart';
import 'package:smart_net_qr_scanner/routes/app_router.dart';
import 'package:smart_net_qr_scanner/utils/app_colors.dart';
import 'package:smart_net_qr_scanner/utils/theme_provider.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showThemeSwitch;
  final bool automaticallyImplyLeading;
  final VoidCallback? onBackPressed;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showThemeSwitch = true,
    this.automaticallyImplyLeading = true,
    this.onBackPressed,
  });

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = Provider.of<ThemeProvider>(context);

    // Check if we're on a screen that should show back button
    final currentRoute = ModalRoute.of(context)?.settings.name;
    final canGoBack = automaticallyImplyLeading &&
                     currentRoute != AppRouter.splash &&
                     !(currentRoute == AppRouter.dashboard &&
                       Navigator.of(context).canPop() == false);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkHeaderBackground : AppColors.primary,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              // Back button if needed
              if (canGoBack)
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                  ),
                  onPressed: onBackPressed ?? () {
                    Navigator.maybePop(context);
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  iconSize: 24,
                ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.background,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (actions != null) ...actions!,
              if (showThemeSwitch) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => themeProvider.toggleTheme(),
                  icon: Icon(
                    isDark ? Icons.light_mode : Icons.dark_mode,
                    color: AppColors.background,
                  ),
                  tooltip: isDark ? 'Chế độ sáng' : 'Chế độ tối',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

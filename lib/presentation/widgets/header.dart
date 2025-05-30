import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit() : super(ThemeMode.system);

  void toggleTheme() {
    emit(state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light);
  }
}

class Header extends StatefulWidget {
  const Header({super.key});

  @override
  _HeaderState createState() => _HeaderState();
}

class _HeaderState extends State<Header> {
  double _zoom = 100;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).primaryColor,
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Firmware Deployment Tool',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          Row(
            children: [
              Text(
                '${_zoom.toInt()}%',
                style: const TextStyle(fontSize: 14, color: Colors.white),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.zoom_out, size: 18, color: Colors.white),
                onPressed: () => setState(() => _zoom = (_zoom - 10).clamp(70, 150)),
              ),
              IconButton(
                icon: const Icon(Icons.zoom_in, size: 18, color: Colors.white),
                onPressed: () => setState(() => _zoom = (_zoom + 10).clamp(70, 150)),
              ),
              IconButton(
                icon: const Icon(Icons.fullscreen, size: 18, color: Colors.white),
                onPressed: () {},
              ),
              IconButton(
                icon: Icon(
                  context.watch<ThemeCubit>().state == ThemeMode.dark ? Icons.wb_sunny : Icons.nightlight_round,
                  size: 18,
                  color: Colors.white,
                ),
                onPressed: () => context.read<ThemeCubit>().toggleTheme(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
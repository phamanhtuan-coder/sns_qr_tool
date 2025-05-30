import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LoginPage extends StatefulWidget {
  final Function({required String username, required String password, required bool remember}) onLogin;

  const LoginPage({super.key, required this.onLogin});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _remember = false;
  bool _showPassword = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 448),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
                  ),
                  child: SvgPicture.string(
                    '''
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                      <path d="M22 12h-4l-3 9L9 3l-3 9H2" />
                    </svg>
                    ''',
                    width: 48,
                    height: 48,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Firmware Deployment Tool',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Đăng nhập để tiếp tục',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                ),
                const SizedBox(height: 32),
                // Form
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        if (_error != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              border: Border.all(color: Colors.red.shade200),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, size: 16, color: Colors.red),
                                const SizedBox(width: 8),
                                Expanded(child: Text(_error!, style: const TextStyle(color: Colors.red))),
                              ],
                            ),
                          ),
                        TextField(
                          controller: _usernameController,
                          decoration: InputDecoration(
                            labelText: 'Tên đăng nhập',
                            prefixIcon: const Icon(Icons.person, size: 16),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _passwordController,
                          obscureText: !_showPassword,
                          decoration: InputDecoration(
                            labelText: 'Mật khẩu',
                            prefixIcon: const Icon(Icons.lock, size: 16),
                            suffixIcon: IconButton(
                              icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility, size: 16),
                              onPressed: () => setState(() => _showPassword = !_showPassword),
                            ),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Checkbox(
                                  value: _remember,
                                  onChanged: (value) => setState(() => _remember = value!),
                                ),
                                const Text('Ghi nhớ đăng nhập', style: TextStyle(fontSize: 14)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
                              setState(() => _error = 'Vui lòng điền đầy đủ thông tin đăng nhập');
                              return;
                            }
                            widget.onLogin(
                              username: _usernameController.text,
                              password: _passwordController.text,
                              remember: _remember,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Đăng nhập'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Phiên bản 1.0.0', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
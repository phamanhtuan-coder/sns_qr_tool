import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MobileLoginPage extends StatefulWidget {
  final Function({required String username, required String password, required bool remember}) onLogin;

  const MobileLoginPage({super.key, required this.onLogin});

  @override
  _MobileLoginPageState createState() => _MobileLoginPageState();
}

class _MobileLoginPageState extends State<MobileLoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _remember = false;
  bool _showPassword = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 384),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
                    ),
                    child: SvgPicture.string(
                      '''
                      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <path d="M22 12h-4l-3 9L9 3l-3 9H2" />
                      </svg>
                      ''',
                      width: 40,
                      height: 40,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Production QR Validator',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in to continue',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                  ),
                  const SizedBox(height: 32),
                  // Form
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          if (_error != null)
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                border: Border.all(color: Colors.red.shade200),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline, size: 14, color: Colors.red),
                                  const SizedBox(width: 8),
                                  Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                                ],
                              ),
                            ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _usernameController,
                            decoration: InputDecoration(
                              labelText: 'Username',
                              prefixIcon: const Icon(Icons.person, size: 16),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _passwordController,
                            obscureText: !_showPassword,
                            decoration: InputDecoration(
                              labelText: 'Password',
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
                            children: [
                              Checkbox(
                                value: _remember,
                                onChanged: (value) => setState(() => _remember = value!),
                              ),
                              const Text('Remember me', style: TextStyle(fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
                                setState(() => _error = 'Please enter your credentials');
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
                            child: const Text('Sign In'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Version 1.0.0', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
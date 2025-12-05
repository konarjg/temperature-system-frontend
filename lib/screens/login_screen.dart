import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_colors.dart';
import '../providers/auth_provider.dart';
import '../main_layout.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isObscure = true;
  bool _isRegistering = false; 

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.thermostat, color: AppColors.primaryBlue, size: 80),
                  const SizedBox(height: 32),
                  Text(
                    _isRegistering ? "Create Account" : "Welcome Back",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 48),

                  TextFormField(
                    controller: _emailController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: _inputDecoration("Email", Icons.email_outlined),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Please enter email';
                      if (!value.contains('@')) return 'Invalid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _isObscure,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: _inputDecoration("Password", Icons.lock_outline).copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isObscure ? Icons.visibility_off : Icons.visibility,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () => setState(() => _isObscure = !_isObscure),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Please enter password';
                      if (_isRegistering && value.length < 6) return 'Password too short (min 6)';
                      return null;
                    },
                  ),
                  
                  if (_isRegistering) ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _isObscure,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: _inputDecoration("Confirm Password", Icons.lock_clock_outlined),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Please confirm password';
                        if (value != _passwordController.text) return 'Passwords do not match';
                        return null;
                      },
                    ),
                  ],

                  const SizedBox(height: 32),
                  
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: authProvider.isLoading ? null : () async {
                        if (_formKey.currentState!.validate()) {
                          bool success;
                          if (_isRegistering) {
                            success = await authProvider.register(
                              _emailController.text, 
                              _passwordController.text
                            );
                          } else {
                            success = await authProvider.login(
                              _emailController.text, 
                              _passwordController.text
                            );
                          }

                          if (!context.mounted) return;

                          if (!success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(_isRegistering ? 'Registration Failed' : 'Login Failed'), 
                                backgroundColor: AppColors.error
                              ),
                            );
                            return;
                          }

                          if (authProvider.isAuthenticated) {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (_) => const MainLayout()),
                            );
                          } else if (_isRegistering) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Account created! Please check your email to verify.'), 
                                backgroundColor: Colors.green
                              ),
                            );

                            setState(() {
                              _isRegistering = false;
                              _passwordController.clear();
                              _confirmPasswordController.clear();
                            });
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: authProvider.isLoading 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(_isRegistering ? "Register" : "Log In", style: const TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isRegistering = !_isRegistering;
                        _formKey.currentState?.reset();
                        _emailController.clear();
                        _passwordController.clear();
                        _confirmPasswordController.clear();
                      });
                    },
                    child: Text(
                      _isRegistering 
                        ? "Already have an account? Log In" 
                        : "Don't have an account? Register",
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.textSecondary),
      prefixIcon: Icon(icon, color: AppColors.textSecondary),
      filled: true,
      fillColor: AppColors.cardSurface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryBlue)),
      errorStyle: const TextStyle(color: AppColors.error),
    );
  }
}
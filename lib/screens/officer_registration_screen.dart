import 'package:copmap_flutter/models/user_role.dart';
import 'package:copmap_flutter/services/auth_service.dart';
import 'package:copmap_flutter/services/database_service.dart';
import 'package:copmap_flutter/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class OfficerRegistrationScreen extends StatefulWidget {
  const OfficerRegistrationScreen({super.key});

  @override
  State<OfficerRegistrationScreen> createState() => _OfficerRegistrationScreenState();
}

class _OfficerRegistrationScreenState extends State<OfficerRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final _dbService = DatabaseService();
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _badgeController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _badgeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Create Firebase Auth user
      final userCredential = await _authService.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Update user profile with name
      await userCredential.user?.updateDisplayName(_nameController.text.trim());

      // Create officer record in Firestore
      await _dbService.createOfficerFromUser(
        userCredential.user!,
        badgeNumber: _badgeController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration successful! You can now login.'),
            backgroundColor: AppTheme.statusActive,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration failed: $e'),
            backgroundColor: AppTheme.statusOffline,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = _emailController.text.trim();
    final role = UserRoleExtension.determineRoleFromEmail(email);
    final isStationMaster = role == UserRole.stationMaster;
    
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(isStationMaster ? 'Station Master Registration' : 'Field Officer Registration'),
        backgroundColor: AppTheme.background,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isStationMaster ? 'Register as Station Master' : 'Register as Field Officer',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isStationMaster 
                    ? 'Create your station master account to manage duties and monitor officers'
                    : 'Create your field officer account to receive duties and track location',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),

              // Role Information Card
              if (email.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isStationMaster 
                        ? AppTheme.primary.withValues(alpha: 0.1)
                        : AppTheme.statusActive.withValues(alpha: 0.1),
                    border: Border.all(
                      color: isStationMaster 
                          ? AppTheme.primary.withValues(alpha: 0.3)
                          : AppTheme.statusActive.withValues(alpha: 0.3),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isStationMaster ? LucideIcons.shield : LucideIcons.users,
                        color: isStationMaster ? AppTheme.primary : AppTheme.statusActive,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Role: ${role.displayName}',
                              style: TextStyle(
                                color: isStationMaster ? AppTheme.primary : AppTheme.statusActive,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              isStationMaster 
                                  ? 'You will have access to the web dashboard'
                                  : 'You will have access to the mobile app',
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              // Name Field
              _buildTextField(
                controller: _nameController,
                label: 'Full Name',
                hint: 'Enter your full name',
                icon: LucideIcons.user,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your full name';
                  }
                  if (value.trim().length < 3) {
                    return 'Name must be at least 3 characters';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Email Field
              _buildTextField(
                controller: _emailController,
                label: 'Email Address',
                hint: isStationMaster 
                    ? 'Enter stationmaster@gmail.com'
                    : 'Enter your email address',
                icon: LucideIcons.mail,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your email address';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
                onChanged: (value) {
                  // Trigger rebuild to update role information
                  setState(() {});
                },
              ),

              const SizedBox(height: 20),

              // Badge Number Field
              _buildTextField(
                controller: _badgeController,
                label: 'Badge Number',
                hint: 'Enter your badge number',
                icon: LucideIcons.shield,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your badge number';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Password Field
              _buildTextField(
                controller: _passwordController,
                label: 'Password',
                hint: 'Enter your password',
                icon: LucideIcons.lock,
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? LucideIcons.eye : LucideIcons.eyeOff,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Confirm Password Field
              _buildTextField(
                controller: _confirmPasswordController,
                label: 'Confirm Password',
                hint: 'Confirm your password',
                icon: LucideIcons.lock,
                obscureText: _obscureConfirmPassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword ? LucideIcons.eye : LucideIcons.eyeOff,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                  },
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your password';
                  }
                  if (value != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 32),

              // Register Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isStationMaster ? AppTheme.primary : AppTheme.statusActive,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Register as ${role.displayName}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                ),
              ),

              const SizedBox(height: 24),

              // Login Link
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Already have an account? ',
                      style: TextStyle(color: Colors.grey),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Login',
                        style: TextStyle(color: AppTheme.primary),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Role Information
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          LucideIcons.info,
                          color: Colors.grey,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Role Assignment',
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'stationmaster@gmail.com → Station Master (Web Dashboard)\nfieldofficer@gmail.com → Field Officer (Mobile App)',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          onChanged: onChanged,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey),
            prefixIcon: Icon(icon, color: Colors.grey),
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.secondary),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.secondary),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.primary),
            ),
            filled: true,
            fillColor: AppTheme.background,
          ),
        ),
      ],
    );
  }
}

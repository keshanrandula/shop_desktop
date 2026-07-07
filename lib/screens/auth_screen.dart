import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../widgets/custom_button.dart';
import '../utils/theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();

  // Login Controllers
  final TextEditingController _loginUsername = TextEditingController();
  final TextEditingController _loginPassword = TextEditingController();

  // Register Controllers
  final TextEditingController _regUsername = TextEditingController();
  final TextEditingController _regPassword = TextEditingController();
  final TextEditingController _regConfirmPassword = TextEditingController();
  String _selectedRole = 'Cashier'; // Default role

  bool _obscureLoginPassword = true;
  bool _obscureRegPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginUsername.dispose();
    _loginPassword.dispose();
    _regUsername.dispose();
    _regPassword.dispose();
    _regConfirmPassword.dispose();
    super.dispose();
  }

  void _handleLogin(AppState appState) async {
    if (!_loginFormKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);

    final success = await appState.login(
      _loginUsername.text.trim(),
      _loginPassword.text,
    );

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully authenticated! Welcome back.'),
            backgroundColor: AppTheme.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid username or password. Please try again.'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  void _handleRegister(AppState appState) async {
    if (!_registerFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final success = await appState.register(
      _regUsername.text.trim(),
      _regPassword.text,
      _selectedRole,
    );

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account registered successfully! You can now log in.'),
            backgroundColor: AppTheme.success,
          ),
        );
        _tabController.animateTo(0); // Switch to login tab
        _loginUsername.text = _regUsername.text; // Autofill login username
        _regUsername.clear();
        _regPassword.clear();
        _regConfirmPassword.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration failed. Username might already exist.'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      body: Stack(
        children: [
          // Elegant decorative gradient background circles
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primary.withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            right: -100,
            child: Container(
              width: 450,
              height: 450,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.secondary.withOpacity(0.06),
              ),
            ),
          ),

          // Central Card Container
          Center(
            child: SingleChildScrollView(
              child: Card(
                elevation: 12,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: const BorderSide(color: AppTheme.border, width: 1.5),
                ),
                child: Container(
                  width: 440,
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo branding
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppTheme.primary, AppTheme.secondary],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'ShopPOS Systems',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.textPrimary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // Tabs selector
                      TabBar(
                        controller: _tabController,
                        tabs: const [
                          Tab(text: 'LOGIN'),
                          Tab(text: 'REGISTER'),
                        ],
                        indicatorColor: AppTheme.primaryLight,
                        indicatorSize: TabBarIndicatorSize.tab,
                        labelColor: AppTheme.textPrimary,
                        unselectedLabelColor: AppTheme.textSecondary,
                        dividerColor: Colors.transparent,
                        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 24),

                      // Tabs contents height wrapper
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: _tabController.index == 0 ? 250 : 390,
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            // 1. LOGIN PANEL
                            Form(
                              key: _loginFormKey,
                              child: Column(
                                children: [
                                  TextFormField(
                                    controller: _loginUsername,
                                    decoration: const InputDecoration(
                                      labelText: 'Username',
                                      prefixIcon: Icon(Icons.person_outline_rounded),
                                    ),
                                    validator: (val) => val == null || val.trim().isEmpty
                                        ? 'Please enter your username'
                                        : null,
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _loginPassword,
                                    obscureText: _obscureLoginPassword,
                                    decoration: InputDecoration(
                                      labelText: 'Password',
                                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                                      suffixIcon: GestureDetector(
                                        onTap: () => setState(() =>
                                            _obscureLoginPassword = !_obscureLoginPassword),
                                        child: Icon(
                                          _obscureLoginPassword
                                              ? Icons.visibility_off_rounded
                                              : Icons.visibility_rounded,
                                        ),
                                      ),
                                    ),
                                    validator: (val) => val == null || val.isEmpty
                                        ? 'Please enter your password'
                                        : null,
                                  ),
                                  const Spacer(),
                                  CustomButton(
                                    text: 'LOG IN',
                                    icon: Icons.login_rounded,
                                    width: double.infinity,
                                    isLoading: _isLoading,
                                    onPressed: () => _handleLogin(appState),
                                  ),
                                ],
                              ),
                            ),

                            // 2. REGISTER PANEL
                            Form(
                              key: _registerFormKey,
                              child: SingleChildScrollView(
                                child: Column(
                                  children: [
                                    TextFormField(
                                      controller: _regUsername,
                                      decoration: const InputDecoration(
                                        labelText: 'Desired Username',
                                        prefixIcon: Icon(Icons.person_add_alt_1_rounded),
                                      ),
                                      validator: (val) => val == null || val.trim().isEmpty
                                          ? 'Please enter a username'
                                          : null,
                                    ),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      controller: _regPassword,
                                      obscureText: _obscureRegPassword,
                                      decoration: InputDecoration(
                                        labelText: 'Choose Password',
                                        prefixIcon: const Icon(Icons.lock_open_rounded),
                                        suffixIcon: GestureDetector(
                                          onTap: () => setState(() =>
                                              _obscureRegPassword = !_obscureRegPassword),
                                          child: Icon(
                                            _obscureRegPassword
                                                ? Icons.visibility_off_rounded
                                                : Icons.visibility_rounded,
                                          ),
                                        ),
                                      ),
                                      validator: (val) => val == null || val.length < 4
                                          ? 'Password must be at least 4 characters'
                                          : null,
                                    ),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      controller: _regConfirmPassword,
                                      obscureText: _obscureConfirmPassword,
                                      decoration: InputDecoration(
                                        labelText: 'Confirm Password',
                                        prefixIcon: const Icon(Icons.lock_rounded),
                                        suffixIcon: GestureDetector(
                                          onTap: () => setState(() =>
                                              _obscureConfirmPassword = !_obscureConfirmPassword),
                                          child: Icon(
                                            _obscureConfirmPassword
                                                ? Icons.visibility_off_rounded
                                                : Icons.visibility_rounded,
                                          ),
                                        ),
                                      ),
                                      validator: (val) {
                                        if (val != _regPassword.text) {
                                          return 'Passwords do not match';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    // Role dropdown selector
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('Select Role:',
                                            style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
                                        DropdownButton<String>(
                                          value: _selectedRole,
                                          dropdownColor: AppTheme.surfaceSecondary,
                                          style: const TextStyle(
                                              color: AppTheme.textPrimary,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14),
                                          underline: const SizedBox(),
                                          onChanged: (val) {
                                            if (val != null) {
                                              setState(() => _selectedRole = val);
                                            }
                                          },
                                          items: ['Cashier', 'Admin']
                                              .map((role) => DropdownMenuItem(
                                                  value: role, child: Text(role)))
                                              .toList(),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 24),
                                    CustomButton(
                                      text: 'CREATE ACCOUNT',
                                      icon: Icons.how_to_reg_rounded,
                                      width: double.infinity,
                                      isLoading: _isLoading,
                                      onPressed: () => _handleRegister(appState),
                                      type: ButtonType.success,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

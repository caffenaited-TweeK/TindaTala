import 'package:flutter/material.dart';

import '../data/app_store.dart';
import '../theme.dart';
import '../widgets/common_widgets.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey('splash-screen'),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [TindaColors.cream, Color(0xFFFFF1D3)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const _AwningRibbon(),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const TindaLogo(size: 136),
                      const SizedBox(height: 18),
                      Text(
                        'TindaTala',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontSize: 32),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'A little tala for your tindahan.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 26),
                      const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 3),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Getting your store ready…',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.store});

  final AppStore store;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  final _storeNameController = TextEditingController(
    text: 'Aling Nena’s Tindahan',
  );
  bool _isRegistering = false;
  bool _hidePassword = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmationController.dispose();
    _storeNameController.dispose();
    super.dispose();
  }

  void _switchMode() {
    setState(() {
      _isRegistering = !_isRegistering;
      _errorMessage = null;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isRegistering &&
        _passwordController.text != _confirmationController.text) {
      setState(() => _errorMessage = 'The passwords do not match.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      if (_isRegistering) {
        await widget.store.register(
          _usernameController.text,
          _passwordController.text,
          storeName: _storeNameController.text,
        );
      } else {
        await widget.store.login(
          _usernameController.text,
          _passwordController.text,
        );
      }
    } catch (error) {
      if (mounted) setState(() => _errorMessage = readableError(error));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: const _AwningRibbon(key: ValueKey('auth-awning-ribbon')),
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Center(child: TindaLogo(size: 112)),
                          const SizedBox(height: 14),
                          Text(
                            _isRegistering
                                ? 'Open your tindahan'
                                : 'Maayong adlaw!',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 7),
                          Text(
                            _isRegistering
                                ? 'Create a local account for your store notebook.'
                                : 'Sign in to your TindaTala store notebook.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 24),
                          if (_isRegistering) ...[
                            _label(context, 'Store name'),
                            TextFormField(
                              key: const ValueKey('auth-store-name-field'),
                              controller: _storeNameController,
                              textCapitalization: TextCapitalization.words,
                              decoration: const InputDecoration(
                                hintText: 'Aling Nena’s Tindahan',
                                prefixIcon: Icon(Icons.storefront_outlined),
                              ),
                              validator: (value) =>
                                  value == null || value.trim().isEmpty
                                  ? 'Enter your store name.'
                                  : null,
                            ),
                            const SizedBox(height: 14),
                          ],
                          _label(context, 'Username'),
                          TextFormField(
                            key: const ValueKey('auth-username-field'),
                            controller: _usernameController,
                            textCapitalization: TextCapitalization.none,
                            autocorrect: false,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              hintText: 'Your username',
                              prefixIcon: Icon(Icons.person_outline_rounded),
                            ),
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                ? 'Enter your username.'
                                : null,
                          ),
                          const SizedBox(height: 14),
                          _label(context, 'Password'),
                          TextFormField(
                            key: const ValueKey('auth-password-field'),
                            controller: _passwordController,
                            obscureText: _hidePassword,
                            textInputAction: _isRegistering
                                ? TextInputAction.next
                                : TextInputAction.done,
                            onFieldSubmitted: (_) {
                              if (!_isRegistering) _submit();
                            },
                            decoration: InputDecoration(
                              hintText: 'Your password',
                              prefixIcon: const Icon(
                                Icons.lock_outline_rounded,
                              ),
                              suffixIcon: IconButton(
                                tooltip: _hidePassword
                                    ? 'Show password'
                                    : 'Hide password',
                                onPressed: () => setState(
                                  () => _hidePassword = !_hidePassword,
                                ),
                                icon: Icon(
                                  _hidePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Enter your password.';
                              }
                              if (_isRegistering && value.length < 6) {
                                return 'Use at least 6 characters.';
                              }
                              return null;
                            },
                          ),
                          if (_isRegistering) ...[
                            const SizedBox(height: 14),
                            _label(context, 'Confirm password'),
                            TextFormField(
                              key: const ValueKey(
                                'auth-confirm-password-field',
                              ),
                              controller: _confirmationController,
                              obscureText: _hidePassword,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _submit(),
                              decoration: const InputDecoration(
                                hintText: 'Enter your password again',
                                prefixIcon: Icon(Icons.lock_outline_rounded),
                              ),
                              validator: (value) =>
                                  value == null || value.isEmpty
                                  ? 'Confirm your password.'
                                  : null,
                            ),
                          ],
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 12),
                            _ErrorBanner(message: _errorMessage!),
                          ],
                          const SizedBox(height: 20),
                          FilledButton.icon(
                            key: const ValueKey('auth-submit-button'),
                            onPressed: _isSubmitting ? null : _submit,
                            icon: _isSubmitting
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: TindaColors.ivory,
                                    ),
                                  )
                                : Icon(
                                    _isRegistering
                                        ? Icons.storefront_outlined
                                        : Icons.login_rounded,
                                  ),
                            label: Text(
                              _isRegistering ? 'Create account' : 'Sign in',
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed: _isSubmitting ? null : _switchMode,
                            child: Text(
                              _isRegistering
                                  ? 'Already have an account? Sign in'
                                  : 'New to TindaTala? Create an account',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your store data stays saved on this device.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(BuildContext context, String label) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(label, style: Theme.of(context).textTheme.titleMedium),
  );
}

class _AwningRibbon extends StatelessWidget {
  const _AwningRibbon({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 18,
      child: Row(
        children: List.generate(
          10,
          (index) => Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: index.isEven ? TindaColors.red : TindaColors.cream,
                border: Border.all(color: TindaColors.brown, width: 0.6),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(7),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFBE8E1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TindaColors.error),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: TindaColors.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: TindaColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

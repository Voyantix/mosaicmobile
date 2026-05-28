import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'escape_back_wrapper.dart';
import 'game_content.dart';
import 'voyantix_auth_service.dart';

class CloudSavesScreen extends StatefulWidget {
  const CloudSavesScreen({super.key});

  @override
  State<CloudSavesScreen> createState() => _CloudSavesScreenState();
}

class _CloudSavesScreenState extends State<CloudSavesScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  StreamSubscription<AuthState>? _authSubscription;
  bool _isSignUp = false;
  bool _isSubmitting = false;
  String? _message;

  User? get _currentUser => VoyantixAuthService.currentUser;

  @override
  void initState() {
    super.initState();
    _authSubscription = VoyantixAuthService.authStateChanges?.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _message = 'Enter your email and password.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _message = null;
    });

    try {
      if (_isSignUp) {
        await VoyantixAuthService.signUp(email: email, password: password);
        setState(() {
          _message = 'Account created. Check your email if confirmation is on.';
        });
      } else {
        await VoyantixAuthService.signIn(email: email, password: password);
        setState(() => _message = null);
      }
    } on AuthException catch (error) {
      setState(() => _message = error.message);
    } catch (_) {
      setState(() => _message = 'Could not connect to Voyantix right now.');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _signOut() async {
    setState(() {
      _isSubmitting = true;
      _message = null;
    });

    try {
      await VoyantixAuthService.signOut();
      setState(() => _message = 'Signed out.');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _goBack() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return EscapeBackWrapper(
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              mosaicSceneAsset,
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: ColoredBox(color: Colors.black.withValues(alpha: 0.74)),
            ),
            SafeArea(
              child: Stack(
                children: [
                  Positioned(
                    left: 72,
                    top: 56,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 44,
                        minHeight: 44,
                      ),
                      alignment: Alignment.centerLeft,
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white70),
                      onPressed: _goBack,
                    ),
                  ),
                  Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(72, 104, 72, 64),
                      child: Align(
                        alignment: Alignment.center,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 760),
                          child: _currentUser == null
                              ? _buildSignedOut()
                              : _buildSignedIn(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignedOut() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'ACCOUNT',
          style: TextStyle(
            fontFamily: 'Orbitron',
            fontSize: 38,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 4,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Sign in with a free Voyantix account to back up your progress to the cloud.',
          style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
        ),
        const SizedBox(height: 24),
        _CloudPanel(
          child: VoyantixAuthService.isReady
              ? _buildAuthForm()
              : const _CloudMessage(
                  title: 'Voyantix auth is not configured',
                  body:
                      'Add the Supabase anon key at build time with VOYANTIX_SUPABASE_ANON_KEY to enable login.',
                ),
        ),
      ],
    );
  }

  Widget _buildSignedIn() {
    final user = _currentUser;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'VOYANTIX PROFILE',
          style: TextStyle(
            fontFamily: 'Orbitron',
            fontSize: 38,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 4,
          ),
        ),
        const SizedBox(height: 24),
        _CloudPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'SIGNED IN',
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  color: Color(0xFFD8D3C8),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                user?.email ?? 'Voyantix account',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 12),
              const Text(
                'Your Mosaic progress is linked to this Voyantix account.',
                style: TextStyle(color: Colors.white70, height: 1.45),
              ),
              if (_message != null) ...[
                const SizedBox(height: 16),
                Text(_message!, style: const TextStyle(color: Colors.white70)),
              ],
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: _isSubmitting ? null : _signOut,
                icon: const Icon(Icons.logout_rounded),
                label: const Text('SIGN OUT'),
                style: _cloudButtonStyle(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAuthForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _isSignUp ? 'CREATE ACCOUNT' : 'LOGIN',
          style: const TextStyle(
            fontFamily: 'Orbitron',
            color: Color(0xFFD8D3C8),
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          style: const TextStyle(color: Colors.white),
          decoration: _fieldDecoration('Email'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _passwordController,
          obscureText: true,
          autofillHints: const [AutofillHints.password],
          style: const TextStyle(color: Colors.white),
          decoration: _fieldDecoration('Password'),
          onSubmitted: (_) => _submit(),
        ),
        if (_message != null) ...[
          const SizedBox(height: 14),
          Text(_message!, style: const TextStyle(color: Colors.white70)),
        ],
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: _isSubmitting ? null : _submit,
          icon: Icon(_isSignUp ? Icons.person_add_alt_1 : Icons.login_rounded),
          label: Text(_isSignUp ? 'CREATE ACCOUNT' : 'LOGIN'),
          style: _cloudButtonStyle(isPrimary: true),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: _isSubmitting
              ? null
              : () {
                  setState(() {
                    _isSignUp = !_isSignUp;
                    _message = null;
                  });
                },
          style: _cloudButtonStyle(),
          child: Text(_isSignUp ? 'I ALREADY HAVE AN ACCOUNT' : 'SIGN UP'),
        ),
      ],
    );
  }

  InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.16)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Color(0xFFD8D3C8)),
      ),
    );
  }
}

class _CloudPanel extends StatelessWidget {
  const _CloudPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: child,
      ),
    );
  }
}

class _CloudMessage extends StatelessWidget {
  const _CloudMessage({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontFamily: 'Orbitron',
            color: Color(0xFFD8D3C8),
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 12),
        Text(body, style: const TextStyle(color: Colors.white70, height: 1.45)),
      ],
    );
  }
}

ButtonStyle _cloudButtonStyle({bool isPrimary = false}) {
  return FilledButton.styleFrom(
    backgroundColor: isPrimary ? Colors.white : Colors.transparent,
    foregroundColor: isPrimary ? Colors.black : Colors.white,
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
    textStyle: const TextStyle(
      fontFamily: 'Orbitron',
      fontSize: 12,
      fontWeight: FontWeight.bold,
      letterSpacing: 1.5,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(6),
      side: BorderSide(
        color: isPrimary ? Colors.white : Colors.white.withValues(alpha: 0.18),
      ),
    ),
  );
}

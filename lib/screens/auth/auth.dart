import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../theme/tokens.dart';
import '../../widgets/common.dart';

String authMessage(FirebaseAuthException e) => switch (e.code) {
      'invalid-email' => 'That doesn’t look like an email address.',
      'user-not-found' ||
      'wrong-password' ||
      'invalid-credential' ||
      'invalid-login-credentials' =>
        'That email and password don’t match an account.',
      'email-already-in-use' =>
        'There’s already an account with that email. Try signing in.',
      'weak-password' => 'Use at least 6 characters for your password.',
      'too-many-requests' => 'Too many attempts. Wait a minute and try again.',
      'network-request-failed' => 'No connection. Check your internet and retry.',
      'user-disabled' => 'This account has been disabled.',
      _ => 'Something went wrong. Please try again.',
    };

class DfLogo extends StatelessWidget {
  const DfLogo({super.key, this.size = 56});
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.df;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: c.primary,
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: DfShadow.floating,
      ),
      child: Icon(LucideIcons.check, color: Colors.white, size: size * 0.54),
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.df;
    const points = [
      (LucideIcons.flame, 'Build a streak', 'Finish one task a day to keep it going.'),
      (LucideIcons.calendar, 'See your whole day', 'Tasks and calendar events in one place.'),
      (LucideIcons.chartColumn, 'Know where time goes', 'A heatmap and a breakdown by tag.'),
    ];
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(DfSpace.s6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              const DfLogo(),
              const SizedBox(height: DfSpace.s6),
              Text('Plan the day.\nKeep the streak.',
                  style: DfText.display.copyWith(color: c.text)),
              const SizedBox(height: DfSpace.s3),
              Text(
                'Tasks, reminders and your calendar in one place.',
                style: DfText.body.copyWith(color: c.textSecondary),
              ),
              const SizedBox(height: DfSpace.s8),
              for (final (icon, title, body) in points)
                Padding(
                  padding: const EdgeInsets.only(bottom: DfSpace.s4),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: c.primarySoft,
                          borderRadius: BorderRadius.circular(DfRadius.md),
                        ),
                        child: Icon(icon, size: 20, color: c.primary),
                      ),
                      const SizedBox(width: DfSpace.s3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title,
                                style:
                                    DfText.bodyStrong.copyWith(color: c.text)),
                            Text(body,
                                style: DfText.small
                                    .copyWith(color: c.textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              const Spacer(flex: 2),
              DfButton(
                label: 'Create an account',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AuthFormScreen(signUp: true)),
                ),
              ),
              const SizedBox(height: DfSpace.s3),
              DfButton(
                label: 'I already have an account',
                kind: DfButtonKind.secondary,
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AuthFormScreen(signUp: false)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AuthFormScreen extends StatefulWidget {
  const AuthFormScreen({super.key, required this.signUp});
  final bool signUp;

  @override
  State<AuthFormScreen> createState() => _AuthFormScreenState();
}

class _AuthFormScreenState extends State<AuthFormScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _show = false;
  bool _busy = false;
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    final password = _password.text;
    setState(() {
      _emailError = email.isEmpty ? 'Enter your email.' : null;
      _passwordError = password.isEmpty ? 'Enter your password.' : null;
    });
    if (_emailError != null || _passwordError != null) return;

    setState(() => _busy = true);
    try {
      if (widget.signUp) {
        final cred = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);
        final name = _name.text.trim();
        if (name.isNotEmpty) {
          await cred.user?.updateDisplayName(name);
          await cred.user?.reload();
        }
      } else {
        await FirebaseAuth.instance
            .signInWithEmailAndPassword(email: email, password: password);
      }
      // The auth gate swaps in the app; clear this route off the stack.
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final message = authMessage(e);
      setState(() {
        _busy = false;
        if (e.code == 'invalid-email' || e.code == 'email-already-in-use') {
          _emailError = message;
        } else {
          _passwordError = message;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _passwordError = 'Something went wrong. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.df;
    final signUp = widget.signUp;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              DfSpace.s6, DfSpace.s2, DfSpace.s6, DfSpace.s4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DfIconButton(
                icon: LucideIcons.chevronLeft,
                semanticLabel: 'Back',
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(top: DfSpace.s4),
                  child: AutofillGroup(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(signUp ? 'Create your account' : 'Welcome back',
                            style: DfText.h1.copyWith(color: c.text)),
                        const SizedBox(height: 4),
                        Text(
                          signUp
                              ? 'Start your first streak today.'
                              : 'Sign in to pick up your streak.',
                          style:
                              DfText.body.copyWith(color: c.textSecondary),
                        ),
                        const SizedBox(height: DfSpace.s6),
                        if (signUp) ...[
                          DfTextField(
                            controller: _name,
                            label: 'Name',
                            hint: 'What should we call you?',
                            icon: LucideIcons.user,
                            autofillHints: const [AutofillHints.givenName],
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: DfSpace.s4),
                        ],
                        DfTextField(
                          controller: _email,
                          label: 'Email',
                          hint: 'you@example.com',
                          icon: LucideIcons.mail,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          error: _emailError,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: DfSpace.s4),
                        DfTextField(
                          controller: _password,
                          label: 'Password',
                          hint: signUp ? 'At least 6 characters' : null,
                          icon: LucideIcons.lock,
                          obscure: !_show,
                          autofillHints: [
                            signUp
                                ? AutofillHints.newPassword
                                : AutofillHints.password
                          ],
                          error: _passwordError,
                          onSubmitted: (_) => _submit(),
                          suffix: IconButton(
                            tooltip: _show ? 'Hide password' : 'Show password',
                            icon: Icon(
                                _show ? LucideIcons.eyeOff : LucideIcons.eye,
                                size: 20,
                                color: c.textMuted),
                            onPressed: () => setState(() => _show = !_show),
                          ),
                        ),
                        if (!signUp)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ResetPasswordScreen(
                                      email: _email.text.trim()),
                                ),
                              ),
                              child: Text('Forgot password?',
                                  style: DfText.smallStrong
                                      .copyWith(color: c.primary)),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              DfButton(
                label: signUp ? 'Create account' : 'Sign in',
                loading: _busy,
                onPressed: _submit,
              ),
              const SizedBox(height: DfSpace.s3),
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (_) => AuthFormScreen(signUp: !signUp)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Text.rich(
                      TextSpan(
                        text: signUp
                            ? 'Already have an account? '
                            : 'New to DayFlow? ',
                        style: DfText.small.copyWith(color: c.textSecondary),
                        children: [
                          TextSpan(
                            text: signUp ? 'Sign in' : 'Create an account',
                            style: DfText.smallStrong
                                .copyWith(color: c.primary),
                          ),
                        ],
                      ),
                    ),
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

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key, this.email = ''});
  final String email;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  late final _email = TextEditingController(text: widget.email);
  bool _busy = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final email = _email.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Enter your email.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) setState(() => _sent = true);
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _error = authMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.df;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              DfSpace.s6, DfSpace.s2, DfSpace.s6, DfSpace.s4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DfIconButton(
                icon: LucideIcons.chevronLeft,
                semanticLabel: 'Back',
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(height: DfSpace.s4),
              Text('Reset your password',
                  style: DfText.h1.copyWith(color: c.text)),
              const SizedBox(height: 4),
              Text(
                _sent
                    ? 'If an account exists for that email, a reset link is on its way. Check your inbox.'
                    : 'Enter your email and we’ll send you a link to set a new one.',
                style: DfText.body.copyWith(color: c.textSecondary),
              ),
              const SizedBox(height: DfSpace.s6),
              if (!_sent)
                DfTextField(
                  controller: _email,
                  label: 'Email',
                  hint: 'you@example.com',
                  icon: LucideIcons.mail,
                  keyboardType: TextInputType.emailAddress,
                  error: _error,
                  onSubmitted: (_) => _send(),
                ),
              const Spacer(),
              DfButton(
                label: _sent ? 'Back to sign in' : 'Send reset link',
                loading: _busy,
                onPressed: _sent ? () => Navigator.pop(context) : _send,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

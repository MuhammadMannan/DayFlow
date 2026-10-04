import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../theme/tokens.dart';
import '../../widgets/common.dart';

String authMessage(FirebaseAuthException e) => switch (e.code) {
      'invalid-email' => 'That doesn’t look like an email address.',
      'user-not-found' ||
      'wrong-password' ||
      'invalid-credential' ||
      'invalid-login-credentials' =>
        'That password doesn’t match this account.',
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
    // The preview cards always use the light palette on the blue backdrop.
    const light = DfColors.light;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: light.primary,
        body: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _BackdropPainter())),
            Column(
              children: [
                // A sample day, to show what the app looks like in use.
                Expanded(
                  child: SafeArea(
                    bottom: false,
                    child: ExcludeSemantics(
                      child: Center(
                        child: SingleChildScrollView(
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 36, vertical: DfSpace.s4),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _Pill(
                                    color: light.flameSoft,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(LucideIcons.flame,
                                            size: 16, color: light.flame),
                                        const SizedBox(width: 6),
                                        Text('12 days',
                                            style: DfText.smallStrong
                                                .copyWith(color: light.flame)),
                                      ],
                                    ),
                                  ),
                                  _Pill(
                                    color: Colors.white,
                                    child: Text('3 of 5 today',
                                        style: DfText.smallStrong
                                            .copyWith(color: light.primary)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: DfSpace.s3),
                              _SampleTask(
                                title: 'Morning run',
                                time: '7:30 AM',
                                tag: 'Health',
                                tagIndex: 3,
                                done: true,
                              ),
                              const SizedBox(height: DfSpace.s3),
                              Container(
                                padding:
                                    const EdgeInsets.fromLTRB(12, 12, 16, 12),
                                decoration: BoxDecoration(
                                  color: light.eventSoft,
                                  borderRadius:
                                      BorderRadius.circular(DfRadius.lg),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 3,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: light.event,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text('Team standup',
                                              style: DfText.bodyStrong
                                                  .copyWith(color: light.text)),
                                          Text('6:30 – 7:00 PM · Google Meet',
                                              style: DfText.small.copyWith(
                                                  color: light.textSecondary)),
                                        ],
                                      ),
                                    ),
                                    Icon(LucideIcons.calendar,
                                        size: 18, color: light.event),
                                  ],
                                ),
                              ),
                              const SizedBox(height: DfSpace.s3),
                              _SampleTask(
                                title: 'Call mom',
                                time: '8:30 PM',
                                tag: 'Personal',
                                tagIndex: 2,
                                bell: true,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(32)),
                    boxShadow: DfShadow.sheet,
                  ),
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                          DfSpace.s6, DfSpace.s6, DfSpace.s6, DfSpace.s3),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: c.primary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(LucideIcons.check,
                                    color: Colors.white, size: 16),
                              ),
                              const SizedBox(width: 8),
                              Text('DayFlow',
                                  style: DfText.h3.copyWith(color: c.text)),
                            ],
                          ),
                          const SizedBox(height: DfSpace.s3),
                          Text('Plan the day.\nKeep the streak.',
                              style: DfText.display.copyWith(color: c.text)),
                          const SizedBox(height: DfSpace.s3),
                          Text(
                            'Tasks, reminders and your calendar in one place, with a streak that rewards showing up.',
                            style:
                                DfText.body.copyWith(color: c.textSecondary),
                          ),
                          const SizedBox(height: DfSpace.s4),
                          DfButton(
                            label: 'Get started',
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const AuthFormScreen(signUp: true)),
                            ),
                          ),
                          const SizedBox(height: DfSpace.s1),
                          Center(
                            child: TextButton(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const AuthFormScreen(signUp: false)),
                              ),
                              child: Text('I already have an account',
                                  style: DfText.bodyStrong
                                      .copyWith(color: c.primary)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BackdropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.07);
    canvas.drawCircle(
        Offset(size.width * 0.15, size.height * 0.16), size.width * 0.62, paint);
    canvas.drawCircle(
        Offset(size.width * 0.95, size.height * 0.48), size.width * 0.52, paint);
  }

  @override
  bool shouldRepaint(_BackdropPainter old) => false;
}

class _Pill extends StatelessWidget {
  const _Pill({required this.color, required this.child});
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(DfRadius.full),
        ),
        child: child,
      );
}

class _SampleTask extends StatelessWidget {
  const _SampleTask({
    required this.title,
    required this.time,
    required this.tag,
    required this.tagIndex,
    this.done = false,
    this.bell = false,
  });

  final String title;
  final String time;
  final String tag;
  final int tagIndex;
  final bool done;
  final bool bell;

  @override
  Widget build(BuildContext context) {
    const light = DfColors.light;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(DfRadius.lg),
        boxShadow: DfShadow.card,
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done ? light.success : Colors.transparent,
              border: Border.all(
                  color: done ? light.success : light.borderStrong, width: 2),
            ),
            child: done
                ? const Icon(LucideIcons.check, size: 14, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: DfText.bodyStrong.copyWith(
                        color: done ? light.textMuted : light.text)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(LucideIcons.clock, size: 14, color: light.textMuted),
                    const SizedBox(width: 4),
                    Text(time,
                        style: DfText.small.copyWith(color: light.textMuted)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: light.tagSoft(tagIndex),
                        borderRadius: BorderRadius.circular(DfRadius.full),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                                color: light.tag(tagIndex),
                                shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 6),
                          Text(tag,
                              style: DfText.smallStrong
                                  .copyWith(color: light.tag(tagIndex))),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (bell) Icon(LucideIcons.bell, size: 18, color: light.textMuted),
        ],
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
  void initState() {
    super.initState();
    // Keeps the password strength hint in step with typing.
    _password.addListener(() {
      if (mounted) setState(() {});
    });
  }

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
                              ? 'Your tasks and streak sync across devices.'
                              : 'Sign in to pick up your streak.',
                          style: DfText.bodyRegular
                              .copyWith(color: c.textSecondary),
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
                        if (signUp &&
                            _passwordError == null &&
                            _password.text.length >= 8) ...[
                          const SizedBox(height: DfSpace.s2),
                          Row(
                            children: [
                              Icon(LucideIcons.check,
                                  size: 14, color: c.success),
                              const SizedBox(width: 6),
                              Text('Strong password, 8+ characters',
                                  style: DfText.small
                                      .copyWith(color: c.textSecondary)),
                            ],
                          ),
                        ],
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

  /// "muhammad@example.com" becomes "m•••@example.com".
  String get _masked {
    final email = _email.text.trim();
    final at = email.indexOf('@');
    if (at < 1) return email;
    return '${email[0]}•••${email.substring(at)}';
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
              const SizedBox(height: 6),
              Text(
                'Enter the email you signed up with and we’ll send a link to set a new password.',
                style: DfText.bodyRegular.copyWith(color: c.textSecondary),
              ),
              const SizedBox(height: DfSpace.s4),
              DfTextField(
                controller: _email,
                label: 'Email',
                hint: 'you@example.com',
                icon: LucideIcons.mail,
                keyboardType: TextInputType.emailAddress,
                error: _error,
                onSubmitted: (_) => _send(),
              ),
              const SizedBox(height: DfSpace.s4),
              DfButton(
                label: 'Send reset link',
                loading: _busy,
                onPressed: _send,
              ),
              if (_sent) ...[
                const SizedBox(height: DfSpace.s4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: c.successSoft,
                    borderRadius: BorderRadius.circular(DfRadius.lg),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                            color: c.success, shape: BoxShape.circle),
                        child: const Icon(LucideIcons.mail,
                            size: 16, color: Colors.white),
                      ),
                      const SizedBox(width: DfSpace.s3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Check your inbox',
                                style:
                                    DfText.bodyStrong.copyWith(color: c.text)),
                            const SizedBox(height: 2),
                            Text(
                              'If an account exists for $_masked, a link is on its way.',
                              style: DfText.small
                                  .copyWith(color: c.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const Spacer(),
              if (_sent)
                Center(
                  child: GestureDetector(
                    onTap: _busy ? null : _send,
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Text.rich(
                        TextSpan(
                          text: 'Didn’t get it? ',
                          style:
                              DfText.small.copyWith(color: c.textSecondary),
                          children: [
                            TextSpan(
                              text: 'Resend',
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

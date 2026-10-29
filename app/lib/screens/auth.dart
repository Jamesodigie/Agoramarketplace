import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../icons.dart';
import '../nav.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'seller_onboarding.dart';
import 'seller.dart';
import 'shop.dart';

class AuthHead extends StatelessWidget {
  final String title, body;
  final Widget? icon;
  const AuthHead({super.key, required this.title, required this.body, this.icon});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 6, bottom: 28),
        child: Column(children: [
          (icon ?? const LogoTile(size: 64)).popIn(),
          const SizedBox(height: 16),
          Text(title, textAlign: TextAlign.center, style: ts(24, w: w7, ls: -0.3)).fadeUp(60),
          const SizedBox(height: 8),
          ConstrainedBox(constraints: const BoxConstraints(maxWidth: 320), child: Text(body, textAlign: TextAlign.center, style: ts(14.5, c: C.muted, h: 1.5)).fadeUp(110)),
        ]),
      );
}

void afterAuth() {
  if (app.role == 'seller') {
    goReset(const SellerStep1());
  } else {
    goReset(const AllSetScreen());
  }
}

class _Social extends StatelessWidget {
  final String icon, label;
  final VoidCallback onTap;
  const _Social(this.icon, this.label, this.onTap);
  @override
  Widget build(BuildContext context) => Pressable(
        onTap: onTap,
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: C.line)),
          child: Row(children: [Ic(icon, size: 28), const SizedBox(width: 16), Expanded(child: Text(label, style: ts(15.5, w: w5))), Ic('chev', size: 20, color: C.muted)]),
        ),
      );
}

class CreateAccountScreen extends StatelessWidget {
  const CreateAccountScreen({super.key});
  @override
  Widget build(BuildContext context) => AppPage(children: [
        const AuthHead(title: 'Create your account', body: 'Join Agora and start shopping with peace of mind.'),
        ...stagger([
          _Social('google', 'Continue with Google', () => processing(context, 'Connecting…', 'Signing you in securely', afterAuth)),
          _Social('apple', 'Continue with Apple', () => processing(context, 'Connecting…', 'Signing you in securely', afterAuth)),
          const _OrDivider('or'),
          _Social('doc', 'Sign up with email', () => go(const SignUpScreen())),
        ], start: 150, step: 60).expand((w) => [w, const SizedBox(height: 14)]),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text('Already have an account?', style: ts(14, c: C.muted)), TextBtn('Log in', onTap: () => go(const SignInScreen()))]),
      ]);
}

class _OrDivider extends StatelessWidget {
  final String t;
  const _OrDivider(this.t);
  @override
  Widget build(BuildContext context) => Row(children: [
        const Expanded(child: Divider(color: C.line)),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 14), child: Text(t, style: ts(14, c: C.muted))),
        const Expanded(child: Divider(color: C.line)),
      ]);
}

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});
  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final name = TextEditingController(text: app.userName);
  final email = TextEditingController(text: app.userEmail);
  final pw = TextEditingController();
  String? err;

  void _submit() {
    final n = name.text.trim(), e = email.text.trim();
    if (n.isEmpty || !RegExp(r'^\S+@\S+\.\S+$').hasMatch(e)) return setState(() => err = 'Enter your full name and a valid email address.');
    if (pw.text.length < 8) return setState(() => err = 'Use at least 8 characters for your password.');
    app.userName = n;
    app.userEmail = e;
    afterAuth();
  }

  @override
  Widget build(BuildContext context) => AppPage(children: [
        const AuthHead(title: 'Sign up with your email', body: 'Enter your details to get started.', icon: SizedBox.shrink()),
        ...stagger([
          Field(label: 'Full name', ctrl: name, autofill: const [AutofillHints.name]),
          Field(label: 'Email address', ctrl: email, keyboard: TextInputType.emailAddress, autofill: const [AutofillHints.email]),
          Field(label: 'Password', ctrl: pw, password: true, hint: 'Create a password', autofill: const [AutofillHints.newPassword]),
          ErrText(err),
          Btn('Create account', onTap: _submit),
          Text('By creating an account you agree to our Terms of Service and Privacy Policy.', textAlign: TextAlign.center, style: ts(12.5, c: C.muted, h: 1.5)),
        ]).expand((w) => [w, const SizedBox(height: 18)]),
      ]);
}

class AllSetScreen extends StatelessWidget {
  const AllSetScreen({super.key});
  @override
  Widget build(BuildContext context) => AppPage(
        topbar: false,
        children: [
          const SizedBox(height: 70),
          const StatusHead(kind: 'green', icon: 'check', title: "You're all set!", body: "Welcome to Agora. Let's get you shopping safely.", confetti: true),
          Btn('Start shopping', onTap: () => goReset(const HomeScreen())).fadeUp(300),
        ],
      );
}

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});
  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final email = TextEditingController(text: app.userEmail);
  final pw = TextEditingController();
  bool remember = true;
  String? err;
  void _submit() {
    if (!RegExp(r'^\S+@\S+\.\S+$').hasMatch(email.text.trim())) return setState(() => err = 'Enter a valid email address.');
    if (pw.text.isEmpty) return setState(() => err = 'Enter your password. Any password works in this prototype.');
    if (app.role == 'seller') {
      goReset(app.verify == 'done' ? const SellerDashboard() : const SellerStep1());
    } else {
      goReset(const HomeScreen());
    }
    toast('Signed in');
  }

  @override
  Widget build(BuildContext context) => AppPage(children: [
        const AuthHead(title: 'Welcome back!', body: 'Sign in to your account to continue shopping safely.'),
        ...stagger([
          Field(label: 'Email address', ctrl: email, keyboard: TextInputType.emailAddress, autofill: const [AutofillHints.email]),
          Field(label: 'Password', ctrl: pw, password: true, hint: 'Enter your password', autofill: const [AutofillHints.password]),
          Row(children: [
            Expanded(child: CheckRow(on: remember, onChanged: (v) => setState(() => remember = v), text: Text('Remember me', style: ts(14)))),
            TextBtn('Forgot password?', size: 14, onTap: () => go(const ForgotScreen())),
          ]),
          ErrText(err),
          Btn('Sign in', onTap: _submit),
          const _OrDivider('Or'),
          Btn('Continue with Google', kind: BtnKind.outline, icon: 'google', onTap: () => processing(context, 'Connecting…', 'Signing you in securely', () => goReset(const HomeScreen()))),
        ]).expand((w) => [w, const SizedBox(height: 16)]),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text("Don't have an account?", style: ts(14, c: C.muted)), TextBtn('Sign up', onTap: () => back())]),
      ]);
}

class ForgotScreen extends StatelessWidget {
  const ForgotScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final email = TextEditingController(text: app.userEmail);
    return AppPage(children: [
      const AuthHead(title: 'Forgot your password?', body: 'Enter the email address linked to your account and we will send you a code.'),
      ...stagger([
        Field(label: 'Email address', ctrl: email, keyboard: TextInputType.emailAddress),
        Btn('Send code', onTap: () {
          toast('Code sent to ${email.text.trim()}');
          go(const OtpScreen());
        }),
      ]).expand((w) => [w, const SizedBox(height: 18)]),
    ]);
  }
}

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});
  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final ctrls = List.generate(4, (_) => TextEditingController());
  final nodes = List.generate(4, (_) => FocusNode());
  @override
  void dispose() {
    for (final n in nodes) {
      n.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppPage(children: [
        AuthHead(
          title: 'Enter the code',
          body: 'We sent a 4-digit code to ${app.userEmail}. Any 4 digits work in this prototype.',
          icon: const BadgeIcon('blue', 'lock'),
        ),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (var i = 0; i < 4; i++)
            Container(
              width: 58,
              height: 62,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              child: TextField(
                controller: ctrls[i],
                focusNode: nodes[i],
                autofocus: i == 0,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 1,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: ts(24, w: w6),
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: C.line)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: C.blue, width: 1.5)),
                ),
                onChanged: (v) {
                  if (v.isNotEmpty && i < 3) nodes[i + 1].requestFocus();
                  if (v.isEmpty && i > 0) nodes[i - 1].requestFocus();
                  if (ctrls.every((c) => c.text.isNotEmpty)) {
                    Future.delayed(const Duration(milliseconds: 250), () => go(const NewPasswordScreen()));
                  }
                },
              ),
            ).rise(100 + i * 50),
        ]),
        const SizedBox(height: 22),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text("Didn't get it?", style: ts(14, c: C.muted)), TextBtn('Resend code', onTap: () => toast('A new code is on its way'))]),
        const SizedBox(height: 16),
        Btn('Verify', onTap: () => go(const NewPasswordScreen())),
      ]);
}

class NewPasswordScreen extends StatefulWidget {
  final bool change;
  const NewPasswordScreen({super.key, this.change = false});
  @override
  State<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> {
  final a = TextEditingController(), b = TextEditingController();
  String? err;
  void _submit() {
    if (a.text.length < 8) return setState(() => err = 'Use at least 8 characters.');
    if (a.text != b.text) return setState(() => err = 'The two passwords do not match.');
    if (widget.change) {
      back();
      toast('Password updated');
    } else {
      goReset(const ResetDoneScreen());
    }
  }

  @override
  Widget build(BuildContext context) => AppPage(children: [
        const AuthHead(title: 'Create a new password', body: 'Your new password must be different from your previous one and at least 8 characters long.'),
        ...stagger([
          Field(label: 'New password', ctrl: a, password: true, hint: 'Enter new password', autofill: const [AutofillHints.newPassword]),
          Field(label: 'Confirm password', ctrl: b, password: true, hint: 'Confirm new password'),
          ErrText(err),
          Btn(widget.change ? 'Update password' : 'Reset password', onTap: _submit),
        ]).expand((w) => [w, const SizedBox(height: 18)]),
      ]);
}

class ResetDoneScreen extends StatelessWidget {
  const ResetDoneScreen({super.key});
  @override
  Widget build(BuildContext context) => AppPage(topbar: false, children: [
        const SizedBox(height: 70),
        const StatusHead(kind: 'green', icon: 'check', title: 'Password reset', body: 'Your password has been updated. Sign in with your new password.', confetti: true),
        Btn('Back to sign in', onTap: () => goReset(const SignInScreen())).fadeUp(300),
      ]);
}

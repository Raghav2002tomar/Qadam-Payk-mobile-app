// lib/auth/phone_signup_wizard.dart
import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';

class PhoneSignupWizard extends StatefulWidget {
  const PhoneSignupWizard({super.key});
  @override
  State<PhoneSignupWizard> createState() => _PhoneSignupWizardState();
}

class _PhoneSignupWizardState extends State<PhoneSignupWizard> {
  final _page = PageController();
  int _step = 0;

  // Step keys & controllers
  final _phoneKey = GlobalKey<FormState>();
  final _otpKey = GlobalKey<FormState>();
  final _nameKey = GlobalKey<FormState>();
  final _passKey = GlobalKey<FormState>();

  final _phoneCtrl = TextEditingController(text: '+234');
  final _otpCtrl = TextEditingController();
  final _firstCtrl = TextEditingController();
  final _lastCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  String? _verificationId; // populate from backend when sending OTP
  bool _busy = false;

  @override
  void dispose() {
    _page.dispose();
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    _firstCtrl.dispose();
    _lastCtrl.dispose();
    _emailCtrl.dispose();
    _pwdCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  // Validators
  String? _phone(String? v) {
    if (v == null || v.trim().isEmpty) return 'Phone number is required';
    final ok = RegExp(r'^\+\d{6,15}$').hasMatch(v.trim());
    return ok ? null : 'Use country code, e.g. +2348012345678';
  }

  String? _email(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email is required';
    return RegExp(r'^\S+@\S+\.\S+$').hasMatch(v.trim()) ? null : 'Enter a valid email';
  }

  String? _pwd(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (v.length < 8) return 'At least 8 characters';
    return null;
  }

  // Actions per step
  Future<void> _sendOtp() async {
    if (!_phoneKey.currentState!.validate()) return;
    setState(() => _busy = true);
    // TODO: Call backend/Firebase verifyPhoneNumber; set _verificationId in codeSent
    await Future.delayed(const Duration(milliseconds: 700));
    _verificationId = 'stub-verification-id';
    setState(() => _busy = false);
    _goNext();
  }

  Future<void> _verifyOtp() async {
    if (!_otpKey.currentState!.validate()) return;
    setState(() => _busy = true);
    // TODO: Use _verificationId + _otpCtrl.text to verify
    await Future.delayed(const Duration(milliseconds: 700));
    setState(() => _busy = false);
    _goNext();
  }

  void _goNext() {
    if (_step >= 4) return;
    setState(() => _step++);
    _page.animateToPage(_step, duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
  }

  void _goBack() {
    if (_step == 0) return;
    setState(() => _step--);
    _page.animateToPage(_step, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  Future<void> _continuePressed() async {
    FocusScope.of(context).unfocus();
    switch (_step) {
      case 0:
        return _sendOtp();
      case 1:
        return _verifyOtp();
      case 2:
        if (_nameKey.currentState!.validate()) _goNext();
        return;
      case 3:
        if (_passKey.currentState!.validate()) _goNext();
        return;
      case 4:
      // Account Created screen actions here (e.g., go to setup)
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        leading: _step == 0
            ? null
            : IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: _goBack,
        ),
        title: const Text('Create your account'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: (_step + 1) / 5, // 5 steps total
                  minHeight: 4,
                  color: scheme.primary,
                  backgroundColor: scheme.surfaceContainerHighest,
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _page,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _PhoneStep(formKey: _phoneKey, controller: _phoneCtrl),
                  _OtpStep(formKey: _otpKey, controller: _otpCtrl, phoneGetter: () => _phoneCtrl.text),
                  _NameEmailStep(
                    formKey: _nameKey,
                    firstCtrl: _firstCtrl,
                    lastCtrl: _lastCtrl,
                    emailCtrl: _emailCtrl,
                    emailValidator: _email,
                  ),
                  _PasswordStep(
                    formKey: _passKey,
                    pwdCtrl: _pwdCtrl,
                    confirmCtrl: _confirmCtrl,
                    pwdValidator: _pwd,
                  ),
                  const _AccountCreatedStep(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _busy ? null : _continuePressed,
                  child: _busy
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(_step < 4 ? 'Continue' : 'Done'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// STEP 0 – Phone number
class _PhoneStep extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController controller;
  const _PhoneStep({required this.formKey, required this.controller});
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("What’s your phone number?", style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontSize: 24
            )),
            const SizedBox(height: 12),
            Text("A code will be sent to verify \nyour phone number", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 12)),
            const SizedBox(height: 30),
            Text('Enter phone number', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextFormField(
              controller: controller,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                filled: true, // enable background fill
                fillColor: Color(0xFFF5F5F5),
                labelText: 'Phone number',
                hintText: '+2348012345678',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Phone number is required';
                final ok = RegExp(r'^\+\d{6,15}$').hasMatch(v.trim());
                return ok ? null : 'Use country code, e.g. +2348012345678';
              },
            ),
          ],
        ),
      ),
    );
  }
}

// STEP 1 – OTP
class _OtpStep extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController controller;
  final String Function() phoneGetter;
  const _OtpStep({required this.formKey, required this.controller, required this.phoneGetter});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = PinTheme(
      width: 46,
      height: 46,
      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outlineVariant),
        color: Theme.of(context).inputDecorationTheme.fillColor,
      ),
    );
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Enter Verification Code', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              'Enter the 6-digit code sent to\n${phoneGetter()}',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 30),
            Pinput(
              controller: controller,
              length: 6,
              defaultPinTheme: base.copyWith(
                decoration: base.decoration?.copyWith(
                  color: const Color(0xFFF5F5F5), // background color
                ),
              ),
              focusedPinTheme: base.copyWith(
                decoration: base.decoration?.copyWith(
                  color: const Color(0xFFF5F5F5), // keep same bg when focused
                  border: Border.all(color: scheme.primary, width: 1.6),
                ),
              ),
              submittedPinTheme: base.copyWith(
                decoration: base.decoration?.copyWith(
                  color: const Color(0xFFF5F5F5), // keep same bg when submitted
                  border: Border.all(color: scheme.primary),
                ),
              ),
              validator: (v) => v != null && v.length == 6 ? null : 'Enter 6-digit code',
            ),

            const SizedBox(height: 4),
            TextButton(
              onPressed: () {
                // TODO: resend OTP
              },
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              child: const Text("Didn't get the code? Resend"),
            ),
          ],
        ),
      ),
    );
  }
}

// STEP 2 – Name & Email
class _NameEmailStep extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController firstCtrl;
  final TextEditingController lastCtrl;
  final TextEditingController emailCtrl;
  final String? Function(String?) emailValidator;

  const _NameEmailStep({
    required this.formKey,
    required this.firstCtrl,
    required this.lastCtrl,
    required this.emailCtrl,
    required this.emailValidator,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Provide the information below', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 30),
            TextFormField(
              controller: firstCtrl,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration( filled: true, // enable background fill
                fillColor: Color(0xFFF5F5F5), labelText: 'First Name'),
              validator: (v) => v == null || v.trim().isEmpty ? 'First name is required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: lastCtrl,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration( filled: true, // enable background fill
                fillColor: Color(0xFFF5F5F5), labelText: 'Last Name'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Last name is required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: emailCtrl,
              textInputAction: TextInputAction.done,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration( filled: true, // enable background fill
                fillColor: Color(0xFFF5F5F5),  labelText: 'Email address'),
              validator: emailValidator,
            ),
          ],
        ),
      ),
    );
  }
}

// STEP 3 – Password & Confirm
class _PasswordStep extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController pwdCtrl;
  final TextEditingController confirmCtrl;
  final String? Function(String?) pwdValidator;
  const _PasswordStep({
    required this.formKey,
    required this.pwdCtrl,
    required this.confirmCtrl,
    required this.pwdValidator,
  });

  @override
  State<_PasswordStep> createState() => _PasswordStepState();
}

class _PasswordStepState extends State<_PasswordStep> {
  bool _show1 = false;
  bool _show2 = false;

  @override
  Widget build(BuildContext context) {
    final onVar = Theme.of(context).colorScheme.onSurfaceVariant;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      child: Form(
        key: widget.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Create your password', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 30),
            TextFormField(
              controller: widget.pwdCtrl,
              textInputAction: TextInputAction.next,
              obscureText: !_show1,
              decoration: InputDecoration(
                filled: true, // enable background fill
                fillColor: Color(0xFFF5F5F5), // light grey background
                labelText: 'Password',
                suffixIcon: IconButton(
                  icon: Icon(_show1 ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: onVar),
                  onPressed: () => setState(() => _show1 = !_show1),
                ),
              ),
              validator: widget.pwdValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: widget.confirmCtrl,
              textInputAction: TextInputAction.done,
              obscureText: !_show2,
              decoration: InputDecoration(
                filled: true, // enable background fill
                fillColor: Color(0xFFF5F5F5), // light grey background
                labelText: 'Confirm Password',
                suffixIcon: IconButton(
                  icon: Icon(_show2 ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: onVar),
                  onPressed: () => setState(() => _show2 = !_show2),
                ),
              ),
              validator: (v) {
                final m = widget.pwdValidator(v);
                if (m != null) return m;
                if (v != widget.pwdCtrl.text) return 'Passwords do not match';
                return null;
              },
            ),
            const SizedBox(height: 8),
            Text(
              'Hint: Password should contain at least 8 characters',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: onVar),
            ),
          ],
        ),
      ),
    );
  }
}

// STEP 4 – Account Created
class _AccountCreatedStep extends StatelessWidget {
  const _AccountCreatedStep();

  @override
  Widget build(BuildContext context) {

    final scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            elevation: 0,
            color: scheme.surfaceContainerHighest,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Image.asset("assets/images/Group 8.png"),
                  // CircleAvatar(
                  //   radius: 28,
                  //   backgroundColor: scheme.primary.withOpacity(0.15),
                  //   child: Icon(Icons.verified_rounded, color: scheme.primary, size: 32),
                  // ),
                  const SizedBox(height: 12),
                  Text('Account Created!', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 6),
                  Text(
                    'Set up the store and get the business ready for activation',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                  _setupItem(context, "assets/images/busness_info.png", 'Add business information',
                      'Add more information about the business'),
                  _setupItem(context, "assets/images/store.png", 'Set-up your store',
                      'Create and customise the online store'),
                  _setupItem(context, "assets/images/product_list.png", 'Create your product list',
                      'Add items to your product list with images'),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () {
                        // TODO: continue to setup flow
                      },
                      child: const Text('Continue to Setup'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton(
                      onPressed: () {
                        // TODO: skip for later
                      },
                      child: const Text('Skip for Later'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _setupItem(BuildContext context, String? icon, String title, String subtitle) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: scheme.primary.withOpacity(0.10),
        // child: Icon(icon, size: 18, color: scheme.primary),
        child: Image.asset(icon as String),
      ),
      title: Text(title, style: Theme.of(context).textTheme.titleSmall),
      subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
    );
  }
}

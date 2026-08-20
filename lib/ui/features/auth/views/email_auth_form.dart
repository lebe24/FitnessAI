import 'package:fitness/ui/features/auth/view_models/auth_view_model.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const _lime = Color(0xFFCCFF00);

/// Email and password sign-in, and sign-up.
///
/// The app previously offered only Google. The "Gmail" option it had was not a
/// separate path at all — it validated that the address ended in @gmail.com and
/// then ran the same OAuth flow, so anyone without a Google account could not
/// create one, and App Review could not sign in with credentials handed to
/// them in App Store Connect.
///
/// Both modes live in one widget because they differ by a single call and a
/// couple of words; splitting them would duplicate the validation, which is
/// where the security-relevant details are.
class EmailAuthForm extends StatefulWidget {
  final AuthViewModel vm;
  final VoidCallback onCancel;

  const EmailAuthForm({
    super.key,
    required this.vm,
    required this.onCancel,
  });

  @override
  State<EmailAuthForm> createState() => _EmailAuthFormState();
}

class _EmailAuthFormState extends State<EmailAuthForm> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _isSignUp = false;
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final email = _email.text.trim();
    final password = _password.text;

    if (_isSignUp) {
      await widget.vm.signUpWithEmail(email, password);
    } else {
      await widget.vm.signInWithEmailPassword(email, password);
    }
  }

  String? _validateEmail(String? v) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return 'Enter your email address';
    // Deliberately permissive: the only thing worth rejecting here is input
    // that cannot be an address at all. Anything stricter turns valid
    // addresses away, and the server verifies it regardless.
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value)) {
      return 'That does not look like an email address';
    }
    return null;
  }

  String? _validatePassword(String? v) {
    final value = v ?? '';
    if (value.isEmpty) return 'Enter a password';
    // Only enforced on sign-up. Applying it to sign-in would lock out anyone
    // whose existing password predates the rule.
    if (_isSignUp && value.length < 8) {
      return 'Use at least 8 characters';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            autocorrect: false,
            style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
            decoration: _decoration('Email address', Icons.mail_outline_rounded),
            validator: _validateEmail,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _password,
            obscureText: _obscure,
            textInputAction: TextInputAction.done,
            autofillHints: [
              _isSignUp ? AutofillHints.newPassword : AutofillHints.password,
            ],
            style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
            decoration: _decoration(
              'Password',
              Icons.lock_outline_rounded,
              suffix: IconButton(
                icon: Icon(
                  _obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 18,
                  color: Colors.white38,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            validator: _validatePassword,
            onFieldSubmitted: (_) => _submit(),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: widget.onCancel,
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.poppins(
                        color: Colors.white38,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: widget.vm.isLoading ? null : _submit,
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: _lime,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: _lime.withValues(alpha: 0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _isSignUp ? 'Create account' : 'Sign in',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Center(
            child: TextButton(
              onPressed: () => setState(() {
                _isSignUp = !_isSignUp;
                // Re-validating under the other mode's rules would show errors
                // for input the user has not revisited.
                _formKey.currentState?.reset();
              }),
              child: Text(
                _isSignUp
                    ? 'Already have an account? Sign in'
                    : 'New here? Create an account',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  color: Colors.white54,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _decoration(String hint, IconData icon, {Widget? suffix}) {
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: color, width: width),
        );

    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(color: Colors.white24, fontSize: 14),
      prefixIcon: Icon(icon, size: 18, color: Colors.white38),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.04),
      enabledBorder: border(Colors.white12),
      focusedBorder: border(_lime.withValues(alpha: 0.5), 1.5),
      errorBorder: border(Colors.redAccent),
      focusedErrorBorder: border(Colors.redAccent, 1.5),
      errorStyle: GoogleFonts.inter(fontSize: 11, color: Colors.redAccent),
      contentPadding:
          const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    );
  }
}

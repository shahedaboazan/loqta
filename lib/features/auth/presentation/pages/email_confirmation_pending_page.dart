import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:loqta/core/theme/app_theme.dart';
import 'package:loqta/core/widgets/brand_logo.dart';
import 'package:loqta/core/widgets/info_banner.dart';
import 'package:loqta/core/widgets/loqta_app_bar.dart';
import 'package:loqta/core/widgets/loqta_button.dart';
import 'package:loqta/features/auth/presentation/bloc/auth_bloc.dart';

/// Confirmation-pending screen shown after a successful sign-up.
///
/// Replaces the old six-digit OTP screen. Supabase sends its standard
/// "Confirm your signup" email containing a link; the user clicks it, their
/// address is confirmed, and they then sign in manually with their email and
/// password. Nothing is asked of them here, so the screen only explains what
/// to do next and offers a way back to Sign In.
///
/// The user is never signed in by this flow: `AuthRepositoryImpl` drops any
/// session Supabase hands back at sign-up, so `AuthGate` still renders Sign In
/// underneath this route.
class EmailConfirmationPendingPage extends StatelessWidget {
  const EmailConfirmationPendingPage({super.key, required this.email});

  /// The address the confirmation link was sent to.
  final String email;

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      // The confirmation link is handled outside the app (it opens the
      // confirmation URL), so the app can be left sitting on this screen after
      // the address is confirmed. Whenever the session is absent, return to the
      // gate's root route, which is Sign In: the required flow always ends in a
      // manual password sign-in and never lands on Home from here.
      listenWhen: (previous, current) => current is Unauthenticated,
      listener: (context, state) =>
          Navigator.of(context).popUntil((route) => route.isFirst),
      child: _content(context),
    );
  }

  Widget _content(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFFFF), Color(0xFFF6FCF8)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                LoqtaSpacing.gutter,
                0,
                LoqtaSpacing.gutter,
                24,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: LoqtaSpacing.maxContentWidth,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const LoqtaAppBar(title: 'Check Your Email'),
                    const SizedBox(height: 10),
                    const Center(child: BrandLogo(size: 68)),
                    const SizedBox(height: 22),
                    Center(
                      child: BrandPill(
                        label: 'One last step',
                        icon: Icons.mark_email_read_outlined,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Check your email',
                      textAlign: TextAlign.center,
                      style: LoqtaText.heading,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'We sent you a confirmation link. Open the email and '
                      'click the link to verify your email address. Once your '
                      'email is confirmed, return to Loqta and sign in with '
                      'your email and password.',
                      textAlign: TextAlign.center,
                      style: LoqtaText.subtitle,
                    ),
                    const SizedBox(height: 24),
                    _EmailChip(email: email),
                    const SizedBox(height: 22),
                    const InfoBanner(
                      icon: Icons.mark_email_unread_outlined,
                      title: 'Check your spam folder',
                      message:
                          'Confirmation emails occasionally land in spam or '
                          'promotions. Mark Loqta as safe so you never miss a '
                          'bargain alert.',
                    ),
                    const SizedBox(height: 18),
                    const IconCaption(
                      icon: Icons.shield_outlined,
                      label: 'Guarding your Damascus marketplace account',
                    ),
                    const SizedBox(height: 24),
                    LoqtaButton(
                      label: 'Back to Sign In',
                      onPressed: () =>
                          Navigator.of(context)
                              .popUntil((route) => route.isFirst),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The pill showing which address the confirmation link was sent to.
class _EmailChip extends StatelessWidget {
  const _EmailChip({required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: const Color(0xFFEEF2FA),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.alternate_email,
              size: 14,
              color: LoqtaColors.primaryDark,
            ),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                email,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: LoqtaColors.headingPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  fontFamily: LoqtaText.family,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

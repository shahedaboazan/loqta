import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:loqta/core/localization/app_localizations.dart';
import 'package:loqta/core/theme/app_theme.dart';
import 'package:loqta/core/widgets/loqta_app_bar.dart';
import 'package:loqta/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:loqta/features/auth/presentation/pages/forgot_password_page.dart';

/// Security & Privacy.
///
/// Reached from Settings and from the "Delete Account" row on Profile. It
/// groups the two things that belong to the account itself: the credentials
/// that protect it, and the data it holds.
class SecurityPrivacyPage extends StatelessWidget {
  const SecurityPrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.loqtaColors;
    final strings = context.l10n;

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            LoqtaAppBar(title: strings.securityPrivacy),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  LoqtaSpacing.gutter,
                  8,
                  LoqtaSpacing.gutter,
                  24,
                ),
                children: [
                  _GroupLabel(strings.accountSecurity),
                  const SizedBox(height: 10),
                  _Row(
                    icon: Icons.lock_outline,
                    label: strings.changePassword,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const ForgotPasswordPage(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  _GroupLabel(strings.privacyInformation),
                  const SizedBox(height: 10),
                  _InfoCard(
                    text:
                        'Your listings, messages and profile are only visible to '
                        'other signed-in Loqta members. Your email is used to '
                        'sign in and to send account notices.',
                  ),
                  const SizedBox(height: 22),
                  _GroupLabel(strings.account),
                  const SizedBox(height: 10),
                  _Row(
                    icon: Icons.delete_outline,
                    label: strings.deleteAccount,
                    tint: Theme.of(context).colorScheme.error,
                    onTap: () => _explainDeletion(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Explains what deleting the account means.
  ///
  /// The app cannot remove the Supabase account itself — that needs an
  /// administrative key the client never holds — so the account is not
  /// deleted from here. Signing out is offered instead, and the row is left
  /// in place so the entry point is not lost.
  Future<void> _explainDeletion(BuildContext context) async {
    final strings = context.l10n;
    final signOut = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings.deleteAccount),
        content: Text(
          'Deleting your account removes your listings and messages with it. '
          'Account deletion is not available in the app yet, so you can only '
          'sign out here.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(strings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(strings.signOut),
          ),
        ],
      ),
    );
    if (signOut != true || !context.mounted) return;
    context.read<AuthBloc>().add(const SignOutRequested());
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}

/// A small uppercase group heading.
class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = context.loqtaColors;
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        color: palette.textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        fontFamily: LoqtaText.family,
      ),
    );
  }
}

/// A navigable row, matching the rows on the Settings screen.
class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.label, this.onTap, this.tint});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final palette = context.loqtaColors;
    final color = tint ?? palette.heading;
    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          child: Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: LoqtaText.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 12,
                color: palette.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A short paragraph of information.
class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = context.loqtaColors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border),
      ),
      child: Text(
        text,
        style: LoqtaText.body.copyWith(color: palette.textSecondary),
      ),
    );
  }
}

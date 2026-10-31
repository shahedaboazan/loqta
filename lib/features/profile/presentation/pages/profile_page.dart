import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:loqta/core/localization/app_localizations.dart';
import 'package:loqta/core/theme/app_theme.dart';
import 'package:loqta/core/widgets/loqta_app_bar.dart';
import 'package:loqta/core/widgets/user_avatar.dart';
import 'package:loqta/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:loqta/features/listings/presentation/pages/my_listings_page.dart';
import 'package:loqta/features/listings/presentation/pages/transaction_history_page.dart';
import 'package:loqta/features/chat/presentation/pages/chat_list_page.dart';
import 'package:loqta/features/profile/domain/repositories/profile_repository.dart';
import 'package:loqta/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:loqta/features/settings/presentation/pages/settings_page.dart';
import 'package:loqta/features/chat/domain/services/image_picker_service.dart';
import 'package:loqta/features/profile/presentation/bloc/profile_bloc.dart';

/// Screen 18 — Profile, and the fifth main-navigation destination.
///
/// Rebuilt from `design_drafts/screens/18_profile.png`: a white card holding
/// the avatar, name, email and phone, an outlined "Edit Profile" button, then
/// grouped navigation rows for My Activity, Settings and Account.
///
/// The destinations that exist today are wired below. My Listings, Transaction
/// History and My Ratings are listed in the navigation map but their screens are
/// built in later phases, so they are omitted here rather than rendered as rows
/// that go nowhere.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProfileBloc>(
      create: (context) =>
          ProfileBloc(repository: context.read<ProfileRepository>())
            ..add(const ProfileRequested()),
      child: const ProfileView(),
    );
  }
}

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.loqtaColors;
    final strings = context.l10n;

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<ProfileBloc, ProfileState>(
          builder: (context, state) {
            final user = context.select((AuthBloc bloc) => bloc.state);
            final email = user is Authenticated ? user.user.email : '';

            return Column(
              children: [
                LoqtaAppBar(
                  title: strings.profile,
                  showBack: Navigator.of(context).canPop(),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      LoqtaSpacing.gutter,
                      4,
                      LoqtaSpacing.gutter,
                      24,
                    ),
                    children: [
                      _ProfileCard(state: state, email: email),
                      const SizedBox(height: 22),
                      _SectionLabel(strings.myActivity),
                      const SizedBox(height: 10),
                      _ProfileRow(
                        icon: Icons.inventory_2_outlined,
                        label: strings.myListings,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const MyListingsPage(),
                          ),
                        ),
                      ),
                      _ProfileRow(
                        icon: Icons.receipt_long_outlined,
                        label: strings.transactionHistory,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const TransactionHistoryPage(),
                          ),
                        ),
                      ),
                      _ProfileRow(
                        icon: Icons.star_outline,
                        label: strings.myRatings,
                        enabled: false,
                      ),
                      _ProfileRow(
                        icon: Icons.chat_bubble_outline,
                        label: strings.chatMessages,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (context) => ChatListPage(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      _SectionLabel(strings.settings),
                      const SizedBox(height: 10),
                      _ProfileRow(
                        icon: Icons.settings_outlined,
                        label: strings.settings,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const SettingsPage(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      _SectionLabel(strings.account),
                      const SizedBox(height: 10),
                      _ProfileRow(
                        icon: Icons.logout,
                        label: strings.logOut,
                        onTap: () => _confirmLogOut(context),
                      ),
                      _ProfileRow(
                        icon: Icons.delete_outline,
                        label: strings.deleteAccount,
                        tint: Theme.of(context).colorScheme.error,
                        onTap: () => _confirmDeleteAccount(context),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _confirmLogOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.logOut),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<AuthBloc>().add(const SignOutRequested());
    }
  }

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.deleteAccount),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      // In a real app we would call the actual delete account method here.
      // Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const DeleteAccountPage()));
    }
  }
}

Future<void> _showAvatarOptions(BuildContext context) async {
  final action = await showModalBottomSheet<String>(
    context: context,
    builder: (sheetContext) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text(
                'Profile photo',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(sheetContext, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(sheetContext, 'gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Use default avatar'),
              onTap: () => Navigator.pop(sheetContext, 'default'),
            ),
          ],
        ),
      );
    },
  );

  if (action == null || !context.mounted) return;

  if (action == 'default') {
    context.read<ProfileBloc>().add(const ProfilePhotoRemoved());
    return;
  }

  try {
    final imagePicker = context.read<ImagePickerService>();

    final image = action == 'camera'
        ? await imagePicker.takePhoto()
        : await imagePicker.pickImage();

    if (!context.mounted || image == null) return;

    context.read<ProfileBloc>().add(ProfilePhotoSelected(image));
  } on ImagePickException catch (error) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(error.message)));
  } catch (_) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not select the profile photo.')),
    );
  }
}

/// A small uppercase group heading.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

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

/// The header card: avatar, name, email, phone and the Edit Profile button.
class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.state, required this.email});

  final ProfileState state;
  final String email;

  @override
  Widget build(BuildContext context) {
    final palette = context.loqtaColors;
    final strings = context.l10n;
    final profile = state.profile;
    final firstName = profile?.firstName?.trim() ?? '';
    final lastName = profile?.lastName?.trim() ?? '';

    final fullName = '$firstName $lastName'.trim();
    final displayName = fullName.isEmpty ? 'Loqta member' : fullName;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(LoqtaSpacing.radiusCard),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        children: [
          if (state.status == ProfileStatus.loading)
            const SizedBox(
              height: 92,
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    LoqtaColors.primary,
                  ),
                ),
              ),
            )
          else
            InkWell(
              customBorder: const CircleBorder(),
              onTap: () => _showAvatarOptions(context),
              child: UserAvatar(
                name: displayName,
                imageUrl: profile?.avatarUrl,
                size: 92,
              ),
            ),
          const SizedBox(height: 12),
          Text(
            displayName,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: LoqtaText.heading.copyWith(
              fontSize: 19,
              color: palette.heading,
            ),
          ),
          if (email.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              email,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: LoqtaText.caption.copyWith(color: palette.textSecondary),
            ),
          ],
          if ((profile?.phoneNumber ?? '').isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              profile!.phoneNumber!,
              textAlign: TextAlign.center,
              style: LoqtaText.caption.copyWith(color: palette.textSecondary),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: state.status == ProfileStatus.loading
                  ? null
                  : () {
                      // The Edit Profile screen is not part of this build. The
                      // button reports that instead of pushing an unregistered
                      // route, which would throw at runtime.
                      ScaffoldMessenger.of(context)
                        ..clearSnackBars()
                        ..showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Editing your profile is coming in a later '
                              'release.',
                            ),
                          ),
                        );
                    },
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: Text(strings.editProfile),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
                side: BorderSide(color: palette.border),
                backgroundColor: palette.surfaceRaised,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(LoqtaSpacing.radiusField),
                ),
                textStyle: LoqtaText.fieldLabel.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One navigation row in the Profile card list.
class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.icon,
    required this.label,
    this.onTap,
    this.tint,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  /// Overrides the icon/label colour, used for the destructive row.
  final Color? tint;

  /// When false the row is visibly inert. Reserved for destinations that are
  /// part of the approved navigation map but not yet built.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final palette = context.loqtaColors;
    final color = tint ?? palette.heading;
    final callback = enabled ? onTap : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border),
      ),
      child: InkWell(
        onTap: callback,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: enabled ? color : palette.textTertiary,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: LoqtaText.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: enabled ? color : palette.textTertiary,
                  ),
                ),
              ),
              Icon(
                // Chevron mirrors automatically in RTL; arrow_forward_ios points
                // right in LTR and left in Arabic, which is what we want.
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

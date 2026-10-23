import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:loqta/core/theme/app_theme.dart';

/// The top bar shared by every authentication screen.
///
/// Matches the approved screenshots (05–09): a thin back chevron on the left
/// (omitted on the root sign-in screen, which has no back affordance), the
/// screen name centred, and a circular green account button on the right.
class LoqtaAppBar extends StatelessWidget implements PreferredSizeWidget {
  const LoqtaAppBar({
    super.key,
    required this.title,
    this.showBack = true,
    this.onBack,
    this.trailing,
  });

  final String title;

  /// Whether the back chevron is rendered.
  final bool showBack;

  /// Invoked when the chevron is tapped. Defaults to popping the route.
  final VoidCallback? onBack;

  /// Overrides the trailing account button.
  final Widget? trailing;

  static const double _height = 52;

  @override
  Size get preferredSize => const Size.fromHeight(_height);

  void _handleBack(BuildContext context) {
    final callback = onBack;
    if (callback != null) {
      callback();
      return;
    }
    // On a root route there is nothing to pop, so fall back to leaving the app
    // rather than popping the only route.
    popRouteOrExit(context);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // The title is centred in the bar itself, not in the remaining
          // space between the chevron and the account button, which would
          // make it look off-centre. The padding keeps a long title clear of
          // both of them.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 52),
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: LoqtaText.screenTitle,
            ),
          ),
          Positioned(
            left: 4,
            child: showBack
                ? IconButton(
                    onPressed: () => _handleBack(context),
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      size: 18,
                      color: LoqtaColors.headingPrimary,
                    ),
                    tooltip: 'Back',
                    visualDensity: VisualDensity.compact,
                  )
                : const SizedBox.shrink(),
          ),
          Positioned(
            right: LoqtaSpacing.gutter - 6,
            child: trailing ?? const AccountButton(),
          ),
        ],
      ),
    );
  }
}

/// The circular green account button on the right of [LoqtaAppBar].
class AccountButton extends StatelessWidget {
  const AccountButton({super.key, this.onPressed, this.size = 34});

  final VoidCallback? onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: LoqtaColors.primary,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(
            Icons.person_outline,
            size: size * 0.55,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

/// Pops the route, or exits the app when [context] sits on the root route.
///
/// Kept as a small helper so every screen performs back navigation the same
/// way.
void popRouteOrExit(BuildContext context) {
  final navigator = Navigator.of(context);
  if (navigator.canPop()) {
    navigator.pop();
  } else {
    SystemNavigator.pop();
  }
}

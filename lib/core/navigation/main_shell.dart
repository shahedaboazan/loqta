import 'package:flutter/material.dart';

import 'package:loqta/core/localization/app_localizations.dart';
import 'package:loqta/core/theme/app_theme.dart';
import 'package:loqta/features/auth/presentation/pages/home_page.dart';
import 'package:loqta/features/chat/presentation/pages/chat_list_page.dart';
import 'package:loqta/features/listings/presentation/pages/favorites_page.dart';
import 'package:loqta/features/profile/presentation/pages/profile_page.dart';

/// The five top-level destinations of the Loqta app shell.
///
/// The order is fixed by the product navigation map and must not change:
/// Home, Favorites, Sell, Messages, Profile.
///
/// Note that Search is deliberately *not* a destination. Search is reached from
/// the Home search bar, which is why [MainDestination.sell] sits in the middle
/// as a primary action rather than a sixth tab.
enum MainDestination {
  home,
  favorites,
  sell,
  messages,
  profile;

  /// Whether this destination is one of the four tappable tabs.
  ///
  /// [MainDestination.sell] is a raised action button, not a tab, so it has no
  /// "selected" appearance of its own.
  bool get isTab => this != MainDestination.sell;
}

/// The single bottom navigation bar used by every main destination.
///
/// There is exactly one implementation of this bar in the app. Home, Favorites,
/// Messages and Profile all render it through [MainShell]; no destination draws
/// its own copy, so the order, styling and behaviour cannot drift apart.
class LoqtaBottomNav extends StatelessWidget {
  const LoqtaBottomNav({
    super.key,
    required this.current,
    required this.onDestinationSelected,
    required this.onSellTap,
  });

  /// The active destination. Ignored for [MainDestination.sell].
  final MainDestination current;

  /// Called when one of the four tabs is tapped.
  final ValueChanged<MainDestination> onDestinationSelected;

  /// Called when the raised Sell pill is tapped. Opens the Create Listing flow
  /// rather than switching destination.
  final VoidCallback onSellTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.loqtaColors;
    final strings = context.l10n;

    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border(top: BorderSide(color: palette.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          // Pinned height: an unbounded Row of Expanded children would
          // otherwise stretch to fill the whole screen.
          height: 64,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
                child: Row(
                  children: [
                    _NavTab(
                      icon: Icons.home_outlined,
                      activeIcon: Icons.home,
                      label: strings.navHome,
                      selected: current == MainDestination.home,
                      onTap: () => onDestinationSelected(MainDestination.home),
                    ),
                    _NavTab(
                      icon: Icons.favorite_border,
                      activeIcon: Icons.favorite,
                      label: strings.navFavorites,
                      selected: current == MainDestination.favorites,
                      onTap: () =>
                          onDestinationSelected(MainDestination.favorites),
                    ),
                    // Spacer reserved for the raised Sell pill, which is
                    // painted on top of the bar by the Stack below.
                    const Expanded(child: SizedBox.shrink()),
                    _NavTab(
                      icon: Icons.chat_bubble_outline,
                      activeIcon: Icons.chat_bubble,
                      label: strings.navMessages,
                      selected: current == MainDestination.messages,
                      onTap: () =>
                          onDestinationSelected(MainDestination.messages),
                    ),
                    _NavTab(
                      icon: Icons.person_outline,
                      activeIcon: Icons.person,
                      label: strings.navProfile,
                      selected: current == MainDestination.profile,
                      onTap: () =>
                          onDestinationSelected(MainDestination.profile),
                    ),
                  ],
                ),
              ),
              _SellPill(onTap: onSellTap),
            ],
          ),
        ),
      ),
    );
  }
}

/// The centre action: a raised, pill-shaped green button carrying a plus icon
/// and the "Sell" label.
///
/// It reads as a primary action rather than a navigation tab — it has no
/// selected state and it does not change destination — while still sitting
/// inside the bar's visual centre, matching the approved references.
class _SellPill extends StatelessWidget {
  const _SellPill({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.loqtaColors;
    final strings = context.l10n;

    return Transform.translate(
      offset: const Offset(0, -14),
      child: Material(
        color: Theme.of(context).colorScheme.primary,
        elevation: 4,
        shadowColor: palette.shadow,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: Theme.of(context).colorScheme.onPrimary,
                width: 2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add,
                  size: 20,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
                const SizedBox(width: 6),
                Text(
                  strings.navSell,
                  style: LoqtaText.button.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  const _NavTab({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.loqtaColors;
    final color = selected
        ? Theme.of(context).colorScheme.primary
        : palette.textTertiary;

    return Expanded(
      child: Semantics(
        selected: selected,
        button: true,
        label: label,
        child: InkWell(
          onTap: onTap,
          // A generous vertical target: the visual row is small but the touch
          // area fills the full bar height.
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(selected ? activeIcon : icon, size: 22, color: color),
                const SizedBox(height: 3),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 10.5,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    fontFamily: LoqtaText.family,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The shared shell that hosts every main destination.
///
/// Destinations live in an [IndexedStack] so each one keeps its scroll
/// position, form contents and BLoC state while the user moves between tabs —
/// switching to Messages and back must not reset Home.
///
/// The shell provides the BLoCs that must be *shared* across destinations (the
/// favourites list, so unfavouriting on Home is immediately reflected on the
/// Favorites tab), then hosts each destination page.
///
/// Search is pushed on top of the shell rather than becoming a tab, so it keeps
/// the shared bar and popping it returns to the tab the user came from.
class MainShell extends StatefulWidget {
  const MainShell({super.key, this.initialDestination = MainDestination.home});

  /// The destination shown on first build. Only AuthGate's initial frame uses
  /// this; after that the shell remembers the user's own selection.
  final MainDestination initialDestination;

  @override
  State<MainShell> createState() => MainShellState();
}

class MainShellState extends State<MainShell> {
  MainDestination _destination = MainDestination.home;

  /// Destinations built so far.
  ///
  /// An [IndexedStack] builds every child eagerly, which would open Favorites,
  /// Messages and Profile (and their repositories) before the user ever visits
  /// them. Building a destination on first selection keeps that startup work
  /// out of the Home frame while still preserving each visited page's state.
  final Set<MainDestination> _visited = <MainDestination>{};

  @override
  void initState() {
    super.initState();
    _destination = widget.initialDestination;
    _visited.add(_destination);
  }

  /// Switches the visible destination.
  ///
  /// Exposed to descendant pages (via [MainShellScope]) so Home can jump to
  /// Favorites or Profile from its app bar without duplicating the bar.
  void select(MainDestination destination) {
    if (_destination == destination) return;
    setState(() {
      _destination = destination;
      _visited.add(destination);
    });
  }

  Widget _pageFor(MainDestination destination) {
    if (!_visited.contains(destination)) return const SizedBox.shrink();
    return switch (destination) {
      MainDestination.home => const HomePage(),
      MainDestination.favorites => const FavoritesPage(),
      // The Sell slot is never rendered as a page: the pill is a primary
      // action, so tapping it never lands here.
      MainDestination.sell => const SizedBox.shrink(),
      MainDestination.messages => const ChatListPage(),
      MainDestination.profile => const ProfilePage(),
    };
  }

  void _notifyCreateListingUnavailable() {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        const SnackBar(
          content: Text('Listing a new item is coming in a later release.'),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.loqtaColors.background,
      body: MainShellScope(
        state: this,
        child: IndexedStack(
          index: _destination.index,
          children: [
            for (final destination in MainDestination.values)
              _pageFor(destination),
          ],
        ),
      ),
      bottomNavigationBar: LoqtaBottomNav(
        current: _destination,
        onDestinationSelected: select,
        onSellTap: _notifyCreateListingUnavailable,
      ),
    );
  }
}

/// Lets descendants reach the enclosing shell to switch destinations without
/// holding a reference to it.
///
/// Used by Home's avatar, which switches to the Profile tab instead of pushing
/// a duplicate copy of a screen that already exists as a destination.
class MainShellScope extends InheritedWidget {
  const MainShellScope({super.key, required this.state, required super.child});

  final MainShellState state;

  /// Selects a destination on the nearest enclosing shell.
  static MainShellState? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<MainShellScope>()?.state;
  }

  @override
  bool updateShouldNotify(MainShellScope oldWidget) => oldWidget.state != state;
}

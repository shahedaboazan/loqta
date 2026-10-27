import 'package:flutter/material.dart';
import 'package:loqta/core/localization/app_localizations.dart';
import 'package:loqta/features/listings/presentation/pages/my_listings_page.dart';

class PublishSuccessPage extends StatelessWidget {
  const PublishSuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(strings.publishSuccess),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(), // Return to previous
              child: Text(strings.cancel), // Assuming 'Done' maps to cancel/pop
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute<void>(builder: (_) => const MyListingsPage()),
              ),
              child: Text(strings.myListings),
            ),
          ],
        ),
      ),
    );
  }
}

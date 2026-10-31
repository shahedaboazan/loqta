
import 'package:flutter/material.dart';

import 'package:loqta/core/data/listing_categories.dart';
import 'package:loqta/core/theme/app_theme.dart';
import 'package:loqta/core/widgets/loqta_app_bar.dart';
import 'package:loqta/features/listings/presentation/pages/search_page.dart';

class AllCategoriesPage extends StatelessWidget {
  const AllCategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LoqtaColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const LoqtaAppBar(title: 'All Categories'),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(LoqtaSpacing.gutter),
                itemCount: kListingCategories.length,
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.9,
                ),
                itemBuilder: (context, index) {
                  final category = kListingCategories[index];

                  return Material(
                    color: LoqtaColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => SearchPage(
                              initialQuery: '',
                              category: category.key,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: LoqtaColors.border,
                          ),
                        ),
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              category.icon,
                              size: 30,
                              color: LoqtaColors.primary,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              category.key,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: LoqtaColors.textPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                fontFamily: LoqtaText.family,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

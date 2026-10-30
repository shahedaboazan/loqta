import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:loqta/core/data/listing_categories.dart';
import 'package:loqta/core/data/syria_locations.dart';
import 'package:loqta/core/data/listing_form_options.dart';
import 'package:loqta/core/localization/app_localizations.dart';
import 'package:loqta/core/theme/app_theme.dart';
import 'package:loqta/core/widgets/loqta_app_bar.dart';
import 'package:loqta/core/widgets/loqta_button.dart';
import 'package:loqta/core/widgets/loqta_text_field.dart';
import 'package:loqta/features/chat/domain/services/image_picker_service.dart';
import 'package:loqta/features/listings/domain/entities/listing.dart';
import 'package:loqta/features/listings/domain/entities/listing_draft.dart';
import 'package:loqta/features/listings/domain/repositories/listing_repository.dart';
import 'package:loqta/features/listings/domain/usecases/publish_listing_usecase.dart';
import 'package:loqta/features/listings/presentation/bloc/create_listing_bloc.dart';
import 'package:loqta/features/listings/presentation/pages/listing_preview_page.dart';
import 'package:loqta/features/listings/presentation/utils/create_listing_field_errors.dart';
import 'package:loqta/features/profile/domain/repositories/profile_repository.dart';
import 'package:loqta/features/profile/presentation/bloc/profile_bloc.dart';
/// Screen 22 — Create Listing.
///
/// Owns the [CreateListingBloc] for the whole flow, collects the draft and
/// validates the whole form before handing over to the Listing Preview screen.
///
/// The exact pickup address is asked for here and stored privately through the
/// publish call; it is never shown on a public surface.
class CreateListingPage extends StatelessWidget {
  const CreateListingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CreateListingBloc>(
      create: (_) => CreateListingBloc(
        picker: context.read<ImagePickerService>(),
        publish: PublishListingUseCase(context.read<ListingRepository>()),
      ),
      child: const CreateListingView(),
    );
  }
}

class CreateListingView extends StatefulWidget {
  const CreateListingView({super.key});

  @override
  State<CreateListingView> createState() => _CreateListingViewState();
}

class _CreateListingViewState extends State<CreateListingView> {
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _pickupController = TextEditingController();
  final _descriptionController = TextEditingController();

  int _previewNonce = 0;

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _pickupController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _continue() {
    if (context.read<CreateListingBloc>().state.isPickingPhotos) return;
    context.read<CreateListingBloc>().add(
      const CreateListingContinueRequested(),
    );
  }

  void _pickPhotos() {
    context.read<CreateListingBloc>().add(const CreateListingPhotosRequested());
  }

  Future<void> _goToPreview(
    BuildContext context,
    CreateListingState state,
  ) async {
    final currentNonce = state.previewNonce;
    if (currentNonce == _previewNonce) return;
    _previewNonce = currentNonce;
    final bloc = context.read<CreateListingBloc>();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (routeContext) => BlocProvider<ProfileBloc>(
  create: (_) => ProfileBloc(
    repository: routeContext.read<ProfileRepository>(),
  )..add(const ProfileRequested()),
  child: BlocProvider<CreateListingBloc>.value(
    value: bloc,
    child: const ListingPreviewPage(),
  ),
),
      ),
    );
  }

  void _handleState(BuildContext context, CreateListingState state) {
    _goToPreview(context, state);
  }

  void _handleNotice(BuildContext context, CreateListingState state) {
    final notice = state.notice;
    if (notice == null) return;
    context.read<CreateListingBloc>().add(const CreateListingNoticeHandled());
    final message = switch (notice) {
      CreateListingNoticePhotoLimit() => context.l10n.photoLimit,
      CreateListingNoticePhotoPickFailed(:final message) => message,
    };
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String? _errorOf(
    BuildContext context,
    ListingField field,
    ListingFieldError? error,
  ) {
    if (error == null) return null;
    return createListingFieldErrorText(context.l10n, field, error);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CreateListingBloc, CreateListingState>(
      listener: (context, state) {
        _handleState(context, state);
        _handleNotice(context, state);
      },
      builder: (context, state) {
        final strings = context.l10n;
        final draft = state.draft;
        final bloc = context.read<CreateListingBloc>();

        return Scaffold(
          backgroundColor: LoqtaColors.background,
          appBar: LoqtaAppBar(title: strings.createListing),
          bottomNavigationBar: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                LoqtaSpacing.gutter,
                12,
                LoqtaSpacing.gutter,
                12,
              ),
              child: LoqtaButton(
                label: strings.continueToPreview,
                onPressed: state.isPickingPhotos ? null : _continue,
                showArrow: true,
                height: 52,
              ),
            ),
          ),
          body: SafeArea(
            top: false,
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                LoqtaSpacing.gutter,
                16,
                LoqtaSpacing.gutter,
                24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ListingTypeSection(
                    draft: draft,
                    onChanged: (type) => bloc.add(ListingTypeChanged(type)),
                  ),
                  const SizedBox(height: 20),
                  _SectionHeader(strings.photos, isRequired: true),
                  const SizedBox(height: 4),
                  const Text(
                    'Clear, natural daylight photos sell up to 3x faster',
                    style: TextStyle(
                      color: LoqtaColors.textSecondary,
                      fontSize: 12,
                      fontFamily: LoqtaText.family,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _PhotosSection(
                    onPick: state.isPickingPhotos ? () {} : _pickPhotos,
                  ),
                  const SizedBox(height: 20),
                  _SectionHeader(strings.title, isRequired: true),
                  const SizedBox(height: 8),
                  _TitleField(
                    controller: _titleController,
                    hint: strings.titleHint,
                    counter:
                        '${draft.title.trim().length}/${ListingDraft.maxTitleLength}',
                    error: _errorOf(
                      context,
                      ListingField.title,
                      state.errors[ListingField.title],
                    ),
                    onChanged: (value) =>
                        bloc.add(CreateListingTitleChanged(value)),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Mention item type, brand, and key attributes (e.g. Modern Fabric Sofa 3-seater)',
                    style: TextStyle(
                      color: LoqtaColors.textSecondary,
                      fontSize: 11,
                      fontFamily: LoqtaText.family,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SelectField(
                    label: strings.category,
                    isRequired: true,
                    value: draft.category,
                    placeholder: strings.selectCategory,
                    options: kListingCategories
                        .map(
                          (category) => context.l10n.resolveCategory(
                            category.labelKey,
                            category.key,
                          ),
                        )
                        .toList(),
                    onSelected: (category) =>
                        bloc.add(CreateListingCategoryChanged(category)),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Allowed categories: Furniture, Electronics, Home Appliances, Clothes, Shoes, Children’s Items, Household Items, Books, Tools & Equipment, Car Parts, Other.',
                    style: TextStyle(
                      color: LoqtaColors.textSecondary,
                      fontSize: 11,
                      fontFamily: LoqtaText.family,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _ConditionSection(
                    value: draft.condition,
                    error: _errorOf(
                      context,
                      ListingField.condition,
                      state.errors[ListingField.condition],
                    ),
                    onChanged: (condition) =>
                        bloc.add(CreateListingConditionChanged(condition)),
                  ),
                  const SizedBox(height: 16),
                  if (draft.type == ListingType.sale) ...[
                    _SectionHeader(strings.price, isRequired: true),
                    const SizedBox(height: 16),
                    _PriceSection(
                      controller: _priceController,
                      priceText: draft.priceText,
                      currency: draft.currency,
                      error: _errorOf(
                        context,
                        ListingField.price,
                        state.errors[ListingField.price],
                      ),
                      currencyError: _errorOf(
                        context,
                        ListingField.currency,
                        state.errors[ListingField.currency],
                      ),
                      onPriceChanged: (value) =>
                          bloc.add(CreateListingPriceChanged(value)),
                      onCurrencyChanged: (currency) =>
                          bloc.add(CreateListingCurrencyChanged(currency)),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Price in Syrian Pounds (SYP).',
                      style: TextStyle(
                        color: LoqtaColors.textSecondary,
                        fontSize: 11,
                        fontFamily: LoqtaText.family,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  _SectionHeader(strings.governorate, isRequired: true),
                  const SizedBox(height: 8),
                  _SelectField(
                    label: '',
                    isRequired: false,
                    value: draft.governorate.isEmpty
                        ? strings.selectGovernorate
                        : draft.governorate,
                    placeholder: strings.selectGovernorate,
                    options: SyriaLocations.governorateKeys,
                    onSelected: (governorate) =>
                        bloc.add(CreateListingGovernorateChanged(governorate)),
                  ),
                  const SizedBox(height: 20),

                  _PickupAddressSection(
                    controller: _pickupController,
                    error: _errorOf(
                      context,
                      ListingField.pickupAddress,
                      state.errors[ListingField.pickupAddress],
                    ),
                    onChanged: (value) =>
                        bloc.add(CreateListingPickupAddressChanged(value)),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: context.loqtaColors.surfaceRaised,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: context.loqtaColors.border),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.lock_outline,
                          size: 16,
                          color: LoqtaColors.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Your exact pickup address is private. It is never displayed publicly on your listing and is only shared with confirmed buyers/recipients.',
                            style: TextStyle(
                              fontSize: 11,
                              color: LoqtaColors.textSecondary,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  _DeliverySection(
                    value: draft.deliveryAvailable,
                    error: _errorOf(
                      context,
                      ListingField.delivery,
                      state.errors[ListingField.delivery],
                    ),
                    onChanged: (value) =>
                        bloc.add(CreateListingDeliveryChanged(value)),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: context.loqtaColors.surfaceRaised,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: context.loqtaColors.border),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 16,
                          color: LoqtaColors.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'You will arrange pickup or delivery directly with the other person through chat. Loqta does not manage transport.',
                            style: TextStyle(
                              fontSize: 11,
                              color: LoqtaColors.textSecondary,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  _SectionHeader(strings.description, isRequired: true),
                  const SizedBox(height: 8),
                  _DescriptionField(
                    controller: _descriptionController,
                    error: _errorOf(
                      context,
                      ListingField.description,
                      state.errors[ListingField.description],
                    ),
                    onChanged: (value) =>
                        bloc.add(CreateListingDescriptionChanged(value)),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Include dimensions, defects, reasons for selling',
                    style: TextStyle(
                      color: LoqtaColors.textSecondary,
                      fontSize: 11,
                      fontFamily: LoqtaText.family,
                    ),
                  ),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label, {this.isRequired = false});

  final String label;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    return Text(
      isRequired ? '$label *' : label,
      style: const TextStyle(
        color: LoqtaColors.headingPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w700,
        fontFamily: LoqtaText.family,
      ),
    );
  }
}

class _ListingTypeSection extends StatelessWidget {
  const _ListingTypeSection({required this.draft, required this.onChanged});

  final ListingDraft draft;
  final ValueChanged<ListingType> onChanged;

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;

    return Row(
      children: [
        for (var i = 0; i < ListingType.values.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: _OptionCard(
              icon: ListingType.values[i].isDonation
                  ? Icons.redeem_outlined
                  : Icons.check_circle_outline,
              label: ListingType.values[i].isDonation
                  ? strings.listingTypeDonation
                  : strings.listingTypeSale,
              selected: draft.type == ListingType.values[i],
              onTap: () => onChanged(ListingType.values[i]),
            ),
          ),
        ],
      ],
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(LoqtaSpacing.radiusField),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? LoqtaColors.surfaceMint : LoqtaColors.surface,
          borderRadius: BorderRadius.circular(LoqtaSpacing.radiusField),
          border: Border.all(
            color: selected ? LoqtaColors.primary : LoqtaColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: selected ? LoqtaColors.primary : LoqtaColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected
                    ? LoqtaColors.primary
                    : LoqtaColors.headingPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                fontFamily: LoqtaText.family,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotosSection extends StatelessWidget {
  const _PhotosSection({required this.onPick});

  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final bloc = context.watch<CreateListingBloc>();
    final draft = bloc.state.draft;
    final strings = context.l10n;
    final photoError = bloc.state.errors[ListingField.photos];
    final error = photoError != null
        ? createListingFieldErrorText(strings, ListingField.photos, photoError)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (var i = 0; i < draft.photos.length; i++)
              _PhotoTile(
                photo: draft.photos[i],
                onRemove: () =>
                    context.read<CreateListingBloc>().add(PhotoRemoved(i)),
              ),
            if (draft.photos.length < ListingDraft.maxPhotos)
              _AddPhotoTile(onTap: onPick),
          ],
        ),
        if (error != null) ...[const SizedBox(height: 8), _FieldError(error)],
      ],
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({required this.photo, required this.onRemove});

  final ListingDraftPhoto photo;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 76,
      height: 76,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(
              photo.bytes,
              width: 76,
              height: 76,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddPhotoTile extends StatelessWidget {
  const _AddPhotoTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 76,
      height: 76,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: LoqtaColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.zero,
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_a_photo_outlined,
              size: 20,
              color: LoqtaColors.primary,
            ),
            SizedBox(height: 2),
            Text(
              'Add',
              style: TextStyle(
                color: LoqtaColors.primary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                fontFamily: LoqtaText.family,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TitleField extends StatelessWidget {
  const _TitleField({
    required this.controller,
    required this.hint,
    required this.counter,
    required this.error,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final String counter;
  final String? error;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return LoqtaTextField(
      controller: controller,
      label: '',
      hintText: hint,
      counter: counter,
      helper: error,
      helperError: error != null,
      inputFormatters: [
        LengthLimitingTextInputFormatter(ListingDraft.maxTitleLength),
      ],
      onChanged: onChanged,
    );
  }
}

class _SelectField extends StatelessWidget {
  const _SelectField({
    required this.label,
    required this.isRequired,
    required this.value,
    required this.placeholder,
    required this.options,
    required this.onSelected,
  });

  final String label;
  final bool isRequired;
  final String value;
  final String placeholder;
  final List<String> options;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return _FieldShell(
      label: isRequired ? '$label *' : label,
      isRequired: false,
      child: _SelectControl(
        title: isRequired ? '$label *' : label,
        value: value.isEmpty ? placeholder : value,
        options: options,
        selectedValue: value,
        onSelected: onSelected,
      ),
    );
  }
}

class _SelectControl extends StatelessWidget {
  const _SelectControl({
    required this.title,
    required this.value,
    required this.options,
    required this.selectedValue,
    required this.onSelected,
  });

  final String title;
  final String value;
  final List<String> options;
  final String selectedValue;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showModalBottomSheet<String>(
          context: context,
          isScrollControlled: true,
          backgroundColor: LoqtaColors.background,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (sheetContext) {
            final maxHeight = MediaQuery.sizeOf(sheetContext).height * 0.75;

            return SafeArea(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxHeight),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        LoqtaSpacing.gutter,
                        16,
                        LoqtaSpacing.gutter,
                        8,
                      ),
                      child: Text(
                        title,
                        style: LoqtaText.heading.copyWith(
                          color: LoqtaColors.headingPrimary,
                        ),
                      ),
                    ),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: options.length,
                        itemBuilder: (context, index) {
                          final option = options[index];

                          return ListTile(
                            title: Text(option),
                            selected: option == selectedValue,
                            selectedTileColor: LoqtaColors.surfaceMint,
                            onTap: () {
                              Navigator.of(sheetContext).pop(option);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );

        if (picked != null) onSelected(picked);

        if (picked != null) onSelected(picked);
      },
      borderRadius: BorderRadius.circular(LoqtaSpacing.radiusField),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: LoqtaColors.fieldFill,
          borderRadius: BorderRadius.circular(LoqtaSpacing.radiusField),
          border: Border.all(color: LoqtaColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value,
                style: LoqtaText.body.copyWith(
                  color: LoqtaColors.headingPrimary,
                ),
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down,
              size: 18,
              color: LoqtaColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldShell extends StatelessWidget {
  const _FieldShell({
    required this.label,
    required this.isRequired,
    required this.child,
  });

  final String label;
  final bool isRequired;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(isRequired ? '$label *' : label, style: LoqtaText.fieldLabel),
          const SizedBox(height: 7),
        ],
        child,
      ],
    );
  }
}

class _FieldError extends StatelessWidget {
  const _FieldError(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.error_outline, size: 13, color: LoqtaColors.error),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            message,
            style: LoqtaText.caption.copyWith(color: LoqtaColors.error),
          ),
        ),
      ],
    );
  }
}

class _ConditionSection extends StatelessWidget {
  const _ConditionSection({
    required this.value,
    required this.error,
    required this.onChanged,
  });

  final String value;
  final String? error;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldShell(
          label: '${strings.condition} *',
          isRequired: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  value.isNotEmpty ? 'Selected: $value' : '',
                  style: const TextStyle(
                    color: LoqtaColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: kListingConditionValues.map((condition) {
                  final selected = value == condition;
                  return ChoiceChip(
                    label: Text(condition),
                    selected: selected,
                    selectedColor: LoqtaColors.primary,
                    backgroundColor: LoqtaColors.surface,
                    labelStyle: TextStyle(
                      color: selected
                          ? Colors.white
                          : LoqtaColors.headingPrimary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      fontFamily: LoqtaText.family,
                    ),
                    showCheckmark: false,
                    onSelected: (_) => onChanged(condition),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          '“Good” means normal gentle use, minor signs of cosmetic wear, fully functional.',
          style: TextStyle(
            color: LoqtaColors.textSecondary,
            fontSize: 11,
            fontFamily: LoqtaText.family,
          ),
        ),
        if (error != null) ...[const SizedBox(height: 8), _FieldError(error!)],
      ],
    );
  }
}

class _PriceSection extends StatelessWidget {
  const _PriceSection({
    required this.controller,
    required this.priceText,
    required this.currency,
    required this.error,
    required this.currencyError,
    required this.onPriceChanged,
    required this.onCurrencyChanged,
  });

  final TextEditingController controller;
  final String priceText;
  final String currency;
  final String? error;
  final String? currencyError;
  final ValueChanged<String> onPriceChanged;
  final ValueChanged<String> onCurrencyChanged;

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;

    return _FieldShell(
      label: '${strings.price} *',
      isRequired: false,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                hintText: strings.enterPrice,
                hintStyle: LoqtaText.fieldHint,
                filled: true,
                fillColor: LoqtaColors.fieldFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(LoqtaSpacing.radiusField),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
              ),
              onChanged: onPriceChanged,
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 110,
            child: _SelectControl(
              title: strings.currency,
              value: currency,
              options: kListingCurrencies,
              selectedValue: currency,
              onSelected: onCurrencyChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _PickupAddressSection extends StatelessWidget {
  const _PickupAddressSection({
    required this.controller,
    required this.error,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String? error;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;

    return _FieldShell(
      label: '${strings.exactPickupAddress} *',
      isRequired: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Specific street, building or landmark for handoff',
            style: TextStyle(
              color: LoqtaColors.textSecondary,
              fontSize: 11,
              fontFamily: LoqtaText.family,
            ),
          ),
          const SizedBox(height: 8),
          LoqtaTextField(
            controller: controller,
            label: '',
            hintText: strings.exactPickupAddressHint,
            helper: error,
            helperError: error != null,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _DeliverySection extends StatelessWidget {
  const _DeliverySection({
    required this.value,
    required this.error,
    required this.onChanged,
  });

  final bool? value;
  final String? error;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldShell(
          label: '${strings.deliveryOption} *',
          isRequired: false,
          child: Column(
            children: [
              _DeliveryRow(
                label: strings.pickupOnly,
                subLabel: 'Buyer collects in person from your area.',
                selected: value == false,
                onTap: () => onChanged(false),
              ),
              const SizedBox(height: 8),
              _DeliveryRow(
                label: strings.deliveryAvailable,
                subLabel: 'You can arrange or handle local delivery directly.',
                selected: value == true,
                onTap: () => onChanged(true),
              ),
            ],
          ),
        ),
        if (error != null) ...[const SizedBox(height: 8), _FieldError(error!)],
      ],
    );
  }
}

class _DeliveryRow extends StatelessWidget {
  const _DeliveryRow({
    required this.label,
    required this.subLabel,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String subLabel;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(LoqtaSpacing.radiusField),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? LoqtaColors.surfaceMint : LoqtaColors.surface,
          borderRadius: BorderRadius.circular(LoqtaSpacing.radiusField),
          border: Border.all(
            color: selected ? LoqtaColors.primary : LoqtaColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                selected ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 20,
                color: selected
                    ? LoqtaColors.primary
                    : LoqtaColors.textTertiary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: LoqtaText.body.copyWith(
                      color: LoqtaColors.headingPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      color: LoqtaColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DescriptionField extends StatelessWidget {
  const _DescriptionField({
    required this.controller,
    required this.error,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String? error;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return LoqtaTextField(
      controller: controller,
      label: '',
      maxLines: 4,
      keyboardType: TextInputType.multiline,
      inputFormatters: [
        LengthLimitingTextInputFormatter(ListingDraft.maxDescriptionLength),
      ],
      helper: error,
      helperError: error != null,
      onChanged: onChanged,
    );
  }
}

import 'package:loqta/core/localization/app_strings.dart';

/// The Arabic translation of every string in [AppStrings].
///
/// Implementing the abstract interface means the compiler enforces that this
/// class stays complete: adding a getter to `AppStrings` without adding it here
/// fails `flutter analyze`, so a half-translated release cannot ship.
class AppStringsAr extends AppStrings {
  const AppStringsAr();

  @override
  String get preview => 'معاينة';
  @override
  String get publish => 'نشر';
  @override
  String get publishSuccess => 'تم النشر';
  @override
  String get appName => 'لقطة';
  @override
  String get retry => 'إعادة المحاولة';
  @override
  String get cancel => 'إلغاء';
  @override
  String get save => 'حفظ';
  @override
  String get delete => 'حذف';
  @override
  String get remove => 'إزالة';
  @override
  String get edit => 'تعديل';
  @override
  String get back => 'رجوع';
  @override
  String get loading => 'جارٍ التحميل...';
  @override
  String get somethingWentWrong => 'حدث خطأ ما.';
  @override
  String get tryAgain => 'حاول مرة أخرى';

  @override
  String get navHome => 'الرئيسية';
  @override
  String get navFavorites => 'المفضلة';
  @override
  String get navSell => 'بيع';
  @override
  String get navMessages => 'الرسائل';
  @override
  String get navProfile => 'حسابي';
  @override
  String get navSearch => 'بحث';

  @override
  String get onboarding1Title => 'بيع واشترِ بالقرب منك';
  @override
  String get onboarding1Body => 'اكتشف صفقات رائعة من أشخاص في مدينتك.';
  @override
  String get onboarding2Title => 'امنح الأشياء حياة ثانية';
  @override
  String get onboarding2Body => 'تبرّع بما لا تحتاجه وساعد مجتمعك.';
  @override
  String get onboarding3Title => 'تواصل بأمان';
  @override
  String get onboarding3Body =>
      'محادثة مباشرة مع المشترين والمتبرعين، واتفقوا على موعد تسليم آمن.';
  @override
  String get onboardingCta1 => 'التالي';
  @override
  String get onboardingCta2 => 'التالي';
  @override
  String get onboardingCta3 => 'ابدأ الآن';
  @override
  String get onboardingSkip => 'تخطي';
  @override
  String get getStarted => 'ابدأ الآن';

  @override
  String get signIn => 'تسجيل الدخول';
  @override
  String get signUp => 'إنشاء حساب';
  @override
  String get signInTitle => 'مرحباً بعودتك';
  @override
  String get signInSubtitle => 'سجّل الدخول للمتابعة إلى لقطة.';
  @override
  String get signUpTitle => 'أنشئ حسابك';
  @override
  String get signUpSubtitle => 'انضم إلى لقطة وابدأ التداول خلال دقائق.';
  @override
  String get email => 'البريد الإلكتروني';
  @override
  String get password => 'كلمة المرور';
  @override
  String get confirmPassword => 'تأكيد كلمة المرور';
  @override
  String get fullName => 'الاسم الكامل';
  @override
  String get firstName => 'الاسم الأول';
  @override
  String get lastName => 'اسم العائلة';
  @override
  String get forgotPassword => 'نسيت كلمة المرور؟';
  @override
  String get dontHaveAccount => 'ليس لديك حساب؟';
  @override
  String get alreadyHaveAccount => 'لديك حساب بالفعل؟';
  @override
  String get orContinueWith => 'أو تابع باستخدام';
  @override
  String get welcomeBack => 'مرحباً بعودتك';
  @override
  String get createAccount => 'إنشاء الحساب';
  @override
  String get emailRequired => 'البريد الإلكتروني مطلوب';
  @override
  String get emailInvalid => 'أدخل بريداً إلكترونياً صحيحاً';
  @override
  String get passwordRequired => 'كلمة المرور مطلوبة';
  @override
  String get passwordTooShort => 'يجب ألا تقل كلمة المرور عن ٦ أحرف';
  @override
  String get passwordsDoNotMatch => 'كلمتا المرور غير متطابقتين';
  @override
  String get nameRequired => 'الاسم مطلوب';
  @override
  String get signOut => 'تسجيل الخروج';
  @override
  String get signInFailed => 'تعذّر تسجيل الدخول. يرجى المحاولة مرة أخرى.';
  @override
  String get signUpFailed => 'تعذّر إنشاء حسابك. يرجى المحاولة مرة أخرى.';
  @override
  String get accountCreated => 'تم إنشاء الحساب';
  @override
  String get confirmationEmailSent => 'تم إرسال رسالة التأكيد';
  @override
  String get confirmationEmailBody =>
      'يرجى التحقق من بريدك الوارد واتباع الرابط لتفعيل حسابك.';
  @override
  String get resendEmail => 'إعادة إرسال البريد';
  @override
  String get backToSignIn => 'العودة لتسجيل الدخول';
  @override
  String get forgotPasswordTitle => 'إعادة تعيين كلمة المرور';
  @override
  String get forgotPasswordSubtitle =>
      'أدخل بريدك الإلكتروني وسنرسل لك رابط إعادة التعيين.';
  @override
  String get resetEmailSent => 'تم إرسال رسالة إعادة تعيين كلمة المرور';
  @override
  String get resetPasswordTitle => 'اختر كلمة مرور جديدة';
  @override
  String get resetPasswordSubtitle => 'أدخل كلمة مرور جديدة لحسابك.';
  @override
  String get newPassword => 'كلمة المرور الجديدة';
  @override
  String get passwordUpdated => 'تم تحديث كلمة المرور';
  @override
  String get openEmailApp => 'افتح تطبيق البريد';

  @override
  String get searchHint => 'ابحث عن عناصر...';
  @override
  String get locationAll => 'الكل';
  @override
  String get forSale => 'للبيع';
  @override
  String get forDonation => ' للتبرع';
  @override
  String get browseForSale => 'تصفّح العناصر المعروضة للبيع';
  @override
  String get communityGifts => 'هدايا مجانية من المجتمع';
  @override
  String get categories => 'الفئات';
  @override
  String get seeAll => 'عرض الكل';
  @override
  String get featuredFinds => 'مختارات مميزة';
  @override
  String get latestItems => 'أحدث العناصر';
  @override
  String get noListingsYet => 'لا توجد إعلانات بعد';
  @override
  String get noListingsYetBody => 'كن أول من يعرض عنصراً للبيع أو للتبرع.';
  @override
  String get filterBy => 'تصفية حسب';

  @override
  String get condition => 'الحالة';
  @override
  String get newItem => 'جديد';
  @override
  String get likeNew => 'كالجديد';
  @override
  String get goodCondition => 'حالة جيدة';
  @override
  String get acceptable => 'مقبولة';
  @override
  String get usedFairly => 'مستعمل';
  @override
  String get free => 'مجاناً';
  @override
  String get description => 'الوصف';
  @override
  String get category => 'الفئة';
  @override
  String get governorate => 'المحافظة';
  @override
  String get area => 'المنطقة';
  @override
  String get deliveryAvailable => 'توصيل متاح';
  @override
  String get pickupOnly => 'استلام فقط';
  @override
  String get contactSeller => 'تواصل مع البائع';
  @override
  String get requestItem => 'اطلب هذا العنصر';
  @override
  String get reportListing => 'الإبلاغ عن الإعلان';
  @override
  String get seller => 'البائع';
  @override
  String get donor => 'المتبرع';
  @override
  String get deleteListing => 'حذف الإعلان';
  @override
  String get noListings => 'لا توجد إعلانات';
  @override
  String get noListingsBody =>
      'ستظهر الإعلانات التي تنشئها هنا لتتمكن من إدارتها.';
  @override
  String get listingNotFound => 'هذا الإعلان لم يعد متاحاً.';

  @override
  String get searchTitle => 'بحث';
  @override
  String get searchResults => 'نتائج البحث';
  @override
  String get noResults => 'لا توجد نتائج';
  @override
  String get noResultsBody => 'جرّب كلمات مختلفة أو امسح عوامل التصفية.';
  @override
  String get applyFilters => 'تطبيق التصفية';
  @override
  String get clearFilters => 'مسح التصفية';
  @override
  String get filters => 'تصفية';
  @override
  String get keyword => 'كلمة مفتاحية';
  @override
  String get priceRange => 'نطاق السعر';
  @override
  String get listingType => 'نوع الإعلان';
  @override
  String get all => 'الكل';
  @override
  String get noFavorites => 'لا توجد مفضلات أخرى';
  @override
  String get noFavoritesBody =>
      'احفظ العناصر التي تعجبك أثناء التصفح وستجدها بسهولة هنا في أي وقت.';
  @override
  String get browseMoreItems => 'تصفّح المزيد من العناصر';
  @override
  String get removeFromFavorites => 'إزالة من المفضلة';

  @override
  String get createListing => 'إنشاء إعلان';
  @override
  String get photos => 'الصور';
  @override
  String get addPhotos => 'إضافة';
  @override
  String get goodDaylightPhotos =>
      'الصور الواضحة بإضاءة النهار الطبيعي تبيع أسرع بثلاث مرات';
  @override
  String get title => 'العنوان';
  @override
  String get titleHint => 'ما الذي تبيعه؟';
  @override
  String get itemLocation => 'موقع العنصر (المحافظة والمنطقة)';
  @override
  String get exactPickupAddress => 'عنوان الاستلام الدقيق (خاص)';
  @override
  String get exactPickupAddressHint => 'عنوان الشارع، البناء، أقرب معلم';
  @override
  String get exactPickupAddressPrivacy =>
      'عنوان الاستلام الدقيق خاص بك. لا يظهر علناً أبداً ولا يُشارك إلا مع المشترين أو المتبرعين المؤكَّدين.';
  @override
  String get deliveryOption => 'خيار التسليم';
  @override
  String get deliveryOptionNote =>
      'ستتولى ترتيب الاستلام أو التسليم مباشرة مع الشخص الآخر. لا تتولى لقطة إدارة المدفوعات أو الشحن.';
  @override
  String get continueToPreview => 'المتابعة للمعاينة';
  @override
  String get listingTypePrice => 'نوع الإعلان والسعر';
  @override
  String get whatWouldYouLikeToDo => 'ماذا تريد أن تفعل؟';
  @override
  String get whatWouldYouLikeToDoBody =>
      'اختر هل أنت تبيع عنصراً أم تتبرع به في مجتمعك المحلي.';
  @override
  String get sellYourPrice => 'بِالسعر الذي تريد';
  @override
  String get communityGift => 'هدية مجتمعية';
  @override
  String get openListingEditor => 'جارٍ فتح محرّر الإعلان...';
  @override
  String get cancelAndReturnHome => 'إلغاء والعودة للرئيسية';
  @override
  String get directNeighborNote =>
      'كلا الخيارين يظهر ضمن مجتمعك المحلي. البائعون يصلون إلى أشخاص أكثر عبر القناتين ويحددون أسعارهم بأنفسهم.';
  @override
  String get listingPreview => 'معاينة الإعلان';
  @override
  String get publishListing => 'نشر الإعلان';
  @override
  String get publishing => 'جارٍ النشر...';
  @override
  String get publishFailed => 'تعذّر نشر إعلانك. تم الاحتفاظ ببياناتك.';
  @override
  String get published => 'إعلانك متاح الآن.';
  @override
  String get viewListing => 'عرض الإعلان';
  @override
  String get myListings => 'إعلاناتي';
  @override
  String get backToHome => 'العودة للرئيسية';
  @override
  String get requiredField => 'هذا الحقل مطلوب';
  @override
  String get enterPrice => 'أدخل السعر';
  @override
  String get priceMustBePositive => 'يجب أن يكون السعر أكبر من صفر';
  @override
  String get selectCategory => 'اختر فئة';
  @override
  String get selectGovernorate => 'اختر محافظة';
  @override
  String get selectArea => 'اختر منطقة';
  @override
  String get privateNote => 'خاص';
  @override
  String get listingTypeSale => 'للبيع';
  @override
  String get listingTypeDonation => ' للتبرع';
  @override
  String get price => 'السعر';
  @override
  String get currency => 'العملة';
  @override
  String get photosHint => 'حتى 5 صور';
  @override
  String get photoRequired => 'أضف صورة واحدة على الأقل';
  @override
  String get photoLimit => 'يمكنك إضافة 5 صور كحد أقصى';
  @override
  String get titleTooShort => 'العنوان 3 أحرف على الأقل';
  @override
  String get titleTooLong => 'العنوان 120 حرفًا كحد أقصى';
  @override
  String get priceInvalid => 'أدخل سعرًا صحيحًا';
  @override
  String get selectCondition => 'اختر الحالة';
  @override
  String get selectCurrency => 'اختر العملة';
  @override
  String get selectDeliveryOption => 'اختر خيار التوصيل';
  @override
  String get conditionFair => 'مقبول';
  @override
  String get publishSuccessTitle => 'تم النشر';
  @override
  String get listingPublishedByYou => 'تم نشر إعلانك بنجاح';
  @override
  String get descriptionTooLong => 'الوصف 1000 حرف كحد أقصى';

  @override
  String get statusAvailable => 'متاح';
  @override
  String get statusReserved => 'محجوز';
  @override
  String get statusSold => 'تم البيع';
  @override
  String get statusDonated => 'تم التبرع';
  @override
  String get statusDeleted => 'محذوف';
  @override
  String get myListingsTitle => 'إعلاناتي';
  @override
  String get manage => 'إدارة';
  @override
  String get markReserved => 'تحديد كمحجوز';
  @override
  String get markSold => 'تحديد كمباع';
  @override
  String get markDonated => 'تحديد كمتبرَّع به';

  @override
  String get chatMessages => 'المحادثات';
  @override
  String get directAndSecure => 'محادثات مباشرة وآمنة بين الأشخاص';
  @override
  String get verified => 'موثّق';
  @override
  String get noMessages => 'لا توجد رسائل أخرى';
  @override
  String get noMessagesBody =>
      'ستظهر محادثاتك حول الإعلانات هنا، لتنسيق آمن وسري مع المشترين والبائعين المحليين.';
  @override
  String get messageHint => 'رسالة';
  @override
  String get reportUser => 'الإبلاغ عن المستخدم';
  @override
  String get reportUserTitle => 'الإبلاغ عن المستخدم';
  @override
  String get today => 'اليوم';
  @override
  String get yesterday => 'أمس';

  @override
  String get notifications => 'الإشعارات';
  @override
  String get allNotifications => 'كل الإشعارات';
  @override
  String get markAllRead => 'تعليم الكل كمقروء';
  @override
  String get noNotifications => 'لا توجد إشعارات';
  @override
  String get noNotificationsBody => 'لا يوجد جديد لديك.';

  @override
  String get profile => 'حسابي';
  @override
  String get editProfile => 'تعديل الملف الشخصي';
  @override
  String get changePhoto => 'تغيير الصورة';
  @override
  String get removePhoto => 'إزالة الصورة';
  @override
  String get phoneNumber => 'رقم الهاتف';
  @override
  String get optional => 'اختياري';
  @override
  String get readOnly => 'للقراءة فقط';
  @override
  String get emailCannotChange => 'لا يمكن تغيير البريد الإلكتروني';
  @override
  String get saveChanges => 'حفظ التغييرات';
  @override
  String get profileSaved => 'تم تحديث الملف الشخصي';
  @override
  String get profileSaveFailed => 'تعذّر حفظ ملفك الشخصي.';
  @override
  String get verifiedMember => 'عضو موثّق في لقطة';
  @override
  String get verifiedMemberBody =>
      'حافظ على تحديث بيانات التواصل لتسهيل عملية التسليم.';
  @override
  String get myActivity => 'نشاطي';
  @override
  String get transactionHistory => 'سجل المعاملات';
  @override
  String get myRatings => 'تقييماتي';
  @override
  String get settings => 'الإعدادات';
  @override
  String get account => 'الحساب';
  @override
  String get logOut => 'تسجيل الخروج';
  @override
  String get deleteAccount => 'حذف الحساب';
  @override
  String get notificationsCount => 'الإشعارات';

  @override
  String get active => 'نشطة';
  @override
  String get completed => 'مكتملة';
  @override
  String get history => 'السجل';
  @override
  String get noTransactions => 'لا يوجد سجل معاملات بعد';
  @override
  String get noTransactionsBody => 'ستظهر المعاملات المكتملة هنا.';
  @override
  String get transactionDetails => 'تفاصيل المعاملة';
  @override
  String get transactionType => 'نوع المعاملة';
  @override
  String get counterpart => 'الطرف الآخر';
  @override
  String get agreedAmount => 'المبلغ المتفق عليه';
  @override
  String get currentStatus => 'الحالة الحالية';
  @override
  String get handoffLocation => 'موقع التسليم';
  @override
  String get completeTransaction => 'إتمام المعاملة';
  @override
  String get confirmCompleteTitle => 'إتمام هذه المعاملة؟';
  @override
  String get confirmCompleteBody =>
      'سيتم اعتبار العنصر مسلَّماً. لا يمكن التراجع عن ذلك.';
  @override
  String get confirmAndComplete => 'تأكيد وإتمام';
  @override
  String get transactionCompleted => 'تم إتمام المعاملة';
  @override
  String get transactionCompleteFailed =>
      'تعذّر إتمام المعاملة. يرجى المحاولة مرة أخرى.';
  @override
  String get exchangeLifecycle => 'مراحل العملية';
  @override
  String get listingPublished => 'متاح\nتم النشر';
  @override
  String get reservedInHandoff => 'محجوز\nقيد التسليم';
  @override
  String get soldComplete => 'تم البيع\nمكتملة';
  @override
  String get itemHandoffNote =>
      'تم تنسيق تبادل العنصر مباشرة عبر المحادثة. أكمل المعاملة بمجرد تسليم العنصر.';

  @override
  String get rateTransaction => 'قيّم المعاملة';
  @override
  String get ratingComment => 'تعليق';
  @override
  String get ratingCommentHint => 'شارك كيف كانت تجربة التبادل (اختياري)';
  @override
  String get submitRating => 'إرسال التقييم';
  @override
  String get ratingSubmitted => 'شكراً لتقييمك';
  @override
  String get ratingSubmitFailed => 'تعذّر إرسال تقييمك.';
  @override
  String get alreadyRated => 'لقد قيّمت هذه المعاملة مسبقاً';
  @override
  String get myRatingsTitle => 'تقييماتي';
  @override
  String get noRatings => 'لا توجد تقييمات بعد';
  @override
  String get noRatingsBody =>
      'ستظهر هنا التقييمات التي تتلقاها بعد إتمام المعاملات.';
  @override
  String get averageRating => 'متوسط التقييم';
  @override
  String get ratingsCount => 'تقييم';

  @override
  String get language => 'اللغة';
  @override
  String get english => 'English';
  @override
  String get arabic => 'العربية';
  @override
  String get theme => 'المظهر';
  @override
  String get lightMode => 'فاتح';
  @override
  String get darkMode => 'داكن';
  @override
  String get securityPrivacy => 'الأمان والخصوصية';
  @override
  String get changePassword => 'تغيير كلمة المرور';
  @override
  String get accountSecurity => 'أمان الحساب';
  @override
  String get privacyInformation => 'معلومات الخصوصية';
  @override
  String get aboutLoqta => 'حول لقطة';
  @override
  String get version => 'الإصدار';

  @override
  String get reportListingTitle => 'الإبلاغ عن الإعلان';
  @override
  String get reportUserReasonTitle => 'سبب الإبلاغ';
  @override
  String get reasonInappropriateContent => 'محتوى غير لائق';
  @override
  String get reasonFraud => 'احتيال / احتيال إلكتروني';
  @override
  String get reasonMisleadingInfo => 'معلومات مضللة';
  @override
  String get reasonIncorrectCategory => 'فئة غير صحيحة';
  @override
  String get reasonSuspiciousListing => 'إعلان مشبوه';
  @override
  String get reasonHarassment => 'تحرّش';
  @override
  String get reasonInappropriateBehavior => 'سلوك غير لائق';
  @override
  String get reasonSuspiciousActivity => 'نشاط مشبوه';
  @override
  String get reasonOther => 'أخرى';
  @override
  String get submitReport => 'إرسال البلاغ';
  @override
  String get reportSubmitted => 'تم إرسال البلاغ';
  @override
  String get reportSubmitFailed =>
      'تعذّر إرسال البلاغ. يرجى المحاولة مرة أخرى.';

  @override
  String get categoryAll => 'الكل';
  @override
  String get categoryFurniture => 'أثاث';
  @override
  String get categoryElectronics => 'إلكترونيات';
  @override
  String get categoryAppliances => 'أجهزة منزلية';
  @override
  String get categoryClothes => 'ملابس';
  @override
  String get categoryShoes => 'أحذية';
  @override
  String get categoryKids => 'أطفال';
  @override
  String get categoryBooks => 'كتب';
  @override
  String get categoryHomeGarden => 'منزل وحديقة';
  @override
  String get categorySports => 'رياضة';
  @override
  String get categoryVehicles => 'مركبات';
  @override
  String get categoryPhones => 'هواتف';
  @override
  String get categoryComputers => 'حواسيب';
  @override
  String get categoryJewelry => 'مجوهرات';
  @override
  String get categoryToys => 'ألعاب';
  @override
  String get categoryOther => 'أخرى';
  @override
  String get categoryWomen => 'نساء';
  @override
  String get categoryBags => 'حقائب';
}

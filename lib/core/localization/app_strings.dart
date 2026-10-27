/// The canonical English copy for every user-facing string in Loqta.
///
/// This class is the single source of truth for English text. The Arabic
/// translation lives in `app_strings_ar.dart` and implements the same abstract
/// interface, so adding a string here is a compile error until it is also added
/// to the Arabic implementation — a missing translation can never silently fall
/// back to English at runtime.
///
/// See `app_localizations.dart` for how a locale is resolved.
abstract class AppStrings {
  const AppStrings();

  // ---------------------------------------------------------------- common --
  String get appName;
  String get retry;
  String get cancel;
  String get save;
  String get delete;
  String get remove;
  String get edit;
  String get back;
  String get loading;
  String get somethingWentWrong;
  String get tryAgain;

  // ----------------------------------------------------------------- nav ----
  String get navHome;
  String get navFavorites;
  String get navSell;
  String get navMessages;
  String get navProfile;
  String get navSearch;

  // -------------------------------------------------------------- splash ----

  // ---------------------------------------------------------- onboarding ----
  String get onboarding1Title;
  String get onboarding1Body;
  String get onboarding2Title;
  String get onboarding2Body;
  String get onboarding3Title;
  String get onboarding3Body;
  String get onboardingCta1;
  String get onboardingCta2;
  String get onboardingCta3;
  String get onboardingSkip;
  String get getStarted;

  // ---------------------------------------------------------------- auth ----
  String get signIn;
  String get signUp;
  String get signInTitle;
  String get signInSubtitle;
  String get signUpTitle;
  String get signUpSubtitle;
  String get email;
  String get password;
  String get confirmPassword;
  String get fullName;
  String get firstName;
  String get lastName;
  String get forgotPassword;
  String get dontHaveAccount;
  String get alreadyHaveAccount;
  String get orContinueWith;
  String get welcomeBack;
  String get createAccount;
  String get emailRequired;
  String get emailInvalid;
  String get passwordRequired;
  String get passwordTooShort;
  String get passwordsDoNotMatch;
  String get nameRequired;
  String get signOut;
  String get signInFailed;
  String get signUpFailed;
  String get accountCreated;
  String get confirmationEmailSent;
  String get confirmationEmailBody;
  String get resendEmail;
  String get backToSignIn;
  String get forgotPasswordTitle;
  String get forgotPasswordSubtitle;
  String get resetEmailSent;
  String get resetPasswordTitle;
  String get resetPasswordSubtitle;
  String get newPassword;
  String get passwordUpdated;
  String get openEmailApp;

  // ---------------------------------------------------------------- home ----
  String get searchHint;
  String get locationAll;
  String get forSale;
  String get forDonation;
  String get browseForSale;
  String get communityGifts;
  String get categories;
  String get seeAll;
  String get featuredFinds;
  String get latestItems;
  String get noListingsYet;
  String get noListingsYetBody;
  String get filterBy;

  // ------------------------------------------------------------- listing ----
  String get condition;
  String get newItem;
  String get likeNew;
  String get goodCondition;
  String get acceptable;
  String get usedFairly;
  String get free;
  String get description;
  String get category;
  String get governorate;
  String get area;
  String get deliveryAvailable;
  String get pickupOnly;
  String get contactSeller;
  String get requestItem;
  String get reportListing;
  String get seller;
  String get donor;
  String get deleteListing;
  String get noListings;
  String get noListingsBody;
  String get listingNotFound;

  // ---------------------------------------------------------------- srp -----
  String get searchTitle;
  String get searchResults;
  String get noResults;
  String get noResultsBody;
  String get applyFilters;
  String get clearFilters;
  String get filters;
  String get keyword;
  String get priceRange;
  String get listingType;
  String get all;
  String get noFavorites;
  String get noFavoritesBody;
  String get browseMoreItems;
  String get removeFromFavorites;

  // ------------------------------------------------------------- create -----
  String get createListing;
  String get photos;
  String get addPhotos;
  String get goodDaylightPhotos;
  String get title;
  String get titleHint;
  String get itemLocation;
  String get exactPickupAddress;
  String get exactPickupAddressHint;
  String get exactPickupAddressPrivacy;
  String get deliveryOption;
  String get deliveryOptionNote;
  String get continueToPreview;
  String get listingTypePrice;
  String get whatWouldYouLikeToDo;
  String get whatWouldYouLikeToDoBody;
  String get sellYourPrice;
  String get communityGift;
  String get openListingEditor;
  String get cancelAndReturnHome;
  String get directNeighborNote;
  String get listingPreview;
  String get publishListing;
  String get preview;
  String get publish;
  String get publishSuccess;
  String get publishing;
  String get publishFailed;
  String get published;
  String get viewListing;
  String get myListings;
  String get backToHome;
  String get requiredField;
  String get enterPrice;
  String get priceMustBePositive;
  String get selectCategory;
  String get selectGovernorate;
  String get selectArea;
  String get privateNote;
  String get listingTypeSale;
  String get listingTypeDonation;
  String get price;
  String get currency;
  String get photosHint;
  String get photoRequired;
  String get photoLimit;
  String get titleTooShort;
  String get titleTooLong;
  String get priceInvalid;
  String get selectCondition;
  String get selectCurrency;
  String get selectDeliveryOption;
  String get conditionFair;
  String get publishSuccessTitle;
  String get listingPublishedByYou;
  String get descriptionTooLong;

  // ------------------------------------------------------------ listings ----
  String get statusAvailable;
  String get statusReserved;
  String get statusSold;
  String get statusDonated;
  String get statusDeleted;
  String get myListingsTitle;
  String get manage;
  String get markReserved;
  String get markSold;
  String get markDonated;

  // ------------------------------------------------------------ messages ----
  String get chatMessages;
  String get directAndSecure;
  String get verified;
  String get noMessages;
  String get noMessagesBody;
  String get messageHint;
  String get reportUser;
  String get reportUserTitle;
  String get today;
  String get yesterday;

  // ------------------------------------------------------- notifications ----
  String get notifications;
  String get allNotifications;
  String get markAllRead;
  String get noNotifications;
  String get noNotificationsBody;

  // ------------------------------------------------------------- profile ----
  String get profile;
  String get editProfile;
  String get changePhoto;
  String get removePhoto;
  String get phoneNumber;
  String get optional;
  String get readOnly;
  String get emailCannotChange;
  String get saveChanges;
  String get profileSaved;
  String get profileSaveFailed;
  String get verifiedMember;
  String get verifiedMemberBody;
  String get myActivity;
  String get transactionHistory;
  String get myRatings;
  String get settings;
  String get account;
  String get logOut;
  String get deleteAccount;
  String get notificationsCount;

  // -------------------------------------------------------- transactions ----
  String get active;
  String get completed;
  String get history;
  String get noTransactions;
  String get noTransactionsBody;
  String get transactionDetails;
  String get transactionType;
  String get counterpart;
  String get agreedAmount;
  String get currentStatus;
  String get handoffLocation;
  String get completeTransaction;
  String get confirmCompleteTitle;
  String get confirmCompleteBody;
  String get confirmAndComplete;
  String get transactionCompleted;
  String get transactionCompleteFailed;
  String get exchangeLifecycle;
  String get listingPublished;
  String get reservedInHandoff;
  String get soldComplete;
  String get itemHandoffNote;

  // -------------------------------------------------------------- ratings ---
  String get rateTransaction;
  String get ratingComment;
  String get ratingCommentHint;
  String get submitRating;
  String get ratingSubmitted;
  String get ratingSubmitFailed;
  String get alreadyRated;
  String get myRatingsTitle;
  String get noRatings;
  String get noRatingsBody;
  String get averageRating;
  String get ratingsCount;

  // ------------------------------------------------------------ settings ----
  String get language;
  String get english;
  String get arabic;
  String get theme;
  String get lightMode;
  String get darkMode;
  String get securityPrivacy;
  String get changePassword;
  String get accountSecurity;
  String get privacyInformation;
  String get aboutLoqta;
  String get version;

  // -------------------------------------------------------------- report ----
  String get reportListingTitle;
  String get reportUserReasonTitle;
  String get reasonInappropriateContent;
  String get reasonFraud;
  String get reasonMisleadingInfo;
  String get reasonIncorrectCategory;
  String get reasonSuspiciousListing;
  String get reasonHarassment;
  String get reasonInappropriateBehavior;
  String get reasonSuspiciousActivity;
  String get reasonOther;
  String get submitReport;
  String get reportSubmitted;
  String get reportSubmitFailed;

  // --------------------------------------------------------- categories -----
  String get categoryAll;
  String get categoryFurniture;
  String get categoryElectronics;
  String get categoryAppliances;
  String get categoryClothes;
  String get categoryShoes;
  String get categoryKids;
  String get categoryBooks;
  String get categoryHomeGarden;
  String get categorySports;
  String get categoryVehicles;
  String get categoryPhones;
  String get categoryComputers;
  String get categoryJewelry;
  String get categoryToys;
  String get categoryOther;
}

/// The English implementation of [AppStrings].
class AppStringsEn extends AppStrings {
  const AppStringsEn();

  @override
  String get appName => 'Loqta';
  @override
  String get retry => 'Retry';
  @override
  String get cancel => 'Cancel';
  @override
  String get save => 'Save';
  @override
  String get delete => 'Delete';
  @override
  String get remove => 'Remove';
  @override
  String get edit => 'Edit';
  @override
  String get back => 'Back';
  @override
  String get loading => 'Loading...';
  @override
  String get somethingWentWrong => 'Something went wrong.';
  @override
  String get tryAgain => 'Try again';

  @override
  String get navHome => 'Home';
  @override
  String get navFavorites => 'Favorites';
  @override
  String get navSell => 'Sell';
  @override
  String get navMessages => 'Messages';
  @override
  String get navProfile => 'Profile';
  @override
  String get navSearch => 'Search';

  @override
  String get onboarding1Title => 'Buy & Sell Nearby';
  @override
  String get onboarding1Body =>
      'Discover great deals from people in your own city.';
  @override
  String get onboarding2Title => 'Give Items a Second Life';
  @override
  String get onboarding2Body =>
      'Donate what you no longer need and help your community.';
  @override
  String get onboarding3Title => 'Connect Safely';
  @override
  String get onboarding3Body =>
      'Chat directly with buyers and donors, and agree on a safe handoff.';
  @override
  String get onboardingCta1 => 'Next';
  @override
  String get onboardingCta2 => 'Next';
  @override
  String get onboardingCta3 => 'Get Started';
  @override
  String get onboardingSkip => 'Skip';
  @override
  String get getStarted => 'Get Started';

  @override
  String get signIn => 'Sign In';
  @override
  String get signUp => 'Sign Up';
  @override
  String get signInTitle => 'Welcome Back';
  @override
  String get signInSubtitle => 'Sign in to continue to Loqta.';
  @override
  String get signUpTitle => 'Create Your Account';
  @override
  String get signUpSubtitle => 'Join Loqta and start trading in minutes.';
  @override
  String get email => 'Email';
  @override
  String get password => 'Password';
  @override
  String get confirmPassword => 'Confirm Password';
  @override
  String get fullName => 'Full Name';
  @override
  String get firstName => 'First Name';
  @override
  String get lastName => 'Last Name';
  @override
  String get forgotPassword => 'Forgot Password';
  @override
  String get dontHaveAccount => "Don't have an account?";
  @override
  String get alreadyHaveAccount => 'Already have an account?';
  @override
  String get orContinueWith => 'Or continue with';
  @override
  String get welcomeBack => 'Welcome back';
  @override
  String get createAccount => 'Create Account';
  @override
  String get emailRequired => 'Email is required';
  @override
  String get emailInvalid => 'Enter a valid email address';
  @override
  String get passwordRequired => 'Password is required';
  @override
  String get passwordTooShort => 'Password must be at least 6 characters';
  @override
  String get passwordsDoNotMatch => 'Passwords do not match';
  @override
  String get nameRequired => 'Name is required';
  @override
  String get signOut => 'Sign Out';
  @override
  String get signInFailed => 'Could not sign you in. Please try again.';
  @override
  String get signUpFailed => 'Could not create your account. Please try again.';
  @override
  String get accountCreated => 'Account created';
  @override
  String get confirmationEmailSent => 'Confirmation email sent';
  @override
  String get confirmationEmailBody =>
      'Please check your inbox and follow the link to activate your account.';
  @override
  String get resendEmail => 'Resend Email';
  @override
  String get backToSignIn => 'Back to Sign In';
  @override
  String get forgotPasswordTitle => 'Reset Password';
  @override
  String get forgotPasswordSubtitle =>
      'Enter your email and we will send you a reset link.';
  @override
  String get resetEmailSent => 'Password reset email sent';
  @override
  String get resetPasswordTitle => 'Choose a New Password';
  @override
  String get resetPasswordSubtitle => 'Enter a new password for your account.';
  @override
  String get newPassword => 'New Password';
  @override
  String get passwordUpdated => 'Password updated';
  @override
  String get openEmailApp => 'Open email app';

  @override
  String get searchHint => 'Search for items...';
  @override
  String get locationAll => 'All';
  @override
  String get forSale => 'For Sale';
  @override
  String get forDonation => 'For Donation';
  @override
  String get browseForSale => 'Browse items for sale';
  @override
  String get communityGifts => 'Free community gifts';
  @override
  String get categories => 'Categories';
  @override
  String get seeAll => 'See All';
  @override
  String get featuredFinds => 'Featured Finds';
  @override
  String get latestItems => 'Latest items';
  @override
  String get noListingsYet => 'No listings yet';
  @override
  String get noListingsYetBody =>
      'Be the first to list an item for sale or donation.';
  @override
  String get filterBy => 'Filter by';

  @override
  String get condition => 'Condition';
  @override
  String get newItem => 'New';
  @override
  String get likeNew => 'Like New';
  @override
  String get goodCondition => 'Good Condition';
  @override
  String get acceptable => 'Acceptable';
  @override
  String get usedFairly => 'Used';
  @override
  String get free => 'Free';
  @override
  String get description => 'Description';
  @override
  String get category => 'Category';
  @override
  String get governorate => 'Governorate';
  @override
  String get area => 'Area';
  @override
  String get deliveryAvailable => 'Delivery Available';
  @override
  String get pickupOnly => 'Pickup Only';
  @override
  String get contactSeller => 'Contact Seller';
  @override
  String get requestItem => 'Request Item';
  @override
  String get reportListing => 'Report Listing';
  @override
  String get seller => 'Seller';
  @override
  String get donor => 'Donor';
  @override
  String get deleteListing => 'Delete Listing';
  @override
  String get noListings => 'No listings yet';
  @override
  String get noListingsBody =>
      'Listings you create will appear here for you to manage.';
  @override
  String get listingNotFound => 'This listing is no longer available.';

  @override
  String get searchTitle => 'Search';
  @override
  String get searchResults => 'Search Results';
  @override
  String get noResults => 'No results';
  @override
  String get noResultsBody => 'Try different keywords or clear your filters.';
  @override
  String get applyFilters => 'Apply Filters';
  @override
  String get clearFilters => 'Clear Filters';
  @override
  String get filters => 'Filters';
  @override
  String get keyword => 'Keyword';
  @override
  String get priceRange => 'Price Range';
  @override
  String get listingType => 'Listing Type';
  @override
  String get all => 'All';
  @override
  String get noFavorites => 'No other favorites yet';
  @override
  String get noFavoritesBody =>
      'Save items you like while browsing and find them easily here whenever you want to revisit them.';
  @override
  String get browseMoreItems => 'Browse More Items';
  @override
  String get removeFromFavorites => 'Remove from favorites';

  @override
  String get createListing => 'Create Listing';
  @override
  String get photos => 'Photos';
  @override
  String get addPhotos => 'Add';
  @override
  String get goodDaylightPhotos =>
      'Clear, natural daylight photos sell up to 3x faster';
  @override
  String get title => 'Title';
  @override
  String get titleHint => 'What are you selling?';
  @override
  String get itemLocation => 'Item Location (Governorate & Area)';
  @override
  String get exactPickupAddress => 'Exact Pickup Address (Private)';
  @override
  String get exactPickupAddressHint =>
      'Street address, building, nearest landmark';
  @override
  String get exactPickupAddressPrivacy =>
      'Your exact pickup address is private. It is never displayed publicly and is only shared with confirmed buyers or donors.';
  @override
  String get deliveryOption => 'Delivery Option';
  @override
  String get deliveryOptionNote =>
      'You will arrange pickup or delivery directly with the other person. Loqta does not manage payments or shipping.';
  @override
  String get continueToPreview => 'Continue to Preview';
  @override
  String get listingTypePrice => 'Listing Type & Price';
  @override
  String get whatWouldYouLikeToDo => 'What would you like to do?';
  @override
  String get whatWouldYouLikeToDoBody =>
      'Choose whether you are selling an item or giving it away in your local community.';
  @override
  String get sellYourPrice => 'Sell Your Price';
  @override
  String get communityGift => 'Community Gift';
  @override
  String get openListingEditor => 'Opening listing editor...';
  @override
  String get cancelAndReturnHome => 'Cancel and Return Home';
  @override
  String get directNeighborNote =>
      'Both options appear with your local community. Sellers reach more people through both channels and set their own pricing.';
  @override
  String get listingPreview => 'Listing Preview';
  @override
  String get publishListing => 'Publish Listing';
  @override
  String get preview => 'Preview';
  @override
  String get publish => 'Publish';
  @override
  String get publishSuccess => 'Publish Success';
  @override
  String get publishing => 'Publishing...';
  @override
  String get publishFailed =>
      'Could not publish your listing. Your information was kept.';
  @override
  String get published => 'Your listing is now live.';
  @override
  String get viewListing => 'View Listing';
  @override
  String get myListings => 'My Listings';
  @override
  String get backToHome => 'Back to Home';
  @override
  String get requiredField => 'This field is required';
  @override
  String get enterPrice => 'Enter a price';
  @override
  String get priceMustBePositive => 'Price must be greater than zero';
  @override
  String get selectCategory => 'Select a category';
  @override
  String get selectGovernorate => 'Select a governorate';
  @override
  String get selectArea => 'Select an area';
  @override
  String get privateNote => 'Private';
  @override
  String get listingTypeSale => 'For Sale';
  @override
  String get listingTypeDonation => 'For Donation';
  @override
  String get price => 'Price';
  @override
  String get currency => 'Currency';
  @override
  String get photosHint => 'Show your item in clear, natural light';
  @override
  String get photoRequired => 'Add at least one photo of your item';
  @override
  String get photoLimit => 'You can add up to 5 photos';
  @override
  String get titleTooShort => 'Title must be at least 3 characters';
  @override
  String get titleTooLong => 'Title must be 120 characters or fewer';
  @override
  String get priceInvalid => 'Enter a valid price';
  @override
  String get selectCondition => 'Select a condition';
  @override
  String get selectCurrency => 'Select a currency';
  @override
  String get selectDeliveryOption => 'Select a delivery option';
  @override
  String get conditionFair => 'Fair';
  @override
  String get publishSuccessTitle => 'Listing Published';
  @override
  String get listingPublishedByYou => 'Listing published by you';
  @override
  String get descriptionTooLong =>
      'Description must be 1000 characters or fewer';

  @override
  String get statusAvailable => 'Available';
  @override
  String get statusReserved => 'Reserved';
  @override
  String get statusSold => 'Sold';
  @override
  String get statusDonated => 'Donated';
  @override
  String get statusDeleted => 'Deleted';
  @override
  String get myListingsTitle => 'My Listings';
  @override
  String get manage => 'Manage';
  @override
  String get markReserved => 'Mark as Reserved';
  @override
  String get markSold => 'Mark as Sold';
  @override
  String get markDonated => 'Mark as Donated';

  @override
  String get chatMessages => 'Chat Messages';
  @override
  String get directAndSecure => 'Direct & secure peer-to-peer chats';
  @override
  String get verified => 'Verified';
  @override
  String get noMessages => 'No other messages';
  @override
  String get noMessagesBody =>
      'Your conversations about listings will appear here. Safe and confidential coordination with local buyers & sellers.';
  @override
  String get messageHint => 'Message';
  @override
  String get reportUser => 'Report User';
  @override
  String get reportUserTitle => 'Report User';
  @override
  String get today => 'Today';
  @override
  String get yesterday => 'Yesterday';

  @override
  String get notifications => 'Notification';
  @override
  String get allNotifications => 'All Notification';
  @override
  String get markAllRead => 'Mark all read';
  @override
  String get noNotifications => 'No notifications';
  @override
  String get noNotificationsBody => 'You are all caught up.';

  @override
  String get profile => 'Profile';
  @override
  String get editProfile => 'Edit Profile';
  @override
  String get changePhoto => 'Change Photo';
  @override
  String get removePhoto => 'Remove Photo';
  @override
  String get phoneNumber => 'Phone Number';
  @override
  String get optional => 'Optional';
  @override
  String get readOnly => 'Read-only';
  @override
  String get emailCannotChange => 'Email cannot be changed';
  @override
  String get saveChanges => 'Save Changes';
  @override
  String get profileSaved => 'Profile updated';
  @override
  String get profileSaveFailed => 'Could not save your profile.';
  @override
  String get verifiedMember => 'Verified Loqta Member';
  @override
  String get verifiedMemberBody =>
      'Keep your contact details up to date for smooth handoffs.';
  @override
  String get myActivity => 'My Activity';
  @override
  String get transactionHistory => 'Transaction History';
  @override
  String get myRatings => 'My Ratings';
  @override
  String get settings => 'Settings';
  @override
  String get account => 'Account';
  @override
  String get logOut => 'Log Out';
  @override
  String get deleteAccount => 'Delete Account';
  @override
  String get notificationsCount => 'Notifications';

  @override
  String get active => 'Active';
  @override
  String get completed => 'Completed';
  @override
  String get history => 'History';
  @override
  String get noTransactions => 'No transaction history yet';
  @override
  String get noTransactionsBody => 'Completed transactions will appear here.';
  @override
  String get transactionDetails => 'Transaction Details';
  @override
  String get transactionType => 'Transaction Type';
  @override
  String get counterpart => 'Counterpart';
  @override
  String get agreedAmount => 'Agreed Amount';
  @override
  String get currentStatus => 'Current Status';
  @override
  String get handoffLocation => 'Handoff Location';
  @override
  String get completeTransaction => 'Complete Transaction';
  @override
  String get confirmCompleteTitle => 'Complete this transaction?';
  @override
  String get confirmCompleteBody =>
      'This marks the item as handed over. It cannot be undone.';
  @override
  String get confirmAndComplete => 'Confirm and Complete';
  @override
  String get transactionCompleted => 'Transaction completed';
  @override
  String get transactionCompleteFailed =>
      'Could not complete the transaction. Please try again.';
  @override
  String get exchangeLifecycle => 'Exchange Lifecycle';
  @override
  String get listingPublished => 'Available\nListed';
  @override
  String get reservedInHandoff => 'Reserved\nIn Handoff';
  @override
  String get soldComplete => 'Sold\nComplete';
  @override
  String get itemHandoffNote =>
      'Item exchange coordinated directly via chat handoff. Finalize once item is handed over.';

  @override
  String get rateTransaction => 'Rate Transaction';
  @override
  String get ratingComment => 'Comment';
  @override
  String get ratingCommentHint => 'Share how the exchange went (optional)';
  @override
  String get submitRating => 'Submit Rating';
  @override
  String get ratingSubmitted => 'Thanks for your rating';
  @override
  String get ratingSubmitFailed => 'Could not submit your rating.';
  @override
  String get alreadyRated => 'You already rated this transaction';
  @override
  String get myRatingsTitle => 'My Ratings';
  @override
  String get noRatings => 'No ratings yet';
  @override
  String get noRatingsBody =>
      'Ratings you receive after completed transactions will appear here.';
  @override
  String get averageRating => 'Average Rating';
  @override
  String get ratingsCount => 'ratings';

  @override
  String get language => 'Language';
  @override
  String get english => 'English';
  @override
  String get arabic => 'العربية';
  @override
  String get theme => 'Theme';
  @override
  String get lightMode => 'Light';
  @override
  String get darkMode => 'Dark';
  @override
  String get securityPrivacy => 'Security & Privacy';
  @override
  String get changePassword => 'Change Password';
  @override
  String get accountSecurity => 'Account Security';
  @override
  String get privacyInformation => 'Privacy Information';
  @override
  String get aboutLoqta => 'About Loqta';
  @override
  String get version => 'Version';

  @override
  String get reportListingTitle => 'Report Listing';
  @override
  String get reportUserReasonTitle => 'Reason for report';
  @override
  String get reasonInappropriateContent => 'Inappropriate content';
  @override
  String get reasonFraud => 'Fraud / scam';
  @override
  String get reasonMisleadingInfo => 'Misleading information';
  @override
  String get reasonIncorrectCategory => 'Incorrect category';
  @override
  String get reasonSuspiciousListing => 'Suspicious listing';
  @override
  String get reasonHarassment => 'Harassment';
  @override
  String get reasonInappropriateBehavior => 'Inappropriate behavior';
  @override
  String get reasonSuspiciousActivity => 'Suspicious activity';
  @override
  String get reasonOther => 'Other';
  @override
  String get submitReport => 'Submit Report';
  @override
  String get reportSubmitted => 'Report submitted';
  @override
  String get reportSubmitFailed =>
      'Could not submit the report. Please try again.';

  @override
  String get categoryAll => 'All';
  @override
  String get categoryFurniture => 'Furniture';
  @override
  String get categoryElectronics => 'Electronics';
  @override
  String get categoryAppliances => 'Appliances';
  @override
  String get categoryClothes => 'Clothes';
  @override
  String get categoryShoes => 'Shoes';
  @override
  String get categoryKids => 'Kids';
  @override
  String get categoryBooks => 'Books';
  @override
  String get categoryHomeGarden => 'Home & Garden';
  @override
  String get categorySports => 'Sports';
  @override
  String get categoryVehicles => 'Vehicles';
  @override
  String get categoryPhones => 'Phones';
  @override
  String get categoryComputers => 'Computers';
  @override
  String get categoryJewelry => 'Jewelry';
  @override
  String get categoryToys => 'Toys';
  @override
  String get categoryOther => 'Other';
}

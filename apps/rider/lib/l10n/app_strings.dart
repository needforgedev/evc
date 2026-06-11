import 'package:flutter/widgets.dart';

/// Lightweight, codegen-free localization for the Rider app (English + Arabic).
/// `AppStrings.of(context).whereTo` returns the string for the active locale;
/// RTL mirroring is handled by Flutter from the locale (Arabic → RTL).
class AppStrings {
  AppStrings(this.locale);
  final Locale locale;

  static AppStrings of(BuildContext context) =>
      Localizations.of<AppStrings>(context, AppStrings) ?? AppStrings(const Locale('en'));

  bool get isAr => locale.languageCode == 'ar';
  String _t(String key) =>
      (_ar[key] != null && isAr) ? _ar[key]! : (_en[key] ?? key);

  // ── onboarding ──
  String get enterMobile => _t('enterMobile');
  String get otpSubtitle => _t('otpSubtitle');
  String get sendCode => _t('sendCode');
  String get termsNote => _t('termsNote');
  String get verifyNumber => _t('verifyNumber');
  String get verifyContinue => _t('verifyContinue');
  String get whatsYourName => _t('whatsYourName');
  String get soDriversKnow => _t('soDriversKnow');
  String get fullName => _t('fullName');
  String get emailOptional => _t('emailOptional');
  String get continueLabel => _t('continueLabel');
  String get incorrectCode => _t('incorrectCode');
  String otpSentTo(String phone) => isAr
      ? 'أدخل الرمز المكوّن من 6 أرقام الذي أرسلناه إلى واتساب للرقم $phone.'
      : 'Enter the 6-digit code we sent to your WhatsApp for $phone.';

  // ── home / booking ──
  String get whereAreYouGoing => _t('whereAreYouGoing');
  String get whereTo => _t('whereTo');
  String get saved => _t('saved');
  String get electric => _t('electric');
  String get planYourRide => _t('planYourRide');
  String get enterDestination => _t('enterDestination');
  String get destination => _t('destination');

  // ── ride options ──
  String get change => _t('change');
  String get promoCode => _t('promoCode');
  String get apply => _t('apply');
  String get paymentMethod => _t('paymentMethod');
  String get invalidPromo => _t('invalidPromo');
  String get couldNotRequest => _t('couldNotRequest');
  String confirmFor(String tier, String price) =>
      isAr ? 'تأكيد $tier · $price' : 'Confirm $tier · $price';
  String minTrip(int n) => isAr ? '$n دقيقة' : '$n min trip';

  // ── live trip ──
  String get findingEv => _t('findingEv');
  String get driverFound => _t('driverFound');
  String get driverOnWay => _t('driverOnWay');
  String get driverArrived => _t('driverArrived');
  String get onWayToDest => _t('onWayToDest');
  String get youveArrived => _t('youveArrived');
  String get tripCanceled => _t('tripCanceled');
  String get cancelRide => _t('cancelRide');
  String get done => _t('done');
  String get tripComplete => _t('tripComplete');
  String get callDriver => _t('callDriver');
  String get meetAtPickup => _t('meetAtPickup');
  String get onTheWayToYou => _t('onTheWayToYou');
  String get creatingTrip => _t('creatingTrip');
  String onYourWayMin(int n) =>
      isAr ? 'في طريقك · ~$n دقيقة' : 'On your way · ~$n min';
  String get onYourWay => _t('onYourWay');
  String toPlace(String name) => isAr ? 'إلى $name' : 'To $name';
  String coversTrip(int km) =>
      isAr ? '$km كم مدى · يكفي رحلتك' : '$km km range · covers your trip';

  // ── receipt ──
  String get subtotal => _t('subtotal');
  String get vat => _t('vat');
  String get promoDiscount => _t('promoDiscount');
  String get tip => _t('tip');
  String get total => _t('total');

  // ── rating ──
  String get rateYourDriver => _t('rateYourDriver');
  String get addTipOptional => _t('addTipOptional');
  String get noTip => _t('noTip');
  String get submitRating => _t('submitRating');
  String get thanksRating => _t('thanksRating');
  String tipAmount(String amt) => isAr ? 'إرسال + إكرامية $amt' : 'Submit & tip $amt';

  // ── account ──
  String get account => _t('account');
  String get tripsLabel => _t('tripsLabel');
  String get co2Saved => _t('co2Saved');
  String get ratingLabel => _t('ratingLabel');
  String get yourTrips => _t('yourTrips');
  String get paymentMethods => _t('paymentMethods');
  String get savedPlaces => _t('savedPlaces');
  String get safety => _t('safety');
  String get referEarn => _t('referEarn');
  String get help => _t('help');
  String get settings => _t('settings');
  String get language => _t('language');
  String get signOut => _t('signOut');

  // ── saved places ──
  String get addPlace => _t('addPlace');
  String get noSavedPlaces => _t('noSavedPlaces');
  String get savedPlacesHint => _t('savedPlacesHint');
  String get homeLabel => _t('homeLabel');
  String get workLabel => _t('workLabel');
  String get saveAsPlace => _t('saveAsPlace');

  static const Map<String, String> _en = {
    'enterMobile': 'Enter your mobile number',
    'otpSubtitle': "We'll send you a 6-digit verification code on WhatsApp.",
    'sendCode': 'Send code',
    'termsNote': "By continuing you agree to EVC's Terms & Privacy Policy.",
    'verifyNumber': 'Verify your number',
    'verifyContinue': 'Verify & continue',
    'whatsYourName': "What's your name?",
    'soDriversKnow': 'So drivers know who to pick up.',
    'fullName': 'Full name',
    'emailOptional': 'Email (optional)',
    'continueLabel': 'Continue',
    'incorrectCode': 'Incorrect or expired code.',
    'whereAreYouGoing': 'Where are you going?',
    'whereTo': 'Where to?',
    'saved': 'Saved',
    'electric': '100% electric',
    'planYourRide': 'Plan your ride',
    'enterDestination': 'Enter destination',
    'destination': 'Destination',
    'change': 'Change',
    'promoCode': 'Promo code',
    'apply': 'Apply',
    'paymentMethod': 'Payment method',
    'invalidPromo': 'Invalid or expired promo code.',
    'couldNotRequest': 'Could not request ride',
    'findingEv': 'Finding your EV…',
    'driverFound': 'Driver found — confirming…',
    'driverOnWay': 'Your driver is on the way',
    'driverArrived': 'Your driver has arrived',
    'onWayToDest': 'On the way to your destination',
    'youveArrived': "You've arrived",
    'tripCanceled': 'Trip canceled',
    'cancelRide': 'Cancel ride',
    'done': 'Done',
    'tripComplete': 'Trip complete',
    'callDriver': 'Call driver',
    'meetAtPickup': 'Meet your driver at the pickup point.',
    'onTheWayToYou': 'On the way to you.',
    'creatingTrip': 'Creating your trip…',
    'onYourWay': 'On your way',
    'subtotal': 'Subtotal',
    'vat': 'VAT (5%)',
    'promoDiscount': 'Promo discount',
    'tip': 'Tip',
    'total': 'Total',
    'rateYourDriver': 'Rate your driver',
    'addTipOptional': 'Add a tip (optional)',
    'noTip': 'No tip',
    'submitRating': 'Submit rating',
    'thanksRating': 'Thanks for rating your driver ⭐',
    'account': 'Account',
    'tripsLabel': 'Trips',
    'co2Saved': 'CO₂ saved',
    'ratingLabel': 'Rating',
    'yourTrips': 'Your trips',
    'paymentMethods': 'Payment methods',
    'savedPlaces': 'Saved places',
    'safety': 'Safety',
    'referEarn': 'Refer & earn',
    'help': 'Help',
    'settings': 'Settings',
    'language': 'Language',
    'signOut': 'Sign out',
    'addPlace': 'Add place',
    'noSavedPlaces': 'No saved places yet',
    'savedPlacesHint': 'Add Home, Work, or any spot for one-tap booking.',
    'homeLabel': 'Home',
    'workLabel': 'Work',
    'saveAsPlace': 'Save as place',
  };

  static const Map<String, String> _ar = {
    'enterMobile': 'أدخل رقم هاتفك المحمول',
    'otpSubtitle': 'سنرسل لك رمز تحقّق من 6 أرقام عبر واتساب.',
    'sendCode': 'إرسال الرمز',
    'termsNote': 'بالمتابعة فإنك توافق على شروط EVC وسياسة الخصوصية.',
    'verifyNumber': 'تأكيد رقمك',
    'verifyContinue': 'تأكيد ومتابعة',
    'whatsYourName': 'ما اسمك؟',
    'soDriversKnow': 'ليعرف السائقون من سيُقِلّونه.',
    'fullName': 'الاسم الكامل',
    'emailOptional': 'البريد الإلكتروني (اختياري)',
    'continueLabel': 'متابعة',
    'incorrectCode': 'رمز غير صحيح أو منتهي الصلاحية.',
    'whereAreYouGoing': 'إلى أين تريد الذهاب؟',
    'whereTo': 'إلى أين؟',
    'saved': 'المحفوظة',
    'electric': 'كهربائية 100٪',
    'planYourRide': 'خطّط لرحلتك',
    'enterDestination': 'أدخل الوجهة',
    'destination': 'الوجهة',
    'change': 'تغيير',
    'promoCode': 'رمز ترويجي',
    'apply': 'تطبيق',
    'paymentMethod': 'طريقة الدفع',
    'invalidPromo': 'رمز ترويجي غير صالح أو منتهي الصلاحية.',
    'couldNotRequest': 'تعذّر طلب الرحلة',
    'findingEv': 'نبحث عن سيارتك الكهربائية…',
    'driverFound': 'تم العثور على سائق — جارٍ التأكيد…',
    'driverOnWay': 'سائقك في الطريق إليك',
    'driverArrived': 'وصل سائقك',
    'onWayToDest': 'في الطريق إلى وجهتك',
    'youveArrived': 'لقد وصلت',
    'tripCanceled': 'أُلغيت الرحلة',
    'cancelRide': 'إلغاء الرحلة',
    'done': 'تم',
    'tripComplete': 'اكتملت الرحلة',
    'callDriver': 'اتصل بالسائق',
    'meetAtPickup': 'قابل سائقك في نقطة الانطلاق.',
    'onTheWayToYou': 'في الطريق إليك.',
    'creatingTrip': 'جارٍ إنشاء رحلتك…',
    'onYourWay': 'في طريقك',
    'subtotal': 'المجموع الفرعي',
    'vat': 'ضريبة القيمة المضافة (5٪)',
    'promoDiscount': 'خصم ترويجي',
    'tip': 'إكرامية',
    'total': 'الإجمالي',
    'rateYourDriver': 'قيّم سائقك',
    'addTipOptional': 'أضف إكرامية (اختياري)',
    'noTip': 'بدون إكرامية',
    'submitRating': 'إرسال التقييم',
    'thanksRating': 'شكرًا لتقييمك سائقك ⭐',
    'account': 'الحساب',
    'tripsLabel': 'الرحلات',
    'co2Saved': 'ثاني أكسيد الكربون الموفّر',
    'ratingLabel': 'التقييم',
    'yourTrips': 'رحلاتك',
    'paymentMethods': 'طرق الدفع',
    'savedPlaces': 'الأماكن المحفوظة',
    'safety': 'الأمان',
    'referEarn': 'اربح بالدعوة',
    'help': 'المساعدة',
    'settings': 'الإعدادات',
    'language': 'اللغة',
    'signOut': 'تسجيل الخروج',
    'addPlace': 'إضافة مكان',
    'noSavedPlaces': 'لا توجد أماكن محفوظة بعد',
    'savedPlacesHint': 'أضف المنزل أو العمل أو أي مكان للحجز بنقرة واحدة.',
    'homeLabel': 'المنزل',
    'workLabel': 'العمل',
    'saveAsPlace': 'حفظ كمكان',
  };
}

/// Delegate that supplies [AppStrings] for the active locale.
class AppStringsDelegate extends LocalizationsDelegate<AppStrings> {
  const AppStringsDelegate();
  @override
  bool isSupported(Locale locale) =>
      ['en', 'ar'].contains(locale.languageCode);
  @override
  Future<AppStrings> load(Locale locale) async => AppStrings(locale);
  @override
  bool shouldReload(AppStringsDelegate old) => false;
}
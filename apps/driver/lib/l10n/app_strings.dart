import 'package:flutter/widgets.dart';

/// Codegen-free localization for the Driver app (English + Arabic).
class AppStrings {
  AppStrings(this.locale);
  final Locale locale;

  static AppStrings of(BuildContext context) =>
      Localizations.of<AppStrings>(context, AppStrings) ??
      AppStrings(const Locale('en'));

  bool get isAr => locale.languageCode == 'ar';
  String _t(String key) =>
      (_ar[key] != null && isAr) ? _ar[key]! : (_en[key] ?? key);

  // ── onboarding ──
  String get driverSignIn => _t('driverSignIn');
  String get enterMobileVerify => _t('enterMobileVerify');
  String get sendCode => _t('sendCode');
  String get verifyNumber => _t('verifyNumber');
  String get verify => _t('verify');
  String get incorrectCode => _t('incorrectCode');
  String get yourDetails => _t('yourDetails');
  String get yourEv => _t('yourEv');
  String get driverOwned => _t('driverOwned');
  String get company => _t('company');
  String get continueLabel => _t('continueLabel');
  String get signInToDrive => _t('signInToDrive');
  String get uploadDocuments => _t('uploadDocuments');
  String get fullName => _t('fullName');
  String get emailOptional => _t('emailOptional');
  String get model => _t('model');
  String get plate => _t('plate');
  String get ownership => _t('ownership');
  String get batteryPct => _t('batteryPct');
  String get rangeKm => _t('rangeKm');
  String get serviceTier => _t('serviceTier');
  String otpSentTo(String phone) => isAr
      ? 'أدخل الرمز المكوّن من 6 أرقام الذي أرسلناه إلى واتساب للرقم $phone.'
      : 'Enter the 6-digit code we sent to your WhatsApp for $phone.';

  // ── home dashboard ──
  String get earnedToday => _t('earnedToday');
  String get trips => _t('trips');
  String get rating => _t('rating');
  String get lookingForTrips => _t('lookingForTrips');
  String get goOnline => _t('goOnline');
  String get goOffline => _t('goOffline');
  String get pendingApproval => _t('pendingApproval');

  // ── active trip ──
  String get newRideRequest => _t('newRideRequest');
  String get decline => _t('decline');
  String get accept => _t('accept');
  String get startTrip => _t('startTrip');
  String get completeTrip => _t('completeTrip');
  String get iveArrived => _t('iveArrived');
  String get dropOff => _t('dropOff');
  String get pickUp => _t('pickUp');
  String get youEarned => _t('youEarned');
  String get rateYourRider => _t('rateYourRider');
  String get done => _t('done');
  String youEarn(String amt) => isAr ? 'ستربح $amt' : 'You earn $amt';

  // ── account ──
  String get account => _t('account');
  String get acceptance => _t('acceptance');
  String get myVehicle => _t('myVehicle');
  String get documentsCompliance => _t('documentsCompliance');
  String get payoutsBank => _t('payoutsBank');
  String get taxSummary => _t('taxSummary');
  String get supportDisputes => _t('supportDisputes');
  String get settings => _t('settings');
  String get signOut => _t('signOut');
  String get language => _t('language');
  String get statusPending => _t('statusPending');
  String get statusActive => _t('statusActive');
  String get statusSuspended => _t('statusSuspended');

  static const Map<String, String> _en = {
    'driverSignIn': 'Driver sign in',
    'enterMobileVerify':
        "Enter your mobile number — we'll send a code to verify it.",
    'sendCode': 'Send code',
    'verifyNumber': 'Verify your number',
    'verify': 'Verify',
    'incorrectCode': 'Incorrect or expired code.',
    'yourDetails': 'Your details',
    'yourEv': 'Your EV',
    'driverOwned': 'Driver-owned',
    'company': 'Company',
    'continueLabel': 'Continue',
    'signInToDrive': 'Sign in to drive',
    'uploadDocuments': 'Upload documents',
    'fullName': 'Full name',
    'emailOptional': 'Email (optional)',
    'model': 'Model',
    'plate': 'Plate',
    'ownership': 'Ownership',
    'batteryPct': 'Battery %',
    'rangeKm': 'Range (km)',
    'serviceTier': 'Service tier',
    'earnedToday': 'Earned today',
    'trips': 'Trips',
    'rating': 'Rating',
    'lookingForTrips': 'Looking for trips nearby…',
    'goOnline': 'Go online',
    'goOffline': 'Go offline',
    'pendingApproval':
        "Pending approval — you can't go online until ops verify your account.",
    'newRideRequest': 'New ride request',
    'decline': 'Decline',
    'accept': 'Accept',
    'startTrip': 'Start trip',
    'completeTrip': 'Complete trip',
    'iveArrived': "I've arrived",
    'dropOff': 'Drop-off',
    'pickUp': 'Pick-up',
    'youEarned': 'You earned',
    'rateYourRider': 'Rate your rider',
    'done': 'Done',
    'account': 'Account',
    'acceptance': 'Acceptance',
    'myVehicle': 'My vehicle',
    'documentsCompliance': 'Documents & compliance',
    'payoutsBank': 'Payouts & bank',
    'taxSummary': 'Tax summary',
    'supportDisputes': 'Support & disputes',
    'settings': 'Settings',
    'signOut': 'Sign out',
    'language': 'Language',
    'statusPending': 'Pending',
    'statusActive': 'Active',
    'statusSuspended': 'Suspended',
  };

  static const Map<String, String> _ar = {
    'driverSignIn': 'تسجيل دخول السائق',
    'enterMobileVerify': 'أدخل رقم هاتفك — سنرسل رمزًا للتحقق منه.',
    'sendCode': 'إرسال الرمز',
    'verifyNumber': 'تأكيد رقمك',
    'verify': 'تأكيد',
    'incorrectCode': 'رمز غير صحيح أو منتهي الصلاحية.',
    'yourDetails': 'بياناتك',
    'yourEv': 'سيارتك الكهربائية',
    'driverOwned': 'ملك السائق',
    'company': 'الشركة',
    'continueLabel': 'متابعة',
    'signInToDrive': 'سجّل الدخول للقيادة',
    'uploadDocuments': 'رفع المستندات',
    'fullName': 'الاسم الكامل',
    'emailOptional': 'البريد الإلكتروني (اختياري)',
    'model': 'الطراز',
    'plate': 'اللوحة',
    'ownership': 'الملكية',
    'batteryPct': 'نسبة البطارية',
    'rangeKm': 'المدى (كم)',
    'serviceTier': 'فئة الخدمة',
    'earnedToday': 'أرباح اليوم',
    'trips': 'الرحلات',
    'rating': 'التقييم',
    'lookingForTrips': 'نبحث عن رحلات قريبة…',
    'goOnline': 'ابدأ العمل',
    'goOffline': 'إيقاف العمل',
    'pendingApproval':
        'قيد الموافقة — لا يمكنك العمل حتى يتم التحقق من حسابك.',
    'newRideRequest': 'طلب رحلة جديد',
    'decline': 'رفض',
    'accept': 'قبول',
    'startTrip': 'بدء الرحلة',
    'completeTrip': 'إنهاء الرحلة',
    'iveArrived': 'لقد وصلت',
    'dropOff': 'نقطة الوصول',
    'pickUp': 'نقطة الانطلاق',
    'youEarned': 'لقد ربحت',
    'rateYourRider': 'قيّم الراكب',
    'done': 'تم',
    'account': 'الحساب',
    'acceptance': 'القبول',
    'myVehicle': 'مركبتي',
    'documentsCompliance': 'المستندات والامتثال',
    'payoutsBank': 'المدفوعات والبنك',
    'taxSummary': 'ملخص الضرائب',
    'supportDisputes': 'الدعم والنزاعات',
    'settings': 'الإعدادات',
    'signOut': 'تسجيل الخروج',
    'language': 'اللغة',
    'statusPending': 'قيد المراجعة',
    'statusActive': 'نشط',
    'statusSuspended': 'موقوف',
  };
}

class AppStringsDelegate extends LocalizationsDelegate<AppStrings> {
  const AppStringsDelegate();
  @override
  bool isSupported(Locale locale) => ['en', 'ar'].contains(locale.languageCode);
  @override
  Future<AppStrings> load(Locale locale) async => AppStrings(locale);
  @override
  bool shouldReload(AppStringsDelegate old) => false;
}

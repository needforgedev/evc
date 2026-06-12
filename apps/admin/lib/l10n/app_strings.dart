import 'package:flutter/widgets.dart';

/// Codegen-free localization for the Admin app (English + Arabic).
class AppStrings {
  AppStrings(this.locale);
  final Locale locale;

  static AppStrings of(BuildContext context) =>
      Localizations.of<AppStrings>(context, AppStrings) ??
      AppStrings(const Locale('en'));

  bool get isAr => locale.languageCode == 'ar';
  String _t(String key) =>
      (_ar[key] != null && isAr) ? _ar[key]! : (_en[key] ?? key);

  // ── nav ──
  String get overview => _t('overview');
  String get live => _t('live');
  String get drivers => _t('drivers');
  String get trips => _t('trips');
  String get more => _t('more');

  // ── overview ──
  String get activeTrips => _t('activeTrips');
  String get activeDrivers => _t('activeDrivers');
  String get completedTrips => _t('completedTrips');
  String get revenue => _t('revenue');
  String get network => _t('network');
  String get totalDrivers => _t('totalDrivers');
  String get totalTrips => _t('totalTrips');
  String get pendingApprovals => _t('pendingApprovals');
  String awaitingApproval(int n) =>
      isAr ? '$n سائق بانتظار الموافقة' : '$n driver${n == 1 ? '' : 's'} awaiting approval';

  // ── more menu ──
  String get fleetVehicles => _t('fleetVehicles');
  String get fleetSub => _t('fleetSub');
  String get pricingPromos => _t('pricingPromos');
  String get pricingSub => _t('pricingSub');
  String get finance => _t('finance');
  String get financeSub => _t('financeSub');
  String get supportDisputes => _t('supportDisputes');
  String get supportSub => _t('supportSub');
  String get analytics => _t('analytics');
  String get analyticsSub => _t('analyticsSub');
  String get rolesPermissions => _t('rolesPermissions');
  String get rolesSub => _t('rolesSub');
  String get settings => _t('settings');
  String get settingsSub => _t('settingsSub');
  String get language => _t('language');
  String get signOut => _t('signOut');

  // ── login ──
  String get opsControlPanel => _t('opsControlPanel');
  String get workEmail => _t('workEmail');
  String get password => _t('password');
  String get signIn => _t('signIn');
  String get rolesLine => _t('rolesLine');

  static const Map<String, String> _en = {
    'overview': 'Overview',
    'live': 'Live',
    'drivers': 'Drivers',
    'trips': 'Trips',
    'more': 'More',
    'activeTrips': 'Active trips',
    'activeDrivers': 'Active drivers',
    'completedTrips': 'Completed trips',
    'revenue': 'Revenue',
    'network': 'Network',
    'totalDrivers': 'Total drivers',
    'totalTrips': 'Total trips',
    'pendingApprovals': 'Pending approvals',
    'fleetVehicles': 'Fleet & vehicles',
    'fleetSub': 'Registry, battery, maintenance',
    'pricingPromos': 'Pricing & promos',
    'pricingSub': 'Fares, surge zones, promo codes',
    'finance': 'Finance',
    'financeSub': 'Revenue, payouts, VAT',
    'supportDisputes': 'Support & disputes',
    'supportSub': 'Tickets, lost items, safety',
    'analytics': 'Analytics',
    'analyticsSub': 'Demand, CO₂, charging, retention',
    'rolesPermissions': 'Roles & permissions',
    'rolesSub': 'Super-admin · Ops · Finance · Support',
    'settings': 'Settings',
    'settingsSub': 'Regions, currency, VAT',
    'language': 'Language',
    'signOut': 'Sign out',
    'opsControlPanel': 'Operations control panel',
    'workEmail': 'Work email',
    'password': 'Password',
    'signIn': 'Sign in',
    'rolesLine': 'Super-admin · Ops · Finance · Support',
  };

  static const Map<String, String> _ar = {
    'overview': 'نظرة عامة',
    'live': 'مباشر',
    'drivers': 'السائقون',
    'trips': 'الرحلات',
    'more': 'المزيد',
    'activeTrips': 'رحلات نشطة',
    'activeDrivers': 'سائقون نشطون',
    'completedTrips': 'رحلات مكتملة',
    'revenue': 'الإيرادات',
    'network': 'الشبكة',
    'totalDrivers': 'إجمالي السائقين',
    'totalTrips': 'إجمالي الرحلات',
    'pendingApprovals': 'الموافقات المعلّقة',
    'fleetVehicles': 'الأسطول والمركبات',
    'fleetSub': 'السجل، البطارية، الصيانة',
    'pricingPromos': 'التسعير والعروض',
    'pricingSub': 'الأجرة، مناطق التسعير، الرموز الترويجية',
    'finance': 'المالية',
    'financeSub': 'الإيرادات، المدفوعات، الضريبة',
    'supportDisputes': 'الدعم والنزاعات',
    'supportSub': 'التذاكر، المفقودات، الأمان',
    'analytics': 'التحليلات',
    'analyticsSub': 'الطلب، الكربون، الشحن، الاحتفاظ',
    'rolesPermissions': 'الأدوار والصلاحيات',
    'rolesSub': 'مدير عام · العمليات · المالية · الدعم',
    'settings': 'الإعدادات',
    'settingsSub': 'المناطق، العملة، الضريبة',
    'language': 'اللغة',
    'signOut': 'تسجيل الخروج',
    'opsControlPanel': 'لوحة التحكم بالعمليات',
    'workEmail': 'البريد الإلكتروني للعمل',
    'password': 'كلمة المرور',
    'signIn': 'تسجيل الدخول',
    'rolesLine': 'مدير عام · العمليات · المالية · الدعم',
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

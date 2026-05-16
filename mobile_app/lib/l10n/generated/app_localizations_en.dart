// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get welcomeBack => 'Welcome back 👋';

  @override
  String get signIn => 'Sign In';

  @override
  String get signInToContinue => 'Sign in to continue';

  @override
  String get email => 'Email';

  @override
  String get phone => 'Phone';

  @override
  String get password => 'Password';

  @override
  String get admin => 'Admin';

  @override
  String get member => 'Member';

  @override
  String memberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count members',
      one: '1 member',
      zero: 'No members',
    );
    return '$_temp0';
  }

  @override
  String get activeMembers => 'Active Members';

  @override
  String get revenue => 'Revenue';

  @override
  String get plans => 'Plans';

  @override
  String get expiringSoon => 'Expiring Soon';

  @override
  String get membersExpiringSoon => 'Members Expiring Soon';

  @override
  String get recentPayments => 'Recent Payments';

  @override
  String get members => 'Members';

  @override
  String get payments => 'Payments';

  @override
  String get messages => 'Messages';

  @override
  String get settings => 'Settings';

  @override
  String get profile => 'Profile';

  @override
  String get home => 'Home';

  @override
  String get logs => 'Logs';

  @override
  String get weightTracker => 'Weight Tracker';

  @override
  String get logWorkout => 'Log Workout';

  @override
  String get logDiet => 'Log Diet';

  @override
  String get logWeight => 'Log Weight';

  @override
  String get yourProgress => 'Your Progress';

  @override
  String get quickLog => 'Quick Log';

  @override
  String get weightThisWeek => 'Weight This Week';

  @override
  String get createMember => 'Create Member';

  @override
  String get editMember => 'Edit Member';

  @override
  String get recordPayment => 'Record Payment';

  @override
  String get assignPlan => 'Assign Plan';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get retry => 'Retry';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get search => 'Search';

  @override
  String get searchMembers => 'Search members...';

  @override
  String get noMembers => 'No members found';

  @override
  String get noPayments => 'No payments yet';

  @override
  String get noMessages => 'No messages yet';

  @override
  String get somethingWentWrong => 'Something went wrong';

  @override
  String get noInternetConnection => 'No internet connection';

  @override
  String get pullToRefresh => 'Pull to refresh';

  @override
  String get changePassword => 'Change Password';

  @override
  String get currentPassword => 'Current Password';

  @override
  String get newPassword => 'New Password';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get logout => 'Logout';

  @override
  String get goodMorning => 'Good morning';

  @override
  String get goodAfternoon => 'Good afternoon';

  @override
  String get goodEvening => 'Good evening';

  @override
  String get assalamuAlaikum => 'Assalamu Alaikum';

  @override
  String daysLeft(int count) {
    return '$count days left';
  }

  @override
  String get amount => 'Amount';

  @override
  String get paymentMethod => 'Payment Method';

  @override
  String get cash => 'Cash';

  @override
  String get bkash => 'bKash';

  @override
  String get nagad => 'Nagad';

  @override
  String get card => 'Card';

  @override
  String get date => 'Date';

  @override
  String get typeAMessage => 'Type a message...';

  @override
  String get send => 'Send';

  @override
  String get active => 'Active';

  @override
  String get inactive => 'Inactive';

  @override
  String get expired => 'Expired';

  @override
  String get all => 'All';
}

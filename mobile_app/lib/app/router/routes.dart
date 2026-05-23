/// Named route path constants.
///
/// Use these instead of raw strings to avoid typos and enable
/// easy refactoring. Every route in the app has a constant here.
abstract final class Routes {
  // ─── Auth ──────────────────────────────────────────────
  static const login = '/login';
  static const changePassword = '/change-password';

  // ─── Admin ─────────────────────────────────────────────
  static const adminDashboard = '/admin';
  static const adminMembers = '/admin/members';
  static String adminMemberDetail(String id) => '/admin/members/$id';
  static String adminMemberEdit(String id) => '/admin/members/$id/edit';
  static const adminMemberCreate = '/admin/members/create';
  static const adminPlans = '/admin/plans';
  static const adminSubscriptions = '/admin/subscriptions';
  static const adminPayments = '/admin/payments';
  static const adminMessages = '/admin/messages';
  static String adminChat(String conversationId) =>
      '/admin/messages/$conversationId';
  static const adminBroadcast = '/admin/messages/broadcast';
  static const adminSettings = '/admin/settings';

  // ─── Member ────────────────────────────────────────────
  static const memberHome = '/member';
  static const memberProfile = '/member/profile';
  static const memberDietChart = '/member/diet-chart';
  static const memberLogs = '/member/logs';
  static const memberSubscription = '/member/subscription';
  static const memberPayments = '/member/payments';
  static const memberWeightLog = '/member/logs/weight';
  static const memberWorkoutLog = '/member/logs/workout';
  static const memberDietLog = '/member/logs/diet';
  static const memberFoodLog = '/member/logs/food';
  static const memberMessages = '/member/messages';
  static String memberChat(String conversationId) =>
      '/member/messages/$conversationId';

  // ─── Misc ──────────────────────────────────────────────
  static const splash = '/splash';
  static const developer = '/developer';
}

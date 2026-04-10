/// Централизованные пути приложения (совпадают с [GoRoute.path] в `app.dart`).
abstract final class AppRoutes {
  AppRoutes._();

  static const onboarding = '/onboarding';
  static const home = '/';
  static const expenses = '/expenses';
  static const expensesNew = '/expenses/new';
  static const budgets = '/budgets';
  static const analytics = '/analytics';
  static const import = '/import';
  static const importReview = '/import/review';
  static const export = '/export';
  static const backup = '/backup';
  static const settings = '/settings';
  static const debts = '/debts';
  static const categories = '/categories';
  static const rules = '/rules';
  static const recurring = '/recurring';
}

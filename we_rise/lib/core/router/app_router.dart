import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers.dart';
import '../../features/onboarding/presentation/language_select_screen.dart';
import '../../features/onboarding/presentation/role_picker_screen.dart';
import '../../features/auth/presentation/sign_in_screen.dart';
import '../../features/complaints/presentation/home_shell.dart';
import '../../features/complaints/presentation/map_screen.dart';
import '../../features/complaints/presentation/report_screen.dart';
import '../../features/complaints/presentation/my_reports_screen.dart';
import '../../features/complaints/presentation/complaint_detail_screen.dart';
import '../../features/volunteer/presentation/tasks_screen.dart';
import '../../features/volunteer/presentation/task_detail_screen.dart';
import '../../features/moderation/presentation/moderation_screen.dart';
import '../../features/moderation/presentation/review_screen.dart';
import '../../features/partner/presentation/ngo_profile_screen.dart';
import '../../features/partner/presentation/partner_dashboard_screen.dart';
import '../../features/authority/presentation/authority_screen.dart';
import '../../features/complaints/presentation/solved_gallery_screen.dart';
import '../../features/volunteer/presentation/certificate_screen.dart';
import '../../features/whatsapp/presentation/whatsapp_simulator_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/profile/presentation/settings_screen.dart';
import '../../features/profile/presentation/privacy_policy_screen.dart';
import '../../features/profile/presentation/terms_screen.dart';
import '../../features/profile/presentation/delete_account_screen.dart';
import '../shared/widgets/permission_rationale_screen.dart';

// ── Route names ─────────────────────────────────────────────────────────────
abstract final class Routes {
  static const languageSelect = '/language';
  static const rolePicker = '/role';
  static const signIn = '/sign-in';
  static const home = '/home';
  static const map = 'map';
  static const report = 'report';
  static const myReports = 'my-reports';
  static const volunteer = 'volunteer';
  static const profile = 'profile';
  static const complaintDetail = '/complaint/:id';
  static const taskDetail = '/task/:id';
  static const moderation = '/moderation';
  static const reviewComplaint = '/moderation/review/:id';
  static const partnerDashboard = '/partner';
  static const authorityView = '/authority';
  static const solvedGallery = '/solved';
  static const whatsappIntake = '/whatsapp';
  static const certificate = '/certificate';
  static const ngoProfile = '/ngo/:id';
  static const settings = '/settings';
  static const privacyPolicy = '/privacy';
  static const terms = '/terms';
  static const deleteAccount = '/delete-account';
  static const permission = '/permission/:type';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: Routes.languageSelect,
    redirect: (context, state) {
      final isAuthed = authState.valueOrNull != null;
      final isOnboarding = state.matchedLocation == Routes.languageSelect ||
          state.matchedLocation == Routes.rolePicker;
      final isAuth = state.matchedLocation == Routes.signIn;

      if (!isAuthed && !isOnboarding && !isAuth) return Routes.languageSelect;
      if (isAuthed && isOnboarding) return Routes.home;
      return null;
    },
    routes: [
      GoRoute(
        path: Routes.languageSelect,
        builder: (_, __) => const LanguageSelectScreen(),
      ),
      GoRoute(
        path: Routes.rolePicker,
        builder: (_, __) => const RolePickerScreen(),
      ),
      GoRoute(
        path: Routes.signIn,
        builder: (_, __) => const SignInScreen(),
      ),
      // ── Main shell with bottom nav ──────────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => HomeShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.home,
              builder: (_, __) => const MapScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/report',
              builder: (_, __) => const ReportScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/my-reports',
              builder: (_, __) => const MyReportsScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/volunteer',
              builder: (_, __) => const TasksScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/profile',
              builder: (_, __) => const ProfileScreen(),
            ),
          ]),
        ],
      ),
      // ── Detail screens ──────────────────────────────────────────────────
      GoRoute(
        path: '/complaint/:id',
        builder: (_, state) =>
            ComplaintDetailScreen(complaintId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/task/:id',
        builder: (_, state) =>
            TaskDetailScreen(taskId: state.pathParameters['id']!),
      ),
      // ── Role-specific ───────────────────────────────────────────────────
      GoRoute(
        path: Routes.moderation,
        builder: (_, __) => const ModerationScreen(),
      ),
      GoRoute(
        path: '/moderation/review/:id',
        builder: (_, state) =>
            ReviewScreen(complaintId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: Routes.partnerDashboard,
        builder: (_, __) => const PartnerDashboardScreen(),
      ),
      GoRoute(
        path: Routes.authorityView,
        builder: (_, __) => const AuthorityScreen(),
      ),
      GoRoute(
        path: Routes.solvedGallery,
        builder: (_, __) => const SolvedGalleryScreen(),
      ),
      GoRoute(
        path: Routes.whatsappIntake,
        builder: (_, __) => const WhatsAppSimulatorScreen(),
      ),
      GoRoute(
        path: Routes.certificate,
        builder: (_, __) => const CertificateScreen(),
      ),
      GoRoute(
        path: Routes.ngoProfile,
        builder: (_, state) =>
            NgoProfileScreen(orgId: state.pathParameters['id']!),
      ),
      // ── Settings ────────────────────────────────────────────────────────
      GoRoute(path: Routes.settings, builder: (_, __) => const SettingsScreen()),
      GoRoute(path: Routes.privacyPolicy, builder: (_, __) => const PrivacyPolicyScreen()),
      GoRoute(path: Routes.terms, builder: (_, __) => const TermsScreen()),
      GoRoute(path: Routes.deleteAccount, builder: (_, __) => const DeleteAccountScreen()),
      GoRoute(
        path: '/permission/:type',
        builder: (_, state) =>
            PermissionRationaleScreen(type: state.pathParameters['type']!),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.uri}'),
      ),
    ),
  );
});

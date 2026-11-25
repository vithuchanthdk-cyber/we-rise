import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'app_localizations_en.dart';
part 'app_localizations_ta.dart';

/// Auto-discovered via AppLocalizations.of(context).
abstract class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = [
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  static const supportedLocales = [
    Locale('en'),
    Locale('ta'),
  ];

  // ── App general ──────────────────────────────────────────────────────────
  String get appName;
  String get appTagline;
  String get continueLabel;
  String get cancelLabel;
  String get saveLabel;
  String get deleteLabel;
  String get confirmLabel;
  String get rejectLabel;
  String get submitLabel;
  String get retryLabel;
  String get closeLabel;
  String get nextLabel;
  String get backLabel;
  String get loadingLabel;
  String get errorLabel;
  String get successLabel;
  String get unknownError;
  String get noInternetError;
  String get tryAgain;

  // ── Onboarding ───────────────────────────────────────────────────────────
  String get selectLanguage;
  String get languageEnglish;
  String get languageTamil;
  String get selectRole;
  String get roleCitizen;
  String get roleVolunteer;
  String get roleModerator;
  String get rolePartner;
  String get roleAuthority;
  String get roleCitizenDesc;
  String get roleVolunteerDesc;
  String get roleModeratorDesc;
  String get rolePartnerDesc;
  String get roleAuthorityDesc;
  String get demoMode;
  String get demoModeDesc;

  // ── Auth ─────────────────────────────────────────────────────────────────
  String get signIn;
  String get signUp;
  String get signOut;
  String get email;
  String get password;
  String get forgotPassword;
  String get signInWithGoogle;
  String get deleteAccount;
  String get deleteAccountConfirm;

  // ── Home / map ───────────────────────────────────────────────────────────
  String get homeTitle;
  String get mapTab;
  String get reportTab;
  String get myReportsTab;
  String get volunteerTab;
  String get profileTab;
  String get problemsSolvedTitle;

  // ── Complaint ────────────────────────────────────────────────────────────
  String get reportIssue;
  String get reportOnBehalf;
  String get categoryLabel;
  String get categoryPothole;
  String get categoryGarbage;
  String get categorySewage;
  String get categoryWaterlogging;
  String get categoryBlockedDrain;
  String get categoryStreetlight;
  String get categoryOther;
  String get addPhoto;
  String get takePhoto;
  String get chooseFromGallery;
  String get photoRequired;
  String get maxPhotos;
  String get galleryPhotoWarning;
  String get locationLabel;
  String get locationAuto;
  String get noteLabel;
  String get notePlaceholder;
  String get voiceInput;
  String get voiceListening;
  String get voiceTapToStop;
  String get submittingReport;
  String get reportSubmitted;
  String get reportQueued;
  String get trackingIdLabel;
  String get statusLabel;
  String get priorityLabel;
  String get priorityExplainer;
  String get supportComplaint;
  String get supported;
  String get supportCount;
  String get reportAbuse;
  String get blockUser;

  // ── Status labels ────────────────────────────────────────────────────────
  String get statusPendingReview;
  String get statusVerified;
  String get statusAssigned;
  String get statusWorkStarted;
  String get statusAwaitingConfirmation;
  String get statusProblemSolved;
  String get statusRejected;
  String get statusEscalated;

  // ── Moderation ───────────────────────────────────────────────────────────
  String get moderationTitle;
  String get approve;
  String get reject;
  String get markDuplicate;
  String get rejectionReasonFakePhoto;
  String get rejectionReasonPersonal;
  String get rejectionReasonNotCivic;
  String get rejectionReasonOther;
  String get duplicateWarning;

  // ── Volunteer / task ─────────────────────────────────────────────────────
  String get availableTasks;
  String get joinTask;
  String get taskJoined;
  String get uploadAfterPhoto;
  String get afterPhotoCameraOnly;
  String get locationCheckFailed;
  String get earnedHours;
  String get certificate;
  String get downloadCertificate;

  // ── Closure ──────────────────────────────────────────────────────────────
  String get confirmFixed;
  String get confirmFixedDesc;
  String get confirmations;
  String get confirmationsNeeded;
  String get rejectedReopened;

  // ── Priority explainer ───────────────────────────────────────────────────
  String get whyThisPriority;
  String get prioritySeverity;
  String get priorityAge;
  String get priorityEquity;
  String get priorityRecurrence;
  String get priorityDemand;

  // ── Settings / profile ───────────────────────────────────────────────────
  String get settingsTitle;
  String get privacyPolicy;
  String get termsOfService;
  String get language;
  String get notificationsLabel;
  String get aboutLabel;
  String get versionLabel;

  // ── Permissions ──────────────────────────────────────────────────────────
  String get permLocationTitle;
  String get permLocationBody;
  String get permCameraTitle;
  String get permCameraBody;
  String get permMicTitle;
  String get permMicBody;
  String get permNotifTitle;
  String get permNotifBody;
  String get permOpenSettings;
  String get permDeny;

  // ── Offline queue ────────────────────────────────────────────────────────
  String get offlineQueueBanner;
  String get syncNow;
  String get pendingUploads;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppLocalizations.supportedLocales.contains(Locale(locale.languageCode));

  @override
  Future<AppLocalizations> load(Locale locale) async {
    if (locale.languageCode == 'ta') return _AppLocalizationsTa(locale);
    return _AppLocalizationsEn(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

// ── Locale provider ──────────────────────────────────────────────────────────
final localeProvider = StateProvider<Locale>((ref) => const Locale('en'));

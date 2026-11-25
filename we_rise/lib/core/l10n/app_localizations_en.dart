part of 'app_localizations.dart';

class _AppLocalizationsEn extends AppLocalizations {
  _AppLocalizationsEn(super.locale);

  @override String get appName => 'WE RISE';
  @override String get appTagline => 'Uniting Every Voice to Transform Every Community';
  @override String get continueLabel => 'Continue';
  @override String get cancelLabel => 'Cancel';
  @override String get saveLabel => 'Save';
  @override String get deleteLabel => 'Delete';
  @override String get confirmLabel => 'Confirm';
  @override String get rejectLabel => 'Reject';
  @override String get submitLabel => 'Submit';
  @override String get retryLabel => 'Retry';
  @override String get closeLabel => 'Close';
  @override String get nextLabel => 'Next';
  @override String get backLabel => 'Back';
  @override String get loadingLabel => 'Loading…';
  @override String get errorLabel => 'Error';
  @override String get successLabel => 'Success';
  @override String get unknownError => 'Something went wrong. Please try again.';
  @override String get noInternetError => 'No internet connection. Report saved offline.';
  @override String get tryAgain => 'Try again';

  @override String get selectLanguage => 'Select language';
  @override String get languageEnglish => 'English';
  @override String get languageTamil => 'தமிழ்';
  @override String get selectRole => 'Who are you?';
  @override String get roleCitizen => 'Citizen';
  @override String get roleVolunteer => 'Volunteer';
  @override String get roleModerator => 'Moderator';
  @override String get rolePartner => 'Partner Organisation';
  @override String get roleAuthority => 'Authority';
  @override String get roleCitizenDesc => 'Report civic issues and track their resolution';
  @override String get roleVolunteerDesc => 'Join fix teams, earn verified volunteer hours';
  @override String get roleModeratorDesc => 'Review and verify incoming reports';
  @override String get rolePartnerDesc => 'Assign and supervise volunteer tasks';
  @override String get roleAuthorityDesc => 'View infrastructure issues and patterns';
  @override String get demoMode => 'Demo mode';
  @override String get demoModeDesc => 'Explore with sample Chennai data — no account needed';

  @override String get signIn => 'Sign in';
  @override String get signUp => 'Sign up';
  @override String get signOut => 'Sign out';
  @override String get email => 'Email';
  @override String get password => 'Password';
  @override String get forgotPassword => 'Forgot password?';
  @override String get signInWithGoogle => 'Continue with Google';
  @override String get deleteAccount => 'Delete my account and data';
  @override String get deleteAccountConfirm =>
      'This permanently deletes your account, reports, and all personal data. This cannot be undone.';

  @override String get homeTitle => 'WE RISE';
  @override String get mapTab => 'Map';
  @override String get reportTab => 'Report';
  @override String get myReportsTab => 'My reports';
  @override String get volunteerTab => 'Volunteer';
  @override String get profileTab => 'Profile';
  @override String get problemsSolvedTitle => 'Problems Solved';

  @override String get reportIssue => 'Report an issue';
  @override String get reportOnBehalf => 'Report on behalf of someone';
  @override String get categoryLabel => 'Category';
  @override String get categoryPothole => 'Pothole';
  @override String get categoryGarbage => 'Garbage';
  @override String get categorySewage => 'Sewage leak';
  @override String get categoryWaterlogging => 'Waterlogging';
  @override String get categoryBlockedDrain => 'Blocked drain';
  @override String get categoryStreetlight => 'Streetlight / Electrical';
  @override String get categoryOther => 'Other';
  @override String get addPhoto => 'Add photo';
  @override String get takePhoto => 'Take photo';
  @override String get chooseFromGallery => 'Choose from gallery';
  @override String get photoRequired => 'At least one photo is required';
  @override String get maxPhotos => 'Maximum 3 photos per report';
  @override String get galleryPhotoWarning =>
      'This photo appears to be more than 24 hours old. It will be flagged for moderator review.';
  @override String get locationLabel => 'Location';
  @override String get locationAuto => 'Location captured automatically';
  @override String get noteLabel => 'Note (optional)';
  @override String get notePlaceholder => 'Describe the issue in a few words…';
  @override String get voiceInput => 'Voice input';
  @override String get voiceListening => 'Listening…';
  @override String get voiceTapToStop => 'Tap to stop';
  @override String get submittingReport => 'Submitting report…';
  @override String get reportSubmitted => 'Report submitted successfully';
  @override String get reportQueued => 'No connection — report saved. Will sync when online.';
  @override String get trackingIdLabel => 'Tracking ID';
  @override String get statusLabel => 'Status';
  @override String get priorityLabel => 'Priority';
  @override String get priorityExplainer => 'Why this priority?';
  @override String get supportComplaint => 'I face this too';
  @override String get supported => 'You supported this';
  @override String get supportCount => 'people face this';
  @override String get reportAbuse => 'Report abuse';
  @override String get blockUser => 'Block user';

  @override String get statusPendingReview => 'Pending review';
  @override String get statusVerified => 'Verified';
  @override String get statusAssigned => 'Assigned';
  @override String get statusWorkStarted => 'Work started';
  @override String get statusAwaitingConfirmation => 'Awaiting confirmation';
  @override String get statusProblemSolved => 'Problem solved';
  @override String get statusRejected => 'Rejected';
  @override String get statusEscalated => 'Escalated';

  @override String get moderationTitle => 'Review reports';
  @override String get approve => 'Approve';
  @override String get reject => 'Reject';
  @override String get markDuplicate => 'Mark as duplicate';
  @override String get rejectionReasonFakePhoto => 'Fake or irrelevant photo';
  @override String get rejectionReasonPersonal => 'Personal complaint';
  @override String get rejectionReasonNotCivic => 'Not a civic issue';
  @override String get rejectionReasonOther => 'Other';
  @override String get duplicateWarning =>
      'A similar report exists nearby. Merge to combine supporters?';

  @override String get availableTasks => 'Available tasks';
  @override String get joinTask => 'Join task';
  @override String get taskJoined => 'You have joined this task';
  @override String get uploadAfterPhoto => 'Upload after-photo';
  @override String get afterPhotoCameraOnly =>
      'After-photos must be taken with the camera at the site';
  @override String get locationCheckFailed =>
      'You must be within 50 m of the original complaint location';
  @override String get earnedHours => 'hours earned';
  @override String get certificate => 'Certificate';
  @override String get downloadCertificate => 'Download certificate';

  @override String get confirmFixed => 'Is this fixed?';
  @override String get confirmFixedDesc =>
      'Confirm only if the problem has been genuinely resolved at this location.';
  @override String get confirmations => 'confirmations';
  @override String get confirmationsNeeded => '2 more needed';
  @override String get rejectedReopened => 'Confirmation rejected — complaint reopened';

  @override String get whyThisPriority => 'Why this priority?';
  @override String get prioritySeverity => 'Severity (35%)';
  @override String get priorityAge => 'Time pending (25%)';
  @override String get priorityEquity => 'Area vulnerability (20%)';
  @override String get priorityRecurrence => 'Recurrence (12%)';
  @override String get priorityDemand => 'Community demand (8%)';

  @override String get settingsTitle => 'Settings';
  @override String get privacyPolicy => 'Privacy policy';
  @override String get termsOfService => 'Terms of service';
  @override String get language => 'Language';
  @override String get notificationsLabel => 'Notifications';
  @override String get aboutLabel => 'About WE RISE';
  @override String get versionLabel => 'Version';

  @override String get permLocationTitle => 'Location access';
  @override String get permLocationBody =>
      'WE RISE needs your location to tag issue reports accurately and to verify on-site photos. Location is never shown publicly.';
  @override String get permCameraTitle => 'Camera access';
  @override String get permCameraBody =>
      'Photos are required to verify civic complaints. The camera is used only when you tap "Take photo".';
  @override String get permMicTitle => 'Microphone access';
  @override String get permMicBody =>
      'Voice input lets you describe issues in Tamil or English without typing. Used only while you hold the voice button.';
  @override String get permNotifTitle => 'Notifications';
  @override String get permNotifBody =>
      'Get updates when your report is verified, assigned, or resolved.';
  @override String get permOpenSettings => 'Open settings';
  @override String get permDeny => 'Not now';

  @override String get offlineQueueBanner =>
      'You\'re offline. Reports will sync when connection returns.';
  @override String get syncNow => 'Sync now';
  @override String get pendingUploads => 'pending uploads';
}

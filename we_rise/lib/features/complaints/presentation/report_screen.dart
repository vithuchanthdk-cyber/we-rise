import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/shared/widgets/offline_banner.dart';
import '../../../core/shared/widgets/we_rise_button.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/presentation/providers.dart';
import '../data/ai_category_service.dart';
import '../data/location_service.dart';
import '../data/photo_service.dart';
import '../data/providers.dart';
import '../domain/enums.dart';
import '../domain/models.dart';
import '../domain/priority_calculator.dart';
import '../domain/risk_classifier.dart';
import '../domain/tracking_id_service.dart';

class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({super.key});

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  static const int _maxPhotos = 3;
  static const _uuid = Uuid();

  final _noteController = TextEditingController();
  final _onBehalfController = TextEditingController();

  final List<PickedPhotoResult> _photos = [];
  LocationResult? _locationResult;
  bool _loadingLocation = true;
  late DateTime _capturedTime;

  ComplaintCategory _category = ComplaintCategory.pothole;
  ComplaintCategory _aiSuggested = ComplaintCategory.pothole;
  bool _userOverrodeCategory = false;

  bool _reportOnBehalf = false;
  bool _listening = false;
  String _voiceLocale = 'en_IN';

  bool _submitting = false;
  double _uploadProgress = 0;
  String? _submitError;

  @override
  void initState() {
    super.initState();
    _capturedTime = DateTime.now();
    _fetchLocation();
  }

  @override
  void dispose() {
    _noteController.dispose();
    _onBehalfController.dispose();
    super.dispose();
  }

  Future<void> _fetchLocation() async {
    setState(() => _loadingLocation = true);
    final res = await ref.read(locationServiceProvider).getCurrentLocation();
    if (!mounted) return;
    setState(() {
      _locationResult = res;
      _capturedTime = DateTime.now();
      _loadingLocation = false;
    });
  }

  Future<void> _pickPhoto(PhotoSource source) async {
    if (_photos.length >= _maxPhotos) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).maxPhotos)),
      );
      return;
    }

    final photoService = ref.read(photoServiceProvider);
    final picked = source == PhotoSource.camera
        ? await photoService.pickFromCamera()
        : await photoService.pickFromGallery();

    if (picked == null || !mounted) return;

    setState(() {
      _photos.add(picked);
      _updateAiSuggestion();
    });
  }

  void _updateAiSuggestion() {
    final suggested = MockAiCategoryService.suggest(
      note: _noteController.text,
      photoCount: _photos.length,
    );
    _aiSuggested = suggested;
    if (!_userOverrodeCategory) {
      _category = suggested;
    }
  }

  Future<void> _toggleVoice() async {
    final voice = ref.read(voiceServiceProvider);
    if (_listening) {
      await voice.stopListening();
      if (mounted) setState(() => _listening = false);
      return;
    }

    final appLocale = ref.read(localeProvider).languageCode;
    final loc = _voiceLocale.isNotEmpty
        ? _voiceLocale
        : (appLocale == 'ta' ? 'ta_IN' : 'en_IN');

    setState(() => _listening = true);
    await voice.startListening(
      localeId: loc,
      onResult: (words) {
        if (!mounted || words.isEmpty) return;
        setState(() {
          final existing = _noteController.text.trim();
          _noteController.text =
              existing.isEmpty ? words : '$existing $words';
          _updateAiSuggestion();
        });
      },
    );
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    if (_photos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.photoRequired)),
      );
      return;
    }
    if (_locationResult == null) {
      await _fetchLocation();
      if (_locationResult == null) return;
    }

    setState(() {
      _submitting = true;
      _uploadProgress = 0.25;
      _submitError = null;
    });

    try {
      final user = ref.read(currentUserProvider);
      final reporterId = user?.id ?? 'u-citizen-1';
      final isOnline = ref.read(isOnlineProvider);
      final loc = _locationResult!;

      if (!isOnline) {
        final draft = DraftReport(
          id: _uuid.v4(),
          category: _category,
          severity: _category.defaultSeverity,
          location: loc.location,
          wardId: loc.ward.id,
          photoPaths: _photos.map((p) => p.path).toList(),
          photoSources: _photos.map((p) => p.source).toList(),
          createdAt: _capturedTime,
          reporterId: reporterId,
          note: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
          onBehalfOf: _reportOnBehalf &&
                  _onBehalfController.text.trim().isNotEmpty
              ? _onBehalfController.text.trim()
              : null,
        );
        await ref.read(offlineQueueRepositoryProvider).enqueueDraft(draft);
        if (!mounted) return;
        setState(() {
          _submitting = false;
          _uploadProgress = 1.0;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.reportQueued)),
        );
        _resetForm();
        return;
      }

      setState(() => _uploadProgress = 0.6);

      final repo = ref.read(complaintRepositoryProvider);
      final seq = await repo.nextSequenceNumber();
      final trackingId = TrackingIdService.generate(
        sequence: seq,
        year: _capturedTime.year,
      );
      final id = _uuid.v4();
      final risk = RiskClassifier.classify(_category);

      final complaintPhotos = _photos
          .map(
            (p) => ComplaintPhoto(
              id: _uuid.v4(),
              url: p.path,
              source: p.source,
              capturedAt: p.capturedAt,
              isGalleryFlagged: p.isGalleryFlagged,
            ),
          )
          .toList();

      final base = Complaint(
        id: id,
        trackingId: trackingId,
        category: _category,
        severity: _category.defaultSeverity,
        status: ComplaintStatus.PENDING_REVIEW,
        location: loc.location,
        wardId: loc.ward.id,
        photos: complaintPhotos,
        createdAt: _capturedTime,
        lastStatusChangeAt: _capturedTime,
        reporterId: reporterId,
        supporterIds: const [],
        riskClass: risk,
        priorityScore: 0,
        escalated: false,
        reopenCount: 0,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        onBehalfOf: _reportOnBehalf &&
                _onBehalfController.text.trim().isNotEmpty
            ? _onBehalfController.text.trim()
            : null,
        timeline: [
          StatusEvent(
            complaintId: id,
            status: ComplaintStatus.PENDING_REVIEW,
            at: _capturedTime,
            actorRole: 'citizen',
          ),
        ],
      );

      final scored = base.copyWith(
        priorityScore: const PriorityCalculator()
            .score(base, recurrenceCount: 0)
            .total,
      );

      await repo.create(scored);

      if (!mounted) return;
      setState(() {
        _submitting = false;
        _uploadProgress = 1.0;
      });

      _resetForm();
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.reportSubmitted),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${l10n.trackingIdLabel}: $trackingId'),
              const SizedBox(height: 8),
              const Text(
                'Your report is pending moderator review before appearing on the public map.',
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.go('/my-reports');
              },
              child: Text(l10n.myReportsTab),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.push('/complaint/$id');
              },
              child: Text(l10n.continueLabel),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _submitError = e.toString();
      });
    }
  }

  void _resetForm() {
    _photos.clear();
    _noteController.clear();
    _onBehalfController.clear();
    _reportOnBehalf = false;
    _userOverrodeCategory = false;
    _category = ComplaintCategory.pothole;
    _aiSuggested = ComplaintCategory.pothole;
    _uploadProgress = 0;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasGalleryWarning = _photos.any((p) => p.isGalleryFlagged);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.reportIssue)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // ── 1. Photos (mandatory, up to 3) ───────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${l10n.addPhoto} (${_photos.length}/$_maxPhotos)',
                  style: AppTextStyles.titleSmall),
              const Text('Max 400 KB · EXIF stripped',
                  style: AppTextStyles.caption),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('take_photo_btn'),
                  onPressed: _photos.length >= _maxPhotos
                      ? null
                      : () => _pickPhoto(PhotoSource.camera),
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: Text(l10n.takePhoto),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('gallery_photo_btn'),
                  onPressed: _photos.length >= _maxPhotos
                      ? null
                      : () => _pickPhoto(PhotoSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text(l10n.chooseFromGallery),
                ),
              ),
            ],
          ),
          if (_photos.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 112,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _photos.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, idx) {
                  final p = _photos[idx];
                  final kb = (p.sizeBytes / 1024).ceil();
                  return Stack(
                    children: [
                      Container(
                        width: 112,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: p.isGalleryFlagged
                                ? AppColors.warning
                                : AppColors.divider,
                            width: p.isGalleryFlagged ? 2 : 1,
                          ),
                          color: Colors.grey.shade200,
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: [
                            Expanded(
                              child: File(p.path).existsSync()
                                  ? Image.file(
                                      File(p.path),
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                    )
                                  : const Icon(Icons.image, size: 40),
                            ),
                            Container(
                              width: double.infinity,
                              color: Colors.black87,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              child: Text(
                                '${p.source.name} · ${kb}KB',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        top: 2,
                        right: 2,
                        child: InkWell(
                          onTap: () => setState(() => _photos.removeAt(idx)),
                          child: const CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.black54,
                            child: Icon(Icons.close,
                                size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
          if (hasGalleryWarning) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.warning.withAlpha(30),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.warning),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber, color: AppColors.warning),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.galleryPhotoWarning,
                      style: AppTextStyles.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),

          // ── 2. Auto Location & Timestamp (read-only) ─────────────────────
          Text(l10n.locationLabel, style: AppTextStyles.titleSmall),
          const SizedBox(height: AppSpacing.xs),
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm + 4),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.divider),
              borderRadius: const BorderRadius.all(AppRadius.md),
            ),
            child: _loadingLocation
                ? const Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text('Capturing GPS location...'),
                    ],
                  )
                : Row(
                    children: [
                      const Icon(Icons.location_on, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_locationResult?.ward.name ?? 'Chennai'} · '
                              '${_locationResult?.isLiveGps == true ? 'Live GPS' : 'Demo GPS'}',
                              style: AppTextStyles.titleSmall,
                            ),
                            Text(
                              '${_locationResult?.location.latitude.toStringAsFixed(4)}, '
                              '${_locationResult?.location.longitude.toStringAsFixed(4)} · '
                              '${_capturedTime.hour.toString().padLeft(2, '0')}:'
                              '${_capturedTime.minute.toString().padLeft(2, '0')}',
                              style: AppTextStyles.caption,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.lock_outline,
                          size: 16, color: AppColors.textDisabled),
                    ],
                  ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── 3. Category + AI Suggestion ──────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.categoryLabel, style: AppTextStyles.titleSmall),
              Text(
                'AI suggested: ${_aiSuggested.displayName}',
                style: AppTextStyles.caption.copyWith(color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: ComplaintCategory.values.map((cat) {
              final selected = _category == cat;
              return ChoiceChip(
                label: Text(_categoryLabel(cat, l10n)),
                selected: selected,
                onSelected: (_) {
                  setState(() {
                    _category = cat;
                    _userOverrodeCategory = true;
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── 4. Note + Voice Input (EN / TA) ──────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.noteLabel, style: AppTextStyles.titleSmall),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'en_IN', label: Text('EN')),
                  ButtonSegment(value: 'ta_IN', label: Text('தமிழ்')),
                ],
                selected: {_voiceLocale},
                onSelectionChanged: (s) =>
                    setState(() => _voiceLocale = s.first),
                style: const ButtonStyle(
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _noteController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: l10n.notePlaceholder,
                  ),
                  onChanged: (_) => setState(_updateAiSuggestion),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: _listening ? l10n.voiceTapToStop : l10n.voiceInput,
                icon: Icon(_listening ? Icons.stop : Icons.mic),
                onPressed: _toggleVoice,
              ),
            ],
          ),
          if (_listening)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                l10n.voiceListening,
                style: AppTextStyles.caption.copyWith(color: AppColors.error),
              ),
            ),
          const SizedBox(height: AppSpacing.md),

          // ── 5. Report on behalf of someone ───────────────────────────────
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.reportOnBehalf),
            subtitle: const Text(
              'Use when helping a resident without a smartphone',
              style: AppTextStyles.caption,
            ),
            value: _reportOnBehalf,
            onChanged: (v) => setState(() => _reportOnBehalf = v),
          ),
          if (_reportOnBehalf) ...[
            TextField(
              controller: _onBehalfController,
              decoration: const InputDecoration(
                labelText: 'Resident landmark / context (optional, no phone)',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // ── 6. Upload Progress / Error / Submit ──────────────────────────
          if (_submitting) ...[
            LinearProgressIndicator(value: _uploadProgress),
            const SizedBox(height: 8),
            Text(l10n.submittingReport, style: AppTextStyles.caption),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (_submitError != null) ...[
            Container(
              padding: const EdgeInsets.all(8),
              color: AppColors.error.withAlpha(20),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _submitError!,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),
                  TextButton(
                    onPressed: _submit,
                    child: Text(l10n.retryLabel),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          const SizedBox(height: AppSpacing.sm),
          WeRiseButton(
            label: l10n.submitLabel,
            icon: Icons.send,
            loading: _submitting,
            onPressed: _submitting ? null : _submit,
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  static String _categoryLabel(ComplaintCategory cat, AppLocalizations l) =>
      switch (cat) {
        ComplaintCategory.pothole => l.categoryPothole,
        ComplaintCategory.garbage => l.categoryGarbage,
        ComplaintCategory.sewage => l.categorySewage,
        ComplaintCategory.waterlogging => l.categoryWaterlogging,
        ComplaintCategory.blockedDrain => l.categoryBlockedDrain,
        ComplaintCategory.streetlight => l.categoryStreetlight,
        ComplaintCategory.other => l.categoryOther,
      };
}

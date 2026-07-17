import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fridgeos/app/theme/app_spacing.dart';
import 'package:fridgeos/features/barcode/application/scan_detection.dart';
import 'package:fridgeos/features/barcode/presentation/widgets/scan_add_sheet.dart';
import 'package:fridgeos/l10n/gen/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// When true, skips the live camera preview (widget tests / headless CI).
@visibleForTesting
bool debugDisableCameraPreview = false;

/// Full-screen barcode scanner with camera preview and manual fallback.
///
/// Camera frames are never persisted (`returnImage: false`). Detected values are
/// validated via [Barcode.tryParse] before any lookup.
class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  late final MobileScannerController _scanner;
  final _manualController = TextEditingController();

  var _manualMode = false;
  var _lookingUp = false;
  var _switchBusy = false;
  String? _lastDetected;
  String? _cameraErrorMessage;

  @override
  void initState() {
    super.initState();
    // Front camera is the product default (kitchen tablet facing the user).
    _scanner = MobileScannerController(
      autoStart: !debugDisableCameraPreview,
      facing: CameraFacing.front,
      returnImage: false,
      detectionSpeed: DetectionSpeed.normal,
      detectionTimeoutMs: 500,
      formats: const [
        BarcodeFormat.ean8,
        BarcodeFormat.ean13,
        BarcodeFormat.upcA,
      ],
    );
    if (debugDisableCameraPreview) {
      _manualMode = true;
    }
  }

  @override
  void dispose() {
    _scanner.dispose();
    _manualController.dispose();
    super.dispose();
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_lookingUp || _manualMode) return;
    final value = firstValidBarcodeValue(
      capture.barcodes.map((b) => b.rawValue),
    );
    if (value == null) return;
    if (value == _lastDetected) return;
    setState(() => _lastDetected = value);
    await _lookup(value);
  }

  Future<void> _lookup(String raw) async {
    if (_lookingUp) return;
    setState(() => _lookingUp = true);
    // Pause scanning while the lookup / add sheet is open to avoid duplicates.
    if (!debugDisableCameraPreview && !_manualMode) {
      await _scanner.stop();
    }
    try {
      if (!mounted) return;
      await handleBarcodeLookup(ref, context, raw);
    } finally {
      if (mounted) {
        setState(() => _lookingUp = false);
        if (!debugDisableCameraPreview && !_manualMode) {
          await _scanner.start();
        }
      }
    }
  }

  Future<void> _switchCamera() async {
    if (_switchBusy || _manualMode || debugDisableCameraPreview) return;
    setState(() => _switchBusy = true);
    try {
      await _scanner.switchCamera();
    } on Object {
      // Single-camera devices throw; ignore and keep current facing.
    } finally {
      if (mounted) setState(() => _switchBusy = false);
    }
  }

  void _enterManualMode() {
    setState(() {
      _manualMode = true;
      _cameraErrorMessage = null;
    });
  }

  Future<void> _enterCameraMode() async {
    setState(() {
      _manualMode = false;
      _cameraErrorMessage = null;
      _lastDetected = null;
    });
    if (debugDisableCameraPreview) return;
    try {
      await _scanner.start(cameraDirection: CameraFacing.front);
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _manualMode = true;
          _cameraErrorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.scanTitle),
        leading: BackButton(onPressed: _goBack),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _manualMode ? _buildManual(l10n) : _buildCamera(l10n),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                alignment: WrapAlignment.center,
                children: [
                  if (_manualMode)
                    FilledButton.icon(
                      onPressed: debugDisableCameraPreview
                          ? null
                          : _enterCameraMode,
                      icon: const Icon(Icons.qr_code_scanner),
                      label: Text(l10n.scanWithCamera),
                    )
                  else ...[
                    OutlinedButton.icon(
                      onPressed: _switchBusy ? null : _switchCamera,
                      icon: const Icon(Icons.cameraswitch_outlined),
                      label: Text(l10n.switchCamera),
                    ),
                    OutlinedButton.icon(
                      onPressed: _enterManualMode,
                      icon: const Icon(Icons.keyboard_outlined),
                      label: Text(l10n.enterManually),
                    ),
                  ],
                  TextButton.icon(
                    onPressed: _goBack,
                    icon: const Icon(Icons.arrow_back),
                    label: Text(l10n.back),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCamera(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ColoredBox(
            color: Colors.black,
            child: MobileScanner(
              controller: _scanner,
              onDetect: _onDetect,
              errorBuilder: (context, error) {
                final denied =
                    error.errorCode == MobileScannerErrorCode.permissionDenied;
                return _CameraErrorPane(
                  title: denied
                      ? l10n.cameraPermissionDeniedTitle
                      : l10n.cameraUnavailableTitle,
                  body: denied
                      ? l10n.cameraPermissionDeniedBody
                      : l10n.cameraUnavailableBody,
                  onEnterManually: _enterManualMode,
                  enterManuallyLabel: l10n.enterManually,
                );
              },
            ),
          ),
        ),
        if (_lastDetected != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              0,
            ),
            child: Text(
              l10n.detectedBarcode(_lastDetected!),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        if (_lookingUp)
          const Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  Widget _buildManual(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.scanEnterBarcodeBody,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          if (_cameraErrorMessage != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.cameraUnavailableBody,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          TextField(
            controller: _manualController,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _submitManual(),
            decoration: InputDecoration(
              labelText: l10n.fieldBarcode,
              border: const OutlineInputBorder(),
              hintText: '4006381333931',
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            onPressed: _lookingUp ? null : _submitManual,
            icon: _lookingUp
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.search),
            label: Text(l10n.lookupBarcode),
          ),
        ],
      ),
    );
  }

  Future<void> _submitManual() async {
    final raw = _manualController.text.trim();
    if (raw.isEmpty) return;
    await _lookup(raw);
  }
}

class _CameraErrorPane extends StatelessWidget {
  const _CameraErrorPane({
    required this.title,
    required this.body,
    required this.onEnterManually,
    required this.enterManuallyLabel,
  });

  final String title;
  final String body;
  final VoidCallback onEnterManually;
  final String enterManuallyLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.no_photography_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(body, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: onEnterManually,
              child: Text(enterManuallyLabel),
            ),
          ],
        ),
      ),
    );
  }
}

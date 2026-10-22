import 'package:flutter/material.dart';

/// Full-screen friendly dialog to view a prescription image with pinch-zoom and pan.
void showZoomablePrescriptionImageDialog(
  BuildContext context,
  String imageUrl,
) {
  final trimmed = imageUrl.replaceAll('"', '').trim();
  if (trimmed.isEmpty || trimmed == 'null') return;

  showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext dialogContext) {
      final size = MediaQuery.sizeOf(dialogContext);
      final maxH = size.height * 0.72;

      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 28),
        backgroundColor: Colors.transparent,
        child: Material(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(24),
            bottom: Radius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
                child: Text(
                  'Prescription View',
                  style: Theme.of(dialogContext).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: SizedBox(
                  width: size.width - 40,
                  height: maxH,
                  child: InteractiveViewer(
                    minScale: 0.85,
                    maxScale: 5,
                    boundaryMargin: const EdgeInsets.all(200),
                    clipBehavior: Clip.hardEdge,
                    panEnabled: true,
                    scaleEnabled: true,
                    child: Center(
                      child: Image.network(
                        trimmed,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: SizedBox(
                              width: 40,
                              height: 40,
                              child: CircularProgressIndicator(
                                value:
                                    loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                'Could not load image',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Theme.of(dialogContext)
                                      .colorScheme
                                      .error,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      );
    },
  );
}

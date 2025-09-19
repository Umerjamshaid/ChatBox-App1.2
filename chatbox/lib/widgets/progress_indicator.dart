// lib/widgets/progress_indicator.dart
import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:chatbox/constants/colors.dart';

class UploadProgressIndicator extends StatelessWidget {
  final double progress;
  final String? fileName;
  final String? status;
  final VoidCallback? onCancel;

  const UploadProgressIndicator({
    super.key,
    required this.progress,
    this.fileName,
    this.status,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(_getProgressIcon(), color: _getProgressColor(), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  status ?? 'Uploading...',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.onSurface,
                  ),
                ),
              ),
              if (onCancel != null)
                IconButton(
                  icon: Icon(Icons.close, color: AppColors.grey600, size: 20),
                  onPressed: onCancel,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),

          const SizedBox(height: 8),

          // File name
          if (fileName != null)
            Text(
              fileName!,
              style: TextStyle(fontSize: 12, color: AppColors.grey600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

          const SizedBox(height: 12),

          // Progress bar
          LinearPercentIndicator(
            percent: progress.clamp(0.0, 1.0),
            lineHeight: 6,
            backgroundColor: AppColors.grey200,
            progressColor: _getProgressColor(),
            barRadius: const Radius.circular(3),
          ),

          const SizedBox(height: 4),

          // Progress text
          Text(
            '${(progress * 100).toInt()}%',
            style: TextStyle(fontSize: 12, color: AppColors.grey600),
          ),
        ],
      ),
    );
  }

  IconData _getProgressIcon() {
    if (progress < 0.3) return Icons.upload;
    if (progress < 0.7) return Icons.upload_file;
    if (progress < 1.0) return Icons.cloud_upload;
    return Icons.check_circle;
  }

  Color _getProgressColor() {
    if (progress < 0.3) return AppColors.warning;
    if (progress < 0.7) return AppColors.primary;
    if (progress < 1.0) return AppColors.success;
    return AppColors.success;
  }
}

class DownloadProgressIndicator extends StatelessWidget {
  final double progress;
  final String? fileName;
  final String? status;
  final VoidCallback? onCancel;

  const DownloadProgressIndicator({
    super.key,
    required this.progress,
    this.fileName,
    this.status,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(_getProgressIcon(), color: _getProgressColor(), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  status ?? 'Downloading...',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.onSurface,
                  ),
                ),
              ),
              if (onCancel != null)
                IconButton(
                  icon: Icon(Icons.close, color: AppColors.grey600, size: 20),
                  onPressed: onCancel,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),

          const SizedBox(height: 8),

          // File name
          if (fileName != null)
            Text(
              fileName!,
              style: TextStyle(fontSize: 12, color: AppColors.grey600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

          const SizedBox(height: 12),

          // Circular progress indicator
          Center(
            child: CircularPercentIndicator(
              percent: progress.clamp(0.0, 1.0),
              radius: 40,
              lineWidth: 6,
              backgroundColor: AppColors.grey200,
              progressColor: _getProgressColor(),
              center: Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.onSurface,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getProgressIcon() {
    if (progress < 0.3) return Icons.download;
    if (progress < 0.7) return Icons.downloading;
    if (progress < 1.0) return Icons.download_done;
    return Icons.check_circle;
  }

  Color _getProgressColor() {
    if (progress < 0.3) return AppColors.warning;
    if (progress < 0.7) return AppColors.primary;
    if (progress < 1.0) return AppColors.success;
    return AppColors.success;
  }
}

class MediaUploadOverlay extends StatelessWidget {
  final List<Map<String, dynamic>> uploads;

  const MediaUploadOverlay({super.key, required this.uploads});

  @override
  Widget build(BuildContext context) {
    if (uploads.isEmpty) return const SizedBox.shrink();

    return Positioned(
      bottom: 100,
      left: 16,
      right: 16,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.4,
        ),
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: uploads.length,
          itemBuilder: (context, index) {
            final upload = uploads[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: UploadProgressIndicator(
                progress: upload['progress'] ?? 0.0,
                fileName: upload['fileName'],
                status: upload['status'],
                onCancel: upload['onCancel'],
              ),
            );
          },
        ),
      ),
    );
  }
}

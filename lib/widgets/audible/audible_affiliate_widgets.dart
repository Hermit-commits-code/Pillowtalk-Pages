// lib/widgets/audible/audible_affiliate_widgets.dart
import 'package:flutter/material.dart';
import '../../models/user_book.dart';
import '../../services/audible_affiliate_service.dart';

/// Main Audible affiliate button widget
class AudibleAffiliateButton extends StatefulWidget {
  final UserBook book;
  final String? asin; // Audible ASIN if available
  final AudibleButtonStyle style;
  final VoidCallback? onPressed;

  const AudibleAffiliateButton({
    super.key,
    required this.book,
    this.asin,
    this.style = AudibleButtonStyle.primary,
    this.onPressed,
  });

  @override
  State<AudibleAffiliateButton> createState() => _AudibleAffiliateButtonState();
}

class _AudibleAffiliateButtonState extends State<AudibleAffiliateButton> {
  final AudibleAffiliateService _audibleService = AudibleAffiliateService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    if (!_audibleService.shouldShowAudibleLink(widget.book)) {
      return const SizedBox.shrink();
    }

    final buttonText = _audibleService.getAudibleButtonText(widget.book);
    final isAudiobook = widget.book.format == BookFormat.audiobook;

    switch (widget.style) {
      case AudibleButtonStyle.primary:
        return _buildPrimaryButton(buttonText, isAudiobook);
      case AudibleButtonStyle.compact:
        return _buildCompactButton(buttonText, isAudiobook);
      case AudibleButtonStyle.text:
        return _buildTextButton(buttonText, isAudiobook);
      case AudibleButtonStyle.chip:
        return _buildChipButton(buttonText, isAudiobook);
    }
  }

  Widget _buildPrimaryButton(String text, bool isAudiobook) {
    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFF6600),
            Color(0xFFFF8C00),
          ], // Audible orange gradient
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withAlpha((0.3 * 255).round()),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _handleTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isLoading) ...[
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ] else ...[
                  Icon(
                    isAudiobook ? Icons.headphones : Icons.play_circle_outline,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactButton(String text, bool isAudiobook) {
    return SizedBox(
      height: 36,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _handleTap,
        icon: _isLoading
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Icon(
                isAudiobook ? Icons.headphones : Icons.play_circle_outline,
                size: 16,
                color: Colors.white,
              ),
        label: Text(
          text,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF6600),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
    );
  }

  Widget _buildTextButton(String text, bool isAudiobook) {
    return TextButton.icon(
      onPressed: _isLoading ? null : _handleTap,
      icon: _isLoading
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6600)),
              ),
            )
          : Icon(
              isAudiobook ? Icons.headphones : Icons.play_circle_outline,
              size: 16,
              color: const Color(0xFFFF6600),
            ),
      label: Text(
        text,
        style: const TextStyle(
          color: Color(0xFFFF6600),
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildChipButton(String text, bool isAudiobook) {
    return ActionChip(
      onPressed: _isLoading ? null : _handleTap,
      avatar: _isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6600)),
              ),
            )
          : Icon(
              isAudiobook ? Icons.headphones : Icons.play_circle_outline,
              size: 16,
              color: const Color(0xFFFF6600),
            ),
      label: Text(
        text,
        style: const TextStyle(
          color: Color(0xFFFF6600),
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
      backgroundColor: Color(0xFFFF6600).withAlpha((0.1 * 255).round()),
      side: const BorderSide(color: Color(0xFFFF6600), width: 1),
    );
  }

  Future<void> _handleTap() async {
    if (widget.onPressed != null) {
      widget.onPressed!();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _audibleService.openInAudibleApp(
        widget.book,
        asin: widget.asin,
      );

      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to open Audible. Please try again.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error opening Audible. Please try again.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

/// Audiobook promotion widget for non-audiobook formats
class AudiobookPromotionBanner extends StatelessWidget {
  final UserBook book;
  final String? asin;

  const AudiobookPromotionBanner({super.key, required this.book, this.asin});

  @override
  Widget build(BuildContext context) {
    // Only show for non-audiobook formats
    if (book.format == BookFormat.audiobook) {
      return const SizedBox.shrink();
    }

    final audibleService = AudibleAffiliateService();
    final promptText = audibleService.getAudiobookPrompt(book);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFFF6600).withAlpha((0.1 * 255).round()),
            Color(0xFFFF8C00).withAlpha((0.05 * 255).round()),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Color(0xFFFF6600).withAlpha((0.3 * 255).round()),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.headphones, color: const Color(0xFFFF6600), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Love audiobooks?',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: const Color(0xFFFF6600),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  promptText,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          AudibleAffiliateButton(
            book: book,
            asin: asin,
            style: AudibleButtonStyle.compact,
          ),
        ],
      ),
    );
  }
}

/// Narrator information widget for audiobooks
class AudiobookNarratorInfo extends StatelessWidget {
  final UserBook book;

  const AudiobookNarratorInfo({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    if (book.format != BookFormat.audiobook) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.purple.withAlpha((0.1 * 255).round()),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.purple.withAlpha((0.3 * 255).round()),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.record_voice_over, color: Colors.purple, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (book.narrator != null) ...[
                  Text(
                    'Narrated by ${book.narrator}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: Colors.purple[700],
                    ),
                  ),
                ] else ...[
                  Text(
                    'Audiobook format',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: Colors.purple[700],
                    ),
                  ),
                ],
                if (book.runtimeMinutes != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Runtime: ${_formatRuntime(book.runtimeMinutes!)}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatRuntime(int minutes) {
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (hours > 0) {
      return '${hours}h ${remainingMinutes}m';
    } else {
      return '${remainingMinutes}m';
    }
  }
}

/// Listening progress widget for audiobooks
class AudiobookProgressWidget extends StatelessWidget {
  final UserBook book;
  final VoidCallback? onUpdateProgress;

  const AudiobookProgressWidget({
    super.key,
    required this.book,
    this.onUpdateProgress,
  });

  @override
  Widget build(BuildContext context) {
    if (book.format != BookFormat.audiobook || book.runtimeMinutes == null) {
      return const SizedBox.shrink();
    }

    final progress = book.listeningProgressMinutes ?? 0;
    final total = book.runtimeMinutes!;
    final progressPercentage = total > 0
        ? (progress / total).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withAlpha((0.1 * 255).round()),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withAlpha((0.3 * 255).round()), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Listening Progress',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
              Text(
                '${(progressPercentage * 100).toStringAsFixed(0)}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progressPercentage,
            backgroundColor: Colors.blue.withAlpha((0.2 * 255).round()),
            valueColor: AlwaysStoppedAnimation(Colors.blue),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatRuntime(progress),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
              Text(
                _formatRuntime(total),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
            ],
          ),
          if (onUpdateProgress != null) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: onUpdateProgress,
                icon: const Icon(Icons.edit, size: 16),
                label: const Text(
                  'Update Progress',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatRuntime(int minutes) {
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (hours > 0) {
      return '${hours}h ${remainingMinutes}m';
    } else {
      return '${remainingMinutes}m';
    }
  }
}

/// Enum for different Audible button styles
enum AudibleButtonStyle {
  primary, // Large prominent button
  compact, // Smaller elevated button
  text, // Text button with icon
  chip, // Chip-style button
}

/// Combined Audible affiliate section for book detail pages
class AudibleAffiliateSection extends StatelessWidget {
  final UserBook book;
  final String? asin;

  const AudibleAffiliateSection({super.key, required this.book, this.asin});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Audiobook-specific widgets
        if (book.format == BookFormat.audiobook) ...[
          AudiobookNarratorInfo(book: book),
          const SizedBox(height: 12),
          AudiobookProgressWidget(book: book),
          const SizedBox(height: 12),
        ],

        // Promotion banner for non-audiobooks
        if (book.format != BookFormat.audiobook) ...[
          AudiobookPromotionBanner(book: book, asin: asin),
          const SizedBox(height: 12),
        ],

        // Main affiliate button
        AudibleAffiliateButton(
          book: book,
          asin: asin,
          style: AudibleButtonStyle.primary,
        ),
      ],
    );
  }
}

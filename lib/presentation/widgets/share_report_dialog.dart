import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/app_colors.dart';
import '../../data/services/data_export_service.dart';
import '../../providers/app_state_scope.dart';

enum ReportPeriod {
  currentMonth,
  lastMonth,
  customRange,
}

class ShareReportDialog extends StatefulWidget {
  const ShareReportDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const ShareReportDialog(),
    );
  }

  @override
  State<ShareReportDialog> createState() => _ShareReportDialogState();
}

class _ShareReportDialogState extends State<ShareReportDialog> {
  ReportPeriod _selectedPeriod = ReportPeriod.currentMonth;
  DateTimeRange? _customRange;
  bool _isSharing = false;

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final now = DateTime.now();
    int? year;
    int? month;
    DateTimeRange? range;
    String periodTitle;

    switch (_selectedPeriod) {
      case ReportPeriod.currentMonth:
        year = now.year;
        month = now.month;
        periodTitle = 'Current Month';
        break;
      case ReportPeriod.lastMonth:
        year = now.month == 1 ? now.year - 1 : now.year;
        month = now.month == 1 ? 12 : now.month - 1;
        periodTitle = 'Last Month';
        break;
      case ReportPeriod.customRange:
        range = _customRange ??
            DateTimeRange(
              start: now.subtract(const Duration(days: 30)),
              end: now,
            );
        periodTitle = 'Custom Range';
        break;
    }

    final reportText = appState.getShareableFinancialReportText(
      customRange: range,
      year: year,
      month: month,
      periodTitle: periodTitle,
    );

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.assessment_rounded, color: AppColors.accent, size: 24),
                      SizedBox(width: 10),
                      Text(
                        'Share Financial Report',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Period Selector Tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: SegmentedButton<ReportPeriod>(
                segments: const [
                  ButtonSegment(
                    value: ReportPeriod.currentMonth,
                    label: Text('This Month'),
                  ),
                  ButtonSegment(
                    value: ReportPeriod.lastMonth,
                    label: Text('Last Month'),
                  ),
                  ButtonSegment(
                    value: ReportPeriod.customRange,
                    label: Text('Custom'),
                  ),
                ],
                selected: {_selectedPeriod},
                onSelectionChanged: (set) async {
                  final val = set.first;
                  if (val == ReportPeriod.customRange && _customRange == null) {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      initialDateRange: DateTimeRange(
                        start: now.subtract(const Duration(days: 30)),
                        end: now,
                      ),
                    );
                    if (picked != null) {
                      setState(() {
                        _customRange = picked;
                        _selectedPeriod = val;
                      });
                      return;
                    }
                  }
                  setState(() => _selectedPeriod = val);
                },
              ),
            ),

            if (_selectedPeriod == ReportPeriod.customRange && _customRange != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${DateFormat('MMM d, y').format(_customRange!.start)} – ${DateFormat('MMM d, y').format(_customRange!.end)}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.edit_calendar_rounded, size: 16),
                      label: const Text('Change Date'),
                      onPressed: () async {
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                          initialDateRange: _customRange,
                        );
                        if (picked != null) {
                          setState(() => _customRange = picked);
                        }
                      },
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 8),

            // Live Report Preview Card
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceSecondary : AppColors.lightSurfaceSecondary,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    reportText,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12.5,
                      height: 1.45,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Action Buttons: Copy & Share
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      label: const Text(
                        'Copy Text',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      onPressed: () async {
                        await DataExportService.copyToClipboard(reportText);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Financial report copied to clipboard!'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          Navigator.pop(context);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: _isSharing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.share_rounded, size: 18),
                      label: const Text(
                        'Share Report',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      onPressed: _isSharing
                          ? null
                          : () async {
                              setState(() => _isSharing = true);
                              try {
                                await SharePlus.instance.share(
                                  ShareParams(
                                    text: reportText,
                                    subject: 'Financial Summary - $periodTitle',
                                  ),
                                );
                                if (context.mounted) Navigator.pop(context);
                              } catch (_) {
                                await Clipboard.setData(ClipboardData(text: reportText));
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Report copied to clipboard!'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                  Navigator.pop(context);
                                }
                              } finally {
                                if (mounted) setState(() => _isSharing = false);
                              }
                            },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

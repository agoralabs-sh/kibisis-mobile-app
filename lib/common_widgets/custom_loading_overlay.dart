import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kibisis/constants/constants.dart';
import 'package:kibisis/features/settings/appearance/providers/dark_mode_provider.dart';
import 'package:kibisis/utils/theme_extensions.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

class CustomLoadingOverlay extends ConsumerWidget {
  final String text;
  final double? percent;
  final bool isVisible;

  const CustomLoadingOverlay({
    super.key,
    required this.text,
    this.percent,
    this.isVisible = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(isDarkModeProvider);
    double width = MediaQuery.of(context).size.width / 2;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        width: width,
        padding: const EdgeInsets.all(kScreenPadding),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(kWidgetRadius),
            color: context.colorScheme.surface),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: kScreenPadding),
            Text(
              text,
              style: context.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            if (percent != null) ...[
              const SizedBox(height: kScreenPadding),
              SizedBox(
                width: width,
                child: LinearPercentIndicator(
                    lineHeight: kScreenPadding,
                    percent: percent!.clamp(0.0, 1.0),
                    backgroundColor: context.colorScheme.surface,
                    progressColor: percent!.clamp(0.0, 1.0) >= 1
                        ? context.colorScheme.secondary
                        : context.colorScheme.primary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

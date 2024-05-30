import 'package:flutter/material.dart';
import 'package:kibisis/constants/constants.dart';
import 'package:kibisis/utils/theme_extensions.dart';

class CustomTab extends StatelessWidget {
  const CustomTab({
    super.key,
    required this.text,
  });

  final String text;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: kScreenPadding / 2),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius:
            BorderRadius.circular(kScreenPadding / 2), // Set rounded corners
      ),
      child: Tab(text: text),
    );
  }
}

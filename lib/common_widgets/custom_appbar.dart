// custom_app_bar.dart
import 'package:flutter/material.dart';
import 'package:kibisis/constants/constants.dart';

class SplitAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget leadingWidget;
  final Widget actionWidget;
  @override
  final Size preferredSize;

  const SplitAppBar({
    super.key,
    required this.leadingWidget,
    required this.actionWidget,
  }) : preferredSize = const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      flexibleSpace: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: kScreenPadding),
        child: Row(
          children: <Widget>[
            Expanded(
              child: leadingWidget,
            ),
            const SizedBox(
                width: kScreenPadding), // Spacer between the two sections
            actionWidget,
          ],
        ),
      ),
    );
  }
}

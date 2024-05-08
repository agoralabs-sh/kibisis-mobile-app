import 'package:flutter/material.dart' hide Orientation;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:kibisis/common_widgets/custom_button.dart';
import 'package:kibisis/constants/constants.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  static String title = "Login";
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _CreatePinScreenState();
}

class _CreatePinScreenState extends ConsumerState<WelcomeScreen> {
  @override
  Widget build(BuildContext context) {
    String kibisisLogo = Theme.of(context).brightness == Brightness.dark
        ? 'assets/images/kibisis-logo-dark.svg'
        : 'assets/images/kibisis-logo-light.svg';
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(kScreenPadding * 2),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(kibisisLogo,
                    semanticsLabel: 'Kibisis Logo',
                    height: MediaQuery.of(context).size.height / 5),
                const SizedBox(height: kSizedBoxSpacing),
                Text(
                  'Kibisis',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                Text(
                  'v0.0.1',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Column(
                  children: [
                    const SizedBox(
                      height: kSizedBoxSpacing,
                    ),
                    Text(
                      'Welcome. First, let’s create a new pincode to secure this device.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(
                      height: kSizedBoxSpacing,
                    ),
                    CustomButton(
                      text: 'Create Pin',
                      isFullWidth: true,
                      onPressed: () {
                        final currentPath = GoRouter.of(context)
                            .routeInformationProvider
                            .value
                            .uri
                            .path;
                        debugPrint(currentPath);
                        GoRouter.of(context).go('/setup/setupPinPad');
                      },
                    )
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

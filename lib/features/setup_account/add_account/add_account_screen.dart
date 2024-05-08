import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kibisis/common_widgets/custom_list_tile.dart';
import 'package:kibisis/constants/constants.dart';

class AddAccountScreen extends StatelessWidget {
  const AddAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Account"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(kScreenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You can either create a new account or import an existing account via seed.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(
              height: kScreenPadding,
            ),
            CustomListTile(
              title: "Create New Account",
              subtitle: 'You will be prompted to save a seed.',
              leadingIcon: Icons.person_add,
              trailingIcon: Icons.arrow_forward_ios_rounded,
              onTap: () {
                GoRouter.of(context).go('/setup/createAccount');
              },
            ),
            const SizedBox(
              height: kScreenPadding,
            ),
            CustomListTile(
              title: "Import Via Seed",
              subtitle: 'Import an existing account via seed phrase.',
              leadingIcon: Icons.import_export,
              trailingIcon: Icons.arrow_forward_ios_rounded,
              onTap: () {
                debugPrint('Import Via Seed.');
                GoRouter.of(context).go('/setup/importViaSeed');
              },
            ),
          ],
        ),
      ),
    );
  }
}

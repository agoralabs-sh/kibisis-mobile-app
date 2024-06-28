import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kibisis/common_widgets/confirmation_dialog.dart';
import 'package:kibisis/common_widgets/custom_button.dart';
import 'package:kibisis/common_widgets/custom_text_field.dart';
import 'package:kibisis/common_widgets/top_snack_bar.dart';
import 'package:kibisis/constants/constants.dart';
import 'package:kibisis/providers/account_provider.dart';
import 'package:kibisis/providers/accounts_list_provider.dart';
import 'package:kibisis/providers/active_account_provider.dart';
import 'package:kibisis/providers/authentication_provider.dart';
import 'package:kibisis/providers/loading_provider.dart';
import 'package:kibisis/providers/setup_complete_provider.dart';
import 'package:kibisis/providers/storage_provider.dart';
import 'package:kibisis/providers/temporary_account_provider.dart';
import 'package:kibisis/utils/account_selection.dart';
import 'package:kibisis/utils/app_icons.dart';
import 'package:kibisis/utils/refresh_account_data.dart';
import 'package:kibisis/utils/theme_extensions.dart';

class NameAccountScreen extends ConsumerStatefulWidget {
  final AccountFlow accountFlow;
  final String? initialAccountName;
  final String? accountId;

  const NameAccountScreen({
    super.key,
    required this.accountFlow,
    this.initialAccountName,
    this.accountId,
  });

  @override
  NameAccountScreenState createState() => NameAccountScreenState();
}

class NameAccountScreenState extends ConsumerState<NameAccountScreen> {
  final formKey = GlobalKey<FormState>();
  late TextEditingController accountNameController;

  @override
  void initState() {
    super.initState();
    accountNameController = TextEditingController(
      text: widget.initialAccountName ?? '',
    );
  }

  @override
  void dispose() {
    accountNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.accountFlow == AccountFlow.edit
            ? 'Edit Account'
            : 'Name Account'),
        actions: [
          if (widget.accountFlow == AccountFlow.edit)
            Consumer(
              builder: (context, ref, child) {
                final accountsList = ref.watch(accountsListProvider);
                if (accountsList.accounts.length > 1) {
                  return IconButton(
                    icon: AppIcons.icon(icon: AppIcons.delete),
                    onPressed: () async {
                      bool confirm = await showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return const ConfirmationDialog(
                                yesText: 'Delete',
                                noText: 'Cancel',
                                content:
                                    'Are you sure you want to delete this account?',
                              );
                            },
                          ) ??
                          false;

                      if (confirm) {
                        await _deleteAccount(widget.accountId!);
                      }
                    },
                  );
                }
                return Container();
              },
            ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.all(kScreenPadding),
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: kScreenPadding),
                        Text(
                          widget.accountFlow == AccountFlow.edit
                              ? 'Edit your account name'
                              : 'Name your account',
                          style: context.textTheme.bodyMedium?.copyWith(
                            color: context.colorScheme.onSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: kScreenPadding),
                        Text(
                          widget.accountFlow == AccountFlow.edit
                              ? 'You can change your account name below.'
                              : 'Give your account a nickname. Don’t worry, you can change this later.',
                          style: context.textTheme.bodySmall,
                        ),
                        const SizedBox(height: kScreenPadding),
                        CustomTextField(
                          controller: accountNameController,
                          labelText: 'Account Name',
                          onChanged: (value) {},
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter some text';
                            }
                            return null;
                          },
                        ),
                        const Spacer(),
                        CustomButton(
                          text: widget.accountFlow == AccountFlow.edit
                              ? 'Save'
                              : 'Create',
                          isFullWidth: true,
                          onPressed: ref.watch(loadingProvider)
                              ? null
                              : () async {
                                  // Disable button when loading
                                  if (formKey.currentState!.validate()) {
                                    ref
                                        .read(loadingProvider.notifier)
                                        .startLoading(); // Start loading
                                    try {
                                      if (widget.accountFlow ==
                                          AccountFlow.edit) {
                                        await _updateAccountName();
                                      } else {
                                        await completeAccountSetup(
                                            ref,
                                            accountNameController.text,
                                            widget.accountFlow);
                                      }
                                      // Optionally navigate or show a success message here
                                    } catch (e) {
                                      if (!context.mounted) return;
                                      showCustomSnackBar(
                                        context: context,
                                        snackType: SnackType.error,
                                        message:
                                            'Failed to process your request: $e',
                                      );
                                    }
                                    ref
                                        .read(loadingProvider.notifier)
                                        .stopLoading();
                                  }
                                },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _updateAccountName() async {
    final accountName = accountNameController.text;
    await ref.read(accountProvider.notifier).setAccountName(accountName);

    // Get the active account ID
    final accountId = ref.read(activeAccountProvider);
    if (accountId == null) {
      throw Exception('No active account ID found');
    }

    // Update the account name using the accounts list provider
    await ref
        .read(accountsListProvider.notifier)
        .updateAccountName(accountId, accountName);

    // Complete the account setup
    await completeAccountSetup(ref, accountName, widget.accountFlow);
    ref.read(accountsListProvider.notifier).loadAccounts();
  }

  Future<void> _deleteAccount(String accountId) async {
    try {
      await ref.read(accountProvider.notifier).deleteAccount(accountId);
      if (!mounted) return;
      _navigateToWallets();
    } catch (e) {
      if (!mounted) return;
      showCustomSnackBar(
        context: context,
        snackType: SnackType.error,
        message: 'Failed to delete account: $e',
      );
    }
  }

  void _navigateToWallets() {
    if (!mounted) return;
    GoRouter.of(context).go('/wallets');
  }

  Future<void> completeAccountSetup(
    WidgetRef ref,
    String accountName,
    AccountFlow accountFlow,
  ) async {
    try {
      invalidateProviders(ref);
      //update the account provider with the new data collected in the tempaccountprovider
      await ref
          .read(accountProvider.notifier)
          .finalizeAccountCreation(accountName);

      // Set the newly created account as the active account
      final newAccountId =
          await ref.read(accountProvider.notifier).getAccountId() ?? '';

      // await ref
      //     .read(activeAccountProvider.notifier)
      //     .setActiveAccount(newAccountId);

      await ref.read(accountsListProvider.notifier).loadAccounts();

      if (accountFlow == AccountFlow.setup) {
        ref.read(isAuthenticatedProvider.notifier).state = true;
        await ref.read(setupCompleteProvider.notifier).setSetupComplete(true);
      }
      ref.read(temporaryAccountProvider.notifier).clear();

      await ref.refresh(storageProvider).accountExists();

      if (mounted) {
        final accountHandler = AccountHandler(context, ref);
        accountHandler.handleAccountSelection(newAccountId);
      }
    } catch (e) {
      debugPrint('Failed to complete account setup: $e');
    }
  }
}

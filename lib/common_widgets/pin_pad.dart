import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kibisis/common_widgets/confirmation_dialog.dart';
import 'package:kibisis/common_widgets/top_snack_bar.dart';
import 'package:kibisis/constants/constants.dart';
import 'package:kibisis/features/pin_pad/providers/pin_title_provider.dart';
import 'package:kibisis/providers/authentication_provider.dart';
import 'package:kibisis/providers/loading_provider.dart';
import 'package:kibisis/providers/pin_entry_provider.dart';
import 'package:kibisis/providers/pin_provider.dart';
import 'package:kibisis/routing/named_routes.dart';
import 'package:kibisis/utils/app_icons.dart';
import 'package:kibisis/utils/app_reset_util.dart';
import 'package:kibisis/utils/theme_extensions.dart';

class PinPad extends ConsumerStatefulWidget {
  final int pinLength;
  final PinPadMode mode;
  final VoidCallback? onPinVerified;

  const PinPad({
    super.key,
    this.pinLength = 6,
    required this.mode,
    this.onPinVerified,
  });

  @override
  PinPadState createState() => PinPadState();
}

class PinPadState extends ConsumerState<PinPad> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(pinEntryStateNotifierProvider.notifier).clearPin();
    });
  }

  bool isConfirmingPin = false;

  @override
  Widget build(BuildContext context) {
    final pinEntryProvider = ref.watch(pinEntryStateNotifierProvider);
    final pinState = ref.watch(pinEntryStateNotifierProvider);

    bool isPinComplete = ref.watch(isPinCompleteProvider);

    return KeyboardListener(
      focusNode: FocusNode(),
      autofocus: true,
      onKeyEvent: _handleKeyPress,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: kScreenPadding),
          Padding(
            padding: const EdgeInsets.all(kScreenPadding),
            child: Visibility(
              maintainSize: true,
              maintainAnimation: true,
              maintainState: true,
              visible: pinState.error.isNotEmpty,
              child: Text(
                pinState.error,
                style: TextStyle(color: context.colorScheme.error),
              ),
            ),
          ),
          const SizedBox(height: kScreenPadding),
          FittedBox(
            fit: BoxFit.fitWidth,
            child: Padding(
              padding: const EdgeInsets.all(kScreenPadding),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.pinLength, (index) {
                  return Padding(
                    padding: const EdgeInsets.all(kScreenPadding / 2),
                    child: CircleAvatar(
                      radius: 10,
                      backgroundColor: index < pinEntryProvider.pin.length
                          ? context.colorScheme.onSurfaceVariant
                          : Colors.transparent,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: context.colorScheme.onSurfaceVariant,
                              width: 2),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: kScreenPadding * 4),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  double width = constraints.maxWidth;
                  double height = width * 4 / 3;

                  if (height > constraints.maxHeight) {
                    height = constraints.maxHeight;
                    width = height * 3 / 4;
                  }

                  return Center(
                    child: SizedBox(
                      width: width,
                      height: height,
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: 12,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                        ),
                        itemBuilder: (context, index) {
                          if (index == 9) {
                            if (kDebugMode) {
                              return IconButton(
                                style: IconButton.styleFrom(
                                  backgroundColor: context.colorScheme.error,
                                ),
                                icon: AppIcons.icon(
                                    icon: AppIcons.refresh,
                                    size: AppIcons.large,
                                    color: context.colorScheme.onError),
                                onPressed: isPinComplete
                                    ? null
                                    : () async {
                                        bool confirm = await showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return const ConfirmationDialog(
                                                  yesText: 'Reset',
                                                  noText: 'Cancel',
                                                  content:
                                                      'Are you sure you want to reset this device? This will remove all accounts, settings, and security information.',
                                                );
                                              },
                                            ) ??
                                            false;
                                        if (confirm) {
                                          _handleResetApp();
                                        }
                                      },
                                color: context.colorScheme.onSurface,
                                iconSize: kScreenPadding * 2,
                              );
                            } else {
                              return const SizedBox.shrink();
                            }
                          }
                          if (index == 11) {
                            return IconButton(
                              icon: AppIcons.icon(
                                  icon: AppIcons.backspace,
                                  size: AppIcons.large),
                              onPressed: isPinComplete
                                  ? null
                                  : () {
                                      ref
                                          .read(pinEntryStateNotifierProvider
                                              .notifier)
                                          .removeLastKey();
                                    },
                              color: context.colorScheme.onSurface,
                              iconSize: kScreenPadding * 2,
                            );
                          }
                          String key =
                              index == 10 ? '0' : (index + 1).toString();
                          return Padding(
                            padding: const EdgeInsets.all(kScreenPadding / 2),
                            child: ElevatedButton(
                              style: ButtonStyle(
                                shape: MaterialStateProperty.all(
                                    const CircleBorder()),
                                backgroundColor:
                                    MaterialStateProperty.resolveWith<Color>(
                                  (Set<MaterialState> states) {
                                    if (states
                                        .contains(MaterialState.disabled)) {
                                      return context.colorScheme.surface
                                          .withOpacity(0.12);
                                    }
                                    return context.colorScheme.surface;
                                  },
                                ),
                                foregroundColor:
                                    MaterialStateProperty.resolveWith<Color>(
                                  (Set<MaterialState> states) {
                                    if (states
                                        .contains(MaterialState.disabled)) {
                                      return context.colorScheme.onSurface
                                          .withOpacity(0.38);
                                    }
                                    return context.colorScheme.onSurface;
                                  },
                                ),
                                shadowColor:
                                    MaterialStateProperty.resolveWith<Color>(
                                  (Set<MaterialState> states) {
                                    if (states
                                        .contains(MaterialState.disabled)) {
                                      return Colors.transparent;
                                    }
                                    return context.colorScheme.shadow;
                                  },
                                ),
                              ),
                              onPressed: isPinComplete
                                  ? null
                                  : () {
                                      _handlePinKeyPressed(key);
                                    },
                              child: Text(
                                key,
                                style: context.textTheme.titleMedium,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleKeyPress(KeyEvent event) {
    if (event is KeyDownEvent) {
      String? keyLabel;

      if (event.logicalKey == LogicalKeyboardKey.backspace) {
        ref.read(pinEntryStateNotifierProvider.notifier).removeLastKey();
      } else {
        keyLabel = event.logicalKey.keyLabel;
      }

      if (keyLabel != null && RegExp(r'^[0-9]$').hasMatch(keyLabel)) {
        _handlePinKeyPressed(keyLabel);
      }
    }
  }

  void _handlePinKeyPressed(String key) {
    final pinPadProvider = ref.read(pinEntryStateNotifierProvider.notifier);
    final pinTitleNotifier = ref.read(pinTitleProvider.notifier);

    pinPadProvider.addKey(key);

    if (pinPadProvider.isPinComplete()) {
      if ((widget.mode == PinPadMode.setup ||
              widget.mode == PinPadMode.changePin) &&
          !isConfirmingPin) {
        isConfirmingPin = true;
        pinTitleNotifier.setConfirmPinTitle();
        pinPadProvider.setFirstPin(pinPadProvider.getPin());
        pinPadProvider.clearPin();
        pinPadProvider.clearError();
      } else {
        _processCompletePin();
      }
    }
  }

  void _handleResetApp() {
    try {
      ref
          .read(loadingProvider.notifier)
          .startLoading(message: 'Resetting App', fullScreen: true);
      AppResetUtil.resetApp(ref);
      GoRouter.of(context).go('/setup');
    } catch (e) {
      showCustomSnackBar(
        context: context,
        snackType: SnackType.error,
        message: e.toString(),
      );
    } finally {
      ref.read(loadingProvider.notifier).stopLoading();
    }
  }

  String _getOverlayText() {
    switch (widget.mode) {
      case PinPadMode.setup:
        return isConfirmingPin ? 'Confirming PIN' : 'Setting Up';
      case PinPadMode.unlock:
        return 'Authenticating';
      case PinPadMode.verifyTransaction:
        return 'Verifying';
      case PinPadMode.changePin:
        return isConfirmingPin ? 'Confirming New PIN' : 'Setting New PIN';
      default:
        return '';
    }
  }

  Future<void> _processCompletePin() async {
    ref.read(loadingProvider.notifier).startLoading(message: _getOverlayText());
    try {
      await _handlePinComplete();
      if (mounted) {
        _cleanupAfterPin();
      }
    } catch (e) {
      debugPrint('Error during PIN completion: $e');
    } finally {
      if (mounted) {
        ref.read(loadingProvider.notifier).stopLoading();
      }
    }
  }

  Future<void> _handlePinComplete() async {
    final pinNotifier = ref.read(pinEntryStateNotifierProvider.notifier);
    final pinTitleNotifier = ref.read(pinTitleProvider.notifier);
    final pin = pinNotifier.getPin();

    switch (widget.mode) {
      case PinPadMode.setup:
        if (isConfirmingPin) {
          if (pinNotifier.getFirstPin() == pin) {
            await pinNotifier.pinComplete(widget.mode);
            if (mounted) {
              ref.read(isAuthenticatedProvider.notifier).state = true;
              isConfirmingPin = false;
              pinTitleNotifier.setCreatePinTitle();
              _navigateToNextScreen();
            }
          } else {
            if (mounted) {
              pinNotifier.setError('PINs do not match. Please try again.');
              pinNotifier.clearPin();
              pinNotifier.setFirstPin('');
              isConfirmingPin = false;
              pinTitleNotifier.setCreatePinTitle();
            }
          }
        }
        break;
      case PinPadMode.unlock:
        await _handleUnlockMode(pinNotifier);
        break;
      case PinPadMode.verifyTransaction:
        await _handleVerifyTransactionMode(pinNotifier, pin);
        break;
      case PinPadMode.changePin:
        if (isConfirmingPin) {
          if (pinNotifier.getFirstPin() == pin) {
            await ref.read(pinProvider.notifier).setPin(pin);
            if (mounted) {
              Navigator.of(context).pop();
              showCustomSnackBar(
                context: context,
                snackType: SnackType.success,
                message: "PIN successfully changed",
              );
              isConfirmingPin = false;
              pinTitleNotifier.setCreatePinTitle();
            }
          } else {
            pinNotifier.setError('PINs do not match. Please try again.');
            pinNotifier.clearPin();
            pinNotifier.setFirstPin('');
            isConfirmingPin = false;
            pinTitleNotifier.setCreatePinTitle();
          }
        } else {
          isConfirmingPin = true;
          pinTitleNotifier.setConfirmPinTitle();
          pinNotifier.setFirstPin(pin);
          pinNotifier.clearPin();
        }
        break;
      default:
        debugPrint('Unhandled mode in _handlePinComplete');
        break;
    }
  }

  void _navigateToNextScreen() {
    GoRouter.of(context).go('/$welcomeRouteName/$setupAddAccountRouteName');
  }

  Future<void> _handleUnlockMode(PinEntryStateNotifier pinNotifier) async {
    try {
      await pinNotifier.pinComplete(PinPadMode.unlock);
      if (mounted) {
        bool isAuthenticated = ref.read(isAuthenticatedProvider);
        debugPrint('User is authenticated: $isAuthenticated');
        if (isAuthenticated) {
          _navigateToDashboard();
        }
      }
    } catch (e) {
      debugPrint('Error during unlocking mode: $e');
    }
  }

  Future<void> _handleVerifyTransactionMode(
      PinEntryStateNotifier pinNotifier, String pin) async {
    try {
      bool isPinValid = await ref.read(pinProvider.notifier).verifyPin(pin);
      if (mounted) {
        debugPrint('PIN is valid: $isPinValid');
        if (isPinValid) {
          pinNotifier.clearError();
          widget.onPinVerified?.call();
        } else {
          pinNotifier.setError('Incorrect PIN. Try again.');
        }
      }
    } catch (e) {
      debugPrint('Error during PIN verification: $e');
    }
  }

  void _cleanupAfterPin() {
    final pinPadProvider = ref.read(pinEntryStateNotifierProvider.notifier);
    pinPadProvider.clearPin();
    ref.read(isPinCompleteProvider.notifier).state = false;
  }

  void _navigateToDashboard() {
    GoRouter.of(context).go('/');
  }
}

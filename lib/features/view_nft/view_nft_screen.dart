import 'package:ellipsized_text/ellipsized_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:card_swiper/card_swiper.dart';
import 'package:kibisis/constants/constants.dart';
import 'package:kibisis/features/view_nft/providers/show_nft_info_provider.dart';
import 'package:kibisis/providers/nft_provider.dart';
import 'package:kibisis/utils/theme_extensions.dart';
import 'dart:ui';

final currentIndexProvider = StateProvider<int>((ref) {
  return 0;
});

class ViewNftScreen extends ConsumerStatefulWidget {
  final int initialIndex;

  const ViewNftScreen({super.key, required this.initialIndex});

  @override
  ConsumerState<ViewNftScreen> createState() => _ViewNftScreenState();
}

class _ViewNftScreenState extends ConsumerState<ViewNftScreen> {
  late int _swiperIndex;

  @override
  void initState() {
    super.initState();
    _swiperIndex = widget.initialIndex;

    // Set the initial index for the provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(currentIndexProvider.notifier).state = widget.initialIndex;
      debugPrint("Initial Index set to: ${widget.initialIndex}");
    });
  }

  @override
  Widget build(BuildContext context) {
    final nftState = ref.watch(nftNotifierProvider);
    final nfts = nftState.nfts;
    final currentIndex = ref.watch(currentIndexProvider);
    final showNftInfo = ref.watch(showNftInfoProvider);

    if (nfts.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('NFT Viewer')),
        body: const Center(child: Text('No NFTs found')),
      );
    }

    debugPrint("Building with Current Index: $currentIndex");

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('NFT Viewer'),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              switchInCurve: Curves.easeInOut,
              child: Stack(
                fit: StackFit.expand,
                key: ValueKey(currentIndex),
                children: [
                  ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Image.asset(
                      nfts[currentIndex].imageUrl,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.5),
                          Colors.black.withOpacity(0.8),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: Swiper(
              index: _swiperIndex,
              onIndexChanged: (index) {
                if (_swiperIndex != index) {
                  setState(() {
                    _swiperIndex = index;
                  });
                  ref.read(currentIndexProvider.notifier).state = index;
                }
              },
              itemBuilder: (BuildContext context, int index) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(kWidgetRadius),
                  child: GestureDetector(
                    onTap: () =>
                        ref.read(showNftInfoProvider.notifier).toggle(),
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width -
                          (kScreenPadding * 2),
                      height: MediaQuery.of(context).size.width -
                          (kScreenPadding * 2),
                      child: Stack(
                        fit: StackFit.expand,
                        alignment: Alignment.center,
                        children: [
                          Image.asset(
                            nfts[index].imageUrl,
                            fit: BoxFit.fill,
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            top: MediaQuery.of(context).size.width / 2,
                            child: AnimatedOpacity(
                              opacity: showNftInfo ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 300),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [
                                      Colors.black.withOpacity(1.0),
                                      Colors.transparent
                                    ],
                                  ),
                                ),
                                padding: const EdgeInsets.all(kScreenPadding),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    EllipsizedText(
                                      nfts[index].name,
                                      style: context.textTheme.displayLarge
                                          ?.copyWith(
                                              fontWeight: FontWeight.bold),
                                    ),
                                    EllipsizedText(nfts[index].owner,
                                        style: context.textTheme.displayMedium),
                                    EllipsizedText(nfts[index].description,
                                        style: context.textTheme.displaySmall),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
              itemCount: nfts.length,
              loop: true,
              itemWidth:
                  MediaQuery.of(context).size.width - (kScreenPadding * 2),
              itemHeight:
                  MediaQuery.of(context).size.width - (kScreenPadding * 2),
              layout: SwiperLayout.STACK,
              scrollDirection: Axis.horizontal,
            ),
          ),
        ],
      ),
    );
  }
}

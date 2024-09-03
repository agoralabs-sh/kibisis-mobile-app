import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kibisis/models/combined_asset.dart';
import 'package:kibisis/providers/algorand_provider.dart';
import 'package:kibisis/utils/arc200_service.dart';
import 'package:kibisis/utils/conver_to_combined_asset.dart';

final searchProvider = StateNotifierProvider.autoDispose<SearchNotifier,
    AsyncValue<List<CombinedAsset>>>((ref) {
  return SearchNotifier(ref);
});

class SearchNotifier extends StateNotifier<AsyncValue<List<CombinedAsset>>> {
  SearchNotifier(this.ref) : super(const AsyncValue.data([]));
  final Ref ref;
  Timer? _debounce;
  void searchAssets(String searchQuery) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        if (searchQuery.length < 2) {
          state = const AsyncValue.data([]);
          return;
        }
        state = const AsyncValue.loading();

        List<CombinedAsset> combinedAssets = [];

        final algorandService = ref.read(algorandServiceProvider);
        final arc200Service = ref.read(arc200ServiceProvider);

        final algorandResponse = await algorandService.searchAssets(
          searchQuery,
          0,
          1e15,
          100,
        );
        final standardAssets = algorandResponse.assets
            .map(convertAssetToCombinedWithoutAmount)
            .toList();
        combinedAssets.addAll(standardAssets);

        final arc200AssetsByIdOrName = await arc200Service
            .searchArc200AssetsByContractIdOrName(searchQuery);
        combinedAssets.addAll(arc200AssetsByIdOrName);

        state = AsyncValue.data(combinedAssets);
      } on Exception catch (e) {
        debugPrint('Exception: $e');
        state = AsyncValue.error(e, StackTrace.current);
      }
    });
  }
}

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_advice_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$planAdviceHash() => r'fe35c54126bd79d6d6581781b9714e787da58a68';

/// Holds the AI recommendation. The state is an AsyncValue, so the UI gets
/// loading / error / data for free (the "isLoading" your ToDO mentioned).
///
/// Copied from [PlanAdvice].
@ProviderFor(PlanAdvice)
final planAdviceProvider =
    AutoDisposeAsyncNotifierProvider<PlanAdvice, String?>.internal(
  PlanAdvice.new,
  name: r'planAdviceProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$planAdviceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$PlanAdvice = AutoDisposeAsyncNotifier<String?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member

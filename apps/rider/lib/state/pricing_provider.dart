import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evc_core/evc_core.dart';

/// Region pricing + active ride tiers (the inputs the upfront fare estimate uses).
final pricingDataProvider =
    FutureProvider<({PricingConfig pricing, List<RideTierConfig> tiers})>(
        (ref) async {
  final pricing = await EvcPricing.fetchPricing();
  final tiers = await EvcPricing.fetchTiers();
  return (pricing: pricing, tiers: tiers);
});

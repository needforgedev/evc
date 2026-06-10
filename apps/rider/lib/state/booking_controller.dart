import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evc_core/evc_core.dart';

import '../mock/mock_data.dart';

/// Everything the rider has chosen for the ride they're about to book.
@immutable
class BookingState {
  const BookingState({
    required this.pickup,
    required this.payment,
    this.destination,
    this.tier,
    this.promoCode,
    this.promoDiscount = 0,
    this.promoLabel,
  });

  final Place pickup;
  final Place? destination;
  final RideTier? tier;
  final PaymentMethod payment;
  final String? promoCode;
  final double promoDiscount;
  final String? promoLabel;

  /// Selected tier, falling back to the cheapest so screens always have one.
  RideTier get effectiveTier => tier ?? MockData.tiers.first;

  BookingState copyWith({
    Place? pickup,
    Place? destination,
    RideTier? tier,
    PaymentMethod? payment,
    String? promoCode,
    double? promoDiscount,
    String? promoLabel,
  }) {
    return BookingState(
      pickup: pickup ?? this.pickup,
      destination: destination ?? this.destination,
      tier: tier ?? this.tier,
      payment: payment ?? this.payment,
      promoCode: promoCode ?? this.promoCode,
      promoDiscount: promoDiscount ?? this.promoDiscount,
      promoLabel: promoLabel ?? this.promoLabel,
    );
  }

  /// copyWith can't set nullable fields back to null — used to clear the promo.
  BookingState clearPromo() => BookingState(
        pickup: pickup,
        destination: destination,
        tier: tier,
        payment: payment,
      );
}

/// Holds the in-progress booking selection (pickup, destination, tier, payment).
class BookingController extends Notifier<BookingState> {
  @override
  BookingState build() => BookingState(
        pickup: MockData.currentLocation,
        payment: MockData.paymentMethods.first,
      );

  void setDestination(Place place) =>
      state = state.copyWith(destination: place, tier: MockData.tiers.first);

  void setPickup(Place place) => state = state.copyWith(pickup: place);

  // Changing tier clears any applied promo (a % discount scales with the fare).
  void setTier(RideTier tier) =>
      state = state.clearPromo().copyWith(tier: tier);

  void setPayment(PaymentMethod payment) =>
      state = state.copyWith(payment: payment);

  void setPromo(String code, double discount, String? label) => state =
      state.copyWith(promoCode: code, promoDiscount: discount, promoLabel: label);

  void clearPromo() => state = state.clearPromo();

  void reset() => state = build();
}

final bookingControllerProvider =
    NotifierProvider<BookingController, BookingState>(BookingController.new);
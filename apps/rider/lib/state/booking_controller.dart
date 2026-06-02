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
  });

  final Place pickup;
  final Place? destination;
  final RideTier? tier;
  final PaymentMethod payment;

  /// Selected tier, falling back to the cheapest so screens always have one.
  RideTier get effectiveTier => tier ?? MockData.tiers.first;

  BookingState copyWith({
    Place? pickup,
    Place? destination,
    RideTier? tier,
    PaymentMethod? payment,
  }) {
    return BookingState(
      pickup: pickup ?? this.pickup,
      destination: destination ?? this.destination,
      tier: tier ?? this.tier,
      payment: payment ?? this.payment,
    );
  }
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

  void setTier(RideTier tier) => state = state.copyWith(tier: tier);

  void setPayment(PaymentMethod payment) =>
      state = state.copyWith(payment: payment);

  void reset() => state = build();
}

final bookingControllerProvider =
    NotifierProvider<BookingController, BookingState>(BookingController.new);
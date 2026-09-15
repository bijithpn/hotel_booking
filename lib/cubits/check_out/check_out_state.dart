import 'package:equatable/equatable.dart';
import '../../models/booking.dart';
import '../../models/guest.dart';

enum PaymentOutcome { success, insufficient, noRoomsSelected }

class PaymentResult {
  final PaymentOutcome outcome;
  final double amountEntered;
  final double due;
  final List<int> roomNumbers;

  const PaymentResult({
    required this.outcome,
    required this.amountEntered,
    required this.due,
    required this.roomNumbers,
  });
}

class CheckOutState extends Equatable {
  final List<Booking> bookings;
  final List<Guest> guests;
  final Guest? selectedGuest;
  final int roomInputNumber;
  final Set<int> selectedRoomNos;
  final Map<int, List<AdditionalCharge>> roomAdditionalCharges;
  final String paymentMethod;
  final String? paymentAmountError;

  static const Map<int, double> roomRates = {101: 1200.0, 103: 1200.0};
  static const Map<int, int> roomNights = {101: 2, 103: 2};

  const CheckOutState({
    required this.bookings,
    required this.guests,
    required this.selectedGuest,
    required this.roomInputNumber,
    required this.selectedRoomNos,
    required this.roomAdditionalCharges,
    required this.paymentMethod,
    this.paymentAmountError,
  });

  factory CheckOutState.initial() {
    final guests = List<Guest>.from(Guest.mockGuests);
    return CheckOutState(
      bookings: List<Booking>.from(Booking.mockBookings),
      guests: guests,
      selectedGuest: guests.isNotEmpty ? guests.first : null,
      roomInputNumber: 101,
      selectedRoomNos: {101, 103},
      roomAdditionalCharges: {
        101: [
          AdditionalCharge(
            description: 'Mini-bar (Water x2)',
            date: DateTime(2026, 4, 3),
            amount: 100.0,
          ),
          AdditionalCharge(
            description: 'Room Service',
            date: DateTime(2026, 4, 3),
            amount: 1200.0,
          ),
          AdditionalCharge(
            description: 'Restaurant Bill (Room 101)',
            date: DateTime(2026, 4, 3),
            amount: 850.0,
          ),
        ],
        103: [
          AdditionalCharge(
            description: 'Mini-bar (Chips)',
            date: DateTime(2026, 4, 3),
            amount: 50.0,
          ),
          AdditionalCharge(
            description: 'Restaurant Bill (Room 103)',
            date: DateTime(2026, 4, 3),
            amount: 1200.0,
          ),
        ],
      },
      paymentMethod: 'Credit Card',
    );
  }

  double getRoomBaseTotal(int roomNo) {
    final nights = roomNights[roomNo] ?? 2;
    final rate = roomRates[roomNo] ?? 1200.0;
    return nights * rate;
  }

  double getRoomExtraTotal(int roomNo) {
    final charges = roomAdditionalCharges[roomNo] ?? [];
    return charges.fold(0.0, (sum, c) => sum + c.amount);
  }

  double getRoomGrandTotal(int roomNo) {
    return getRoomBaseTotal(roomNo) + getRoomExtraTotal(roomNo);
  }

  double get combinedTotal {
    double total = 0.0;
    for (final r in selectedRoomNos) {
      total += getRoomGrandTotal(r);
    }
    return total;
  }

  CheckOutState copyWith({
    List<Booking>? bookings,
    List<Guest>? guests,
    Guest? selectedGuest,
    int? roomInputNumber,
    Set<int>? selectedRoomNos,
    Map<int, List<AdditionalCharge>>? roomAdditionalCharges,
    String? paymentMethod,
    String? paymentAmountError,
    bool clearPaymentAmountError = false,
  }) {
    return CheckOutState(
      bookings: bookings ?? this.bookings,
      guests: guests ?? this.guests,
      selectedGuest: selectedGuest ?? this.selectedGuest,
      roomInputNumber: roomInputNumber ?? this.roomInputNumber,
      selectedRoomNos: selectedRoomNos ?? this.selectedRoomNos,
      roomAdditionalCharges:
          roomAdditionalCharges ?? this.roomAdditionalCharges,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentAmountError: clearPaymentAmountError
          ? null
          : (paymentAmountError ?? this.paymentAmountError),
    );
  }

  @override
  List<Object?> get props => [
    bookings,
    guests,
    selectedGuest,
    roomInputNumber,
    selectedRoomNos,
    roomAdditionalCharges,
    paymentMethod,
    paymentAmountError,
  ];
}

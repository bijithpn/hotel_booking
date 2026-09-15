import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/booking.dart';
import '../../models/guest.dart';
import '../../models/room.dart';
import 'check_out_state.dart';

export 'check_out_state.dart';

class CheckOutCubit extends Cubit<CheckOutState> {
  CheckOutCubit() : super(CheckOutState.initial());

  Guest? findGuestByName(String query) {
    final matching = state.guests.where(
      (g) => g.name.toLowerCase().contains(query.toLowerCase().trim()),
    );
    if (matching.isNotEmpty) {
      emit(state.copyWith(selectedGuest: matching.first));
      return matching.first;
    }
    return state.selectedGuest;
  }

  void selectGuest(Guest g) {
    emit(state.copyWith(selectedGuest: g));
  }

  void incrementRoomInputNumber() {
    emit(state.copyWith(roomInputNumber: state.roomInputNumber + 1));
  }

  void decrementRoomInputNumber() {
    emit(
      state.copyWith(
        roomInputNumber: state.roomInputNumber > 101
            ? state.roomInputNumber - 1
            : 101,
      ),
    );
  }

  void toggleRoomSelection(int roomNo, bool selected) {
    final updated = Set<int>.from(state.selectedRoomNos);
    if (selected) {
      updated.add(roomNo);
    } else {
      updated.remove(roomNo);
    }
    emit(state.copyWith(selectedRoomNos: updated));
  }

  void setPaymentMethod(String name) {
    emit(state.copyWith(paymentMethod: name));
  }

  void addQuickCharge(int roomNo, String desc, double amt) {
    final updated = Map<int, List<AdditionalCharge>>.from(
      state.roomAdditionalCharges,
    );
    updated.putIfAbsent(roomNo, () => []);
    updated[roomNo] = [
      ...updated[roomNo]!,
      AdditionalCharge(
        description: desc,
        date: DateTime(2026, 4, 3),
        amount: amt,
      ),
    ];
    emit(state.copyWith(roomAdditionalCharges: updated));
  }

  void validatePaymentAmount(String value, double totalDue) {
    final entered = double.tryParse(value.trim());
    if (value.trim().isEmpty || entered == null || entered <= 0) {
      emit(state.copyWith(paymentAmountError: 'Enter a valid payment amount'));
    } else if (entered < totalDue) {
      emit(
        state.copyWith(
          paymentAmountError:
              'Must be at least ₹${totalDue.toStringAsFixed(2)}',
        ),
      );
    } else {
      emit(state.copyWith(clearPaymentAmountError: true));
    }
  }

  PaymentResult processPaymentSingle(int roomNo, String amountText) {
    final amountEntered = double.tryParse(amountText) ?? 0.0;
    final due = state.getRoomGrandTotal(roomNo);

    if (amountEntered < due) {
      return PaymentResult(
        outcome: PaymentOutcome.insufficient,
        amountEntered: amountEntered,
        due: due,
        roomNumbers: [roomNo],
      );
    }

    final room = Room.allRooms.where((r) => r.number == roomNo);
    if (room.isNotEmpty) {
      room.first.status = RoomStatus.dirty;
    }
    final updatedSelected = Set<int>.from(state.selectedRoomNos)
      ..remove(roomNo);
    final updatedBookings = state.bookings
        .where((b) => b.roomNumber != roomNo)
        .toList();
    emit(
      state.copyWith(
        selectedRoomNos: updatedSelected,
        bookings: updatedBookings,
      ),
    );

    return PaymentResult(
      outcome: PaymentOutcome.success,
      amountEntered: amountEntered,
      due: due,
      roomNumbers: [roomNo],
    );
  }

  PaymentResult processPaymentCombined(String amountText) {
    if (state.selectedRoomNos.isEmpty) {
      return const PaymentResult(
        outcome: PaymentOutcome.noRoomsSelected,
        amountEntered: 0,
        due: 0,
        roomNumbers: [],
      );
    }

    final amountEntered = double.tryParse(amountText) ?? 0.0;
    final due = state.combinedTotal;

    if (amountEntered < due) {
      return PaymentResult(
        outcome: PaymentOutcome.insufficient,
        amountEntered: amountEntered,
        due: due,
        roomNumbers: state.selectedRoomNos.toList(),
      );
    }

    final checkedOutList = List<int>.from(state.selectedRoomNos);
    for (final rNo in checkedOutList) {
      final room = Room.allRooms.where((r) => r.number == rNo);
      if (room.isNotEmpty) {
        room.first.status = RoomStatus.dirty;
      }
    }
    final updatedBookings = state.bookings
        .where((b) => !checkedOutList.contains(b.roomNumber))
        .toList();
    emit(state.copyWith(selectedRoomNos: <int>{}, bookings: updatedBookings));

    return PaymentResult(
      outcome: PaymentOutcome.success,
      amountEntered: amountEntered,
      due: due,
      roomNumbers: checkedOutList,
    );
  }
}

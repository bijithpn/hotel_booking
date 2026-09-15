import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/booking.dart';
import '../../models/guest.dart';
import '../../models/room.dart';
import 'check_in_state.dart';

export 'check_in_state.dart';

class CheckInCubit extends Cubit<CheckInState> {
  CheckInCubit() : super(CheckInState.initial()) {
    if (state.bookings.isNotEmpty) {
      selectBooking(state.bookings.first);
    }
  }

  void clearErrors() {
    emit(
      state.copyWith(
        clearRentError: true,
        clearGstError: true,
        clearTendantError: true,
        clearGuestNameError: true,
        clearDateError: true,
        clearValidationSummary: true,
      ),
    );
  }

  void validateFieldRealtime({
    required String guestName,
    required String rentText,
    required String gstText,
    required String tendantName,
  }) {
    String? rentError = state.rentError;
    String? gstError = state.gstError;
    String? tendantError = state.tendantError;
    String? guestNameError = state.guestNameError;

    if (guestName.trim().isNotEmpty) guestNameError = null;
    final rent = double.tryParse(rentText.trim());
    if (rent != null && rent > 0) rentError = null;
    final gst = double.tryParse(gstText.trim());
    if (gst != null && gst >= 0) gstError = null;
    if (tendantName.trim().isNotEmpty) tendantError = null;

    String? validationSummary = state.validationSummary;
    if (guestNameError == null &&
        rentError == null &&
        gstError == null &&
        tendantError == null &&
        state.dateError == null) {
      validationSummary = null;
    }

    emit(
      state.copyWith(
        rentError: rentError,
        clearRentError: rentError == null,
        gstError: gstError,
        clearGstError: gstError == null,
        tendantError: tendantError,
        clearTendantError: tendantError == null,
        guestNameError: guestNameError,
        clearGuestNameError: guestNameError == null,
        validationSummary: validationSummary,
        clearValidationSummary: validationSummary == null,
      ),
    );
  }

  bool validateFields({
    required String guestName,
    required String rentText,
    required String gstText,
    required String tendantName,
  }) {
    clearErrors();
    final List<String> errors = [];

    String? guestNameError;
    if (guestName.trim().isEmpty) {
      guestNameError = 'Guest name is required';
      errors.add('Guest name is required');
    }

    String? rentError;
    final rent = double.tryParse(rentText.trim());
    if (rent == null || rent <= 0) {
      rentError = 'Enter valid rent (> 0)';
      errors.add('Valid rent amount is required');
    }

    String? gstError;
    final gst = double.tryParse(gstText.trim());
    if (gst == null || gst < 0) {
      gstError = 'Enter valid GST (>= 0)';
      errors.add('Valid GST percentage is required');
    }

    String? tendantError;
    if (tendantName.trim().isEmpty) {
      tendantError = 'Tendant name is required';
      errors.add('Tendant name is required');
    }

    String? dateError;
    if (state.checkoutDate == null) {
      dateError = 'Select checkout date';
      errors.add('Checkout date must be selected');
    } else if (state.selectedBooking != null &&
        !isCheckoutAfterCheckin(
          state.selectedBooking!.checkIn,
          state.checkoutDate!,
        )) {
      dateError = 'Checkout must be after check-in';
      errors.add('Checkout date must be after check-in date');
    }

    if (errors.isNotEmpty) {
      emit(
        state.copyWith(
          guestNameError: guestNameError,
          clearGuestNameError: guestNameError == null,
          rentError: rentError,
          clearRentError: rentError == null,
          gstError: gstError,
          clearGstError: gstError == null,
          tendantError: tendantError,
          clearTendantError: tendantError == null,
          dateError: dateError,
          clearDateError: dateError == null,
          validationSummary: errors.first,
        ),
      );
      return false;
    }

    emit(state.copyWith(clearValidationSummary: true));
    return true;
  }

  void selectBooking(Booking b) {
    final matching = state.guests.where(
      (g) => g.name.toLowerCase() == b.guestName.toLowerCase(),
    );
    final selectedGuest = matching.isNotEmpty
        ? matching.first
        : (state.guests.isNotEmpty ? state.guests.first : null);

    emit(
      state.copyWith(
        selectedBooking: b,
        adults: b.adults,
        kids: b.kids,
        checkoutDate: b.checkOut,
        idProofName:
            b.idProofName ??
            '${b.guestName.toLowerCase().replaceAll(' ', '')}.pdf',
        isFileUploaded: true,
        isConfirmed: false,
        isEditMode: false,
        selectedGuest: selectedGuest,
        clearRentError: true,
        clearGstError: true,
        clearTendantError: true,
        clearGuestNameError: true,
        clearDateError: true,
        clearValidationSummary: true,
      ),
    );
  }

  void setAdults(int val) {
    emit(state.copyWith(adults: val));
  }

  void setKids(int val) {
    emit(state.copyWith(kids: val));
  }

  void setCheckoutDate(DateTime date) {
    emit(state.copyWith(checkoutDate: date, clearDateError: true));
  }

  void setEditMode(bool value) {
    emit(state.copyWith(isEditMode: value));
  }

  void setConfirmed(bool value) {
    emit(state.copyWith(isConfirmed: value));
  }

  /// Selects [g] as the active guest. If a booking exists for this guest it
  /// is also selected (cascading all its fields). Returns true when a
  /// booking was matched and cascaded.
  bool selectGuest(Guest g) {
    final matchingBooking = state.bookings.where(
      (b) => b.guestName.toLowerCase() == g.name.toLowerCase(),
    );
    emit(state.copyWith(selectedGuest: g));
    if (matchingBooking.isNotEmpty) {
      selectBooking(matchingBooking.first);
      return true;
    }
    return false;
  }

  bool updateBooking({
    required String guestName,
    required String rentText,
    required String gstText,
    required String tendantName,
  }) {
    if (state.selectedBooking == null) return false;
    if (!validateFields(
      guestName: guestName,
      rentText: rentText,
      gstText: gstText,
      tendantName: tendantName,
    )) {
      return false;
    }

    final index = state.bookings.indexWhere(
      (b) => b.id == state.selectedBooking!.id,
    );
    if (index != -1) {
      final parsedRent = double.parse(rentText.trim());
      final parsedGst = double.parse(gstText.trim());
      final updated = Booking(
        id: state.selectedBooking!.id,
        guestName: guestName.trim(),
        phone: state.selectedBooking!.phone,
        roomNumber: state.selectedBooking!.roomNumber,
        rentPerNight: parsedRent,
        gstAmount: parsedGst,
        checkIn: state.selectedBooking!.checkIn,
        checkOut: state.checkoutDate ?? state.selectedBooking!.checkOut,
        adults: state.adults,
        kids: state.kids,
        seniorCitizens: state.selectedBooking!.seniorCitizens,
        idProofName: state.idProofName,
        additionalCharges: state.selectedBooking!.additionalCharges,
      );
      final updatedBookings = List<Booking>.from(state.bookings);
      updatedBookings[index] = updated;
      emit(
        state.copyWith(
          bookings: updatedBookings,
          selectedBooking: updated,
          isEditMode: false,
        ),
      );
    }
    return true;
  }

  /// Deletes [b]. Returns the newly selected booking (if any) so the widget
  /// can resync its text controllers, or null if selection was cleared.
  Booking? deleteBooking(Booking b) {
    final updatedBookings = state.bookings
        .where((item) => item.id != b.id)
        .toList();

    if (state.selectedBooking?.id == b.id) {
      if (updatedBookings.isNotEmpty) {
        emit(state.copyWith(bookings: updatedBookings));
        selectBooking(updatedBookings.first);
        return updatedBookings.first;
      } else {
        emit(
          state.copyWith(
            bookings: updatedBookings,
            clearSelectedBooking: true,
            adults: 1,
            kids: 0,
            clearCheckoutDate: true,
            clearIdProofName: true,
            isFileUploaded: false,
            isConfirmed: false,
            isEditMode: false,
          ),
        );
        return null;
      }
    }

    emit(state.copyWith(bookings: updatedBookings));
    return state.selectedBooking;
  }

  void markRoomOccupied(int roomNumber) {
    final room = Room.allRooms.where((r) => r.number == roomNumber);
    if (room.isNotEmpty) {
      room.first.status = RoomStatus.occupied;
    }
  }

  void setUploadedFile(String fileName) {
    if (state.selectedBooking != null) {
      state.selectedBooking!.idProofName = fileName;
    }
    emit(state.copyWith(idProofName: fileName, isFileUploaded: true));
  }

  void addGuest(Guest guest) {
    final updatedGuests = List<Guest>.from(state.guests)..add(guest);
    emit(state.copyWith(guests: updatedGuests, selectedGuest: guest));
  }

  void setFilterQuery(String query) {
    emit(state.copyWith(filterQuery: query));
  }

  void dismissValidationSummary() {
    emit(state.copyWith(clearValidationSummary: true));
  }
}

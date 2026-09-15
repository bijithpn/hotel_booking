import 'package:equatable/equatable.dart';
import '../../models/booking.dart';
import '../../models/guest.dart';

class CheckInState extends Equatable {
  final List<Booking> bookings;
  final List<Guest> guests;
  final Booking? selectedBooking;
  final Guest? selectedGuest;
  final int adults;
  final int kids;
  final DateTime? checkoutDate;
  final String? idProofName;
  final bool isFileUploaded;
  final bool isConfirmed;
  final bool isEditMode;
  final String filterQuery;
  final String? rentError;
  final String? gstError;
  final String? tendantError;
  final String? guestNameError;
  final String? dateError;
  final String? validationSummary;

  const CheckInState({
    required this.bookings,
    required this.guests,
    this.selectedBooking,
    this.selectedGuest,
    this.adults = 2,
    this.kids = 0,
    this.checkoutDate,
    this.idProofName,
    this.isFileUploaded = false,
    this.isConfirmed = false,
    this.isEditMode = false,
    this.filterQuery = '',
    this.rentError,
    this.gstError,
    this.tendantError,
    this.guestNameError,
    this.dateError,
    this.validationSummary,
  });

  factory CheckInState.initial() {
    return CheckInState(
      bookings: List<Booking>.from(Booking.mockBookings),
      guests: List<Guest>.from(Guest.mockGuests),
    );
  }

  bool get hasErrors =>
      rentError != null ||
      gstError != null ||
      tendantError != null ||
      guestNameError != null ||
      dateError != null;

  CheckInState copyWith({
    List<Booking>? bookings,
    List<Guest>? guests,
    Booking? selectedBooking,
    bool clearSelectedBooking = false,
    Guest? selectedGuest,
    int? adults,
    int? kids,
    DateTime? checkoutDate,
    bool clearCheckoutDate = false,
    String? idProofName,
    bool clearIdProofName = false,
    bool? isFileUploaded,
    bool? isConfirmed,
    bool? isEditMode,
    String? filterQuery,
    String? rentError,
    bool clearRentError = false,
    String? gstError,
    bool clearGstError = false,
    String? tendantError,
    bool clearTendantError = false,
    String? guestNameError,
    bool clearGuestNameError = false,
    String? dateError,
    bool clearDateError = false,
    String? validationSummary,
    bool clearValidationSummary = false,
  }) {
    return CheckInState(
      bookings: bookings ?? this.bookings,
      guests: guests ?? this.guests,
      selectedBooking: clearSelectedBooking
          ? null
          : (selectedBooking ?? this.selectedBooking),
      selectedGuest: selectedGuest ?? this.selectedGuest,
      adults: adults ?? this.adults,
      kids: kids ?? this.kids,
      checkoutDate: clearCheckoutDate
          ? null
          : (checkoutDate ?? this.checkoutDate),
      idProofName: clearIdProofName ? null : (idProofName ?? this.idProofName),
      isFileUploaded: isFileUploaded ?? this.isFileUploaded,
      isConfirmed: isConfirmed ?? this.isConfirmed,
      isEditMode: isEditMode ?? this.isEditMode,
      filterQuery: filterQuery ?? this.filterQuery,
      rentError: clearRentError ? null : (rentError ?? this.rentError),
      gstError: clearGstError ? null : (gstError ?? this.gstError),
      tendantError: clearTendantError
          ? null
          : (tendantError ?? this.tendantError),
      guestNameError: clearGuestNameError
          ? null
          : (guestNameError ?? this.guestNameError),
      dateError: clearDateError ? null : (dateError ?? this.dateError),
      validationSummary: clearValidationSummary
          ? null
          : (validationSummary ?? this.validationSummary),
    );
  }

  @override
  List<Object?> get props => [
    bookings,
    guests,
    selectedBooking,
    selectedGuest,
    adults,
    kids,
    checkoutDate,
    idProofName,
    isFileUploaded,
    isConfirmed,
    isEditMode,
    filterQuery,
    rentError,
    gstError,
    tendantError,
    guestNameError,
    dateError,
    validationSummary,
  ];
}

class AdditionalCharge {
  final String description;
  final DateTime date;
  final double amount;

  AdditionalCharge({
    required this.description,
    required this.date,
    required this.amount,
  });
}

class Booking {
  final String id;
  final String guestName;
  final String phone;
  final int roomNumber;
  final double rentPerNight;
  final double gstAmount;
  final DateTime checkIn;
  final DateTime checkOut;
  int adults;
  int kids;
  int seniorCitizens;
  String? idProofName;
  List<AdditionalCharge> additionalCharges;

  Booking({
    required this.id,
    required this.guestName,
    required this.phone,
    required this.roomNumber,
    required this.rentPerNight,
    required this.gstAmount,
    required this.checkIn,
    required this.checkOut,
    this.adults = 2,
    this.kids = 0,
    this.seniorCitizens = 0,
    this.idProofName,
    List<AdditionalCharge>? additionalCharges,
  }) : additionalCharges = additionalCharges ?? [];

  int get nights => checkOut.difference(checkIn).inDays.clamp(1, 999);

  double get roomCharge => rentPerNight * nights;

  double get gst => gstAmount;

  double get extraCharges =>
      additionalCharges.fold(0.0, (sum, c) => sum + c.amount);

  double get totalAmount => roomCharge + gst + extraCharges;

  static final List<Booking> mockBookings = [
    Booking(
      id: 'BK102',
      guestName: 'Mathew Hyden',
      phone: '9876543210',
      roomNumber: 102,
      rentPerNight: 1200,
      gstAmount: 112,
      checkIn: DateTime(2026, 4, 1),
      checkOut: DateTime(2026, 4, 2),
      adults: 2,
      kids: 0,
      seniorCitizens: 2,
      idProofName: 'mathewhyden.pdf',
    ),
    Booking(
      id: 'BK103',
      guestName: 'Sarah Thompson',
      phone: '9876543211',
      roomNumber: 103,
      rentPerNight: 1300,
      gstAmount: 115,
      checkIn: DateTime(2026, 4, 1),
      checkOut: DateTime(2026, 4, 3),
      adults: 2,
      kids: 3,
      seniorCitizens: 3,
      idProofName: 'sarahthompson.pdf',
    ),
    Booking(
      id: 'BK104',
      guestName: 'James Smith',
      phone: '9876543212',
      roomNumber: 104,
      rentPerNight: 1400,
      gstAmount: 110,
      checkIn: DateTime(2026, 4, 1),
      checkOut: DateTime(2026, 4, 4),
      adults: 2,
      kids: 4,
      seniorCitizens: 4,
      idProofName: 'jamessmithid.pdf',
    ),
    Booking(
      id: 'BK105',
      guestName: 'Emily Clark',
      phone: '9876543213',
      roomNumber: 105,
      rentPerNight: 1500,
      gstAmount: 122,
      checkIn: DateTime(2026, 4, 1),
      checkOut: DateTime(2026, 4, 5),
      adults: 2,
      kids: 5,
      seniorCitizens: 5,
      idProofName: 'emilyclarkid.pdf',
    ),
    Booking(
      id: 'BK106',
      guestName: 'Michael Brown',
      phone: '9876543214',
      roomNumber: 106,
      rentPerNight: 1600,
      gstAmount: 125,
      checkIn: DateTime(2026, 4, 1),
      checkOut: DateTime(2026, 4, 6),
      adults: 2,
      kids: 6,
      seniorCitizens: 0,
      idProofName: 'michaelBrownid.pdf',
    ),
    Booking(
      id: 'BK107',
      guestName: 'Jessica Lee',
      phone: '9876543215',
      roomNumber: 107,
      rentPerNight: 1700,
      gstAmount: 150,
      checkIn: DateTime(2026, 4, 1),
      checkOut: DateTime(2026, 4, 7),
      adults: 2,
      kids: 7,
      seniorCitizens: 7,
      idProofName: 'jessicaleeid.pdf',
    ),
    Booking(
      id: 'BK108',
      guestName: 'David Wilson',
      phone: '9876543216',
      roomNumber: 108,
      rentPerNight: 1800,
      gstAmount: 132,
      checkIn: DateTime(2026, 4, 1),
      checkOut: DateTime(2026, 4, 8),
      adults: 2,
      kids: 8,
      seniorCitizens: 0,
      idProofName: 'davidwilsonid.pdf',
    ),
    Booking(
      id: 'BK109',
      guestName: 'Sophia Martinez',
      phone: '9876543217',
      roomNumber: 109,
      rentPerNight: 1900,
      gstAmount: 135,
      checkIn: DateTime(2026, 4, 1),
      checkOut: DateTime(2026, 4, 9),
      adults: 2,
      kids: 9,
      seniorCitizens: 0,
      idProofName: 'sophiamartin.pdf',
    ),
    Booking(
      id: 'BK110',
      guestName: 'Daniel Garcia',
      phone: '9876543218',
      roomNumber: 110,
      rentPerNight: 2000,
      gstAmount: 138,
      checkIn: DateTime(2026, 4, 1),
      checkOut: DateTime(2026, 4, 10),
      adults: 2,
      kids: 10,
      seniorCitizens: 0,
      idProofName: 'danielgarciaid.pdf',
    ),
    Booking(
      id: 'BK111',
      guestName: 'Olivia Rodriguez',
      phone: '9876543219',
      roomNumber: 111,
      rentPerNight: 2100,
      gstAmount: 140,
      checkIn: DateTime(2026, 4, 1),
      checkOut: DateTime(2026, 4, 11),
      adults: 2,
      kids: 11,
      seniorCitizens: 0,
      idProofName: 'oliviarodigue.pdf',
    ),
  ];
}

// --- Date validation helpers ---

bool isCheckoutAfterCheckin(DateTime checkIn, DateTime checkOut) =>
    checkOut.isAfter(checkIn);

bool isCheckinNotInPast(DateTime checkIn) =>
    !checkIn.isBefore(DateTime.now().subtract(const Duration(days: 1)));

int calculateNights(DateTime checkIn, DateTime checkOut) =>
    checkOut.difference(checkIn).inDays.clamp(1, 999);

bool isRoomAvailable(int roomNo, DateTime checkIn, DateTime checkOut) =>
    !Booking.mockBookings.any((b) =>
        b.roomNumber == roomNo &&
        b.checkIn.isBefore(checkOut) &&
        b.checkOut.isAfter(checkIn));

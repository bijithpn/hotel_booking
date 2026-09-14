import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hotel_booking/config/app_colors.dart';
import '../models/booking.dart';
import '../models/guest.dart';
import '../models/room.dart';
import '../routes/app_router.dart';
import '../widgets/section_header.dart';
import '../config/app_toast.dart';

class CheckInScreen extends StatefulWidget {
  const CheckInScreen({super.key});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  late List<Booking> _bookings;
  late List<Guest> _guests;
  Booking? _selectedBooking;
  Guest? _selectedGuest;

  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _rentCtrl = TextEditingController();
  final TextEditingController _gstCtrl = TextEditingController();
  final TextEditingController _tendantNameCtrl = TextEditingController();
  final TextEditingController _guestNameCtrl = TextEditingController();
  final TextEditingController _updateAdultsKidsCtrl = TextEditingController();
  final FocusNode _guestNameFocus = FocusNode();

  int _adults = 2;
  int _kids = 0;
  DateTime? _checkoutDate;
  String? _idProofName;
  bool _isFileUploaded = false;
  bool _isConfirmed = false;
  bool _isEditMode = false;
  final double _extraCharges = 200.0;
  String _filterQuery = '';

  String? _rentError;
  String? _gstError;
  String? _tendantError;
  String? _guestNameError;
  String? _dateError;
  String? _validationSummary;

  @override
  void initState() {
    super.initState();
    _bookings = List.from(Booking.mockBookings);
    _guests = List.from(Guest.mockGuests);
    if (_bookings.isNotEmpty) {
      _selectBooking(_bookings.first);
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _rentCtrl.dispose();
    _gstCtrl.dispose();
    _tendantNameCtrl.dispose();
    _guestNameCtrl.dispose();
    _updateAdultsKidsCtrl.dispose();
    _guestNameFocus.dispose();
    super.dispose();
  }

  void _clearErrors() {
    setState(() {
      _rentError = null;
      _gstError = null;
      _tendantError = null;
      _guestNameError = null;
      _dateError = null;
      _validationSummary = null;
    });
  }

  void _validateFieldRealtime() {
    setState(() {
      if (_guestNameCtrl.text.trim().isNotEmpty) _guestNameError = null;
      final rent = double.tryParse(_rentCtrl.text.trim());
      if (rent != null && rent > 0) _rentError = null;
      final gst = double.tryParse(_gstCtrl.text.trim());
      if (gst != null && gst >= 0) _gstError = null;
      if (_tendantNameCtrl.text.trim().isNotEmpty) _tendantError = null;

      if (_guestNameError == null &&
          _rentError == null &&
          _gstError == null &&
          _tendantError == null &&
          _dateError == null) {
        _validationSummary = null;
      }
    });
  }

  bool _validateFields() {
    _clearErrors();
    final List<String> errors = [];

    if (_guestNameCtrl.text.trim().isEmpty) {
      _guestNameError = 'Guest name is required';
      errors.add('Guest name is required');
    }

    final rent = double.tryParse(_rentCtrl.text.trim());
    if (rent == null || rent <= 0) {
      _rentError = 'Enter valid rent (> 0)';
      errors.add('Valid rent amount is required');
    }

    final gst = double.tryParse(_gstCtrl.text.trim());
    if (gst == null || gst < 0) {
      _gstError = 'Enter valid GST (>= 0)';
      errors.add('Valid GST percentage is required');
    }

    if (_tendantNameCtrl.text.trim().isEmpty) {
      _tendantError = 'Tendant name is required';
      errors.add('Tendant name is required');
    }

    if (_checkoutDate == null) {
      _dateError = 'Select checkout date';
      errors.add('Checkout date must be selected');
    } else if (_selectedBooking != null &&
        !isCheckoutAfterCheckin(_selectedBooking!.checkIn, _checkoutDate!)) {
      _dateError = 'Checkout must be after check-in';
      errors.add('Checkout date must be after check-in date');
    }

    if (errors.isNotEmpty) {
      setState(() {
        _validationSummary = errors.first;
      });
      return false;
    }

    setState(() {
      _validationSummary = null;
    });
    return true;
  }

  void _selectBooking(Booking b) {
    setState(() {
      _selectedBooking = b;
      _rentCtrl.text = b.rentPerNight.toStringAsFixed(2);
      _gstCtrl.text = b.gstAmount.toStringAsFixed(2);
      _guestNameCtrl.text = b.guestName;
      _tendantNameCtrl.text = b.guestName;
      _adults = b.adults;
      _kids = b.kids;
      _updateAdultsKidsCtrl.text = '${b.adults} Adults, ${b.kids} Kids';
      _checkoutDate = b.checkOut;
      _idProofName =
          b.idProofName ??
          '${b.guestName.toLowerCase().replaceAll(' ', '')}.pdf';
      _isFileUploaded = true;
      _isConfirmed = false;
      _isEditMode = false;
      _clearErrors();

      final matching = _guests.where(
        (g) => g.name.toLowerCase() == b.guestName.toLowerCase(),
      );
      if (matching.isNotEmpty) {
        _selectedGuest = matching.first;
      } else {
        _selectedGuest = _guests.first;
      }
    });
  }

  String _formatDate(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year.toString();
    return '$d/$m/$y';
  }

  void _confirmGuestDetails() {
    if (_selectedBooking == null) return;

    if (!_validateFields()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please correct the validation errors in the form.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (_adults < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('At least 1 adult is required for check-in.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      _isConfirmed = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Guest details confirmed for Room ${_selectedBooking!.roomNumber}! Ready for check-in.',
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _updateBooking() {
    if (_selectedBooking == null) return;
    if (!_validateFields()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot update: please fix invalid field values.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      final index = _bookings.indexWhere((b) => b.id == _selectedBooking!.id);
      if (index != -1) {
        final parsedRent = double.parse(_rentCtrl.text.trim());
        final parsedGst = double.parse(_gstCtrl.text.trim());
        final updated = Booking(
          id: _selectedBooking!.id,
          guestName: _guestNameCtrl.text.trim(),
          phone: _selectedBooking!.phone,
          roomNumber: _selectedBooking!.roomNumber,
          rentPerNight: parsedRent,
          gstAmount: parsedGst,
          checkIn: _selectedBooking!.checkIn,
          checkOut: _checkoutDate ?? _selectedBooking!.checkOut,
          adults: _adults,
          kids: _kids,
          seniorCitizens: _selectedBooking!.seniorCitizens,
          idProofName: _idProofName,
          additionalCharges: _selectedBooking!.additionalCharges,
        );
        _bookings[index] = updated;
        _selectedBooking = updated;
        _isEditMode = false;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Booking details updated successfully.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _deleteBooking(Booking b) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Booking'),
        content: Text(
          'Are you sure you want to delete the booking for ${b.guestName} (Room ${b.roomNumber})?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _bookings.removeWhere((item) => item.id == b.id);
                if (_selectedBooking?.id == b.id) {
                  _selectedBooking = _bookings.isNotEmpty
                      ? _bookings.first
                      : null;
                  if (_selectedBooking != null) {
                    _selectBooking(_selectedBooking!);
                  } else {
                    _rentCtrl.text = '';
                    _gstCtrl.text = '';
                    _guestNameCtrl.text = '';
                    _tendantNameCtrl.text = '';
                    _adults = 1;
                    _kids = 0;
                    _updateAdultsKidsCtrl.text = '1 Adults, 0 Kids';
                    _checkoutDate = null;
                    _idProofName = null;
                    _isFileUploaded = false;
                    _isConfirmed = false;
                    _isEditMode = false;
                  }
                }
              });
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Booking deleted.')));
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _completeCheckin() {
    if (_selectedBooking == null) return;
    if (!_isConfirmed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please click "Confirm Guest Details" first before completing check-in.',
          ),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    final room = Room.allRooms.where(
      (r) => r.number == _selectedBooking!.roomNumber,
    );
    if (room.isNotEmpty) {
      room.first.status = RoomStatus.occupied;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.check_circle, color: Colors.green, size: 24),
            SizedBox(width: 8),
            Text('Check-in Completed!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Guest: ${_selectedBooking!.guestName}'),
            const SizedBox(height: 4),
            Text('Room: ${_selectedBooking!.roomNumber} (Status: Occupied)'),
            const SizedBox(height: 4),
            Text('Checkout Date: ${_formatDate(_selectedBooking!.checkOut)}'),
            const SizedBox(height: 4),
            Text(
              'Total Amount: ₹${_selectedBooking!.totalAmount.toStringAsFixed(2)}',
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.navyDark,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _handleFileUpload() {
    final customFileCtrl = TextEditingController();
    String? fileError;
    bool submitted = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          void validateCustomFile() {
            final text = customFileCtrl.text.trim();
            if (text.isEmpty) {
              fileError = 'Please select a document above or enter a file name';
            } else if (text.length < 4) {
              fileError = 'File name is too short (minimum 4 characters)';
            } else {
              fileError = null;
            }
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            title: Row(
              children: const [
                Icon(Icons.upload_file, color: AppColors.navyDark),
                SizedBox(width: 8),
                Text(
                  'Upload Guest ID Proof',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            content: SizedBox(
              width: 380,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select or upload identity verification document:',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    dense: true,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    leading: const Icon(
                      Icons.picture_as_pdf,
                      color: Colors.redAccent,
                    ),
                    title: const Text(
                      'Aadhaar Card (PDF)',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text('Verified • 1.4 MB'),
                    onTap: () {
                      _setUploadedFile('aadhaar_verified.pdf');
                      Navigator.pop(ctx);
                    },
                  ),
                  const SizedBox(height: 6),
                  ListTile(
                    dense: true,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    leading: const Icon(
                      Icons.badge_outlined,
                      color: Colors.blueAccent,
                    ),
                    title: const Text(
                      'Passport (PDF)',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text('International • 2.1 MB'),
                    onTap: () {
                      _setUploadedFile('passport_scan.pdf');
                      Navigator.pop(ctx);
                    },
                  ),
                  const SizedBox(height: 6),
                  ListTile(
                    dense: true,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    leading: const Icon(
                      Icons.drive_eta_outlined,
                      color: Colors.green,
                    ),
                    title: const Text(
                      'Driving License (JPEG)',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text('State Issued • 0.8 MB'),
                    onTap: () {
                      _setUploadedFile('driving_license.jpg');
                      Navigator.pop(ctx);
                    },
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 6),
                  TextField(
                    controller: customFileCtrl,
                    decoration: InputDecoration(
                      labelText: 'Or enter custom file name',
                      hintText: 'e.g. voter_id_scan.pdf',
                      isDense: true,
                      prefixIcon: const Icon(Icons.attach_file, size: 20),
                      errorText: fileError,
                      errorStyle: const TextStyle(
                        color: Colors.red,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(
                          color: fileError != null
                              ? Colors.red
                              : Colors.grey.shade400,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(
                          color: fileError != null
                              ? Colors.red
                              : AppColors.navyDark,
                          width: 2,
                        ),
                      ),
                    ),
                    onChanged: (val) {
                      if (submitted) {
                        setDialogState(() {
                          validateCustomFile();
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navyDark,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  setDialogState(() {
                    submitted = true;
                    validateCustomFile();
                  });
                  if (fileError == null) {
                    final name = customFileCtrl.text.trim();
                    _setUploadedFile(name.contains('.') ? name : '$name.pdf');
                    Navigator.pop(ctx);
                  }
                },
                child: const Text('Upload Document'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _setUploadedFile(String fileName) {
    setState(() {
      _idProofName = fileName;
      _isFileUploaded = true;
      if (_selectedBooking != null) {
        _selectedBooking!.idProofName = fileName;
      }
    });
    AppToast.showSuccess(
      context,
      'Identity verification document "$fileName" uploaded successfully.',
      title: 'Document Uploaded',
    );
  }

  void _showAddGuestDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    String? nameError;
    String? phoneError;
    bool submitted = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          void validateFields() {
            final name = nameCtrl.text.trim();
            final phone = phoneCtrl.text.trim();

            if (name.isEmpty) {
              nameError = 'Guest name is required';
            } else if (name.length < 2) {
              nameError = 'Guest name must be at least 2 characters';
            } else {
              nameError = null;
            }

            if (phone.isEmpty) {
              phoneError = 'Phone number is required';
            } else {
              final digitsOnly = phone.replaceAll(RegExp(r'[\s\-\+\(\)]'), '');
              if (digitsOnly.length < 10) {
                phoneError = 'Please enter a valid 10-digit phone number';
              } else {
                phoneError = null;
              }
            }
          }

          final hasErrors = nameError != null || phoneError != null;

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            title: Row(
              children: const [
                Icon(Icons.person_add, color: AppColors.navyDark, size: 22),
                SizedBox(width: 8),
                Text(
                  'Add New Guest',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            content: SizedBox(
              width: 380,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (submitted && hasErrors) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF2F0),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.red.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red.shade700,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Please fix the validation errors below.',
                              style: TextStyle(
                                color: Colors.red.shade800,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Guest Name *',
                      hintText: 'e.g. John Doe',
                      isDense: true,
                      prefixIcon: const Icon(Icons.person, size: 20),
                      errorText: nameError,
                      errorStyle: const TextStyle(
                        color: Colors.red,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(
                          color: nameError != null
                              ? Colors.red
                              : Colors.grey.shade400,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(
                          color: nameError != null
                              ? Colors.red
                              : AppColors.navyDark,
                          width: 2,
                        ),
                      ),
                    ),
                    onChanged: (val) {
                      if (submitted) {
                        setDialogState(() {
                          validateFields();
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Phone Number *',
                      hintText: 'e.g. 9876543210',
                      isDense: true,
                      prefixIcon: const Icon(Icons.phone, size: 20),
                      errorText: phoneError,
                      errorStyle: const TextStyle(
                        color: Colors.red,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(
                          color: phoneError != null
                              ? Colors.red
                              : Colors.grey.shade400,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(
                          color: phoneError != null
                              ? Colors.red
                              : AppColors.navyDark,
                          width: 2,
                        ),
                      ),
                    ),
                    onChanged: (val) {
                      if (submitted) {
                        setDialogState(() {
                          validateFields();
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navyDark,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Guest'),
                onPressed: () {
                  setDialogState(() {
                    submitted = true;
                    validateFields();
                  });

                  if (nameError == null && phoneError == null) {
                    final newGuest = Guest(
                      id: 'G00${_guests.length + 1}',
                      name: nameCtrl.text.trim(),
                      phone: phoneCtrl.text.trim(),
                    );
                    setState(() {
                      _guests.add(newGuest);
                      _selectedGuest = newGuest;
                      _guestNameCtrl.text = newGuest.name;
                    });
                    Navigator.pop(ctx);
                    AppToast.showSuccess(
                      context,
                      'Guest "${newGuest.name}" added and assigned to the active form.',
                      title: 'Guest Created',
                    );
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _showGetDataDialog() {
    if (_selectedBooking == null) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Booking Data: ${_selectedBooking!.id}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Guest: ${_selectedBooking!.guestName}'),
            Text('Room: ${_selectedBooking!.roomNumber}'),
            Text('Check-in: ${_formatDate(_selectedBooking!.checkIn)}'),
            Text('Check-out: ${_formatDate(_selectedBooking!.checkOut)}'),
            Text('Rent/Night: ₹${_selectedBooking!.rentPerNight}'),
            Text('GST: ₹${_selectedBooking!.gstAmount}'),
            Text('Total: ₹${_selectedBooking!.totalAmount}'),
            Text(
              'ID Proof: ${_selectedBooking!.idProofName ?? "Not attached"}',
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.navyDark,
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showMPayDialog() {
    final total = _selectedBooking?.totalAmount ?? 2500.0;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.qr_code_2, color: AppColors.navyDark),
            SizedBox(width: 8),
            Text('M-Pay Mobile Payment'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.qr_code,
                size: 100,
                color: AppColors.navyDark,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Scan UPI QR to Pay: ₹${total.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 4),
            const Text(
              'UPI ID: raintechhotel@icici',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () {
              Navigator.pop(ctx);
              AppToast.showSuccess(
                context,
                'Payment of ₹${total.toStringAsFixed(2)} confirmed and received via M-Pay UPI QR.',
                title: 'Payment Received',
              );
            },
            child: const Text('Simulate Payment Received'),
          ),
        ],
      ),
    );
  }

  void _showPrintPreviewDialog() {
    if (_selectedBooking == null) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.print, color: AppColors.navyDark),
            SizedBox(width: 8),
            Text('Print Invoice Preview'),
          ],
        ),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  'RAINTECH HOTEL',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              const Center(
                child: Text(
                  'Guest Folio & Booking Invoice',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ),
              const Divider(),
              Text('Invoice Ref: INV-${_selectedBooking!.id}'),
              Text('Guest: ${_selectedBooking!.guestName}'),
              Text('Room: ${_selectedBooking!.roomNumber}'),
              Text(
                'Duration: ${_formatDate(_selectedBooking!.checkIn)} to ${_formatDate(_selectedBooking!.checkOut)}',
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Amount Payable:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '₹${_selectedBooking!.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.navyDark,
            ),
            icon: const Icon(Icons.print, size: 16),
            label: const Text('Send to Printer'),
            onPressed: () {
              Navigator.pop(ctx);
              AppToast.showInfo(
                context,
                'Invoice INV-${_selectedBooking!.id} for ${_selectedBooking!.guestName} sent to system printer.',
                title: 'Print Queued',
              );
            },
          ),
        ],
      ),
    );
  }

  void _showRegistrationCardDialog() {
    if (_selectedBooking == null) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hotel Registration Card'),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Guest Name: ${_selectedBooking!.guestName}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Phone: ${_selectedBooking!.phone}'),
              Text('Room Number: ${_selectedBooking!.roomNumber}'),
              Text(
                'Check-in: ${_formatDate(_selectedBooking!.checkIn)} | Check-out: ${_formatDate(_selectedBooking!.checkOut)}',
              ),
              Text(
                'Adults: ${_selectedBooking!.adults} | Children: ${_selectedBooking!.kids}',
              ),
              const SizedBox(height: 12),
              const Text(
                'Terms & Conditions:\nCheck-out time is 11:00 AM. Keycards must be returned upon departure.',
                style: TextStyle(fontSize: 10, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    'Guest Signature: __________________',
                    style: TextStyle(fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.navyDark,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              AppToast.showInfo(
                context,
                'Registration card for ${_selectedBooking!.guestName} (Room ${_selectedBooking!.roomNumber}) sent to printer.',
                title: 'Print Queued',
              );
            },
            child: const Text('Print Card'),
          ),
        ],
      ),
    );
  }

  void _downloadFolio() {
    if (_selectedBooking == null) return;
    AppToast.showSuccess(
      context,
      'Guest Folio generated and downloaded: Folio_${_selectedBooking!.id}_Room${_selectedBooking!.roomNumber}.pdf',
      title: 'Download Complete',
    );
  }

  Widget _buildTopBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.navyDark),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppRoutes.dashboard);
              }
            },
            tooltip: 'Back to Dashboard',
          ),
          const SizedBox(width: 8),
          const Text(
            'Guest Check-in',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.navyDark,
            ),
          ),
          const SizedBox(width: 32),
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 450),
              height: 44,
              child: TextField(
                controller: _searchCtrl,
                onChanged: (val) =>
                    setState(() => _filterQuery = val.trim().toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Search Booking ID / Guest Name',
                  hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                  prefixIcon: const Icon(
                    Icons.search,
                    size: 18,
                    color: Colors.grey,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  isDense: true,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPanel1() {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: '1. Select Booking & Guest'),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 44,
                  child: TextField(
                    onChanged: (val) =>
                        setState(() => _filterQuery = val.trim().toLowerCase()),
                    decoration: InputDecoration(
                      hintText: 'Search Booking ID / Guest Name',
                      hintStyle: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        size: 18,
                        color: Colors.grey,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      isDense: true,
                    ),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Select Customer',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFCCCCCC)),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<Guest>(
                            value: _guests.contains(_selectedGuest)
                                ? _selectedGuest
                                : null,
                            isExpanded: true,
                            isDense: true,
                            hint: const Text(
                              'Name/Phone number',
                              style: TextStyle(fontSize: 13),
                            ),
                            items: _guests.map((g) {
                              return DropdownMenuItem<Guest>(
                                value: g,
                                child: Text(
                                  '${g.name} (${g.phone})',
                                  style: const TextStyle(fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (g) {
                              if (g != null) {
                                setState(() {
                                  _selectedGuest = g;
                                  _guestNameCtrl.text = g.name;
                                  final matchingBooking = _bookings.where(
                                    (b) =>
                                        b.guestName.toLowerCase() ==
                                        g.name.toLowerCase(),
                                  );
                                  if (matchingBooking.isNotEmpty) {
                                    _selectBooking(matchingBooking.first);
                                  }
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1976D2),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        onPressed: _showAddGuestDialog,
                        child: const Text(
                          '+ Add Guest',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                const Text(
                  'Select Room:',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _bookings.take(6).map((b) {
                    final isSelected = _selectedBooking?.id == b.id;
                    return ChoiceChip(
                      label: Text('Room ${b.roomNumber}'),
                      selected: isSelected,
                      selectedColor: AppColors.navyDark,
                      labelStyle: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.navyDark
                              : Colors.grey.shade300,
                        ),
                      ),
                      onSelected: (_) => _selectBooking(b),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Booking Date',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _selectedBooking != null
                                ? _formatDate(_selectedBooking!.checkIn)
                                : '02/04/2026',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Booking Time',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          const Row(
                            children: [
                              Text(
                                '07:00 PM ',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Icon(
                                Icons.access_time,
                                size: 14,
                                color: Colors.black54,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPanel2() {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: '2. Review & Update Details'),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_validationSummary != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF2F0),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: const Color(0xFFFFCCC7),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error,
                          color: Color(0xFFCF1322),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Validation Error: $_validationSummary',
                            style: const TextStyle(
                              color: Color(0xFFCF1322),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () =>
                              setState(() => _validationSummary = null),
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: Color(0xFFCF1322),
                          ),
                        ),
                      ],
                    ),
                  ),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(
                            height: 18,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Room No.',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF555555),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 44,
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                            ),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFE8D3A2), Color(0xFFC7A254)],
                              ),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0xFFB8882A),
                                width: 1.0,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.bed,
                                  size: 16,
                                  color: AppColors.navyDark,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${_selectedBooking?.roomNumber ?? 101}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: AppColors.navyDark,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.navyDark,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: const Text(
                                    'SELECTED',
                                    style: TextStyle(
                                      fontSize: 8,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(
                            height: 18,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Rent',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF555555),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          SizedBox(
                            height: 44,
                            child: TextField(
                              controller: _rentCtrl,
                              keyboardType: TextInputType.number,
                              textAlignVertical: TextAlignVertical.center,
                              onChanged: (_) => _validateFieldRealtime(),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: _rentError != null
                                    ? const Color(0xFFFFF2F0)
                                    : Colors.white,
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  borderSide: BorderSide(
                                    color: _rentError != null
                                        ? Colors.red.shade700
                                        : const Color(0xFFCCCCCC),
                                    width: _rentError != null ? 1.5 : 1.0,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  borderSide: BorderSide(
                                    color: _rentError != null
                                        ? Colors.red.shade700
                                        : AppColors.navyDark,
                                    width: 1.5,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                isDense: true,
                              ),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(
                            height: 18,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'GST',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF555555),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          SizedBox(
                            height: 44,
                            child: TextField(
                              controller: _gstCtrl,
                              keyboardType: TextInputType.number,
                              textAlignVertical: TextAlignVertical.center,
                              onChanged: (_) => _validateFieldRealtime(),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: _gstError != null
                                    ? const Color(0xFFFFF2F0)
                                    : Colors.white,
                                suffixIconConstraints: const BoxConstraints(
                                  minWidth: 32,
                                  maxWidth: 32,
                                  minHeight: 38,
                                  maxHeight: 38,
                                ),
                                suffixIcon: Container(
                                  margin: const EdgeInsets.only(right: 2),
                                  alignment: Alignment.center,
                                  decoration: const BoxDecoration(
                                    border: Border(
                                      left: BorderSide(
                                        color: Color(0xFFCCCCCC),
                                      ),
                                    ),
                                    color: Color(0xFFF7F7F7),
                                    borderRadius: BorderRadius.only(
                                      topRight: Radius.circular(5),
                                      bottomRight: Radius.circular(5),
                                    ),
                                  ),
                                  child: const Text(
                                    '%',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  borderSide: BorderSide(
                                    color: _gstError != null
                                        ? Colors.red.shade700
                                        : const Color(0xFFCCCCCC),
                                    width: _gstError != null ? 1.5 : 1.0,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  borderSide: BorderSide(
                                    color: _gstError != null
                                        ? Colors.red.shade700
                                        : AppColors.navyDark,
                                    width: 1.5,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.only(
                                  left: 12,
                                  right: 4,
                                  top: 10,
                                  bottom: 10,
                                ),
                                isDense: true,
                              ),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(
                            height: 18,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Tenant Name',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF555555),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          SizedBox(
                            height: 44,
                            child: TextField(
                              controller: _tendantNameCtrl,
                              textAlignVertical: TextAlignVertical.center,
                              onChanged: (_) => _validateFieldRealtime(),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: _tendantError != null
                                    ? const Color(0xFFFFF2F0)
                                    : Colors.white,
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  borderSide: BorderSide(
                                    color: _tendantError != null
                                        ? Colors.red.shade700
                                        : const Color(0xFFCCCCCC),
                                    width: _tendantError != null ? 1.5 : 1.0,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  borderSide: BorderSide(
                                    color: _tendantError != null
                                        ? Colors.red.shade700
                                        : AppColors.navyDark,
                                    width: 1.5,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                isDense: true,
                              ),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(
                            height: 18,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'No-of Adults',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF555555),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 44,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0xFFCCCCCC),
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                                value: _adults,
                                isExpanded: true,
                                isDense: true,
                                icon: const Icon(
                                  Icons.arrow_drop_down,
                                  color: Colors.black54,
                                ),
                                items: ({for (int i = 1; i <= 20; i++) i, _adults}
                                        .toList()
                                      ..sort())
                                    .map(
                                      (n) => DropdownMenuItem(
                                        value: n,
                                        child: Text(
                                          n.toString().padLeft(2, '0'),
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _adults = val;
                                      _updateAdultsKidsCtrl.text =
                                          '$_adults Adults, $_kids Kids';
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(
                            height: 18,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'No-of Kids',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF555555),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 44,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0xFFCCCCCC),
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                                value: _kids,
                                isExpanded: true,
                                isDense: true,
                                icon: const Icon(
                                  Icons.arrow_drop_down,
                                  color: Colors.black54,
                                ),
                                items: ({for (int i = 0; i <= 20; i++) i, _kids}
                                        .toList()
                                      ..sort())
                                    .map(
                                      (n) => DropdownMenuItem(
                                        value: n,
                                        child: Text(
                                          n.toString().padLeft(2, '0'),
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _kids = val;
                                      _updateAdultsKidsCtrl.text =
                                          '$_adults Adults, $_kids Kids';
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(
                            height: 18,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Checkout Date',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF555555),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate:
                                    _checkoutDate ?? DateTime(2026, 4, 2),
                                firstDate: DateTime(2026, 1, 1),
                                lastDate: DateTime(2030, 12, 31),
                              );
                              if (picked != null) {
                                setState(() {
                                    _checkoutDate = picked;
                                  _dateError = null;
                                });
                              }
                            },
                            child: Container(
                              height: 44,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: _dateError != null
                                    ? const Color(0xFFFFF2F0)
                                    : Colors.white,
                                border: Border.all(
                                  color: _dateError != null
                                      ? Colors.red.shade700
                                      : const Color(0xFFCCCCCC),
                                  width: _dateError != null ? 1.5 : 1.0,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _checkoutDate != null
                                        ? _formatDate(_checkoutDate!)
                                        : 'Select Date',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const Icon(
                                    Icons.calendar_month,
                                    size: 18,
                                    color: Colors.black54,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          const SizedBox(
                            height: 18,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Uploaded File',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF555555),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: _handleFileUpload,
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              height: 44,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: _isFileUploaded
                                    ? const Color(0xFFF0FDF4)
                                    : const Color(0xFFFAFAFA),
                                border: Border.all(
                                  color: _isFileUploaded
                                      ? Colors.green.shade600
                                      : const Color(0xFFCCCCCC),
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _isFileUploaded
                                        ? Icons.check_circle
                                        : Icons.upload_file,
                                    size: 18,
                                    color: _isFileUploaded
                                        ? Colors.green.shade700
                                        : AppColors.navyDark,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _isFileUploaded
                                          ? 'File Uploaded'
                                          : 'Click to Upload',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: _isFileUploaded
                                            ? Colors.green.shade800
                                            : AppColors.navyDark,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Icon(
                                    Icons.description_outlined,
                                    size: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(
                            height: 18,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Update ID Proof',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF555555),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: _handleFileUpload,
                            child: Container(
                              height: 44,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: _isFileUploaded
                                    ? const Color(0xFFF6FFED)
                                    : Colors.white,
                                border: Border.all(
                                  color: _isFileUploaded
                                      ? Colors.green
                                      : const Color(0xFFCCCCCC),
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      _idProofName ?? 'Upload ID proof...',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: _isFileUploaded
                                            ? Colors.green.shade900
                                            : Colors.black87,
                                        fontWeight: _isFileUploaded
                                            ? FontWeight.bold
                                            : FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Icon(
                                    _isFileUploaded
                                        ? Icons.verified
                                        : Icons.description_outlined,
                                    size: 18,
                                    color: _isFileUploaded
                                        ? Colors.green
                                        : Colors.black54,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          const SizedBox(
                            height: 18,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Guest Count',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF555555),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 44,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0xFFCCCCCC),
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                                value: (_adults + _kids).clamp(1, 30),
                                isExpanded: true,
                                isDense: true,
                                icon: const Icon(
                                  Icons.arrow_drop_down,
                                  color: Colors.black54,
                                ),
                                items: ({
                                  for (int i = 1; i <= 30; i++) i,
                                  (_adults + _kids).clamp(1, 30),
                                }.toList()
                                      ..sort())
                                    .map(
                                      (n) => DropdownMenuItem(
                                        value: n,
                                        child: Text(
                                          n.toString().padLeft(2, '0'),
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) {},
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(
                            height: 18,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Update No. of Adults/Kids',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF555555),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          SizedBox(
                            height: 44,
                            child: TextField(
                              controller: _updateAdultsKidsCtrl,
                              textAlignVertical: TextAlignVertical.center,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFCCCCCC),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  borderSide: const BorderSide(
                                    color: AppColors.navyDark,
                                    width: 1.5,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                isDense: true,
                              ),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          const SizedBox(
                            height: 18,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Update Guest Name',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF555555),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          SizedBox(
                            height: 44,
                            child: TextField(
                              controller: _guestNameCtrl,
                              focusNode: _guestNameFocus,
                              textAlignVertical: TextAlignVertical.center,
                              onChanged: (_) => _validateFieldRealtime(),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: _guestNameError != null
                                    ? const Color(0xFFFFF2F0)
                                    : Colors.white,
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  borderSide: BorderSide(
                                    color: _guestNameError != null
                                        ? Colors.red.shade700
                                        : const Color(0xFFCCCCCC),
                                    width: _guestNameError != null ? 1.5 : 1.0,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  borderSide: BorderSide(
                                    color: _guestNameError != null
                                        ? Colors.red.shade700
                                        : AppColors.navyDark,
                                    width: 1.5,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                isDense: true,
                              ),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(
                            height: 18,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Charges Breakdown',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF555555),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 126,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFAFAFA),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0xFFE5E5E5),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: const [
                                    Text(
                                      'Additional Charges',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: AppColors.navyDark,
                                      ),
                                    ),
                                    Icon(
                                      Icons.receipt_long,
                                      size: 16,
                                      color: AppColors.navyDark,
                                    ),
                                  ],
                                ),
                                const Divider(
                                  height: 8,
                                  thickness: 0.8,
                                  color: Color(0xFFEEEEEE),
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: const [
                                    Text(
                                      'Room Charge',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    Text(
                                      '2 beds',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Extra Charges',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    Text(
                                      '₹${_extraCharges.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Tax (GST)',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    Text(
                                      '₹${(_selectedBooking != null ? _selectedBooking!.gstAmount : 112).toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SizedBox(
                      height: 44,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          side: const BorderSide(color: Colors.redAccent),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        onPressed: _selectedBooking != null
                            ? () => _deleteBooking(_selectedBooking!)
                            : null,
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text(
                          'Delete',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 44,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: _isEditMode
                              ? AppColors.navyDark.withValues(alpha: 0.1)
                              : null,
                          foregroundColor: Colors.black87,
                          side: const BorderSide(color: Color(0xFFCCCCCC)),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        onPressed: () {
                          setState(() => _isEditMode = !_isEditMode);
                          _guestNameFocus.requestFocus();
                          AppToast.showInfo(
                            context,
                            _isEditMode
                                ? 'Edit mode enabled: You can now modify guest details and click "Update".'
                                : 'Edit mode closed.',
                            title:
                                _isEditMode ? 'Editing Active' : 'Edit Closed',
                          );
                        },
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: Text(
                          _isEditMode ? 'Editing...' : 'Edit',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 44,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.black87,
                          side: const BorderSide(color: Color(0xFFCCCCCC)),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        onPressed: _updateBooking,
                        icon: const Icon(Icons.sync, size: 18),
                        label: const Text(
                          'Update',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      height: 44,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isConfirmed
                              ? Colors.green
                              : AppColors.navyDark,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        onPressed: _confirmGuestDetails,
                        icon: Icon(
                          _isConfirmed
                              ? Icons.check_circle
                              : Icons.verified_user_outlined,
                          size: 18,
                        ),
                        label: Text(
                          _isConfirmed
                              ? 'Details Confirmed ✓'
                              : 'Confirm Guest Details',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable() {
    final filtered = _bookings.where((b) {
      if (_filterQuery.isEmpty) return true;
      return b.guestName.toLowerCase().contains(_filterQuery) ||
          b.id.toLowerCase().contains(_filterQuery) ||
          b.roomNumber.toString().contains(_filterQuery);
    }).toList();

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            showCheckboxColumn: false,
            headingRowColor: WidgetStateProperty.all(const Color(0xFFF7F8FA)),
            dataRowMinHeight: 40,
            dataRowMaxHeight: 46,
            horizontalMargin: 16,
            columnSpacing: 18,
            columns: const [
              DataColumn(
                label: Text(
                  'ROOM NO.',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'RENT (₹)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'GST',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'NAME',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'NO:OF ADULTS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'NO:OF KIDS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'SENIOR CITIZEN',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'CHECKOUT DATE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'ID PROOF',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'ACTION',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
            rows: filtered.map((b) {
              final isSelected = _selectedBooking?.id == b.id;
              return DataRow(
                selected: isSelected,
                onSelectChanged: (_) => _selectBooking(b),
                color: WidgetStateProperty.resolveWith<Color?>((states) {
                  if (isSelected) {
                    return AppColors.navyDark.withValues(alpha: 0.08);
                  }
                  return null;
                }),
                cells: [
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${b.roomNumber}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? AppColors.navyDark
                                : Colors.black87,
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.navyDark,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'SELECTED',
                              style: TextStyle(
                                fontSize: 7.5,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  DataCell(
                    Text(
                      '₹${b.rentPerNight.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  DataCell(
                    Text(
                      '₹${b.gstAmount.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  DataCell(
                    Text(b.guestName, style: const TextStyle(fontSize: 12)),
                  ),
                  DataCell(
                    Text(
                      b.adults.toString().padLeft(2, '0'),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  DataCell(
                    Text(
                      b.kids.toString().padLeft(2, '0'),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  DataCell(
                    Text(
                      b.seniorCitizens.toString().padLeft(2, '0'),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  DataCell(
                    Text(
                      _formatDate(b.checkOut),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  DataCell(
                    InkWell(
                      onTap: _handleFileUpload,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            (b.idProofName ?? 'Upload ID').length > 13
                                ? '${(b.idProofName ?? 'Upload ID').substring(0, 10)}...'
                                : (b.idProofName ?? 'Upload ID'),
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.blueAccent,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.description_outlined,
                            size: 14,
                            color: Colors.black54,
                          ),
                        ],
                      ),
                    ),
                  ),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(
                            Icons.description_outlined,
                            size: 16,
                            color: Colors.black54,
                          ),
                          onPressed: _showRegistrationCardDialog,
                          tooltip: 'View Registration Card',
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(
                            Icons.more_vert,
                            size: 16,
                            color: Colors.black54,
                          ),
                          onSelected: (val) {
                            if (val == 'edit') {
                              _selectBooking(b);
                              setState(() => _isEditMode = true);
                              _guestNameFocus.requestFocus();
                            } else if (val == 'delete') {
                              _deleteBooking(b);
                            } else if (val == 'print') {
                              _selectBooking(b);
                              _showPrintPreviewDialog();
                            }
                          },
                          itemBuilder: (ctx) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Text(
                                'Edit / Select',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'print',
                              child: Text(
                                'Print Preview',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text(
                                'Delete',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildPanel3() {
    final roomCharge = _selectedBooking != null
        ? _selectedBooking!.roomCharge
        : 2500.0;
    final extra = _selectedBooking != null ? _extraCharges : 2500.0;
    final tax = _selectedBooking != null ? _selectedBooking!.gstAmount : 0.0;
    final total = roomCharge + extra + tax;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: '3. Finalize Check-in & Payment'),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Room Charge',
                      style: TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                    Text(
                      '₹${roomCharge.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Extra Charges',
                      style: TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                    Text(
                      '₹${extra.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tax',
                      style: TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                    Text(
                      '₹${tax.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFE0E0E0)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Amount:',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      '₹${total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.navyDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Paid:',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                    Text(
                      '₹${total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.navyDark,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    onPressed: _completeCheckin,
                    child: const Text(
                      'Complete Check-in',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          foregroundColor: Colors.black87,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        onPressed: _showGetDataDialog,
                        child: const Text(
                          'Get Data',
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          foregroundColor: Colors.black87,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        onPressed: _showMPayDialog,
                        icon: const Icon(Icons.qr_code, size: 14),
                        label: const Text(
                          'M-Pay',
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          foregroundColor: Colors.black87,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        onPressed: _showPrintPreviewDialog,
                        icon: const Icon(Icons.print_outlined, size: 14),
                        label: const Text(
                          'Print',
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      backgroundColor: const Color(0xFFF2F2F2),
                      foregroundColor: Colors.black87,
                      side: const BorderSide(color: Color(0xFFE0E0E0)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    onPressed: _showRegistrationCardDialog,
                    icon: const Icon(Icons.badge_outlined, size: 16),
                    label: const Text(
                      'Print Registration Card',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          foregroundColor: Colors.black87,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        onPressed: _downloadFolio,
                        icon: const Icon(Icons.download_outlined, size: 14),
                        label: const Text(
                          'Download Folio',
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          backgroundColor: AppColors.navyDark,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        onPressed: _completeCheckin,
                        child: const Text(
                          'Complete Check-in',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: Column(
        children: [
          _buildTopBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: 320, child: _buildPanel1()),
                      const SizedBox(width: 16),
                      Expanded(child: _buildPanel2()),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildTable()),
                      const SizedBox(width: 16),
                      SizedBox(width: 300, child: _buildPanel3()),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

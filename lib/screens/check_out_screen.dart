import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hotel_booking/config/app_colors.dart';
import '../models/booking.dart';
import '../models/guest.dart';
import '../models/room.dart';
import '../routes/app_router.dart';
import '../widgets/section_header.dart';
import '../config/app_toast.dart';

class CheckOutScreen extends StatefulWidget {
  const CheckOutScreen({super.key});

  @override
  State<CheckOutScreen> createState() => _CheckOutScreenState();
}

class _CheckOutScreenState extends State<CheckOutScreen> {
  late List<Booking> _bookings;
  late List<Guest> _guests;
  Guest? _selectedGuest;
  int _roomInputNumber = 101;
  final Set<int> _selectedRoomNos = {101, 103};

  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _paymentAmountCtrl = TextEditingController();
  final TextEditingController _chargeDescCtrl = TextEditingController();
  String _paymentMethod = 'Credit Card';
  String? _paymentAmountError;

  final Map<int, List<AdditionalCharge>> _roomAdditionalCharges = {
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
  };

  final Map<int, double> _roomRates = {101: 1200.0, 103: 1200.0};

  final Map<int, int> _roomNights = {101: 2, 103: 2};

  @override
  void initState() {
    super.initState();
    _bookings = List.from(Booking.mockBookings);
    _guests = List.from(Guest.mockGuests);
    _selectedGuest = _guests.first;
    _updatePaymentAmount();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _paymentAmountCtrl.dispose();
    _chargeDescCtrl.dispose();
    super.dispose();
  }

  double _getRoomBaseTotal(int roomNo) {
    final nights = _roomNights[roomNo] ?? 2;
    final rate = _roomRates[roomNo] ?? 1200.0;
    return nights * rate;
  }

  double _getRoomExtraTotal(int roomNo) {
    final charges = _roomAdditionalCharges[roomNo] ?? [];
    return charges.fold(0.0, (sum, c) => sum + c.amount);
  }

  double _getRoomGrandTotal(int roomNo) {
    return _getRoomBaseTotal(roomNo) + _getRoomExtraTotal(roomNo);
  }

  double _getCombinedTotal() {
    double total = 0.0;
    for (final r in _selectedRoomNos) {
      total += _getRoomGrandTotal(r);
    }
    return total;
  }

  void _updatePaymentAmount() {
    _paymentAmountCtrl.text = _getCombinedTotal().toStringAsFixed(2);
  }

  String _formatDate(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year.toString();
    return '$d/$m/$y';
  }

  void _findRoomGuest() {
    setState(() {
      final matching = _guests.where(
        (g) => g.name.toLowerCase().contains(
          _searchCtrl.text.toLowerCase().trim(),
        ),
      );
      if (matching.isNotEmpty) {
        _selectedGuest = matching.first;
      }
    });
    AppToast.showInfo(
      context,
      'Loaded reservation records for ${_selectedGuest?.name ?? "Guest"} (Room $_roomInputNumber).',
      title: 'Records Found',
    );
  }

  void _addQuickCharge(int roomNo, String desc, double amt) {
    setState(() {
      _roomAdditionalCharges.putIfAbsent(roomNo, () => []);
      _roomAdditionalCharges[roomNo]!.add(
        AdditionalCharge(
          description: desc,
          date: DateTime(2026, 4, 3),
          amount: amt,
        ),
      );
      _updatePaymentAmount();
    });
    AppToast.showSuccess(
      context,
      'Added "$desc" (₹${amt.toStringAsFixed(2)}) charge to Room $roomNo bill.',
      title: 'Charge Added',
    );
  }

  void _showAddCustomChargeDialog(int roomNo) {
    final descCtrl = TextEditingController();
    final amtCtrl = TextEditingController();
    String? descError;
    String? amtError;
    bool submitted = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          void validateFields() {
            final desc = descCtrl.text.trim();
            final amtText = amtCtrl.text.trim();

            if (desc.isEmpty) {
              descError = 'Charge description is required';
            } else if (desc.length < 2) {
              descError = 'Description must be at least 2 characters';
            } else {
              descError = null;
            }

            if (amtText.isEmpty) {
              amtError = 'Amount is required';
            } else {
              final parsed = double.tryParse(amtText);
              if (parsed == null || parsed <= 0) {
                amtError = 'Enter a valid positive amount (e.g. 350.00)';
              } else {
                amtError = null;
              }
            }
          }

          final hasErrors = descError != null || amtError != null;

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            title: Row(
              children: [
                const Icon(
                  Icons.receipt_long,
                  color: AppColors.navyDark,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  'Add Charge to Room $roomNo',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
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
                    controller: descCtrl,
                    decoration: InputDecoration(
                      labelText: 'Description *',
                      hintText: 'e.g. Spa, Laundry, Mini-bar',
                      isDense: true,
                      prefixIcon: const Icon(Icons.description, size: 20),
                      errorText: descError,
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
                          color: descError != null
                              ? Colors.red
                              : Colors.grey.shade400,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(
                          color: descError != null
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
                    controller: amtCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Amount (₹) *',
                      hintText: 'e.g. 350.00',
                      isDense: true,
                      prefixIcon: const Icon(Icons.currency_rupee, size: 20),
                      errorText: amtError,
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
                          color: amtError != null
                              ? Colors.red
                              : Colors.grey.shade400,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(
                          color: amtError != null
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
                label: const Text('Add Charge'),
                onPressed: () {
                  setDialogState(() {
                    submitted = true;
                    validateFields();
                  });

                  if (descError == null && amtError == null) {
                    final amt = double.parse(amtCtrl.text.trim());
                    final desc = descCtrl.text.trim();
                    _addQuickCharge(roomNo, desc, amt);
                    Navigator.pop(ctx);
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _processPaymentSingle(int roomNo) {
    final double amountEntered =
        double.tryParse(_paymentAmountCtrl.text) ?? 0.0;
    final double due = _getRoomGrandTotal(roomNo);

    if (amountEntered < due) {
      AppToast.showError(
        context,
        'Entered payment amount (₹${amountEntered.toStringAsFixed(2)}) is less than total due (₹${due.toStringAsFixed(2)}).',
        title: 'Payment Insufficient',
      );
      return;
    }

    setState(() {
      final room = Room.allRooms.where((r) => r.number == roomNo);
      if (room.isNotEmpty) {
        room.first.status = RoomStatus.dirty;
      }
      _selectedRoomNos.remove(roomNo);
      _bookings.removeWhere((b) => b.roomNumber == roomNo);
      _updatePaymentAmount();
    });

    AppToast.showSuccess(
      context,
      'Check-out successfully completed for Room $roomNo. Room status set to Dirty (ready for housekeeping).',
      title: 'Check-out Completed',
    );
  }

  void _processPaymentCombined() {
    if (_selectedRoomNos.isEmpty) {
      AppToast.showWarning(
        context,
        'Please select at least one room from Panel 1 before attempting check-out.',
        title: 'No Rooms Selected',
      );
      return;
    }

    final double amountEntered =
        double.tryParse(_paymentAmountCtrl.text) ?? 0.0;
    final double due = _getCombinedTotal();

    if (amountEntered < due) {
      AppToast.showError(
        context,
        'Entered payment amount (₹${amountEntered.toStringAsFixed(2)}) is less than combined total due (₹${due.toStringAsFixed(2)}).',
        title: 'Payment Insufficient',
      );
      return;
    }

    final checkedOutList = List<int>.from(_selectedRoomNos);
    setState(() {
      for (final rNo in checkedOutList) {
        final room = Room.allRooms.where((r) => r.number == rNo);
        if (room.isNotEmpty) {
          room.first.status = RoomStatus.dirty;
        }
        _bookings.removeWhere((b) => b.roomNumber == rNo);
      }
      _selectedRoomNos.clear();
      _updatePaymentAmount();
    });

    AppToast.showSuccess(
      context,
      'Combined check-out completed for rooms: ${checkedOutList.join(", ")}. Room statuses set to Dirty.',
      title: 'Check-out Completed',
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
            'Guest Check-out',
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
              height: 38,
              child: TextField(
                controller: _searchCtrl,
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
          const SectionHeader(title: '1. Identify Departing Guest'),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Find Guest',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            height: 36,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(0xFFCCCCCC),
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<Guest>(
                                value: _selectedGuest,
                                isExpanded: true,
                                hint: const Text(
                                  'Search Guest',
                                  style: TextStyle(fontSize: 12),
                                ),
                                items: _guests.map((g) {
                                  return DropdownMenuItem(
                                    value: g,
                                    child: Text(
                                      g.name,
                                      style: const TextStyle(fontSize: 12),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (g) {
                                  if (g != null) {
                                    setState(() => _selectedGuest = g);
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Identify by Room',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            height: 36,
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(0xFFCCCCCC),
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '$_roomInputNumber',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    InkWell(
                                      onTap: () =>
                                          setState(() => _roomInputNumber++),
                                      child: const Icon(
                                        Icons.arrow_drop_up,
                                        size: 14,
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () => setState(
                                        () => _roomInputNumber =
                                            (_roomInputNumber > 101
                                            ? _roomInputNumber - 1
                                            : 101),
                                      ),
                                      child: const Icon(
                                        Icons.arrow_drop_down,
                                        size: 14,
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
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 36,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFCCCCCC)),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<Guest>(
                            value: _selectedGuest,
                            isExpanded: true,
                            hint: const Text(
                              'Select Guest from List',
                              style: TextStyle(fontSize: 12),
                            ),
                            items: _guests.map((g) {
                              return DropdownMenuItem(
                                value: g,
                                child: Text(
                                  g.name,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              );
                            }).toList(),
                            onChanged: (g) {
                              if (g != null) setState(() => _selectedGuest = g);
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.navyDark,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      onPressed: _findRoomGuest,
                      child: const Text(
                        'Find Room/Guest',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Guest Name',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _selectedGuest?.name ?? 'Mathew Hyden',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Room No.',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFE8D3A2), Color(0xFFC7A254)],
                            ),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFB8882A)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.bed,
                                size: 14,
                                color: AppColors.navyDark,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$_roomInputNumber',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.navyDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAFAFA),
                    border: Border.all(color: const Color(0xFFE5E5E5)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF0F2F5),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(5),
                            topRight: Radius.circular(5),
                          ),
                        ),
                        child: const Row(
                          children: [
                            SizedBox(
                              width: 45,
                              child: Text(
                                'Room',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'Stay Dates',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Text(
                              'Actions',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildRoomStayRow(101, '02/04/2026-04/04/2026'),
                      const Divider(height: 1, color: Color(0xFFE5E5E5)),
                      _buildRoomStayRow(103, '02/04/2026-04/04/2026'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: const Color(0xFFF2F2F2),
                      foregroundColor: Colors.black87,
                      side: const BorderSide(color: Color(0xFFDDDDDD)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    onPressed: () {},
                    icon: const Icon(Icons.search, size: 16),
                    label: const Text(
                      'Add/Change Selected Rooms',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomStayRow(int roomNo, String dates) {
    final isChecked = _selectedRoomNos.contains(roomNo);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 45,
            child: Text(
              '$roomNo',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              dates,
              style: const TextStyle(fontSize: 11, color: Colors.black87),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: isChecked,
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        _selectedRoomNos.add(roomNo);
                      } else {
                        _selectedRoomNos.remove(roomNo);
                      }
                      _updatePaymentAmount();
                    });
                  },
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                'Select for Check-out',
                style: TextStyle(fontSize: 10, color: Colors.black54),
              ),
            ],
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
          const SectionHeader(title: '2. Review & Finalize Bill'),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_selectedRoomNos.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text(
                        'Please select at least one room in Panel 1 to review bill.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                else ...[
                  if (_selectedRoomNos.contains(101))
                    _buildRoomBillSection(101),
                  if (_selectedRoomNos.contains(101) &&
                      _selectedRoomNos.contains(103))
                    const SizedBox(height: 20),
                  if (_selectedRoomNos.contains(103))
                    _buildRoomBillSection(103),
                  const SizedBox(height: 20),
                  const Divider(color: Color(0xFFE0E0E0)),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Selected Rooms Combined Total: ₹${_getCombinedTotal().toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.navyDark,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomBillSection(int roomNo) {
    final baseTotal = _getRoomBaseTotal(roomNo);
    final nights = _roomNights[roomNo] ?? 2;
    final rate = _roomRates[roomNo] ?? 1200.0;
    final grandTotal = _getRoomGrandTotal(roomNo);
    final charges = _roomAdditionalCharges[roomNo] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 6,
          children: [
            Text(
              '[Room $roomNo]',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.navyDark,
              ),
            ),
            if (roomNo == 103)
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      backgroundColor: const Color(0xFFF2F2F2),
                      foregroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    onPressed: () {},
                    icon: const Icon(Icons.print_outlined, size: 13),
                    label: const Text(
                      'Print Draft Invoice',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      backgroundColor: AppColors.navyDark,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    onPressed: () => _showAddCustomChargeDialog(roomNo),
                    icon: const Icon(Icons.swap_horiz, size: 13),
                    label: const Text(
                      'Adjust Charges',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          '(Nights: $nights, Rate: ₹${rate.toStringAsFixed(2)}, Total: ₹${baseTotal.toStringAsFixed(2)})',
          style: const TextStyle(fontSize: 12, color: Colors.black87),
        ),
        const SizedBox(height: 12),
        const Text(
          'Additional Charges (Add Items)',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 150, maxWidth: 240),
              child: SizedBox(
                height: 34,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search/Add Charges',
                    hintStyle: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      size: 16,
                      color: Colors.grey,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    isDense: true,
                  ),
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEEEEEE),
                foregroundColor: Colors.black87,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              onPressed: () => _addQuickCharge(roomNo, 'Mini-bar item', 100.0),
              child: const Text('Mini-bar', style: TextStyle(fontSize: 11)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEEEEEE),
                foregroundColor: Colors.black87,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              onPressed: () =>
                  _addQuickCharge(roomNo, 'Laundry Service', 150.0),
              child: const Text('Laundry', style: TextStyle(fontSize: 11)),
            ),
            InkWell(
              onTap: () => _showAddCustomChargeDialog(roomNo),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.navyDark,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFAFAFA),
            border: Border.all(color: const Color(0xFFE5E5E5)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFFF0F2F5),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(5),
                    topRight: Radius.circular(5),
                  ),
                ),
                child: const Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Room Charges & External Bills',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 90,
                      child: Text(
                        'Date',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 70,
                      child: Text(
                        'Amount',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ),
              ...charges.map((c) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFEBEBEB)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          c.description,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 90,
                        child: Text(
                          _formatDate(c.date),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 70,
                        child: Text(
                          '₹${c.amount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Room $roomNo Total',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Text(
              '₹${grandTotal.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.navyDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                backgroundColor: const Color(0xFFF2F2F2),
                foregroundColor: Colors.black87,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              onPressed: () {},
              icon: const Icon(Icons.print_outlined, size: 14),
              label: Text(
                'Print Room $roomNo Invoice',
                style: const TextStyle(fontSize: 11),
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                backgroundColor: AppColors.navyDark,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              onPressed: () => _showAddCustomChargeDialog(roomNo),
              icon: const Icon(Icons.swap_horiz, size: 14),
              label: Text(
                'Adjust Charges (Room $roomNo)',
                style: const TextStyle(fontSize: 11),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPanel3() {
    final totalDue = _getCombinedTotal();

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
          const SectionHeader(title: '3. Payment & Check-out'),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Amount Due',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      '₹${totalDue.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.navyDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '(Selected Rooms)',
                      style: TextStyle(fontSize: 11, color: Colors.black54),
                    ),
                    Text(
                      '₹0.00',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Payment Method',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFCCCCCC)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _paymentMethod,
                      isExpanded: true,
                      items: ['Credit Card', 'Cash', 'M-Pay'].map((m) {
                        return DropdownMenuItem(
                          value: m,
                          child: Text(m, style: const TextStyle(fontSize: 12)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _paymentMethod = val);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Payment Amount',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 38,
                  child: TextField(
                    controller: _paymentAmountCtrl,
                    keyboardType: TextInputType.number,
                    onChanged: (val) {
                      final entered = double.tryParse(val.trim());
                      final totalDue = _getCombinedTotal();
                      setState(() {
                        if (val.trim().isEmpty ||
                            entered == null ||
                            entered <= 0) {
                          _paymentAmountError = 'Enter a valid payment amount';
                        } else if (entered < totalDue) {
                          _paymentAmountError =
                              'Must be at least ₹${totalDue.toStringAsFixed(2)}';
                        } else {
                          _paymentAmountError = null;
                        }
                      });
                    },
                    decoration: InputDecoration(
                      prefixText: '₹ ',
                      filled: true,
                      fillColor: _paymentAmountError != null
                          ? const Color(0xFFFFF2F0)
                          : Colors.white,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(
                          color: _paymentAmountError != null
                              ? Colors.red.shade700
                              : const Color(0xFFCCCCCC),
                          width: _paymentAmountError != null ? 1.5 : 1.0,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(
                          color: _paymentAmountError != null
                              ? Colors.red.shade700
                              : AppColors.navyDark,
                          width: 1.5,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                      ),
                      isDense: true,
                    ),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (_paymentAmountError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Row(
                      children: [
                        const Icon(Icons.error, size: 11, color: Colors.red),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            _paymentAmountError!,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A5F),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    onPressed: _selectedRoomNos.isNotEmpty
                        ? () => _processPaymentSingle(_selectedRoomNos.first)
                        : null,
                    child: Column(
                      children: [
                        const Text(
                          'Process Payment & Check-out',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Proceed with Room ${_selectedRoomNos.isNotEmpty ? _selectedRoomNos.first : 101} Check-out\nComplete Check-out',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 9.5,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.navyDark,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    onPressed: _selectedRoomNos.isNotEmpty
                        ? _processPaymentCombined
                        : null,
                    child: const Column(
                      children: [
                        Text(
                          'Payment & Check-out',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Combine and Proceed with\nSelected Rooms Check-out',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 9.5,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: Color(0xFFE0E0E0)),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      backgroundColor: const Color(0xFFF2F2F2),
                      foregroundColor: Colors.black87,
                      side: const BorderSide(color: Color(0xFFE0E0E0)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    onPressed: () {},
                    child: const Text(
                      'Print Final Invoice',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      backgroundColor: const Color(0xFFF2F2F2),
                      foregroundColor: Colors.black87,
                      side: const BorderSide(color: Color(0xFFE0E0E0)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    onPressed: () {},
                    child: const Text(
                      'Email Final Invoice',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
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
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final double availableForPanel2 =
                      constraints.maxWidth - 310 - 300 - 32;
                  final double panel2Width = availableForPanel2 > 440
                      ? availableForPanel2
                      : 440;

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(width: 310, child: _buildPanel1()),
                        const SizedBox(width: 16),

                        SizedBox(width: panel2Width, child: _buildPanel2()),
                        const SizedBox(width: 16),

                        SizedBox(width: 300, child: _buildPanel3()),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

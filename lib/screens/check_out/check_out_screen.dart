import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hotel_booking/config/app_colors.dart';
import '../../cubits/check_out/check_out_cubit.dart';
import '../../models/guest.dart';
import 'package:hotel_booking/routes/app_routes.dart';
import '../../widgets/section_header.dart';
import '../../config/app_toast.dart';
import '../../config/responsive.dart';

class CheckOutScreen extends StatefulWidget {
  const CheckOutScreen({super.key});

  @override
  State<CheckOutScreen> createState() => _CheckOutScreenState();
}

class _CheckOutScreenState extends State<CheckOutScreen> {
  late final CheckOutCubit _cubit;

  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _paymentAmountCtrl = TextEditingController();
  final TextEditingController _chargeDescCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cubit = CheckOutCubit();
    _paymentAmountCtrl.text = _cubit.state.combinedTotal.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _paymentAmountCtrl.dispose();
    _chargeDescCtrl.dispose();
    _cubit.close();
    super.dispose();
  }

  void _syncPaymentAmount() {
    _paymentAmountCtrl.text = _cubit.state.combinedTotal.toStringAsFixed(2);
  }

  String _formatDate(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year.toString();
    return '$d/$m/$y';
  }

  void _findRoomGuest() {
    final guest = _cubit.findGuestByName(_searchCtrl.text);
    AppToast.showInfo(
      context,
      'Loaded reservation records for ${guest?.name ?? "Guest"} (Room ${_cubit.state.roomInputNumber}).',
      title: 'Records Found',
    );
  }

  void _addQuickCharge(int roomNo, String desc, double amt) {
    _cubit.addQuickCharge(roomNo, desc, amt);
    _syncPaymentAmount();
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
              width: MediaQuery.of(context).size.width < 420 ? MediaQuery.of(context).size.width * 0.9 : 380,
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
    final result = _cubit.processPaymentSingle(roomNo, _paymentAmountCtrl.text);
    if (result.outcome == PaymentOutcome.insufficient) {
      AppToast.showError(
        context,
        'Entered payment amount (₹${result.amountEntered.toStringAsFixed(2)}) is less than total due (₹${result.due.toStringAsFixed(2)}).',
        title: 'Payment Insufficient',
      );
      return;
    }
    _syncPaymentAmount();
    AppToast.showSuccess(
      context,
      'Check-out successfully completed for Room $roomNo. Room status set to Dirty (ready for housekeeping).',
      title: 'Check-out Completed',
    );
  }

  void _processPaymentCombined() {
    final result = _cubit.processPaymentCombined(_paymentAmountCtrl.text);

    if (result.outcome == PaymentOutcome.noRoomsSelected) {
      AppToast.showWarning(
        context,
        'Please select at least one room from Panel 1 before attempting check-out.',
        title: 'No Rooms Selected',
      );
      return;
    }

    if (result.outcome == PaymentOutcome.insufficient) {
      AppToast.showError(
        context,
        'Entered payment amount (₹${result.amountEntered.toStringAsFixed(2)}) is less than combined total due (₹${result.due.toStringAsFixed(2)}).',
        title: 'Payment Insufficient',
      );
      return;
    }

    _syncPaymentAmount();
    AppToast.showSuccess(
      context,
      'Combined check-out completed for rooms: ${result.roomNumbers.join(", ")}. Room statuses set to Dirty.',
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
          Flexible(
            child: Text(
              'Guest Check-out',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: Responsive.isMobile(context) ? 17 : 22,
                fontWeight: FontWeight.bold,
                color: AppColors.navyDark,
              ),
            ),
          ),
          SizedBox(width: Responsive.isMobile(context) ? 12 : 32),
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 450),
              height: 44,
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

  Widget _buildPanel1(CheckOutState state) {
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: double.infinity,
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
                          const SizedBox(height: 6),
                          Container(
                            height: 44,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(0xFFCCCCCC),
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<Guest>(
                                value: state.selectedGuest,
                                isExpanded: true,
                                hint: const Text(
                                  'Search Guest',
                                  style: TextStyle(fontSize: 13),
                                ),
                                items: state.guests.map((g) {
                                  return DropdownMenuItem(
                                    value: g,
                                    child: Text(
                                      g.name,
                                      style: const TextStyle(fontSize: 13),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (g) {
                                  if (g != null) _cubit.selectGuest(g);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Identify by Room',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 44,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
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
                                  '${state.roomInputNumber}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    InkWell(
                                      onTap: _cubit.incrementRoomInputNumber,
                                      child: const Icon(
                                        Icons.arrow_drop_up,
                                        size: 16,
                                      ),
                                    ),
                                    InkWell(
                                      onTap: _cubit.decrementRoomInputNumber,
                                      child: const Icon(
                                        Icons.arrow_drop_down,
                                        size: 16,
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

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFCCCCCC)),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<Guest>(
                            value: state.selectedGuest,
                            isExpanded: true,
                            hint: const Text(
                              'Select Guest from List',
                              style: TextStyle(fontSize: 13),
                            ),
                            items: state.guests.map((g) {
                              return DropdownMenuItem(
                                value: g,
                                child: Text(
                                  g.name,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              );
                            }).toList(),
                            onChanged: (g) {
                              if (g != null) _cubit.selectGuest(g);
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.navyDark,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        onPressed: _findRoomGuest,
                        child: const Text(
                          'Find Room/Guest',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Guest Name',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            state.selectedGuest?.name ?? 'Mathew Hyden',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
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
                                '${state.roomInputNumber}',
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
                      _buildRoomStayRow(state, 101, '02/04/2026-04/04/2026'),
                      const Divider(height: 1, color: Color(0xFFE5E5E5)),
                      _buildRoomStayRow(state, 103, '02/04/2026-04/04/2026'),
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

  Widget _buildRoomStayRow(CheckOutState state, int roomNo, String dates) {
    final isChecked = state.selectedRoomNos.contains(roomNo);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 45,
                child: Text(
                  '$roomNo',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  dates,
                  style: const TextStyle(fontSize: 11, color: Colors.black87),
                ),
              ),
            ],
          ),
          SizedBox(
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: isChecked,
                    onChanged: (val) {
                      _cubit.toggleRoomSelection(roomNo, val == true);
                      _syncPaymentAmount();
                    },
                  ),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'Select for Check-out',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.black54,
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

  Widget _buildPanel2(CheckOutState state) {
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
                if (state.selectedRoomNos.isEmpty)
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
                  if (state.selectedRoomNos.contains(101))
                    _buildRoomBillSection(state, 101),
                  if (state.selectedRoomNos.contains(101) &&
                      state.selectedRoomNos.contains(103))
                    const SizedBox(height: 20),
                  if (state.selectedRoomNos.contains(103))
                    _buildRoomBillSection(state, 103),
                  const SizedBox(height: 20),
                  const Divider(color: Color(0xFFE0E0E0)),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Selected Rooms Combined Total: ₹${state.combinedTotal.toStringAsFixed(2)}',
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

  Widget _buildRoomBillSection(CheckOutState state, int roomNo) {
    final baseTotal = state.getRoomBaseTotal(roomNo);
    final nights = CheckOutState.roomNights[roomNo] ?? 2;
    final rate = CheckOutState.roomRates[roomNo] ?? 1200.0;
    final grandTotal = state.getRoomGrandTotal(roomNo);
    final charges = state.roomAdditionalCharges[roomNo] ?? [];

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
            Flexible(
              child: Text(
                'Room $roomNo Total',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(width: 8),
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

  Widget _buildPanel3(CheckOutState state) {
    final totalDue = state.combinedTotal;

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
                    const Flexible(
                      child: Text(
                        'Total Amount Due',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '₹${totalDue.toStringAsFixed(2)}',
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.navyDark,
                        ),
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
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      [
                        {'name': 'Credit Card', 'icon': Icons.credit_card},
                        {'name': 'Cash', 'icon': Icons.payments_outlined},
                        {'name': 'M-Pay', 'icon': Icons.phone_android},
                      ].map((m) {
                        final name = m['name'] as String;
                        final icon = m['icon'] as IconData;
                        final isSelected = state.paymentMethod == name;
                        return InkWell(
                          onTap: () => _cubit.setPaymentMethod(name),
                          borderRadius: BorderRadius.circular(6),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            height: 38,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.navyDark
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.navyDark
                                    : const Color(0xFFCCCCCC),
                                width: isSelected ? 1.5 : 1.0,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: AppColors.navyDark.withValues(
                                          alpha: 0.25,
                                        ),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  icon,
                                  size: 16,
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.navyDark,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  name,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                                if (isSelected) ...[
                                  const SizedBox(width: 5),
                                  const Icon(
                                    Icons.check_circle,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Payment Amount',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 44,
                  child: TextField(
                    controller: _paymentAmountCtrl,
                    keyboardType: TextInputType.number,
                    onChanged: (val) {
                      _cubit.validatePaymentAmount(val, state.combinedTotal);
                    },
                    decoration: InputDecoration(
                      prefixText: '₹ ',
                      prefixStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.navyDark,
                      ),
                      filled: true,
                      fillColor: state.paymentAmountError != null
                          ? const Color(0xFFFFF2F0)
                          : Colors.white,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(
                          color: state.paymentAmountError != null
                              ? Colors.red.shade700
                              : const Color(0xFFCCCCCC),
                          width: state.paymentAmountError != null ? 1.5 : 1.0,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(
                          color: state.paymentAmountError != null
                              ? Colors.red.shade700
                              : AppColors.navyDark,
                          width: 1.5,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      isDense: true,
                    ),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.navyDark,
                    ),
                  ),
                ),
                if (state.paymentAmountError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Row(
                      children: [
                        const Icon(Icons.error, size: 11, color: Colors.red),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            state.paymentAmountError!,
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
                    onPressed: state.selectedRoomNos.isNotEmpty
                        ? () =>
                              _processPaymentSingle(state.selectedRoomNos.first)
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
                          'Proceed with Room ${state.selectedRoomNos.isNotEmpty ? state.selectedRoomNos.first : 101} Check-out\nComplete Check-out',
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
                    onPressed: state.selectedRoomNos.isNotEmpty
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
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: AppColors.bgLight,
        body: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: BlocBuilder<CheckOutCubit, CheckOutState>(
                builder: (context, state) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final bool isWide = constraints.maxWidth >= 1024;
                        if (!isWide) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildPanel1(state),
                              const SizedBox(height: 16),
                              _buildPanel2(state),
                              const SizedBox(height: 16),
                              _buildPanel3(state),
                            ],
                          );
                        }

                        final double availableForPanel2 =
                            constraints.maxWidth - 340 - 300 - 32;
                        final double panel2Width = availableForPanel2 > 440
                            ? availableForPanel2
                            : 440;

                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(width: 340, child: _buildPanel1(state)),
                              const SizedBox(width: 16),

                              SizedBox(
                                width: panel2Width,
                                child: _buildPanel2(state),
                              ),
                              const SizedBox(width: 16),

                              SizedBox(width: 300, child: _buildPanel3(state)),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

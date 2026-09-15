import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../config/app_colors.dart';
import '../../../cubits/dashboard/dashboard_cubit.dart';
import '../../../models/booking.dart';
import '../../../models/room.dart';
import '../../../widgets/stat_card.dart';

class DashboardOperationalOverviewCard extends StatelessWidget {
  const DashboardOperationalOverviewCard({super.key});

  double _occupancyPct(List<Room> rooms) {
    if (rooms.isEmpty) return 0;
    return rooms.where((r) => r.status == RoomStatus.occupied).length /
        rooms.length *
        100;
  }

  int _pendingCheckIns() {
    final today = DateTime.now();
    return Booking.mockBookings
        .where(
          (b) =>
              b.checkIn.year == today.year &&
              b.checkIn.month == today.month &&
              b.checkIn.day == today.day,
        )
        .length;
  }

  int _pendingDepartures() {
    final today = DateTime.now();
    return Booking.mockBookings
        .where(
          (b) =>
              b.checkOut.year == today.year &&
              b.checkOut.month == today.month &&
              b.checkOut.day == today.day,
        )
        .length;
  }

  double _revenueToday() {
    final today = DateTime.now();
    return Booking.mockBookings
        .where(
          (b) =>
              b.checkIn.year == today.year &&
              b.checkIn.month == today.month &&
              b.checkIn.day == today.day,
        )
        .fold(0.0, (sum, b) => sum + b.totalAmount);
  }

  @override
  Widget build(BuildContext context) {
    final rooms = context.watch<DashboardCubit>().state.rooms;

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Operational Overview',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppColors.navyDark,
              ),
            ),
            const SizedBox(height: 10),
            Column(
              children: [
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: StatCard(
                          label: 'Occupancy',
                          value: '${_occupancyPct(rooms).toStringAsFixed(0)}%',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: StatCard(
                          label: 'Pending Check-ins',
                          value: '${_pendingCheckIns()}',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: StatCard(
                          label: 'Pending Departures',
                          value: '${_pendingDepartures()}',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: StatCard(
                          label: 'Revenue Today',
                          value: _revenueToday() == 0
                              ? '₹0'
                              : '₹${_revenueToday().toStringAsFixed(0)}',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';
import '../../../models/booking.dart';

class DashboardGoingToVacateCard extends StatelessWidget {
  const DashboardGoingToVacateCard({super.key});

  List<Booking> _vacatingBookings() {
    final today = DateTime.now();
    final matched = Booking.mockBookings
        .where(
          (b) =>
              b.checkOut.year == today.year &&
              b.checkOut.month == today.month &&
              b.checkOut.day == today.day,
        )
        .toList();
    return matched.isNotEmpty ? matched : Booking.mockBookings.take(2).toList();
  }

  @override
  Widget build(BuildContext context) {
    final vacating = _vacatingBookings();

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
            const Row(
              children: [
                Icon(Icons.bed_outlined, size: 16, color: AppColors.navyDark),
                SizedBox(width: 6),
                Text(
                  'Going to Vacate Rooms',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.navyDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: vacating.isEmpty
                  ? const Center(
                      child: Text(
                        'No rooms departing today.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ScrollConfiguration(
                      behavior: _MouseDragScrollBehavior(),
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: vacating.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 10),
                        itemBuilder: (_, i) =>
                            _VacatingCard(booking: vacating[i]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VacatingCard extends StatelessWidget {
  final Booking booking;

  const _VacatingCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final b = booking;
    return Container(
      width: 210,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2E4A7A), Color(0xFF1C2B4A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.horizontal(left: Radius.circular(9)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.bed, size: 26, color: Colors.white),
                const SizedBox(height: 4),
                Text(
                  'Rm ${b.roomNumber}',
                  style: const TextStyle(
                    fontSize: 9,
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Room ${b.roomNumber}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppColors.navyDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Departing - Guest\nCheck-Out Scheduled',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Checkout: ${b.checkOut.hour == 0
                        ? 11
                        : b.checkOut.hour % 12 == 0
                        ? 12
                        : b.checkOut.hour % 12}:00 AM',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1C2B4A),
                    ),
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

class _MouseDragScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.mouse,
    PointerDeviceKind.touch,
    PointerDeviceKind.stylus,
    PointerDeviceKind.unknown,
  };
}

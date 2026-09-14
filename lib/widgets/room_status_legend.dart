import 'package:flutter/material.dart';
import 'package:hotel_booking/config/app_colors.dart';
import '../models/room.dart';

class RoomStatusLegend extends StatelessWidget {
  const RoomStatusLegend({super.key});

  static const _items = [
    (RoomStatus.available, AppColors.roomGreen, 'Available'),
    (RoomStatus.occupied, AppColors.roomBlue, 'Occupied'),
    (RoomStatus.dirty, AppColors.roomRed, 'Dirty'),
    (RoomStatus.maintenance, AppColors.roomOrange, 'Maintenance'),
    (RoomStatus.blocked, AppColors.roomGrey, 'Blocked'),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 6,
      children: _items.map((item) {
        final (_, color, label) = item;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        );
      }).toList(),
    );
  }
}

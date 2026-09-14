import 'package:flutter/material.dart';
import 'package:hotel_booking/config/app_colors.dart';
import '../models/room.dart';

class RoomTile extends StatelessWidget {
  final Room room;
  final VoidCallback? onTap;

  const RoomTile({super.key, required this.room, this.onTap});

  static Color colorFor(RoomStatus status) {
    switch (status) {
      case RoomStatus.available:
        return AppColors.roomGreen;
      case RoomStatus.occupied:
        return AppColors.roomBlue;
      case RoomStatus.dirty:
        return AppColors.roomRed;
      case RoomStatus.maintenance:
        return AppColors.roomOrange;
      case RoomStatus.blocked:
        return AppColors.roomGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = colorFor(room.status);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        margin: const EdgeInsets.symmetric(horizontal: 1.5, vertical: 2),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
        ),
        alignment: Alignment.center,
        child: Text(
          '${room.number}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

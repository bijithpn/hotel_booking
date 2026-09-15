import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';
import '../../../models/room.dart';

class DashboardMaintenanceRoomsDialog {
  static void show(BuildContext context, List<Room> rooms) {
    final maintenanceRooms = rooms
        .where((r) => r.status == RoomStatus.maintenance)
        .toList();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Maintenance Rooms'),
        content: maintenanceRooms.isEmpty
            ? const Text('No rooms currently under maintenance.')
            : SizedBox(
                width: 300,
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: maintenanceRooms.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) => ListTile(
                    dense: true,
                    leading: Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: AppColors.roomOrange,
                        shape: BoxShape.circle,
                      ),
                    ),
                    title: Text('Room ${maintenanceRooms[i].number}'),
                    subtitle: Text(
                      'Floor ${maintenanceRooms[i].floor}  —  ${maintenanceRooms[i].type}',
                    ),
                  ),
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

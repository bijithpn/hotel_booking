import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../config/app_toast.dart';
import '../../../cubits/dashboard/dashboard_cubit.dart';
import '../../../models/room.dart';
import '../../../widgets/room_tile.dart';

class DashboardRoomQuickEditDialog {
  static void show(BuildContext context, Room room) {
    final cubit = context.read<DashboardCubit>();
    RoomStatus selected = room.status;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDs) => AlertDialog(
          title: Text('Room ${room.number}  —  ${room.type}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Floor ${room.floor}  •  ₹${room.pricePerNight}/night  •  Max ${room.maxGuests} guests',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              const Text(
                'Change Status:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              DropdownButton<RoomStatus>(
                value: selected,
                isExpanded: true,
                items: RoomStatus.values
                    .map(
                      (s) => DropdownMenuItem(
                        value: s,
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: RoomTile.colorFor(s),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(s.name[0].toUpperCase() + s.name.substring(1)),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (s) {
                  if (s != null) setDs(() => selected = s);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                cubit.setRoomStatus(room, selected);
                Navigator.pop(ctx);
                AppToast.showSuccess(
                  context,
                  'Room ${room.number} status updated to ${selected.name.toUpperCase()}.',
                  title: 'Status Updated',
                );
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }
}

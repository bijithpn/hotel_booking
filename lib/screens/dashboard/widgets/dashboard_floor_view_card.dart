import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../config/app_colors.dart';
import '../../../cubits/dashboard/dashboard_cubit.dart';
import '../../../models/room.dart';
import '../../../widgets/room_status_legend.dart';
import '../../../widgets/room_tile.dart';
import 'dashboard_room_quick_edit_dialog.dart';

class DashboardFloorViewCard extends StatelessWidget {
  const DashboardFloorViewCard({super.key});

  @override
  Widget build(BuildContext context) {
    final rooms = context.watch<DashboardCubit>().state.rooms;
    final floor1 = rooms.where((r) => r.floor == 1).toList();
    final floor2 = rooms.where((r) => r.floor == 2).toList();

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Room Status - Interactive Floor View',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppColors.navyDark,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              '50 rooms across your property',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            _FloorSection(label: 'Floor 1', rooms: floor1),
            const SizedBox(height: 14),
            _FloorSection(label: 'Floor 2', rooms: floor2),
            const SizedBox(height: 16),
            const RoomStatusLegend(),
            const SizedBox(height: 6),
            const Text(
              'Clicking a room tile opens its quick-edit menu',
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _FloorSection extends StatelessWidget {
  final String label;
  final List<Room> rooms;

  const _FloorSection({required this.label, required this.rooms});

  @override
  Widget build(BuildContext context) {
    final row1 = rooms.take(13).toList();
    final row2 = rooms.skip(13).toList();

    Widget tile(Room r) => RoomTile(
      room: r,
      onTap: () => DashboardRoomQuickEditDialog.show(context, r),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 36,
          height: 98,
          child: Center(
            child: RotatedBox(
              quarterTurns: -1,
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ),

        Expanded(
          child: ScrollConfiguration(
            behavior: _MouseDragScrollBehavior(),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: row1.map(tile).toList()),
                  const SizedBox(height: 4),
                  Row(children: row2.map(tile).toList()),
                ],
              ),
            ),
          ),
        ),
      ],
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

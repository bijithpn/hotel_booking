import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../config/app_colors.dart';
import '../../../cubits/dashboard/dashboard_cubit.dart';
import '../../../models/room.dart';
import '../../../widgets/room_status_legend.dart';
import '../../../widgets/room_tile.dart';

class DashboardOccupancyChartCard extends StatelessWidget {
  const DashboardOccupancyChartCard({super.key});

  @override
  Widget build(BuildContext context) {
    final rooms = context.watch<DashboardCubit>().state.rooms;
    final floor1 = rooms.where((r) => r.floor == 1).toList();
    final floor2 = rooms.where((r) => r.floor == 2).toList();
    final occupied = rooms.where((r) => r.status == RoomStatus.occupied).length;
    final total = rooms.length;
    final pct = total == 0 ? 0.0 : occupied / total;

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
          mainAxisSize: MainAxisSize.min,
          children: [
            _MiniFloorSection(label: 'Floor 1', rooms: floor1),
            const SizedBox(height: 6),

            _MiniFloorSection(label: 'Floor 2', rooms: floor2),
            const SizedBox(height: 12),

            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 100,
                        height: 100,
                        child: CircularProgressIndicator(
                          value: pct,
                          strokeWidth: 13,
                          backgroundColor: const Color(0xFFEEEEEE),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.navyDark,
                          ),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$total',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.navyDark,
                            ),
                          ),
                          const Text(
                            'Rooms\nTotal',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 9, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${(pct * 100).toStringAsFixed(0)}% Occupied',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const RoomStatusLegend(),
          ],
        ),
      ),
    );
  }
}

class _MiniFloorSection extends StatelessWidget {
  final String label;
  final List<Room> rooms;

  const _MiniFloorSection({required this.label, required this.rooms});

  Widget _miniTile(Room room) {
    return Container(
      width: 14,
      height: 14,
      margin: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: RoomTile.colorFor(room.status),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final row1 = rooms.take(13).toList();
    final row2 = rooms.skip(13).toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 28,
          height: 44,
          child: Center(
            child: RotatedBox(
              quarterTurns: -1,
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
        ),

        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 1,
                runSpacing: 1,
                children: row1.map(_miniTile).toList(),
              ),
              const SizedBox(height: 1),
              Wrap(
                spacing: 1,
                runSpacing: 1,
                children: row2.map(_miniTile).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

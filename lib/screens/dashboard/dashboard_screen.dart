import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hotel_booking/config/app_colors.dart';
import '../../config/responsive.dart';
import '../../cubits/dashboard/dashboard_cubit.dart';
import '../../models/booking.dart';
import '../../models/room.dart';
import '../../widgets/room_status_legend.dart';
import '../../widgets/room_tile.dart';
import '../../widgets/stat_card.dart';
import '../../config/app_toast.dart';
import 'package:go_router/go_router.dart';
import 'package:hotel_booking/routes/app_routes.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

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

  void _showRoomQuickEdit(BuildContext context, Room room) {
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

  void _showMaintenanceRooms(BuildContext context, List<Room> rooms) {
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

  Future<void> _navigateTo(BuildContext context, String routePath) async {
    final cubit = context.read<DashboardCubit>();
    await context.push(routePath);
    cubit.reloadRooms();
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final wd = weekdays[dt.weekday - 1];
    var h = dt.hour % 12;
    if (h == 0) h = 12;
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final m = dt.minute.toString().padLeft(2, '0');
    return '$wd, ${months[dt.month - 1]} ${dt.day}, ${dt.year}  |  $h:$m $ampm';
  }

  Widget _buildTopBar(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final isTablet = Responsive.isTablet(context);
    final showDate = !isMobile;
    final showQuickActionsLabel = !isMobile;
    final showLogoText = !isMobile || MediaQuery.sizeOf(context).width >= 360;

    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 20,
        vertical: 12,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.navyDark,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.grid_view, color: Colors.white, size: 20),
          ),
          if (showLogoText) ...[
            const SizedBox(width: 8),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Raintech',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.navyDark,
                  ),
                ),
                Text(
                  'HOTEL',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ],
          SizedBox(width: isMobile ? 12 : 24),

          Expanded(
            child: SizedBox(
              height: 36,
              child: TextField(
                decoration: InputDecoration(
                  hintText: isMobile
                      ? 'Search...'
                      : isTablet
                      ? 'Search guests, rooms...'
                      : 'Search guests, rooms, reservations, staff...',
                  hintStyle: const TextStyle(fontSize: 13),
                  prefixIcon: const Icon(Icons.search, size: 18),
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
          Flexible(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: true,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showDate) ...[
                    const SizedBox(width: 16),
                    Text(
                      _formatDate(DateTime.now()),
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.attach_money, size: 16),
                    label: Text(
                      showQuickActionsLabel ? 'Quick Actions' : '',
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.navyDark,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: showQuickActionsLabel ? 14 : 8,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  if (!isMobile)
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined),
                      onPressed: () {},
                      iconSize: 22,
                    ),
                  const SizedBox(width: 4),
                  const CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.navyDark,
                    child: Icon(Icons.person, size: 18, color: Colors.white),
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavTilesCard(BuildContext context) {
    final items = <_NavItem>[
      _NavItem(
        'Guest Check-in',
        Icons.input_rounded,
        const Color(0xFF4DB6AC),
        onTap: () => _navigateTo(context, AppRoutes.checkIn),
      ),
      _NavItem(
        'Guest Check-Out',
        Icons.output_rounded,
        const Color(0xFFEF9A9A),
        onTap: () => _navigateTo(context, AppRoutes.checkOut),
      ),
      _NavItem(
        'Reservations',
        Icons.calendar_month_outlined,
        const Color(0xFF90CAF9),
      ),
      _NavItem('Housekeeping', Icons.layers_outlined, const Color(0xFFA5D6A7)),
      _NavItem('Restaurant', Icons.restaurant_menu, const Color(0xFFFFCC80)),
      _NavItem('WhatsApp', Icons.chat_bubble_outline, const Color(0xFF80CBC4)),
      _NavItem('Rooms', Icons.bed_outlined, const Color(0xFFCE93D8)),
      _NavItem(
        'Staff',
        Icons.people_alt_outlined,
        const Color(0xFF90CAF9),
        badge: '2 tasks',
      ),
      _NavItem('Floors', Icons.layers, const Color(0xFF80DEEA)),
      _NavItem('Reports', Icons.bar_chart_outlined, const Color(0xFFFFF176)),
      _NavItem('Settings', Icons.settings_outlined, const Color(0xFFBDBDBD)),
      _NavItem(
        'New: Group Booking',
        Icons.group_add_outlined,
        const Color(0xFFBDBDBD),
      ),
    ];

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: Responsive.value(
              context,
              mobile: 3,
              tablet: 4,
              desktop: 6,
            ),
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: Responsive.value(
              context,
              mobile: 0.85,
              tablet: 0.9,
              desktop: 1.0,
            ),
          ),
          itemCount: items.length,
          itemBuilder: (_, i) => _buildNavTile(items[i]),
        ),
      ),
    );
  }

  Widget _buildNavTile(_NavItem item) {
    return InkWell(
      onTap: item.onTap ?? () {},
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE8E8E8)),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: item.iconBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(item.icon, size: 20, color: Colors.white),
                ),
                const SizedBox(height: 5),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    item.label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: Color(0xFF444444),
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (item.badge != null)
              Positioned(
                top: 5,
                right: 5,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    item.badge!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOperationalOverview(List<Room> rooms) {
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

  Widget _buildFloorViewCard(BuildContext context, List<Room> rooms) {
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
            _buildFloorSection(context, 'Floor 1', floor1),
            const SizedBox(height: 14),
            _buildFloorSection(context, 'Floor 2', floor2),
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

  Widget _buildFloorSection(
    BuildContext context,
    String label,
    List<Room> rooms, {
    bool interactive = true,
  }) {
    final row1 = rooms.take(13).toList();
    final row2 = rooms.skip(13).toList();

    Widget tile(Room r) => interactive
        ? RoomTile(room: r, onTap: () => _showRoomQuickEdit(context, r))
        : RoomTile(room: r);

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

  Widget _buildOccupancyChartCard(List<Room> rooms) {
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
            _buildMiniFloorSection('Floor 1', floor1),
            const SizedBox(height: 6),

            _buildMiniFloorSection('Floor 2', floor2),
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

  Widget _buildMiniFloorSection(String label, List<Room> rooms) {
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

  Widget _buildGoingToVacateCard() {
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
                Flexible(
                  child: Text(
                    'Going to Vacate Rooms',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppColors.navyDark,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 125,
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
                        itemBuilder: (_, i) {
                          final b = vacating[i];
                          return Container(
                            width: 210,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFFE0E0E0),
                              ),
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
                                      colors: [
                                        Color(0xFF2E4A7A),
                                        Color(0xFF1C2B4A),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.horizontal(
                                      left: Radius.circular(9),
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.bed,
                                        size: 26,
                                        color: Colors.white,
                                      ),
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
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 8,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
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
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStatusChangerCard(
    BuildContext context,
    DashboardState state,
  ) {
    final cubit = context.read<DashboardCubit>();
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
              'Quick Room Status Changer & Actions',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppColors.navyDark,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<Room>(
              initialValue: state.selectedQuickRoom,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Room #',
                isDense: true,
              ),
              items: state.rooms
                  .map(
                    (r) => DropdownMenuItem(
                      value: r,
                      child: Text(
                        '${r.number}  (${r.status.name})',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (r) => cubit.selectQuickRoom(r),
            ),
            const SizedBox(height: 4),
            const Text(
              'Enter number',
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: state.selectedQuickRoom == null
                    ? null
                    : () {
                        final room = state.selectedQuickRoom!;
                        cubit.completeQuickCleaning();
                        AppToast.showSuccess(
                          context,
                          'Housekeeping complete: Room ${room.number} is now Available and ready for check-in.',
                          title: 'Room Ready',
                        );
                      },
                icon: const Icon(Icons.check_circle_outline, size: 16),
                label: const Text(
                  'Cleaning done, ready to serve',
                  style: TextStyle(fontSize: 12),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  cubit.setAllDirtyToAvailable();
                  AppToast.showSuccess(
                    context,
                    'Housekeeping batch update: All dirty rooms have been serviced and marked as Available.',
                    title: 'Rooms Updated',
                  );
                },
                child: const Text(
                  'Set all Dirty to Cleaning',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _showMaintenanceRooms(context, state.rooms),
                child: const Text(
                  'View All Maintenance',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DashboardCubit(),
      child: Scaffold(
        backgroundColor: AppColors.bgLight,
        body: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: BlocBuilder<DashboardCubit, DashboardState>(
                builder: (context, state) {
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 1024;

                      return SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Main Dashboard',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.navyDark,
                              ),
                            ),
                            const SizedBox(height: 16),

                            if (isWide)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: _buildNavTilesCard(context)),
                                  const SizedBox(width: 16),
                                  SizedBox(
                                    width: 280,
                                    child: _buildOperationalOverview(
                                      state.rooms,
                                    ),
                                  ),
                                ],
                              )
                            else
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildNavTilesCard(context),
                                  const SizedBox(height: 16),
                                  _buildOperationalOverview(state.rooms),
                                ],
                              ),
                            const SizedBox(height: 16),

                            if (isWide)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: _buildFloorViewCard(
                                      context,
                                      state.rooms,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  SizedBox(
                                    width: 280,
                                    child: _buildOccupancyChartCard(
                                      state.rooms,
                                    ),
                                  ),
                                ],
                              )
                            else
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildFloorViewCard(context, state.rooms),
                                  const SizedBox(height: 16),
                                  _buildOccupancyChartCard(state.rooms),
                                ],
                              ),
                            const SizedBox(height: 16),

                            if (isWide)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: _buildGoingToVacateCard(),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    flex: 2,
                                    child: _buildQuickStatusChangerCard(
                                      context,
                                      state,
                                    ),
                                  ),
                                ],
                              )
                            else
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildGoingToVacateCard(),
                                  const SizedBox(height: 16),
                                  _buildQuickStatusChangerCard(context, state),
                                ],
                              ),
                          ],
                        ),
                      );
                    },
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

class _NavItem {
  final String label;
  final IconData icon;
  final Color iconBg;
  final String? badge;
  final VoidCallback? onTap;

  const _NavItem(this.label, this.icon, this.iconBg, {this.badge, this.onTap});
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

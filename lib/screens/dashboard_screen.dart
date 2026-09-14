import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:hotel_booking/config/app_colors.dart';
import '../models/booking.dart';
import '../models/room.dart';
import '../widgets/room_status_legend.dart';
import '../widgets/room_tile.dart';
import '../widgets/stat_card.dart';
import '../config/app_toast.dart';
import 'check_in_screen.dart';
import 'check_out_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late List<Room> _rooms;
  Room? _selectedQuickRoom;

  @override
  void initState() {
    super.initState();
    _rooms = List.from(Room.allRooms);
  }

  double _occupancyPct() {
    if (_rooms.isEmpty) return 0;
    return _rooms.where((r) => r.status == RoomStatus.occupied).length /
        _rooms.length *
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

  void _setRoomStatus(Room room, RoomStatus status) {
    setState(() => room.status = status);
  }

  void _setAllDirtyToAvailable() {
    setState(() {
      for (final r in _rooms) {
        if (r.status == RoomStatus.dirty) r.status = RoomStatus.available;
      }
    });
    AppToast.showSuccess(
      context,
      'Housekeeping batch update: All dirty rooms have been serviced and marked as Available.',
      title: 'Rooms Updated',
    );
  }

  void _showRoomQuickEdit(Room room) {
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
                _setRoomStatus(room, selected);
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

  void _showMaintenanceRooms() {
    final rooms = _rooms
        .where((r) => r.status == RoomStatus.maintenance)
        .toList();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Maintenance Rooms'),
        content: rooms.isEmpty
            ? const Text('No rooms currently under maintenance.')
            : SizedBox(
                width: 300,
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: rooms.length,
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
                    title: Text('Room ${rooms[i].number}'),
                    subtitle: Text(
                      'Floor ${rooms[i].floor}  —  ${rooms[i].type}',
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

  void _navigateTo(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen)).then((
      _,
    ) {
      setState(() {
        _rooms = List.from(Room.allRooms);
      });
    });
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

  Widget _buildTopBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
          const SizedBox(width: 24),

          Expanded(
            child: SizedBox(
              height: 36,
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search guests, rooms, reservations, staff...',
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
          const SizedBox(width: 16),
          Text(
            _formatDate(DateTime.now()),
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.attach_money, size: 16),
            label: const Text('Quick Actions', style: TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.navyDark,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
            iconSize: 22,
          ),
          const CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.navyDark,
            child: Icon(Icons.person, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildNavTilesCard() {
    final items = <_NavItem>[
      _NavItem(
        'Guest Check-in',
        Icons.input_rounded,
        const Color(0xFF4DB6AC),
        onTap: () => _navigateTo(const CheckInScreen()),
      ),
      _NavItem(
        'Guest Check-Out',
        Icons.output_rounded,
        const Color(0xFFEF9A9A),
        onTap: () => _navigateTo(const CheckOutScreen()),
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
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 6,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.0,
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

  Widget _buildOperationalOverview() {
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
                          value: '${_occupancyPct().toStringAsFixed(0)}%',
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

  Widget _buildFloorViewCard() {
    final floor1 = _rooms.where((r) => r.floor == 1).toList();
    final floor2 = _rooms.where((r) => r.floor == 2).toList();

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
            _buildFloorSection('Floor 1', floor1),
            const SizedBox(height: 14),
            _buildFloorSection('Floor 2', floor2),
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
    String label,
    List<Room> rooms, {
    bool interactive = true,
  }) {
    final row1 = rooms.take(13).toList();
    final row2 = rooms.skip(13).toList();

    Widget tile(Room r) => interactive
        ? RoomTile(room: r, onTap: () => _showRoomQuickEdit(r))
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

  Widget _buildOccupancyChartCard() {
    final floor1 = _rooms.where((r) => r.floor == 1).toList();
    final floor2 = _rooms.where((r) => r.floor == 2).toList();
    final occupied = _rooms
        .where((r) => r.status == RoomStatus.occupied)
        .length;
    final total = _rooms.length;
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

  Widget _buildQuickStatusChangerCard() {
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
              initialValue: _selectedQuickRoom,
              decoration: const InputDecoration(
                labelText: 'Room #',
                isDense: true,
              ),
              items: _rooms
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
              onChanged: (r) => setState(() => _selectedQuickRoom = r),
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
                onPressed: _selectedQuickRoom == null
                    ? null
                    : () {
                        _setRoomStatus(
                          _selectedQuickRoom!,
                          RoomStatus.available,
                        );
                        AppToast.showSuccess(
                          context,
                          'Housekeeping complete: Room ${_selectedQuickRoom!.number} is now Available and ready for check-in.',
                          title: 'Room Ready',
                        );
                        setState(() => _selectedQuickRoom = null);
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
                onPressed: _setAllDirtyToAvailable,
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
                onPressed: _showMaintenanceRooms,
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
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: Column(
        children: [
          _buildTopBar(),
          Expanded(
            child: SingleChildScrollView(
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

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildNavTilesCard()),
                      const SizedBox(width: 16),
                      SizedBox(width: 280, child: _buildOperationalOverview()),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildFloorViewCard()),
                      const SizedBox(width: 16),
                      SizedBox(width: 280, child: _buildOccupancyChartCard()),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: _buildGoingToVacateCard()),
                      const SizedBox(width: 16),
                      Expanded(flex: 2, child: _buildQuickStatusChangerCard()),
                    ],
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

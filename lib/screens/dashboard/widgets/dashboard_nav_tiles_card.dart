import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../cubits/dashboard/dashboard_cubit.dart';
import 'package:hotel_booking/routes/app_routes.dart';

class DashboardNavTilesCard extends StatelessWidget {
  const DashboardNavTilesCard({super.key});

  Future<void> _navigateTo(BuildContext context, String routePath) async {
    final cubit = context.read<DashboardCubit>();
    await context.push(routePath);
    cubit.reloadRooms();
  }

  @override
  Widget build(BuildContext context) {
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
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 6,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.0,
          ),
          itemCount: items.length,
          itemBuilder: (_, i) => _NavTile(item: items[i]),
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final _NavItem item;

  const _NavTile({required this.item});

  @override
  Widget build(BuildContext context) {
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
}

class _NavItem {
  final String label;
  final IconData icon;
  final Color iconBg;
  final String? badge;
  final VoidCallback? onTap;

  const _NavItem(this.label, this.icon, this.iconBg, {this.badge, this.onTap});
}

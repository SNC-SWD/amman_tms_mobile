import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:timeago/timeago.dart' as timeago;

const kPrimaryBlue = Color(0xFF163458);
const kAccentGold = Color(0xFFC88C2C);
const kLightGray = Color(0xFFF4F6F9);
const kSlateGray = Color(0xFF4C5C74);
const kSoftGold = Color(0xFFE0B352);
const kBlueTint = Color(0xFFE6EDF6);

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: kPrimaryBlue,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: kLightGray,
        appBar: AppBar(
          backgroundColor: kPrimaryBlue,
          elevation: 0,
          title: const Text(
            'Notifications',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.done_all_rounded),
              onPressed: () {},
              tooltip: 'Mark all as read',
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            _buildNotificationItem(
              icon: Icons.directions_bus_rounded,
              title: 'New Route Assignment',
              message: 'You have been assigned to route TS → Mining Office',
              time: DateTime.now().subtract(const Duration(minutes: 5)),
              isUnread: true,
              color: kAccentGold,
            ),
            _buildNotificationItem(
              icon: Icons.groups_rounded,
              title: 'Passenger Update',
              message: '45 passengers confirmed for route Benete → TS',
              time: DateTime.now().subtract(const Duration(hours: 1)),
              isUnread: true,
              color: kSoftGold,
            ),
            _buildNotificationItem(
              icon: Icons.schedule_rounded,
              title: 'Schedule Change',
              message: 'Route TS → Mining Office time changed to 09:00',
              time: DateTime.now().subtract(const Duration(hours: 2)),
              isUnread: false,
              color: kPrimaryBlue,
            ),
            _buildNotificationItem(
              icon: Icons.warning_rounded,
              title: 'System Maintenance',
              message: 'System will be down for maintenance tonight at 23:00',
              time: DateTime.now().subtract(const Duration(hours: 3)),
              isUnread: false,
              color: Colors.red,
            ),
            _buildNotificationItem(
              icon: Icons.check_circle_rounded,
              title: 'Route Completed',
              message: 'Route Benete → TS has been completed successfully',
              time: DateTime.now().subtract(const Duration(hours: 5)),
              isUnread: false,
              color: Colors.green,
            ),
            _buildNotificationItem(
              icon: Icons.assignment_rounded,
              title: 'Monthly Report',
              message: 'Your monthly performance report is now available',
              time: DateTime.now().subtract(const Duration(days: 1)),
              isUnread: false,
              color: kSlateGray,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem({
    required IconData icon,
    required String title,
    required String message,
    required DateTime time,
    required bool isUnread,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: kPrimaryBlue.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontWeight: isUnread
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                fontSize: 16,
                                color: isUnread ? kPrimaryBlue : kSlateGray,
                              ),
                            ),
                          ),
                          if (isUnread)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: kAccentGold,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        message,
                        style: TextStyle(
                          color: kSlateGray.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        timeago.format(time, locale: 'en_short'),
                        style: TextStyle(
                          color: kSlateGray.withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Notifications',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add),
                label: const Text('New Notification'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: 10,
              itemBuilder: (context, index) {
                final isUnread = index < 2;
                return Card(
                  elevation: isUnread ? 2 : 0,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: isUnread 
                          ? Theme.of(context).primaryColor 
                          : Colors.grey[300],
                      child: Icon(
                        Icons.message,
                        color: isUnread ? Colors.white : Colors.grey[600],
                      ),
                    ),
                    title: Text(
                      'Match Schedule Update - Team $index',
                      style: TextStyle(
                        fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Please check the updated schedule. The location has been moved to Field B.',
                        style: TextStyle(
                          color: isUnread ? Theme.of(context).textTheme.bodyLarge?.color : Colors.grey[600],
                        ),
                      ),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${index + 1}h ago',
                          style: TextStyle(
                            color: isUnread ? Theme.of(context).primaryColor : Colors.grey[500],
                            fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        if (isUnread) ...[
                          const SizedBox(height: 4),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    onTap: () {},
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

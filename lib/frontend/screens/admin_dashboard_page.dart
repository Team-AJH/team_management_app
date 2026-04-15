import 'package:flutter/material.dart';
import 'admin_group_dashboard_page.dart';

// Currently using a local mock. In the future, this might be imported from models.
class MockAdminGroup {
  final String id;
  final String name;
  final String role;
  final String? description;
  final String? sport;

  MockAdminGroup({
    required this.id,
    required this.name,
    required this.role,
    this.description,
    this.sport,
  });
}

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final List<MockAdminGroup> managedGroups = [
    MockAdminGroup(id: 'g1', name: 'Team Sharks', role: 'Head Coach'),
    MockAdminGroup(id: 'g2', name: 'Team Shrimps', role: 'Assistant Coach'),
    MockAdminGroup(id: 'g3', name: 'Team Dolphins', role: 'Organizer'),
  ];

  void _showCreateTeamDialog() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final sportController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create New Team'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Team Name'),
                    validator: (value) =>
                        value == null || value.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(labelText: 'Description'),
                    validator: (value) =>
                        value == null || value.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: sportController,
                    decoration: const InputDecoration(labelText: 'Sport'),
                    validator: (value) =>
                        value == null || value.trim().isEmpty ? 'Required' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  setState(() {
                    managedGroups.add(
                      MockAdminGroup(
                        id: 'g${managedGroups.length + 1}',
                        name: nameController.text.trim(),
                        role: 'Organizer', // Default role for creator
                        description: descriptionController.text.trim(),
                        sport: sportController.text.trim(),
                      ),
                    );
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Admin Groups',
                style: Theme.of(
                  context,
                ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: _showCreateTeamDialog,
                icon: const Icon(Icons.add),
                label: const Text('Create Team'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Select a group to manage its administrative dashboard.',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: managedGroups.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final group = managedGroups[index];
              return Card(
                elevation: 2,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AdminGroupDashboardPage(groupName: group.name),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).primaryColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.group,
                            color: Theme.of(context).primaryColor,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                group.name,
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                group.role,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: Colors.grey[700]),
                              ),
                              if (group.sport != null || group.description != null) ...[
                                const SizedBox(height: 4),
                                if (group.sport != null)
                                  Text(
                                    'Sport: ${group.sport}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                if (group.description != null)
                                  Text(
                                    group.description!,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontStyle: FontStyle.italic,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../backend/repositories/group_repository.dart';
import '../../backend/repositories/user_repository.dart';
import '../../backend/models/app_user.dart';
import '../../backend/data/user_data.dart';

class CreateGroupPage extends StatefulWidget {
  const CreateGroupPage({super.key});

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _sportController = TextEditingController();

  List<AppUser> _allUsers = [];
  final Set<String> _selectedUserIds = {};
  bool _isLoading = true;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userRepo = Provider.of<UserRepository>(context, listen: false);
      final users = await userRepo.getKnownUsers(user.uid);
      if (mounted) {
        setState(() {
          _allUsers = users;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _createGroup() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      _isCreating = true;
    });

    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    final sport = _sportController.text.trim();

    try {
      final additionalMembers = _selectedUserIds.map((uid) {
        final u = _allUsers.firstWhere((usr) => usr.uid == uid);
        return {'uid': u.uid, 'displayName': u.displayName};
      }).toList();

      final groupRepo = Provider.of<GroupRepository>(context, listen: false);
      final appUser = await UserData().getUserById(user.uid);

      await groupRepo.createGroup(
        name: name,
        description: description,
        sportType: sport,
        creatorUserId: user.uid,
        creatorDisplayName: appUser?.displayName ?? user.displayName ?? 'Creator',
        additionalMembers: additionalMembers,
      );

      if (mounted) {
        Navigator.pop(context, true); // Return true indicating success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating team: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Team'),
        actions: [
          if (!_isCreating)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _createGroup,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Team Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _sportController,
                      decoration: const InputDecoration(
                        labelText: 'Sport Type',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 24),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Add Members from Other Teams:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: _allUsers.isEmpty
                          ? const Center(child: Text('No known users available.'))
                          : ListView.builder(
                              itemCount: _allUsers.length,
                              itemBuilder: (context, index) {
                                final user = _allUsers[index];
                                final isSelected = _selectedUserIds.contains(user.uid);

                                return CheckboxListTile(
                                  title: Text(user.displayName),
                                  value: isSelected,
                                  onChanged: (bool? value) {
                                    setState(() {
                                      if (value == true) {
                                        _selectedUserIds.add(user.uid);
                                      } else {
                                        _selectedUserIds.remove(user.uid);
                                      }
                                    });
                                  },
                                );
                              },
                            ),
                    ),
                    if (_isCreating)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}

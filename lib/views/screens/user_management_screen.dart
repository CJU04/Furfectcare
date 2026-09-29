import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:vetcare_connect/config/theme/app_theme.dart';
import 'package:vetcare_connect/providers/auth_provider.dart';
import 'package:vetcare_connect/providers/firebase_user_provider.dart';
import 'package:vetcare_connect/views/widgets/drawer_widget.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortOption = 'Name (A-Z)';
  static const _sortOptions = <String>[
    'Name (A-Z)',
    'Name (Z-A)',
    'Role',
    'Status',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FirebaseUserProvider>(context, listen: false).loadUsers();
    });
  }

  void _showUserDetailsDialog(FirebaseUser user) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('User Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${user.name}'),
            const SizedBox(height: 8),
            Text('Email: ${user.email}'),
            const SizedBox(height: 8),
            Text('Role: ${user.role.value}'),
            const SizedBox(height: 8),
            Text('Status: ${user.approved ? 'Approved' : 'Pending'}'),
            if (user.contactNumber.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Contact: ${user.contactNumber}'),
            ],
            if (user.address.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Address: ${user.address}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _resetUserPassword(
      BuildContext context, FirebaseUser user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reset Password'),
        content: Text('Send password reset email to ${user.email}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Send Reset Email'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sending password reset email...')),
    );

    try {
      await Provider.of<AuthProvider>(context, listen: false)
          .sendPasswordResetEmail(email: user.email);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password reset email sent to ${user.email}')),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send password reset email')),
      );
    }
  }

  Future<void> _confirmAndDeleteUser(FirebaseUser user) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete ${user.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (ok != true) return;

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Deleting ${user.name}...')),
    );

    try {
      await Provider.of<FirebaseUserProvider>(context, listen: false)
          .deleteUser(user.uid);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${user.name} deleted successfully')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete user')),
      );
    }
  }

  Future<void> _confirmAndApproveUser(FirebaseUser user) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Approve User'),
        content: Text('Are you sure you want to approve ${user.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Approve', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );

    if (ok != true) return;

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Approving ${user.name}...')),
    );

    try {
      final updated = FirebaseUser(
        uid: user.uid,
        name: user.name,
        email: user.email,
        role: user.role,
        approved: true,
        contactNumber: user.contactNumber,
        address: user.address,
        imageUrl: user.imageUrl,
        photoUrl: user.photoUrl,
      );
      await Provider.of<FirebaseUserProvider>(context, listen: false)
          .updateUser(updated);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${user.name} approved successfully')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to approve user')),
      );
    }
  }

  Future<void> _confirmAndRejectUser(FirebaseUser user) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reject User'),
        content: Text('Are you sure you want to reject ${user.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Reject', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (ok != true) return;

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Rejecting ${user.name}...')),
    );

    try {
      final updated = FirebaseUser(
        uid: user.uid,
        name: user.name,
        email: user.email,
        role: user.role,
        approved: false,
        contactNumber: user.contactNumber,
        address: user.address,
        imageUrl: user.imageUrl,
        photoUrl: user.photoUrl,
      );
      await Provider.of<FirebaseUserProvider>(context, listen: false)
          .updateUser(updated);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${user.name} rejected')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to reject user')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    // Show loading if auth is still loading
    if (auth.role == null) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (auth.role != UserRole.admin &&
        auth.role != UserRole.staff &&
        auth.role != UserRole.veterinarian) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text(
                'Access Denied',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('Admin, Staff, or Veterinarian privileges required'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<FirebaseUserProvider>(context, listen: false)
                  .loadUsers();
            },
          ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: '/user_management'),
      body: LayoutBuilder(
        builder: (context, constraints) {
          double maxWidth = constraints.maxWidth > 600 ? 800 : double.infinity;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            labelText: 'Search Users',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      DropdownButton<String>(
                        value: _sortOption,
                        items: _sortOptions
                            .map((option) => DropdownMenuItem(
                                value: option, child: Text(option)))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _sortOption = value;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Consumer<FirebaseUserProvider>(
                  builder: (context, userProvider, child) {
                    List<FirebaseUser> users = userProvider.users;

                    if (_searchQuery.trim().isNotEmpty) {
                      final q = _searchQuery.trim().toLowerCase();
                      users = users.where((u) {
                        final nameLower = u.name.toLowerCase();
                        final emailLower = u.email.toLowerCase();
                        final roleLower = u.role.value.toLowerCase();
                        return nameLower.contains(q) ||
                            emailLower.contains(q) ||
                            roleLower.contains(q);
                      }).toList();
                    }

                    // Copy before sorting: userProvider.users is the provider's
                    // internal list — sorting it directly would mutate shared state.
                    users = List<FirebaseUser>.from(users);
                    switch (_sortOption) {
                      case 'Name (Z-A)':
                        users.sort((a, b) => b.name
                            .toLowerCase()
                            .compareTo(a.name.toLowerCase()));
                        break;
                      case 'Role':
                        users.sort(
                            (a, b) => a.role.value.compareTo(b.role.value));
                        break;
                      case 'Status':
                        users.sort((a, b) {
                          final aApproved = a.approved ? 0 : 1;
                          final bApproved = b.approved ? 0 : 1;
                          return aApproved.compareTo(bApproved);
                        });
                        break;
                      default:
                        users.sort((a, b) => a.name
                            .toLowerCase()
                            .compareTo(b.name.toLowerCase()));
                    }

                    if (users.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline,
                                size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            const Text(
                              'No users found',
                              style:
                                  TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: EdgeInsets.symmetric(
                        horizontal: maxWidth > 600 ? (maxWidth - 800) / 2 : 0,
                      ),
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index];

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 6.0,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () => _showUserDetailsDialog(user),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 22,
                                          backgroundColor: AppTheme.primaryGreen
                                              .withValues(alpha: 0.15),
                                          child: Text(
                                            user.name.isNotEmpty
                                                ? user.name[0].toUpperCase()
                                                : 'U',
                                            style: const TextStyle(
                                              color: AppTheme.primaryGreen,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                user.name,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 1),
                                              Text(
                                                user.email,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey.shade700,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 1),
                                              Text(
                                                user.role.value.toUpperCase(),
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.grey.shade600,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: user.approved
                                                ? Colors.green
                                                    .withValues(alpha: 0.1)
                                                : Colors.orange
                                                    .withValues(alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            user.approved
                                                ? 'Approved'
                                                : 'Pending',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: user.approved
                                                  ? Colors.green.shade700
                                                  : Colors.orange.shade700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (auth.role == UserRole.admin) ...[
                                  const SizedBox(width: 10),
                                  if (user.role == UserRole.staff ||
                                      user.role == UserRole.veterinarian)
                                    if (!user.approved) ...[
                                      IconButton(
                                        icon: const Icon(Icons.check_circle,
                                            size: 20, color: Colors.green),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(
                                          minWidth: 32,
                                          minHeight: 32,
                                        ),
                                        onPressed: () =>
                                            _confirmAndApproveUser(user),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.cancel,
                                            size: 20, color: Colors.red),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(
                                          minWidth: 32,
                                          minHeight: 32,
                                        ),
                                        onPressed: () =>
                                            _confirmAndRejectUser(user),
                                      ),
                                    ],
                                  IconButton(
                                    icon: const Icon(Icons.lock_reset_rounded,
                                        size: 20, color: Colors.blue),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 32,
                                      minHeight: 32,
                                    ),
                                    onPressed: () =>
                                        _resetUserPassword(context, user),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        size: 20, color: Colors.red),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 32,
                                      minHeight: 32,
                                    ),
                                    onPressed: () =>
                                        _confirmAndDeleteUser(user),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

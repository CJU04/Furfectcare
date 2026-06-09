import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io' as io;

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';


import 'package:vetcare_connect/providers/auth_provider.dart';
import 'package:vetcare_connect/providers/firebase_user_provider.dart';
import 'package:vetcare_connect/views/widgets/drawer_widget.dart';
import 'package:vetcare_connect/config/theme/app_theme.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullnameController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  io.File? _profileImage;
  final ImagePicker _picker = ImagePicker();
  bool _isEditing = false;
  bool _profileLoaded = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_profileLoaded) {
      _loadProfile();
    }
  }

  void _loadProfile() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final firebaseUserProvider = Provider.of<FirebaseUserProvider>(context, listen: false);
    final currentUser = firebaseUserProvider.currentUser;
    if (currentUser != null) {
      _fullnameController.text = auth.displayName ?? currentUser.fullname;
      _contactNumberController.text = currentUser.contactNumber;
      _emailController.text = currentUser.email;
      _addressController.text = currentUser.address;
      _profileLoaded = true;
      return;
    }
    // currentUser not synced yet — fetch directly from Firestore
    final uid = auth.firebaseUser?.uid;
    if (uid != null) {
      firebaseUserProvider.getUserByUid(uid).then((user) {
        if (user != null && mounted) {
          _fullnameController.text = auth.displayName ?? user.fullname;
          _contactNumberController.text = user.contactNumber;
          _emailController.text = user.email;
          _addressController.text = user.address;
          _profileLoaded = true;
          setState(() {});
        }
      });
    }
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
    });
  }

  void _cancelEditing() {
    _loadProfile(); // reload original values
    setState(() {
      _isEditing = false;
    });
  }

  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final firebaseUserProvider = Provider.of<FirebaseUserProvider>(context, listen: false);
      final currentUser = firebaseUserProvider.currentUser;
      final uid = Provider.of<AuthProvider>(context, listen: false).firebaseUser?.uid;

      if (currentUser != null) {
        final updatedUser = currentUser.copyWith(
          name: _fullnameController.text,
          contactNumber: _contactNumberController.text,
          email: _emailController.text,
          address: _addressController.text,
        );
        await firebaseUserProvider.updateUser(updatedUser);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        setState(() {
          _isEditing = false;
        });
        return;
      }

      // currentUser was null — fetch and update directly
      if (uid != null) {
        final user = await firebaseUserProvider.getUserByUid(uid);
        if (user != null) {
          final updatedUser = user.copyWith(
            name: _fullnameController.text,
            contactNumber: _contactNumberController.text,
            email: _emailController.text,
            address: _addressController.text,
          );
          await firebaseUserProvider.updateUser(updatedUser);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully!')),
          );
          setState(() {
            _isEditing = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final firebaseUserProvider = Provider.of<FirebaseUserProvider>(context);
    final currentUser = firebaseUserProvider.currentUser;
    final displayName = auth.displayName ?? currentUser?.fullname;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Settings'),
        actions: [
          if (!_isEditing)
            IconButton(
              onPressed: _startEditing,
              icon: const Icon(Icons.edit, color: Colors.white),
              tooltip: 'Edit Profile',
            )
          else
            IconButton(
              onPressed: _cancelEditing,
              icon: const Icon(Icons.close, color: Colors.white),
              tooltip: 'Cancel',
            ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: '/profile_settings'),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth > 600 ? 500.0 : double.infinity;
          return Scrollbar(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 16),
                        Center(
                          child: SizedBox(
                            width: 96,
                            height: 96,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                CircleAvatar(
                                  key: ValueKey(_profileImage?.path),
                                  radius: 44,
                                  backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.2),
                                  backgroundImage: _getProfileImage(),
                                  child: _profileImage == null &&
                                      (currentUser?.photoUrl == null || currentUser!.photoUrl!.isEmpty) &&
                                      (currentUser?.imageUrl == null || currentUser!.imageUrl!.isEmpty)
                                      ? Text(
                                          (displayName?.trim().isNotEmpty == true)
                                              ? displayName!.trim()[0].toUpperCase()
                                              : 'U',
                                          style: const TextStyle(fontSize: 36, color: AppTheme.primaryGreen, fontWeight: FontWeight.bold),
                                        )
                                      : null,
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: CircleAvatar(
                                    radius: 12,
                                    backgroundColor: Theme.of(context).colorScheme.secondary,
                                    child: IconButton(
                                      icon: const Icon(Icons.camera_alt, size: 12, color: Colors.white),
                                      onPressed: _pickImage,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _fullnameController,
                readOnly: !_isEditing,
                style: TextStyle(
                  color: _isEditing ? null : Colors.grey.shade700,
                ),
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: const Icon(Icons.person),
                  border: const OutlineInputBorder(),
                  filled: !_isEditing,
                  fillColor: !_isEditing ? Colors.grey.shade100 : null,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your full name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contactNumberController,
                readOnly: !_isEditing,
                style: TextStyle(
                  color: _isEditing ? null : Colors.grey.shade700,
                ),
                decoration: InputDecoration(
                  labelText: 'Contact Number',
                  prefixIcon: const Icon(Icons.phone),
                  border: const OutlineInputBorder(),
                  filled: !_isEditing,
                  fillColor: !_isEditing ? Colors.grey.shade100 : null,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your contact number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                readOnly: true,
                style: TextStyle(color: Colors.grey.shade700),
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email),
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                readOnly: !_isEditing,
                style: TextStyle(
                  color: _isEditing ? null : Colors.grey.shade700,
                ),
                decoration: InputDecoration(
                  labelText: 'Address',
                  prefixIcon: const Icon(Icons.home),
                  border: const OutlineInputBorder(),
                  filled: !_isEditing,
                  fillColor: !_isEditing ? Colors.grey.shade100 : null,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              if (_isEditing)
                ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Save Changes'),
                ),
              ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  ImageProvider? _getProfileImage() {
    final firebaseUserProvider = Provider.of<FirebaseUserProvider>(context, listen: false);
    final currentUser = firebaseUserProvider.currentUser;
    if (_profileImage != null) {
      return FileImage(_profileImage!);
    }
    if (currentUser?.photoUrl != null && currentUser!.photoUrl!.isNotEmpty) {
      return CachedNetworkImageProvider(currentUser!.photoUrl!);
    }
    if (currentUser?.imageUrl != null && currentUser!.imageUrl!.isNotEmpty) {
      return CachedNetworkImageProvider(currentUser!.imageUrl!);
    }
    return null;
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Photo Library'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                  if (image != null) {
                    await _saveImageToAppDirectory(image);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final XFile? image = await _picker.pickImage(source: ImageSource.camera);
                  if (image != null) {
                    await _saveImageToAppDirectory(image);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveImageToAppDirectory(XFile image) async {
    // For web paths, just store locally in memory.
    if (image.path.startsWith('http') || image.path.startsWith('blob:') || image.path.startsWith('data:')) {
      return;
    }

    // Mobile/desktop: copy to local documents directory.
    final directory = await getApplicationDocumentsDirectory();
    final fileName = path.basename(image.path);
    final savedImage = await io.File(image.path).copy('${directory.path}/$fileName');

    if (!mounted) return;
    setState(() {
      _profileImage = savedImage;
    });
  }


  @override
  void dispose() {
    _fullnameController.dispose();
    _contactNumberController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}


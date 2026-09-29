import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:vetcare_connect/utils/platform_image_picker.dart';

import 'package:vetcare_connect/providers/auth_provider.dart';
import 'package:vetcare_connect/providers/firebase_user_provider.dart';
import 'package:vetcare_connect/services/storage_service.dart';
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
  PickedFileData? _profileImage;
  final ImagePicker _picker = ImagePicker();
  bool _isEditing = false;
  bool _isSaving = false;
  double? _uploadProgress;
  String? _uploadedPhotoUrl;
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
    final firebaseUserProvider =
        Provider.of<FirebaseUserProvider>(context, listen: false);
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
    _profileImage = null; // Reset any selected image
    _uploadedPhotoUrl = null;
    _loadProfile(); // reload original values
    setState(() {
      _isEditing = false;
    });
  }

  Future<void> _saveProfile() async {
    if (_isSaving || !_formKey.currentState!.validate()) return;
    final users = context.read<FirebaseUserProvider>();
    final uid = context.read<AuthProvider>().firebaseUser?.uid;
    if (uid == null) return;
    setState(() {
      _isSaving = true;
      _uploadProgress = _profileImage == null ? null : 0;
    });
    try {
      if (_profileImage != null && _uploadedPhotoUrl == null) {
        _uploadedPhotoUrl = await StorageService.instance.uploadPickedFile(
          data: _profileImage!,
          folder: 'profile_pictures',
          referenceName: 'profile_$uid',
          onProgress: (value) {
            if (mounted) setState(() => _uploadProgress = value);
          },
        );
      }
      if (mounted) setState(() => _uploadProgress = null);
      final user =
          await users.getUserByUid(uid).timeout(const Duration(seconds: 30));
      if (user == null)
        throw StateError('Profile not found. Please sign in again.');
      await users
          .updateUser(user.copyWith(
            name: _fullnameController.text.trim(),
            email: _emailController.text.trim(),
            contactNumber: _contactNumberController.text.trim(),
            address: _addressController.text.trim(),
            photoUrl: _uploadedPhotoUrl ?? user.photoUrl,
          ))
          .timeout(const Duration(seconds: 30));
      if (!mounted) return;
      _cancelEditing();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
    } catch (e) {
      // Retain the selection and completed upload URL for a safe retry.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'Could not finish saving your profile. Check your connection '
              'and retry. If a save timed out, refresh first to check whether it completed. $e'),
        ));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
              icon: Icon(
                Icons.edit,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
              tooltip: 'Edit Profile',
            )
          else
            IconButton(
              onPressed: _cancelEditing,
              icon: Icon(
                Icons.close,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
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
                                  key: ValueKey(_profileImage),
                                  radius: 44,
                                  backgroundColor: AppTheme.primaryGreen
                                      .withValues(alpha: 0.2),
                                  backgroundImage: _getProfileImage(),
                                  child: _profileImage == null &&
                                          (currentUser?.photoUrl.isEmpty ??
                                              true) &&
                                          (currentUser?.imageUrl.isEmpty ??
                                              true)
                                      ? Text(
                                          (displayName?.trim().isNotEmpty ==
                                                  true)
                                              ? displayName!
                                                  .trim()[0]
                                                  .toUpperCase()
                                              : 'U',
                                          style: const TextStyle(
                                              fontSize: 36,
                                              color: AppTheme.primaryGreen,
                                              fontWeight: FontWeight.bold),
                                        )
                                      : null,
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: CircleAvatar(
                                    radius: 12,
                                    backgroundColor:
                                        Theme.of(context).colorScheme.secondary,
                                    child: IconButton(
                                      icon: Icon(
                                        Icons.camera_alt,
                                        size: 12,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSecondary,
                                      ),
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
                            color: _isEditing
                                ? null
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Full Name',
                            prefixIcon: const Icon(Icons.person),
                            border: const OutlineInputBorder(),
                            filled: !_isEditing,
                            fillColor: !_isEditing
                                ? Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerLow
                                : null,
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
                            color: _isEditing
                                ? null
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Contact Number',
                            prefixIcon: const Icon(Icons.phone),
                            border: const OutlineInputBorder(),
                            filled: !_isEditing,
                            fillColor:
                                !_isEditing ? Colors.grey.shade100 : null,
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
                            fillColor:
                                !_isEditing ? Colors.grey.shade100 : null,
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
                            onPressed: _isSaving ? null : _saveProfile,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: _isSaving
                                ? Column(children: [
                                    LinearProgressIndicator(
                                        value: _uploadProgress),
                                    const SizedBox(height: 8),
                                    Text(_uploadProgress == null
                                        ? 'Saving profile…'
                                        : 'Uploading photo ${(_uploadProgress! * 100).round()}%'),
                                  ])
                                : const Text('Save Changes'),
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
    final firebaseUserProvider =
        Provider.of<FirebaseUserProvider>(context, listen: false);
    final currentUser = firebaseUserProvider.currentUser;
    if (_profileImage != null) {
      return _profileImage!.previewProvider;
    }
    final photoUrl = currentUser?.photoUrl;
    final imageUrl = currentUser?.imageUrl;
    if (photoUrl != null && photoUrl.isNotEmpty) {
      return CachedNetworkImageProvider(photoUrl);
    }
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return CachedNetworkImageProvider(imageUrl);
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
                  final XFile? image =
                      await _picker.pickImage(source: ImageSource.gallery);
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
                  final XFile? image =
                      await _picker.pickImage(source: ImageSource.camera);
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
    final bytes = await image.readAsBytes();
    if (bytes.isEmpty) throw StateError('The selected image is empty.');
    if (bytes.length > PlatformImagePicker.maxImageBytes) {
      throw PickedFileTooLargeException('Choose an image smaller than 5 MB.');
    }
    if (!mounted) return;
    setState(() {
      _profileImage = PickedFileData(
        name: image.name,
        bytes: bytes,
        mimeType: PickedFileData.mimeForName(image.name),
        size: bytes.length,
      );
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

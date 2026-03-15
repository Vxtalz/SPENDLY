import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _client = Supabase.instance.client;
  bool _isLoading = false;

  late TextEditingController _usernameController;
  late TextEditingController _avatarUrlController;
  late TextEditingController _bioController;

  @override
  void initState() {
    super.initState();
    final user = _client.auth.currentUser;
    final metadata = user?.userMetadata ?? {};
    
    _usernameController = TextEditingController(text: metadata['full_name'] ?? '');
    _avatarUrlController = TextEditingController(text: metadata['avatar_url'] ?? '');
    _bioController = TextEditingController(text: metadata['bio'] ?? '');
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _avatarUrlController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    setState(() => _isLoading = true);
    
    try {
      await _client.auth.updateUser(
        UserAttributes(
          data: {
            'full_name': _usernameController.text.trim(),
            'avatar_url': _avatarUrlController.text.trim(),
            'bio': _bioController.text.trim(),
          },
        ),
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _client.auth.currentUser;
    final avatarUrl = _avatarUrlController.text.trim();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        elevation: 0,
      ),
      body: user == null
          ? const Center(child: Text('Please sign in to view your profile.'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  // Avatar
                  GestureDetector(
                    onTap: () {
                      _pickAvatar();
                    },
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Theme.of(context).colorScheme.primary.withValues(alpha:0.1),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: avatarUrl.isNotEmpty
                              ? (avatarUrl.startsWith('data:image') || avatarUrl.length > 2000) 
                                ? Image.memory(
                                    base64Decode(avatarUrl.contains(',') ? avatarUrl.split(',').last : avatarUrl),
                                    fit: BoxFit.cover,
                                  )
                                : Image.network(
                                    avatarUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.broken_image, size: 30, color: Theme.of(context).colorScheme.primary),
                                          Text('Invalid', style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.primary)),
                                        ],
                                      );
                                    },
                                  )
                              : Icon(Icons.person, size: 50, color: Theme.of(context).colorScheme.primary),
                        ),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFF6A5AE0),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.edit, size: 16, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user.email ?? 'Anonymous User',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 32),
                  
                  // Username Field
                  TextField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Bio Field
                  TextField(
                    controller: _bioController,
                    decoration: InputDecoration(
                      labelText: 'Bio',
                      prefixIcon: const Icon(Icons.info_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _updateProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6A5AE0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Save Changes',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
  
  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 200, // keep the file small enough for metadata
        maxHeight: 200,
        imageQuality: 50,
      );
      
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        final base64Str = base64Encode(bytes);
        final mimeType = pickedFile.mimeType ?? 'image/jpeg';
        
        setState(() {
          _avatarUrlController.text = 'data:$mimeType;base64,$base64Str';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }
}

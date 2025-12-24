import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:datingapp/core/utils/validators.dart';
import 'package:datingapp/providers/auth_provider.dart';
import 'package:datingapp/providers/service_providers.dart';
import 'package:datingapp/models/user_model.dart';
import 'package:datingapp/widgets/common/custom_button.dart';
import 'package:datingapp/widgets/common/custom_text_field.dart';
import 'package:datingapp/core/theme/app_theme.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _bioController = TextEditingController();
  File? _selectedImage;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final storageService = ref.read(storageServiceProvider);
    final image = await storageService.pickImageFromGallery();
    
    if (image != null) {
      setState(() => _selectedImage = image);
    }
  }

  Future<void> _handleComplete() async {
    if (!_formKey.currentState!.validate()) return;

    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    setState(() => _isLoading = true);

    try {
      String photoUrl = '';
      
      // Upload photo if selected
      if (_selectedImage != null) {
        final storageService = ref.read(storageServiceProvider);
        photoUrl = await storageService.uploadProfilePhoto(
          currentUser.uid,
          _selectedImage!,
        );
      }

      // Create user profile
      final user = UserModel(
        uid: currentUser.uid,
        name: _nameController.text.trim(),
        age: int.parse(_ageController.text),
        bio: _bioController.text.trim(),
        photoUrl: photoUrl,
        createdAt: DateTime.now(),
      );

      final firestoreService = ref.read(firestoreServiceProvider);
      await firestoreService.createUser(user);

      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                
                // Profile Photo
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: _selectedImage == null ? AppTheme.primaryGradient : null,
                        image: _selectedImage != null
                            ? DecorationImage(
                                image: FileImage(_selectedImage!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _selectedImage == null
                          ? const Icon(
                              Icons.add_a_photo,
                              size: 40,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                
                Text(
                  'Tap to add photo',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                
                // Name Field
                CustomTextField(
                  controller: _nameController,
                  hintText: 'Name',
                  prefixIcon: Icons.person_outline,
                  validator: Validators.validateName,
                ),
                const SizedBox(height: 16),
                
                // Age Field
                CustomTextField(
                  controller: _ageController,
                  hintText: 'Age',
                  prefixIcon: Icons.cake_outlined,
                  keyboardType: TextInputType.number,
                  validator: Validators.validateAge,
                ),
                const SizedBox(height: 16),
                
                // Bio Field
                CustomTextField(
                  controller: _bioController,
                  hintText: 'Bio (optional)',
                  prefixIcon: Icons.edit_outlined,
                  maxLines: 4,
                  maxLength: 500,
                  validator: Validators.validateBio,
                ),
                const SizedBox(height: 24),
                
                // Complete Button
                CustomButton(
                  text: 'Complete Profile',
                  onPressed: _handleComplete,
                  isLoading: _isLoading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'dart:async';
import 'dart:io';

import 'package:fitness/app/core/di.dart';
import 'package:fitness/app/core/theme/app_pallet.dart';
import 'package:fitness/app/ui/auth/domain/usecase/get_current_user.dart';
import 'package:fitness/app/ui/home/presentation/bloc/upload/upload_bloc.dart';
import 'package:fitness/app/ui/home/presentation/widget/camera_box.dart';
import 'package:fitness/app/core/common/widget/greeting.dart';
import 'package:fitness/app/ui/home/presentation/widget/result_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


class AnalysisPage extends StatefulWidget {
  const AnalysisPage({super.key});

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {
  Timer? _greetingTimer;
  String _greeting = GreetingHelper.getGreeting();
  String _emoji = GreetingHelper.getGreetingEmoji();

  @override
  void initState() {
    super.initState();
    // Update greeting every minute to handle time changes
    _greetingTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        setState(() {
          _greeting = GreetingHelper.getGreeting();
          _emoji = GreetingHelper.getGreetingEmoji();
        });
      }
    });
  }

  @override
  void dispose() {
    _greetingTimer?.cancel();
    super.dispose();
  }

  void _showImageSourceDialog(BuildContext context) {
    // Capture the bloc reference before showing the bottom sheet
    final uploadBloc = context.read<UploadBloc>();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext bottomSheetContext) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Select Image Source',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _ImageSourceOption(
                      icon: Icons.camera_alt,
                      label: 'Camera',
                      onTap: () {
                        Navigator.pop(bottomSheetContext);
                        uploadBloc.add(PickImageFromCamera());
                      },
                    ),
                    _ImageSourceOption(
                      icon: Icons.photo_library,
                      label: 'Gallery',
                      onTap: () {
                        Navigator.pop(bottomSheetContext);
                        uploadBloc.add(PickImageFromGallery());
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<UploadBloc>(),
      child: BlocListener<UploadBloc, UploadState>(
        listener: (context, state) {
          if (state is UploadFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Text(
                        "$_greeting ",
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        _emoji,
                        style: const TextStyle(fontSize: 22),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Builder(
                    builder: (context) {
                      final getCurrentUser = sl<GetCurrentUser>();
                      final user = getCurrentUser();
                      final displayName = user?.name ?? 
                                         user?.email ?? 
                                         'User';
                      return Text(
                        displayName,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                  const SizedBox(height: 40),

                  // Upload box
                  Expanded(
                    child: BlocBuilder<UploadBloc, UploadState>(
                      builder: (context, state) {
                        Widget content;

                        if (state is UploadImageSelected) {
                          content = ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(
                              state.image,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          );
                        } else if (state is UploadLoading && state.image != null) {
                          // Show image while uploading
                          content = Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.file(
                                  state.image!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  color: Colors.black54,
                                ),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          );
                        } else if (state is UploadFailure && state.image != null) {
                          // Show image even on error so user can retry
                          content = ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(
                              state.image!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          );
                        } else if (state is UploadLoading) {
                          // Loading without image (picking image)
                          content = const Center(child: CircularProgressIndicator());
                        } else {
                          content = const Icon(Icons.camera_alt, size: 60, color: Colors.black);
                        }

                        return GestureDetector(
                          onTap: () {
                            // Allow picking new image unless currently picking (loading without image)
                            if (state is! UploadLoading || 
                                (state.image != null)) {
                              _showImageSourceDialog(context);
                            }
                          },
                          child: CameraBox(child: content),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Center(
                    child: Text(
                      "Tap to Upload",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Upload/Analyze button
                  BlocBuilder<UploadBloc, UploadState>(
                    builder: (context, state) {
                      File? imageToUpload;
                      bool hasImage = false;
                      bool isUploading = false;

                      if (state is UploadImageSelected) {
                        hasImage = true;
                        imageToUpload = state.image;
                      } else if (state is UploadLoading && state.image != null) {
                        hasImage = true;
                        isUploading = true;
                        imageToUpload = state.image;
                      } else if (state is UploadFailure && state.image != null) {
                        // Allow retry after error
                        hasImage = true;
                        imageToUpload = state.image;
                      }

                      if (!hasImage) {
                        return const SizedBox.shrink();
                      }

                      // Only show button if we have a valid image
                      if (imageToUpload == null) {
                        return const SizedBox.shrink();
                      }

                      return Center(
                        child: GestureDetector(
                          onTap: isUploading
                              ? null
                              : () {
                                  if (imageToUpload != null) {
                                    showModalBottomSheet<void>(
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      useSafeArea: true,
                                      context: context,
                                      builder: (BuildContext modalContext) =>
                                          BlocProvider.value(
                                        value: context.read<UploadBloc>(),
                                        child: ResultModalPage(
                                          image: imageToUpload!,
                                        ),
                                      ),
                                    );
                                  }
                                },
                          // Do not touch this child
                          child: hasImage ? Container(
                            height: 50,
                            width: 50,
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  // color: AppPallete.gradient1,
                                  blurRadius: 5,
                                  offset: const Offset(2, 5),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.auto_awesome,
                              color: Colors.white,
                            ),
                          ) : null,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Image Source Option Widget
class _ImageSourceOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ImageSourceOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 48,
              color: Colors.black87,
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
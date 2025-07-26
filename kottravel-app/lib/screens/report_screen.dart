import 'dart:io';
import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import '../utils/app_theme.dart';
import '../utils/responsive.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  String? _selectedIssueType;
  File? _selectedImage;
  bool _isSubmitting = false;

  final List<String> _issueTypes = [
    'Potholes',
    'Accident',
    'Road Block',
    'Construction',
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      // Perform different picking methods based on the source
      XFile? image;

      if (source == ImageSource.gallery) {
        // For gallery, try with preferredCameraDevice setting
        image = await _picker
            .pickImage(
              source: source,
              maxWidth: 1920,
              maxHeight: 1080,
              imageQuality: 85,
              preferredCameraDevice:
                  CameraDevice.rear, // This can help with some devices
            )
            .timeout(
              const Duration(seconds: 30),
              onTimeout: () {
                throw TimeoutException(
                  'Image picking timed out. Please try again.',
                );
              },
            );
      } else {
        // For camera, use regular picker
        image = await _picker
            .pickImage(
              source: source,
              maxWidth: 1920,
              maxHeight: 1080,
              imageQuality: 85,
            )
            .timeout(
              const Duration(seconds: 30),
              onTimeout: () {
                throw TimeoutException('Camera timed out. Please try again.');
              },
            );
      }

      // Process the image if it was selected
      if (image != null && mounted) {
        // Verify the file exists and is accessible
        final file = File(image.path);
        if (!await file.exists()) {
          throw Exception('Selected image file does not exist');
        }

        setState(() {
          _selectedImage = file;
        });

        _showSnackBar('Image successfully selected', isError: false);
        debugPrint('Image successfully picked: ${file.path}');
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        String errorMessage;

        if (e.toString().contains('channel')) {
          errorMessage =
              'Unable to access ${source == ImageSource.gallery ? "gallery" : "camera"}. '
              'Please check your device permissions and try again.';
        } else if (e.toString().contains('permission')) {
          errorMessage =
              '${source == ImageSource.gallery ? "Gallery" : "Camera"} permission denied. '
              'Please enable it in settings.';
        } else {
          errorMessage = 'Error picking image: ${e.toString().split('\n')[0]}';
        }

        _showSnackBar(errorMessage, isError: true);
      }
    }
  }

  // Request the appropriate permission based on source
  Future<bool> _requestPermission(ImageSource source) async {
    Permission permission;

    if (source == ImageSource.camera) {
      permission = Permission.camera;
    } else {
      // For gallery, request both old and new permissions
      // The one that doesn't apply will just be ignored on the respective platforms
      await Permission.storage.request();
      await Permission.photos.request();

      // Check either permission
      bool hasAccess =
          await Permission.storage.isGranted ||
          await Permission.photos.isGranted;

      if (hasAccess) {
        return true;
      } else {
        // Check if permanently denied
        if ((await Permission.storage.isPermanentlyDenied) ||
            (await Permission.photos.isPermanentlyDenied)) {
          if (mounted) {
            _showPermissionSettingsDialog('Gallery');
          }
        } else {
          if (mounted) {
            _showSnackBar(
              'Permission is required to access gallery',
              isError: true,
            );
          }
        }
        return false;
      }
    }

    // For camera permission
    PermissionStatus status = await permission.status;

    if (status.isGranted) {
      return true;
    }

    // Request permission
    status = await permission.request();

    // If permission denied and can show rationale, explain why we need it
    if (status.isDenied && mounted) {
      _showSnackBar(
        'Camera permission is required to take photos',
        isError: true,
      );
      return false;
    }

    // If permission permanently denied, direct to app settings
    if (status.isPermanentlyDenied && mounted) {
      _showPermissionSettingsDialog('Camera');
      return false;
    }

    return status.isGranted;
  }

  // Show a dialog explaining how to enable permissions in settings
  void _showPermissionSettingsDialog(String permissionType) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('$permissionType Access Required'),
            content: Text(
              'To use this feature, we need $permissionType permission. '
              'Please enable it in your device settings.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CANCEL'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  openAppSettings();
                },
                child: const Text('OPEN SETTINGS'),
              ),
            ],
          ),
    );
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Select Image Source'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.camera_alt,
                    color: AppColors.primary,
                  ),
                  title: const Text('Camera'),
                  onTap: () async {
                    Navigator.pop(context);
                    if (await _requestPermission(ImageSource.camera)) {
                      _pickImage(ImageSource.camera);
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.photo_library,
                    color: AppColors.primary,
                  ),
                  title: const Text('Gallery'),
                  onTap: () async {
                    Navigator.pop(context);
                    if (await _requestPermission(ImageSource.gallery)) {
                      _pickImage(ImageSource.gallery);
                    }
                  },
                ),
              ],
            ),
          ),
    );
  }

  // 🎯 FIX: New method to save the image file locally
  Future<String?> _saveImageLocally(File image) async {
    try {
      // Get the application's private documents directory
      final Directory appDir = await getApplicationDocumentsDirectory();
      // Create a reports directory if it doesn't exist
      final Directory reportsDir = Directory('${appDir.path}/reports');
      if (!await reportsDir.exists()) {
        await reportsDir.create(recursive: true);
      }

      // Create a unique file name to avoid conflicts
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String filePath = p.join(reportsDir.path, fileName);

      // Copy the picked image file to the new path
      await image.copy(filePath);

      return filePath;
    } catch (e) {
      debugPrint('Error saving image locally: $e');
      return null;
    }
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    // Prevent multiple submissions
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      String? localImagePath;
      if (_selectedImage != null) {
        // Save image locally
        localImagePath = await _saveImageLocally(_selectedImage!);
        if (localImagePath == null) {
          throw Exception('Failed to save image locally. Please try again.');
        }
      }

      // Generate a unique ID for the report
      final reportId = 'report_${DateTime.now().millisecondsSinceEpoch}';
      final timestamp = DateTime.now().toIso8601String();

      // Prepare report data
      final reportData = {
        'id': reportId,
        'issue_type': _selectedIssueType,
        'description': _descriptionController.text.trim(),
        'local_image_path': localImagePath,
        'timestamp': timestamp,
        'status': 'pending',
        // Add user location if available in future
      };

      // Create a database reference
      final DatabaseReference reportRef = FirebaseDatabase.instance
          .ref('issue_reports')
          .child(reportId);

      // Set the data with error handling
      await reportRef
          .set(reportData)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw TimeoutException(
                'Network timeout. Please check your connection.',
              );
            },
          );

      // Add credits to user wallet - using a fixed userId for now
      // In a real app, this would use the authenticated user's ID
      const String userId = 'user001';
      const int creditsToAdd = 10; // Credits earned per report

      // 1. Update user's wallet balance
      final userWalletRef = FirebaseDatabase.instance
          .ref('users')
          .child(userId)
          .child('wallet');

      // Get current balance
      final walletSnapshot = await userWalletRef.get();
      double currentBalance = 0.0;

      if (walletSnapshot.exists) {
        final walletData = Map<String, dynamic>.from(
          walletSnapshot.value as Map,
        );
        currentBalance = (walletData['balance'] as num?)?.toDouble() ?? 0.0;
      }

      // Update balance
      await userWalletRef.update({
        'balance': currentBalance + creditsToAdd,
        'last_updated': timestamp,
      });

      // 2. Add transaction record
      final transactionId = 'tx_${DateTime.now().millisecondsSinceEpoch}';
      final transactionRef = FirebaseDatabase.instance
          .ref('users')
          .child(userId)
          .child('transactions')
          .child(transactionId);

      await transactionRef.set({
        'type': 'credit',
        'amount': creditsToAdd,
        'description': 'Reported issue: $_selectedIssueType',
        'timestamp': timestamp,
        'reportId': reportId,
      });

      if (mounted)
        _showSnackBar(
          'Report sent successfully! Earned $creditsToAdd credits.',
          isError: false,
        );
      _resetForm();
    } catch (e) {
      if (mounted)
        _showSnackBar('Error sending report: ${e.toString()}', isError: true);
      debugPrint('Error submitting report: $e');
    }

    // Always reset the submitting state if the widget is still mounted
    if (mounted) setState(() => _isSubmitting = false);
  }

  void _resetForm() {
    setState(() {
      _selectedIssueType = null;
      _selectedImage = null;
    });
    _formKey.currentState?.reset();
    _descriptionController.clear();
  }

  void _showSnackBar(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions for responsive layout
    final size = MediaQuery.of(context).size;
    final double titleSize = size.width * 0.06;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title with consistent styling
                Text(
                  'Report an Issue',
                  style: TextStyle(
                    fontSize: titleSize,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Manrope',
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 24),
                // Issue Type Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedIssueType,
                  hint: const Text('Select Issue Type'),
                  decoration: const InputDecoration(
                    labelText: 'Issue Type *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(16.0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(16.0)),
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(16.0)),
                      borderSide: BorderSide(
                        color: AppColors.primary,
                        width: 2.0,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(16.0)),
                      borderSide: BorderSide(color: Colors.red),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(16.0)),
                      borderSide: BorderSide(color: Colors.red, width: 2.0),
                    ),
                  ),
                  items:
                      _issueTypes.map((type) {
                        return DropdownMenuItem<String>(
                          value: type,
                          child: Text(type),
                        );
                      }).toList(),
                  onChanged:
                      (value) => setState(() => _selectedIssueType = value),
                  validator:
                      (value) =>
                          value == null ? 'Please select an issue type' : null,
                ),
                const SizedBox(height: 24),

                // Description Field (Optional)
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                    hintText: 'Add any extra details...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(16.0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(16.0)),
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(16.0)),
                      borderSide: BorderSide(
                        color: AppColors.primary,
                        width: 2.0,
                      ),
                    ),
                  ),
                  maxLines: 4,
                ),
                const SizedBox(height: 24),

                // Image Upload Section
                GestureDetector(
                  onTap: _showImageSourceDialog,
                  child: Container(
                    height: 150,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade400),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child:
                        _selectedImage != null
                            ? Stack(
                              fit:
                                  StackFit
                                      .expand, // Fix overflow by using StackFit.expand
                              alignment: Alignment.center,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.file(
                                    _selectedImage!,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                    ),
                                    onPressed:
                                        () => setState(
                                          () => _selectedImage = null,
                                        ),
                                    style: IconButton.styleFrom(
                                      backgroundColor: Colors.black45,
                                      padding: const EdgeInsets.all(
                                        4,
                                      ), // Smaller padding for the close button
                                    ),
                                  ),
                                ),
                              ],
                            )
                            : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize:
                                  MainAxisSize.min, // Fix potential overflow
                              children: [
                                Icon(
                                  Icons.add_a_photo_outlined,
                                  size: 40,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(height: 8),
                                const Text('Upload Photo (Optional)'),
                              ],
                            ),
                  ),
                ),
                const SizedBox(height: 32),

                // Submit Button
                ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitReport,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    elevation: 3,
                    shadowColor: AppColors.primary.withOpacity(0.4),
                  ),
                  icon:
                      _isSubmitting
                          ? Container(
                            width: 24,
                            height: 24,
                            padding: const EdgeInsets.all(2.0),
                            child: const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                          : const Icon(Icons.send),
                  label: const Text(
                    'SEND REPORT',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
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

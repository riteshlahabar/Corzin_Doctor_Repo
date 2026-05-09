import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';

import '../../core/constants/api_constants.dart';
import '../../core/models/doctor_profile.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/cow_walking_loader.dart';
import '../home/home_controller.dart';
import '../reports/reports_view.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({
    super.key,
    required this.controller,
  });

  final HomeController controller;

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  bool _showDoctorInfo = false;
  bool _isEditing = false;
  bool _isSaving = false;
  String? _uploadingDocumentField;

  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _clinicNameController;
  late final TextEditingController _degreeController;
  late final TextEditingController _contactController;
  late final TextEditingController _emailController;
  late final TextEditingController _aadharController;
  late final TextEditingController _panController;
  late final TextEditingController _mmcController;
  late final TextEditingController _clinicRegController;
  late final TextEditingController _clinicAddressController;
  late final TextEditingController _villageController;
  late final TextEditingController _cityController;
  late final TextEditingController _talukaController;
  late final TextEditingController _districtController;
  late final TextEditingController _stateController;
  late final TextEditingController _pincodeController;

  int _lastSyncedProfileId = -1;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _clinicNameController = TextEditingController();
    _degreeController = TextEditingController();
    _contactController = TextEditingController();
    _emailController = TextEditingController();
    _aadharController = TextEditingController();
    _panController = TextEditingController();
    _mmcController = TextEditingController();
    _clinicRegController = TextEditingController();
    _clinicAddressController = TextEditingController();
    _villageController = TextEditingController();
    _cityController = TextEditingController();
    _talukaController = TextEditingController();
    _districtController = TextEditingController();
    _stateController = TextEditingController();
    _pincodeController = TextEditingController();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _clinicNameController.dispose();
    _degreeController.dispose();
    _contactController.dispose();
    _emailController.dispose();
    _aadharController.dispose();
    _panController.dispose();
    _mmcController.dispose();
    _clinicRegController.dispose();
    _clinicAddressController.dispose();
    _villageController.dispose();
    _cityController.dispose();
    _talukaController.dispose();
    _districtController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final profile = widget.controller.profile.value;
      if (profile == null) {
        return const SizedBox.shrink();
      }

      if (_lastSyncedProfileId != profile.id || (!_isEditing && _firstNameController.text != profile.firstName)) {
        _syncControllers(profile);
      }

      return ListView(
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          Container(
            width: double.infinity,
            color: AppColors.primary,
            padding: EdgeInsets.fromLTRB(18, MediaQuery.of(context).padding.top + 8, 18, 14),
            child: const Text(
              'Profile',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'SF Pro Display',
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: AppColors.white,
              ),
            ),
          ),
          Container(
            color: AppColors.white,
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 8),
            child: Column(
              children: [
                _doctorAvatar(profile.photoUrl),
                const SizedBox(height: 10),
                Text(
                  profile.fullName.isEmpty ? 'Doctor' : profile.fullName,
                  style: const TextStyle(
                    fontFamily: 'SF Pro Display',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  profile.email,
                  style: const TextStyle(fontSize: 12.8, color: AppColors.grey),
                ),
                const SizedBox(height: 14),
                _menuTile(
                  icon: Icons.person_outline_rounded,
                  title: 'Profile',
                  subtitle: 'Doctor information and uploaded documents',
                  onTap: () {
                    setState(() {
                      _showDoctorInfo = !_showDoctorInfo;
                    });
                  },
                ),
                AnimatedCrossFade(
                  crossFadeState: _showDoctorInfo ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 220),
                  firstChild: const SizedBox.shrink(),
                  secondChild: _doctorInfoCard(profile),
                ),
                // _menuTile(
                //   icon: Icons.credit_card_outlined,
                //   title: 'My cards',
                //   subtitle: 'UPI, Debit Card, Credit Card, Net Banking, Cash',
                // ),
                _menuTile(
                  icon: Icons.bar_chart_rounded,
                  title: 'Reports',
                  subtitle: 'My earnings and my clients',
                  onTap: () => Get.to(() => ReportsView(controller: widget.controller)),
                ),
                _menuTile(
                  icon: Icons.description_outlined,
                  title: 'Terms & Conditions',
                  subtitle: 'View latest terms from backend',
                  onTap: () => _openTermsDialog(),
                ),
                _menuTile(
                  icon: Icons.shield_outlined,
                  title: 'Privacy policy',
                  subtitle: 'Terms, conditions and privacy policy',
                  onTap: () => _openPrivacyDialog(),
                ),
                _menuTile(
                  icon: Icons.admin_panel_settings_outlined,
                  title: 'Permissions',
                  subtitle: 'Notification, location and alert access',
                  onTap: _openPermissionsSheet,
                ),
                _menuTile(
                  icon: Icons.lock_reset_rounded,
                  title: 'Change Password',
                  subtitle: 'Update your account password',
                  onTap: _openChangePasswordDialog,
                ),
                _menuTile(
                  icon: Icons.share_rounded,
                  title: 'Refer & Earn',
                  subtitle: 'Share farmer app link and earn rewards',
                  onTap: _openReferralSheet,
                ),
                _menuTile(
                  icon: Icons.logout_rounded,
                  title: 'Log out',
                  subtitle: 'Sign out from your account',
                  onTap: widget.controller.logout,
                ),
              ],
            ),
          ),
        ],
      );
    });
  }

  Widget _doctorAvatar(String photoUrl) {
    final source = photoUrl.trim();
    final resolved = _resolveUrl(source);
    return ClipOval(
      child: resolved == null
          ? Container(
              height: 88,
              width: 88,
              color: const Color(0xFFE4EFE4),
              child: const Icon(Icons.person_rounded, size: 38, color: AppColors.grey),
            )
          : Image.network(
              resolved,
              height: 88,
              width: 88,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                height: 88,
                width: 88,
                color: const Color(0xFFE4EFE4),
                child: const Icon(Icons.person_rounded, size: 38, color: AppColors.grey),
              ),
            ),
    );
  }

  Widget _doctorInfoCard(DoctorProfile profile) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4FAF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4EFE4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Doctor Information',
                  style: TextStyle(fontFamily: 'SF Pro Display', fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                onPressed: _isSaving
                    ? null
                    : () {
                        setState(() {
                          _isEditing = !_isEditing;
                          if (!_isEditing) {
                            _syncControllers(profile);
                          }
                        });
                      },
                icon: Icon(_isEditing ? Icons.close_rounded : Icons.edit_rounded, size: 18),
              ),
            ],
          ),
          _editableTile('First Name', _firstNameController),
          _editableTile('Last Name', _lastNameController),
          _editableTile('Clinic Name', _clinicNameController),
          _editableTile('Degree', _degreeController),
          _editableTile('Contact Number', _contactController, keyboardType: TextInputType.phone),
          _editableTile('Email', _emailController, keyboardType: TextInputType.emailAddress),
          _editableTile('Aadhar Number', _aadharController),
          _editableTile('PAN Number', _panController),
          _editableTile('MMC Reg No', _mmcController),
          _editableTile('Clinic Reg No', _clinicRegController),
          _editableTile('Village', _villageController),
          _editableTile('City', _cityController),
          _editableTile('Taluka', _talukaController),
          _editableTile('District', _districtController),
          _editableTile('State', _stateController),
          _editableTile('Pincode', _pincodeController, keyboardType: TextInputType.number),
          _editableTile('Clinic Address', _clinicAddressController, maxLines: 3),
          _plainTile('Status', profile.status.toUpperCase()),
          if (_isEditing) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSaving
                        ? null
                        : () {
                            setState(() {
                              _isEditing = false;
                              _syncControllers(profile);
                            });
                          },
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                    ),
                    child: Text(_isSaving ? 'Saving...' : 'Save'),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          const Text(
            'Documents',
            style: TextStyle(fontFamily: 'SF Pro Display', fontSize: 13.5, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (profile.photoUrl.trim().isNotEmpty)
                _documentCard(
                  title: 'Doctor Photo',
                  source: profile.photoUrl,
                  uploadField: 'doctor_photo',
                  profile: profile,
                  imageOnly: true,
                ),
              ...profile.documents.entries
                  .where((entry) => entry.value.trim().isNotEmpty)
                  .map(
                    (entry) => _documentCard(
                      title: _toTitle(entry.key),
                      source: entry.value,
                      uploadField: _documentUploadField(entry.key),
                      profile: profile,
                    ),
                  ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _plainTile(String label, String value) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE4EFE4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11.4, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(
            value.trim().isEmpty ? '-' : value,
            style: const TextStyle(fontSize: 12.2, color: AppColors.grey),
          ),
        ],
      ),
    );
  }

  Widget _editableTile(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE4EFE4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11.4, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          if (_isEditing)
            TextField(
              controller: controller,
              keyboardType: keyboardType,
              maxLines: maxLines,
              style: const TextStyle(fontSize: 12.2, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            )
          else
            Text(
              controller.text.trim().isEmpty ? '-' : controller.text.trim(),
              style: const TextStyle(fontSize: 12.2, color: AppColors.grey),
            ),
        ],
      ),
    );
  }

  Widget _documentCard({
    required String title,
    required String source,
    required String uploadField,
    required DoctorProfile profile,
    bool imageOnly = false,
  }) {
    final resolved = _resolveUrl(source.trim());
    final lower = (resolved ?? '').toLowerCase();
    final isImage = lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.gif');
    final uploading = _uploadingDocumentField == uploadField;

    return Container(
      width: 110,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE4EFE4)),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              if (isImage && resolved != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    resolved,
                    height: 54,
                    width: 90,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _docFallback(),
                  ),
                )
              else
                _docFallback(),
              Positioned(
                top: 2,
                right: 2,
                child: InkWell(
                  onTap: uploading
                      ? null
                      : () => _pickAndUploadDocument(
                            profile: profile,
                            uploadField: uploadField,
                            label: title,
                            imageOnly: imageOnly,
                          ),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    height: 20,
                    width: 20,
                    decoration: const BoxDecoration(
                      color: AppColors.white,
                      shape: BoxShape.circle,
                    ),
                    child: uploading
                        ? const CowWalkingLoader(
                            size: 18,
                            compact: true,
                            showLabel: false,
                            color: AppColors.primary,
                          )
                        : const Icon(Icons.edit_rounded, size: 13, color: AppColors.primary),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10.6, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _docFallback() {
    return Container(
      height: 54,
      width: 90,
      decoration: BoxDecoration(
        color: const Color(0xFFE8F0E8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFC0392B), size: 20),
    );
  }

  Widget _menuTile({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    final tile = Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFF4FAF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4EFE4)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.black),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                if (subtitle != null && subtitle.trim().isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: AppColors.grey),
                  ),
                ],
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.black),
        ],
      ),
    );

    if (onTap == null) return tile;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: tile,
    );
  }

  void _syncControllers(DoctorProfile profile) {
    _lastSyncedProfileId = profile.id;
    _firstNameController.text = profile.firstName;
    _lastNameController.text = profile.lastName;
    _clinicNameController.text = profile.clinicName;
    _degreeController.text = profile.degree;
    _contactController.text = profile.contactNumber;
    _emailController.text = profile.email;
    _aadharController.text = profile.adharNumber;
    _panController.text = profile.panNumber;
    _mmcController.text = profile.mmcRegistrationNumber;
    _clinicRegController.text = profile.clinicRegistrationNumber;
    _clinicAddressController.text = profile.clinicAddress;
    _villageController.text = profile.village;
    _cityController.text = profile.city;
    _talukaController.text = profile.taluka;
    _districtController.text = profile.district;
    _stateController.text = profile.state;
    _pincodeController.text = profile.pincode;
  }

  String? _resolveUrl(String source) {
    if (source.trim().isEmpty) return null;
    if (source.startsWith('http://') || source.startsWith('https://')) return source;
    final clean = source.replaceFirst(RegExp(r'^/+'), '');
    return '${ApiConstants.publicBaseUrl}/$clean';
  }

  String _toTitle(String key) {
    final words = key.replaceAll('_', ' ').split(' ');
    return words
        .where((word) => word.trim().isNotEmpty)
        .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }

  String _documentUploadField(String sourceKey) {
    final key = sourceKey.toLowerCase().trim();
    if (key == 'doctor_photo' || key == 'doctor_photo_url' || key.contains('photo')) {
      return 'doctor_photo';
    }
    if (key == 'adhar_document' || key.contains('adhar') || key.contains('aadhar')) {
      return 'adhar_document';
    }
    if (key == 'pan_document' || key.contains('pan')) {
      return 'pan_document';
    }
    if (key == 'mmc_document' || key.contains('mmc')) {
      return 'mmc_document';
    }
    if (key == 'clinic_registration_document' || key.contains('clinic_registration')) {
      return 'clinic_registration_document';
    }
    return key;
  }

  Map<String, String> _profileFieldsPayload() {
    return {
      'first_name': _firstNameController.text.trim(),
      'last_name': _lastNameController.text.trim(),
      'clinic_name': _clinicNameController.text.trim(),
      'degree': _degreeController.text.trim(),
      'contact_number': _contactController.text.trim(),
      'email': _emailController.text.trim(),
      'adhar_number': _aadharController.text.trim(),
      'pan_number': _panController.text.trim(),
      'mmc_registration_number': _mmcController.text.trim(),
      'clinic_registration_number': _clinicRegController.text.trim(),
      'clinic_address': _clinicAddressController.text.trim(),
      'village': _villageController.text.trim(),
      'city': _cityController.text.trim(),
      'taluka': _talukaController.text.trim(),
      'district': _districtController.text.trim(),
      'state': _stateController.text.trim(),
      'pincode': _pincodeController.text.trim(),
    };
  }

  Future<void> _pickAndUploadDocument({
    required DoctorProfile profile,
    required String uploadField,
    required String label,
    required bool imageOnly,
  }) async {
    if (_uploadingDocumentField != null || _isSaving) return;

    final payload = _profileFieldsPayload();
    if (payload.values.any((value) => value.isEmpty)) {
      Get.snackbar('Missing Fields', 'Please complete doctor information before uploading documents.');
      return;
    }

    final picked = await FilePicker.platform.pickFiles(
      type: imageOnly ? FileType.image : FileType.custom,
      allowedExtensions: imageOnly ? null : const ['jpg', 'jpeg', 'png', 'webp', 'pdf'],
      withData: true,
    );

    if (picked == null || picked.files.isEmpty) return;
    final file = picked.files.first;
    if ((file.path == null || file.path!.isEmpty) && (file.bytes == null || file.bytes!.isEmpty)) {
      Get.snackbar('File Missing', 'Please choose a valid file.');
      return;
    }

    setState(() {
      _uploadingDocumentField = uploadField;
    });

    try {
      await widget.controller.updateDoctorProfile(
        fields: payload,
        files: {uploadField: file},
        successMessage: '$label uploaded successfully.',
      );
      await widget.controller.refreshProfile();
      final latestProfile = widget.controller.profile.value;
      if (latestProfile != null) {
        _syncControllers(latestProfile);
      } else {
        _syncControllers(profile);
      }
    } catch (error) {
      final message = error.toString().replaceFirst('Exception: ', '');
      Get.snackbar('Upload Failed', message);
    } finally {
      if (mounted) {
        setState(() {
          _uploadingDocumentField = null;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    final payload = _profileFieldsPayload();
    if (payload.values.any((value) => value.isEmpty)) {
      Get.snackbar('Missing Fields', 'Please fill all profile fields before saving.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await widget.controller.updateDoctorProfile(
        fields: payload,
      );
      setState(() {
        _isEditing = false;
      });
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _showPolicyDialog({
    required String title,
    required String content,
  }) {
    final text = content.trim().isEmpty
        ? '$title is not configured yet by admin.'
        : content.trim();

    Get.dialog(
      AlertDialog(
        title: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        content: SingleChildScrollView(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, color: AppColors.black),
          ),
        ),
        actions: [
          TextButton(
            onPressed: Get.back,
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _openTermsDialog() async {
    await widget.controller.refreshSettings();
    _showPolicyDialog(
      title: 'Terms & Conditions',
      content: widget.controller.termsAndConditions,
    );
  }

  Future<void> _openPrivacyDialog() async {
    await widget.controller.refreshSettings();
    _showPolicyDialog(
      title: 'Privacy Policy',
      content: widget.controller.privacyPolicy,
    );
  }

  Future<void> _openPermissionsSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PermissionsSheet(controller: widget.controller),
    );
  }

  Future<void> _openChangePasswordDialog() async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    var hideCurrentPassword = true;
    var hideNewPassword = true;
    var hideConfirmPassword = true;
    var updating = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            InputDecoration passwordDecoration({
              required String label,
              required bool hidden,
              required VoidCallback onToggle,
            }) {
              return InputDecoration(
                labelText: label,
                isDense: true,
                filled: true,
                fillColor: const Color(0xFFF4FAF4),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFD9E7D9)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFD9E7D9)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
                ),
                suffixIconConstraints: const BoxConstraints(minHeight: 34, minWidth: 34),
                suffixIcon: IconButton(
                  splashRadius: 18,
                  onPressed: onToggle,
                  icon: Icon(
                    hidden ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                    size: 18,
                    color: AppColors.grey,
                  ),
                ),
              );
            }

            Future<void> onSubmit() async {
              final currentPassword = currentPasswordController.text.trim();
              final newPassword = newPasswordController.text.trim();
              final confirmPassword = confirmPasswordController.text.trim();

              if (currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
                Get.snackbar('Missing Fields', 'Please fill all password fields.');
                return;
              }
              if (newPassword.length < 8) {
                Get.snackbar('Invalid Password', 'New password must be at least 8 characters.');
                return;
              }
              if (newPassword != confirmPassword) {
                Get.snackbar('Password Mismatch', 'New password and confirm password must match.');
                return;
              }

              setModalState(() {
                updating = true;
              });
              final updated = await widget.controller.changeDoctorPassword(
                currentPassword: currentPassword,
                newPassword: newPassword,
                confirmPassword: confirmPassword,
              );
              if (!mounted || !sheetContext.mounted) return;
              setModalState(() {
                updating = false;
              });
              if (updated) {
                Navigator.of(sheetContext).pop();
              }
            }

            return AnimatedPadding(
              duration: const Duration(milliseconds: 120),
              padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: Material(
                  color: AppColors.white,
                  child: SafeArea(
                    top: false,
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Container(
                                width: 44,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFCFE0CF),
                                  borderRadius: BorderRadius.circular(99),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3FAF3),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE0EEE0)),
                              ),
                              child: const Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.lock_reset_rounded, size: 18, color: AppColors.primary),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Change Password',
                                          style: TextStyle(
                                            fontSize: 15.5,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.black,
                                          ),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          'Update your password securely.',
                                          style: TextStyle(fontSize: 12, color: AppColors.grey),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: currentPasswordController,
                              obscureText: hideCurrentPassword,
                              style: const TextStyle(fontSize: 13.2, fontWeight: FontWeight.w600),
                              decoration: passwordDecoration(
                                label: 'Current Password',
                                hidden: hideCurrentPassword,
                                onToggle: () {
                                  setModalState(() {
                                    hideCurrentPassword = !hideCurrentPassword;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: newPasswordController,
                              obscureText: hideNewPassword,
                              style: const TextStyle(fontSize: 13.2, fontWeight: FontWeight.w600),
                              decoration: passwordDecoration(
                                label: 'New Password',
                                hidden: hideNewPassword,
                                onToggle: () {
                                  setModalState(() {
                                    hideNewPassword = !hideNewPassword;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: confirmPasswordController,
                              obscureText: hideConfirmPassword,
                              style: const TextStyle(fontSize: 13.2, fontWeight: FontWeight.w600),
                              decoration: passwordDecoration(
                                label: 'Confirm Password',
                                hidden: hideConfirmPassword,
                                onToggle: () {
                                  setModalState(() {
                                    hideConfirmPassword = !hideConfirmPassword;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: updating ? null : () => Navigator.of(sheetContext).pop(),
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: const Size.fromHeight(40),
                                      side: const BorderSide(color: Color(0xFFCCE0CC)),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: updating ? null : onSubmit,
                                    style: ElevatedButton.styleFrom(
                                      minimumSize: const Size.fromHeight(40),
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: AppColors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    child: Text(
                                      updating ? 'Updating...' : 'Update Password',
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    // Allow bottom-sheet close animation to finish before disposing controllers.
    await Future<void>.delayed(const Duration(milliseconds: 250));
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
  }

  Future<void> _openReferralSheet() async {
    final currentProfile = widget.controller.profile.value;
    if (currentProfile == null) return;

    final referralsFuture = widget.controller.fetchDoctorReferrals(showError: false);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: FractionallySizedBox(
            heightFactor: 0.9,
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: FutureBuilder<Map<String, dynamic>?>(
                future: referralsFuture,
                builder: (context, snapshot) {
                  final data = snapshot.data ?? const <String, dynamic>{};
                  final summary = (data['summary'] is Map<String, dynamic>)
                      ? data['summary'] as Map<String, dynamic>
                      : const <String, dynamic>{};
                  final rawItems = (data['items'] is List) ? data['items'] as List : const [];
                  final items = rawItems.whereType<Map>().map((e) {
                    return e.map((key, value) => MapEntry(key.toString(), value));
                  }).toList(growable: false);

                  final referralCode =
                      (data['referral_code']?.toString().trim().isNotEmpty == true)
                          ? data['referral_code'].toString().trim()
                          : currentProfile.referralCode.trim();
                  final referralLink =
                      (data['referral_link']?.toString().trim().isNotEmpty == true)
                          ? data['referral_link'].toString().trim()
                          : currentProfile.referralLink.trim();
                  final referralPoints =
                      int.tryParse((data['referral_points'] ?? currentProfile.referralPoints).toString()) ??
                          currentProfile.referralPoints;

                  Widget statChip(String label, String value) {
                    return Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4FAF4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFDCEBDC)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label,
                              style: const TextStyle(fontSize: 10.5, color: AppColors.grey),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              value,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return Padding(
                    padding: EdgeInsets.fromLTRB(16, 10, 16, 12 + MediaQuery.of(sheetContext).viewInsets.bottom),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 44,
                            height: 5,
                            decoration: BoxDecoration(
                              color: const Color(0xFFCFE0CF),
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Refer & Earn',
                          style: TextStyle(fontFamily: 'SF Pro Display', fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Share this farmer app link. Rewards unlock after the farmer subscribes and completes 1 month.',
                          style: TextStyle(fontSize: 12, color: AppColors.grey),
                        ),
                        const SizedBox(height: 12),
                        if (snapshot.connectionState == ConnectionState.waiting)
                          const Expanded(
                            child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                          )
                        else ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF4FAF4),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFDCEBDC)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Referral Code',
                                  style: TextStyle(fontSize: 11, color: AppColors.grey),
                                ),
                                const SizedBox(height: 3),
                                SelectableText(
                                  referralCode.isEmpty ? '-' : referralCode,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'Referral Link',
                                  style: TextStyle(fontSize: 11, color: AppColors.grey),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  referralLink.isEmpty ? '-' : referralLink,
                                  style: const TextStyle(fontSize: 12.2, fontWeight: FontWeight.w600),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: referralLink.isEmpty
                                        ? null
                                        : () async {
                                            await Clipboard.setData(ClipboardData(text: referralLink));
                                            if (!mounted) return;
                                            Get.snackbar('Copied', 'Referral link copied.');
                                          },
                                    icon: const Icon(Icons.copy_rounded, size: 18),
                                    label: const Text('Copy Referral Link'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.primary,
                                      side: const BorderSide(color: Color(0xFFCDE1CD)),
                                      minimumSize: const Size.fromHeight(38),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              statChip('Points', '$referralPoints'),
                              const SizedBox(width: 8),
                              statChip(
                                'Farmers',
                                '${int.tryParse((summary['total_referred'] ?? 0).toString()) ?? 0}',
                              ),
                              const SizedBox(width: 8),
                              statChip(
                                'Rewards',
                                '${int.tryParse((summary['reward_granted'] ?? 0).toString()) ?? 0}',
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Referred Farmers',
                            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: items.isEmpty
                                ? Container(
                                    width: double.infinity,
                                    alignment: Alignment.center,
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAF8),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xFFE2ECE2)),
                                    ),
                                    child: const Text(
                                      'No referred farmer records yet.',
                                      style: TextStyle(color: AppColors.grey, fontSize: 12.5),
                                    ),
                                  )
                                : ListView.separated(
                                    itemCount: items.length,
                                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                                    itemBuilder: (_, index) {
                                      final item = items[index];
                                      final name = item['name']?.toString().trim().isNotEmpty == true
                                          ? item['name'].toString().trim()
                                          : 'Farmer';
                                      final contact = item['contact_number']?.toString() ?? '';
                                      final status = (item['subscription_status']?.toString() ?? 'not_subscribed').toLowerCase();
                                      final registeredAt = DateTime.tryParse(
                                        item['registered_at']?.toString() ?? '',
                                      );
                                      final rewardGranted = item['reward_granted'] == true;

                                      return Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF8FAF8),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: const Color(0xFFE2ECE2)),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    name,
                                                    style: const TextStyle(
                                                      fontSize: 13.2,
                                                      fontWeight: FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: rewardGranted
                                                        ? const Color(0xFFDFF2DF)
                                                        : const Color(0xFFE7E9EC),
                                                    borderRadius: BorderRadius.circular(30),
                                                  ),
                                                  child: Text(
                                                    rewardGranted ? 'Reward Granted' : 'Reward Pending',
                                                    style: TextStyle(
                                                      fontSize: 10.3,
                                                      fontWeight: FontWeight.w700,
                                                      color: rewardGranted ? const Color(0xFF2E7D32) : AppColors.grey,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              contact.isEmpty ? '-' : contact,
                                              style: const TextStyle(fontSize: 12, color: AppColors.grey),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Subscription: ${status == 'active' ? 'Active' : 'Pending'}',
                                              style: TextStyle(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w600,
                                                color: status == 'active' ? const Color(0xFF2E7D32) : AppColors.grey,
                                              ),
                                            ),
                                            if (registeredAt != null) ...[
                                              const SizedBox(height: 1),
                                              Text(
                                                'Registered: ${registeredAt.day.toString().padLeft(2, '0')}-${registeredAt.month.toString().padLeft(2, '0')}-${registeredAt.year}',
                                                style: const TextStyle(fontSize: 11, color: AppColors.grey),
                                              ),
                                            ],
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PermissionsSheet extends StatefulWidget {
  const _PermissionsSheet({required this.controller});

  final HomeController controller;

  @override
  State<_PermissionsSheet> createState() => _PermissionsSheetState();
}

class _PermissionsSheetState extends State<_PermissionsSheet> {
  late Future<List<DoctorAppPermissionItem>> _permissionsFuture;
  DoctorAppPermissionType? _updatingType;

  @override
  void initState() {
    super.initState();
    _permissionsFuture = widget.controller.loadAppPermissionItems();
  }

  void _reloadPermissions() {
    setState(() {
      _permissionsFuture = widget.controller.loadAppPermissionItems();
    });
  }

  Future<void> _handleToggle(DoctorAppPermissionItem item, bool enabled) async {
    setState(() {
      _updatingType = item.type;
    });
    await widget.controller.updateAppPermission(item, enabled);
    if (!mounted) return;
    setState(() {
      _updatingType = null;
      _permissionsFuture = widget.controller.loadAppPermissionItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: FractionallySizedBox(
        heightFactor: 0.72,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: Material(
            color: AppColors.white,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCFE0CF),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Container(
                        height: 38,
                        width: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF5EA),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.admin_panel_settings_outlined, color: AppColors.primary, size: 21),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Permissions',
                              style: TextStyle(
                                fontFamily: 'SF Pro Display',
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.black,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Manage access required for appointments.',
                              style: TextStyle(fontSize: 12, color: AppColors.grey),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _reloadPermissions,
                        icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
                        tooltip: 'Refresh',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4FAF4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFDCEBDC)),
                    ),
                    child: const Text(
                      'Android allows this app to request permissions. To turn any permission off, the phone settings screen will open.',
                      style: TextStyle(fontSize: 11.7, color: AppColors.grey, height: 1.28),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: FutureBuilder<List<DoctorAppPermissionItem>>(
                      future: _permissionsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(color: AppColors.primary),
                          );
                        }

                        final items = snapshot.data ?? const <DoctorAppPermissionItem>[];
                        if (items.isEmpty) {
                          return const Center(
                            child: Text(
                              'No permission details available.',
                              style: TextStyle(fontSize: 12.5, color: AppColors.grey),
                            ),
                          );
                        }

                        return ListView.separated(
                          itemCount: items.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final item = items[index];
                            final updating = _updatingType == item.type;
                            return _permissionTile(item: item, updating: updating);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _permissionTile({
    required DoctorAppPermissionItem item,
    required bool updating,
  }) {
    final enabledColor = item.enabled ? AppColors.primary : const Color(0xFFC0392B);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: item.enabled ? const Color(0xFFF4FAF4) : const Color(0xFFFFF7F7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: item.enabled ? const Color(0xFFDCEBDC) : const Color(0xFFF2D3D3),
        ),
      ),
      child: Row(
        children: [
          Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              color: item.enabled ? const Color(0xFFE6F3E6) : const Color(0xFFFFEAEA),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_permissionIcon(item.type), color: enabledColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: item.enabled ? const Color(0xFFDFF2DF) : const Color(0xFFFFE0E0),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        item.enabled ? 'Allowed' : 'Off',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: enabledColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  item.subtitle,
                  style: const TextStyle(fontSize: 11.3, color: AppColors.grey, height: 1.25),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          updating
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                )
              : Switch(
                  value: item.enabled,
                  activeThumbColor: AppColors.white,
                  activeTrackColor: AppColors.primary,
                  inactiveThumbColor: AppColors.white,
                  inactiveTrackColor: const Color(0xFFE1BABA),
                  onChanged: (value) => _handleToggle(item, value),
                ),
        ],
      ),
    );
  }

  IconData _permissionIcon(DoctorAppPermissionType type) {
    switch (type) {
      case DoctorAppPermissionType.notification:
        return Icons.notifications_active_outlined;
      case DoctorAppPermissionType.locationService:
        return Icons.gps_fixed_rounded;
      case DoctorAppPermissionType.locationPermission:
        return Icons.location_on_outlined;
      case DoctorAppPermissionType.backgroundLocation:
        return Icons.my_location_rounded;
      case DoctorAppPermissionType.alertSound:
        return Icons.volume_up_outlined;
      case DoctorAppPermissionType.appSettings:
        return Icons.settings_outlined;
    }
  }
}

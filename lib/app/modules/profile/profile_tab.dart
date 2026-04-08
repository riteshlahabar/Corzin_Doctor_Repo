import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/api_constants.dart';
import '../../core/models/doctor_profile.dart';
import '../../core/theme/app_colors.dart';
import '../home/home_controller.dart';

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
                _menuTile(
                  icon: Icons.credit_card_outlined,
                  title: 'My cards',
                  subtitle: 'UPI, Debit Card, Credit Card, Net Banking, Cash',
                ),
                _menuTile(
                  icon: Icons.notifications_none_rounded,
                  title: 'Notification',
                  subtitle: 'Manage app notifications',
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
              if (profile.photoUrl.trim().isNotEmpty) _documentCard('Doctor Photo', profile.photoUrl),
              ...profile.documents.entries
                  .where((entry) => entry.value.trim().isNotEmpty)
                  .map((entry) => _documentCard(entry.key.replaceAll('_', ' '), entry.value)),
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

  Widget _documentCard(String title, String source) {
    final resolved = _resolveUrl(source.trim());
    final lower = (resolved ?? '').toLowerCase();
    final isImage = lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.gif');

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

  Future<void> _saveProfile() async {
    if (_firstNameController.text.trim().isEmpty ||
        _lastNameController.text.trim().isEmpty ||
        _clinicNameController.text.trim().isEmpty ||
        _degreeController.text.trim().isEmpty ||
        _contactController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _aadharController.text.trim().isEmpty ||
        _panController.text.trim().isEmpty ||
        _mmcController.text.trim().isEmpty ||
        _clinicRegController.text.trim().isEmpty ||
        _clinicAddressController.text.trim().isEmpty ||
        _villageController.text.trim().isEmpty ||
        _cityController.text.trim().isEmpty ||
        _talukaController.text.trim().isEmpty ||
        _districtController.text.trim().isEmpty ||
        _stateController.text.trim().isEmpty ||
        _pincodeController.text.trim().isEmpty) {
      Get.snackbar('Missing Fields', 'Please fill all profile fields before saving.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await widget.controller.updateDoctorProfile(
        fields: {
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
        },
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
}

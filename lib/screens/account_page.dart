import 'package:flutter/material.dart';

import '../controllers/session_controller.dart';
import '../models/app_user.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({required this.sessionController, super.key});

  final SessionController sessionController;

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  bool _editing = false;

  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _clubNameCtrl;
  late final TextEditingController _associationCtrl;
  late final TextEditingController _bioCtrl;
  late final TextEditingController _handicapCtrl;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final profile = widget.sessionController.profile;
    _firstNameCtrl = TextEditingController(text: profile?.firstName ?? '');
    _lastNameCtrl = TextEditingController(text: profile?.lastName ?? '');
    _usernameCtrl = TextEditingController(text: profile?.username ?? '');
    _clubNameCtrl = TextEditingController(text: profile?.clubName ?? '');
    _associationCtrl = TextEditingController(text: profile?.association ?? '');
    _bioCtrl = TextEditingController(text: profile?.bio ?? '');
    _handicapCtrl = TextEditingController(
      text: profile?.handicap != null ? profile!.handicap.toString() : '',
    );
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _usernameCtrl.dispose();
    _clubNameCtrl.dispose();
    _associationCtrl.dispose();
    _bioCtrl.dispose();
    _handicapCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.sessionController.updateProfile(
        firstName: _firstNameCtrl.text.trim(),
        lastName: _lastNameCtrl.text.trim(),
        username: _usernameCtrl.text.trim(),
        clubName: _clubNameCtrl.text.trim(),
        association: _associationCtrl.text.trim(),
        bio: _bioCtrl.text.trim(),
        handicap: double.tryParse(_handicapCtrl.text.trim()),
      );
      if (!mounted) return;
      setState(() => _editing = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Account updated')),
        );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Failed to update account. Please try again.')),
        );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.sessionController.profile;

    return Scaffold(
      backgroundColor: const Color(0xFF031C14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF083A28),
        foregroundColor: Colors.white,
        title: const Text('Account'),
        actions: [
          if (!_editing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _editing = true),
            )
          else
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => setState(() {
                _editing = false;
                // Reset fields to current profile values
                _firstNameCtrl.text = profile?.firstName ?? '';
                _lastNameCtrl.text = profile?.lastName ?? '';
                _usernameCtrl.text = profile?.username ?? '';
                _clubNameCtrl.text = profile?.clubName ?? '';
                _associationCtrl.text = profile?.association ?? '';
                _bioCtrl.text = profile?.bio ?? '';
                _handicapCtrl.text = profile?.handicap != null
                    ? profile!.handicap.toString()
                    : '';
              }),
            ),
        ],
      ),
      body: _editing ? _buildEditView(profile) : _buildReadView(profile),
    );
  }

  Widget _buildReadView(AppUser? profile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF072E21),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF165D43)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoRow(label: 'First Name', value: profile?.firstName ?? ''),
            const SizedBox(height: 14),
            _InfoRow(label: 'Last Name', value: profile?.lastName ?? ''),
            const SizedBox(height: 14),
            _InfoRow(label: 'Username', value: profile?.username ?? ''),
            const SizedBox(height: 14),
            _InfoRow(label: 'Email', value: profile?.email ?? ''),
            const SizedBox(height: 14),
            _InfoRow(label: 'Role', value: profile?.role ?? ''),
            if ((profile?.clubName ?? '').isNotEmpty) ...[
              const SizedBox(height: 14),
              _InfoRow(label: 'Club', value: profile!.clubName!),
            ],
            if ((profile?.association ?? '').isNotEmpty) ...[
              const SizedBox(height: 14),
              _InfoRow(label: 'Association', value: profile!.association!),
            ],
            if (profile?.handicap != null) ...[
              const SizedBox(height: 14),
              _InfoRow(label: 'Handicap', value: profile!.handicap.toString()),
            ],
            if ((profile?.bio ?? '').isNotEmpty) ...[
              const SizedBox(height: 14),
              _InfoRow(label: 'Bio', value: profile!.bio!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEditView(AppUser? profile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildField('First Name', _firstNameCtrl),
          const SizedBox(height: 14),
          _buildField('Last Name', _lastNameCtrl),
          const SizedBox(height: 14),
          _buildField('Username', _usernameCtrl),
          const SizedBox(height: 14),
          if (profile?.role == 'director') ...[
            _buildField('Club Name', _clubNameCtrl),
            const SizedBox(height: 14),
            _buildField('Association', _associationCtrl),
            const SizedBox(height: 14),
          ],
          _buildField('Handicap', _handicapCtrl, keyboardType: TextInputType.numberWithOptions(decimal: true)),
          const SizedBox(height: 14),
          _buildField('Bio', _bioCtrl, maxLines: 3),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1E8F5C),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFF1F4734),
                disabledForegroundColor: const Color(0xFF5E7D72),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Save Changes'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, {int maxLines = 1, TextInputType? keyboardType}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF7EA699)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF165D43)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF1E8F5C), width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFF072E21),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: '$label: ',
        style: const TextStyle(
          color: Color(0xFF7EA699),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        children: [
          TextSpan(
            text: value.isEmpty ? '—' : value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

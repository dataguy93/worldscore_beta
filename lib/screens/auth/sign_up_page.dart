import 'package:flutter/material.dart';

import '../../config/tier_config.dart';
import '../../controllers/session_controller.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({
    required this.sessionController,
    super.key,
  });

  final SessionController sessionController;

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _clubNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  static const _associationOptions = [
    'USGA',
    'Federación Colombiana de Golf',
  ];
  AppTier _selectedTier = AppTier.pro;
  String? _selectedAssociation;

  @override
  void dispose() {
    _usernameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _clubNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      await widget.sessionController.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        username: _usernameController.text.trim(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        tier: _selectedTier,
        clubName: _selectedTier == AppTier.gm
            ? _clubNameController.text.trim()
            : null,
        association: _selectedTier == AppTier.gm ? _selectedAssociation : null,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              widget.sessionController.errorMessage ??
                  'Unable to create account. Please try again.',
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: ListView(
                shrinkWrap: true,
                children: [
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(labelText: 'Username'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Username is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _firstNameController,
                    decoration: const InputDecoration(labelText: 'First Name'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'First name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _lastNameController,
                    decoration: const InputDecoration(labelText: 'Last Name'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Last name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Email is required';
                      }
                      return null;
                    },
                  ),
                  if (_selectedTier == AppTier.gm) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _clubNameController,
                      decoration: const InputDecoration(labelText: 'Club Name'),
                      validator: (value) {
                        if (_selectedTier == AppTier.gm &&
                            (value == null || value.trim().isEmpty)) {
                          return 'Club name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedAssociation,
                      decoration: const InputDecoration(labelText: 'Association'),
                      items: _associationOptions
                          .map(
                            (association) => DropdownMenuItem<String>(
                              value: association,
                              child: Text(association),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedAssociation = value;
                        });
                      },
                      validator: (value) {
                        if (_selectedTier == AppTier.gm &&
                            (value == null || value.isEmpty)) {
                          return 'Association is required';
                        }
                        return null;
                      },
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password'),
                    validator: (value) {
                      if (value == null || value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Confirm Password'),
                    validator: (value) {
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Choose your plan',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<AppTier>(
                    segments: [
                      ButtonSegment<AppTier>(
                        value: AppTier.pro,
                        label: Text(AppTier.pro.label),
                      ),
                      ButtonSegment<AppTier>(
                        value: AppTier.gm,
                        label: Text(AppTier.gm.label),
                      ),
                    ],
                    selected: {_selectedTier},
                    showSelectedIcon: false,
                    onSelectionChanged: (selection) {
                      setState(() {
                        _selectedTier = selection.first;
                        if (_selectedTier != AppTier.gm) {
                          _clubNameController.clear();
                          _selectedAssociation = null;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_selectedTier.monthlyPrice} · ${_selectedTier.info.tagline}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 20),
                  ListenableBuilder(
                    listenable: widget.sessionController,
                    builder: (context, _) {
                      return FilledButton(
                        onPressed: widget.sessionController.isLoading ? null : _submit,
                        child: widget.sessionController.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Create Account'),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

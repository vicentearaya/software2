import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/app_utils.dart';
import '../../shared/services/auth_service.dart';
import '../../shared/services/pool_service.dart';

class RegisterPoolScreen extends StatefulWidget {
  const RegisterPoolScreen({super.key});

  @override
  State<RegisterPoolScreen> createState() => _RegisterPoolScreenState();
}

class _RegisterPoolScreenState extends State<RegisterPoolScreen> {
  final _nameController = TextEditingController();
  final _volumeController = TextEditingController();
  final _locationController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  final _poolService = PoolService();
  final _authService = AuthService();

  String _selectedType = 'Exterior';
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _volumeController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _handleRegisterPool() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final token = await _authService.getToken();
    if (token == null) {
      if (!mounted) return;
      AppUtils.showSnackBar(context, 'Sesión expirada', isError: true);
      setState(() => _isLoading = false);
      return;
    }

    final result = await _poolService.createPool({
      'nombre': _nameController.text.trim(),
      'volumen': double.tryParse(_volumeController.text) ?? 0,
      'tipo': _selectedType.toLowerCase(),
      'ubicacion': _locationController.text.trim(),
    }, token);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success']) {
      AppUtils.showSnackBar(context, AppStrings.poolCreatedSuccess);
      Navigator.pop(context);
    } else {
      AppUtils.showSnackBar(context, result['message'], isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                _buildBackButton(),
                const SizedBox(height: 24),
                _buildHeader(),
                const SizedBox(height: 40),
                _buildNameField(),
                const SizedBox(height: 16),
                _buildVolumeField(),
                const SizedBox(height: 16),
                _buildTypeDropdown(),
                const SizedBox(height: 16),
                _buildLocationField(),
                const SizedBox(height: 32),
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return IconButton(
      onPressed: () => Navigator.pop(context),
      icon: const Icon(
        Icons.arrow_back_ios,
        color: AppColors.textPrimary,
        size: 20,
      ),
      padding: EdgeInsets.zero,
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppStrings.registerPool, style: Theme.of(context).textTheme.displayLarge),
        const SizedBox(height: 8),
        Text(
          'Ingresa los detalles de tu nueva\npiscina para comenzar el monitoreo',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: const InputDecoration(
        hintText: AppStrings.poolName,
        prefixIcon: Icon(
          Icons.pool,
          color: AppColors.textMuted,
          size: 20,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Campo requerido';
        return null;
      },
    );
  }

  Widget _buildVolumeField() {
    return TextFormField(
      controller: _volumeController,
      keyboardType: TextInputType.number,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: const InputDecoration(
        hintText: AppStrings.poolVolume,
        prefixIcon: Icon(
          Icons.water_rounded,
          color: AppColors.textMuted,
          size: 20,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Campo requerido';
        if (double.tryParse(value) == null) return 'Ingresa un número válido';
        return null;
      },
    );
  }

  Widget _buildTypeDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedType,
      dropdownColor: AppColors.surface,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: const InputDecoration(
        hintText: AppStrings.poolType,
        prefixIcon: Icon(
          Icons.category_outlined,
          color: AppColors.textMuted,
          size: 20,
        ),
      ),
      items: ['Exterior', 'Interior'].map((type) {
        return DropdownMenuItem(
          value: type,
          child: Text(type),
        );
      }).toList(),
      onChanged: (value) => setState(() => _selectedType = value!),
    );
  }

  Widget _buildLocationField() {
    return TextFormField(
      controller: _locationController,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: const InputDecoration(
        hintText: AppStrings.poolLocation,
        prefixIcon: Icon(
          Icons.location_on_outlined,
          color: AppColors.textMuted,
          size: 20,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Campo requerido';
        return null;
      },
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _handleRegisterPool,
      child: _isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Text(AppStrings.register),
    );
  }
}

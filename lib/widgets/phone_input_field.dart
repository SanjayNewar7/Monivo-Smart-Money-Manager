
import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class PhoneInputField extends StatelessWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;

  const PhoneInputField({
    Key? key,
    required this.controller,
    this.validator,
    this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.phone,
      maxLength: 10,
      validator: validator,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: 'Phone Number',
        hintText: 'Enter 10-digit phone number',
        prefixIcon: Container(
          padding: const EdgeInsets.all(12),
          child: const Icon(
            Icons.phone_outlined,
            color: AppColors.primaryBlue,
            size: 20,
          ),
        ),
        counterText: '',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}

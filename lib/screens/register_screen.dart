import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'email_verification_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const rose = Color(0xFFB04F6C);
  static const blushPink = Color(0xFFF6DCE2);
  static const forestGreen = Color(0xFF2F3A2A);
  static const warmText = Color(0xFF5E5652);
  static const cardBorder = Color(0xFFEADFDB);
  static const sageGreen = Color(0xFF6E7B5F);

  final nameController = TextEditingController();
  final dobController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final addressController = TextEditingController();
  final cityController = TextEditingController();
  final emergencyNameController = TextEditingController();
  final emergencyPhoneController = TextEditingController();
  final bloodController = TextEditingController();
  final allergyController = TextEditingController();
  final conditionController = TextEditingController();
  final medicationController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    dobController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    addressController.dispose();
    cityController.dispose();
    emergencyNameController.dispose();
    emergencyPhoneController.dispose();
    bloodController.dispose();
    allergyController.dispose();
    conditionController.dispose();
    medicationController.dispose();
    super.dispose();
  }

  Widget inputField(
    String label,
    IconData icon,
    TextEditingController controller, {
    bool password = false,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        obscureText: password,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: rose),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 18,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: cardBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: cardBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: rose, width: 2),
          ),
        ),
      ),
    );
  }

  Widget dateOfBirthField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: dobController,
        readOnly: true,
        onTap: _selectDateOfBirth,
        decoration: InputDecoration(
          labelText: 'Date of Birth',
          prefixIcon: const Icon(Icons.calendar_today_outlined, color: rose),
          suffixIcon: const Icon(Icons.arrow_drop_down, color: sageGreen),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 18,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: cardBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: cardBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: rose, width: 2),
          ),
        ),
      ),
    );
  }

  Future<void> _selectDateOfBirth() async {
    final now = DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: rose,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: forestGreen,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      final day = pickedDate.day.toString().padLeft(2, '0');
      final month = pickedDate.month.toString().padLeft(2, '0');
      final year = pickedDate.year.toString();

      setState(() {
        dobController.text = '$day/$month/$year';
      });
    }
  }

  Widget bloodTypeField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<String>(
        initialValue:
            bloodController.text.isEmpty ? null : bloodController.text,
        decoration: InputDecoration(
          labelText: 'Blood Type',
          prefixIcon: const Icon(Icons.bloodtype_outlined, color: rose),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 18,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: cardBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: cardBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: rose, width: 2),
          ),
        ),
        items: const [
          DropdownMenuItem(value: 'A+', child: Text('A+')),
          DropdownMenuItem(value: 'A-', child: Text('A-')),
          DropdownMenuItem(value: 'B+', child: Text('B+')),
          DropdownMenuItem(value: 'B-', child: Text('B-')),
          DropdownMenuItem(value: 'AB+', child: Text('AB+')),
          DropdownMenuItem(value: 'AB-', child: Text('AB-')),
          DropdownMenuItem(value: 'O+', child: Text('O+')),
          DropdownMenuItem(value: 'O-', child: Text('O-')),
        ],
        onChanged: (value) {
          if (value != null) {
            bloodController.text = value;
          }
        },
      ),
    );
  }

  Widget sectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: blushPink,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: rose, size: 23),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: forestGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool validateForm() {
    if (nameController.text.trim().isEmpty ||
        dobController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        phoneController.text.trim().isEmpty ||
        passwordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty) {
      _showMessage('Please complete all required personal information.');
      return false;
    }

    if (passwordController.text != confirmPasswordController.text) {
      _showMessage('Passwords do not match.');
      return false;
    }

    if (passwordController.text.length < 8) {
      _showMessage('Password must be at least 8 characters.');
      return false;
    }

    if (!emailController.text.contains('@') ||
        !emailController.text.contains('.')) {
      _showMessage('Please enter a valid email address.');
      return false;
    }

    if (phoneController.text.length < 10) {
      _showMessage('Please enter a valid phone number.');
      return false;
    }

    return true;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void createAccount() {
    if (!validateForm()) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EmailVerificationScreen(
          email: emailController.text.trim(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/backgrounds/background.jpeg',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              color: Colors.white.withValues(alpha: 0.25),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      Center(
                        child: Image.asset(
                          'assets/images/logo/logo.png',
                          height: 100,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Create Your Account',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: forestGreen,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Join Her Health and take charge of your wellness.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15, color: warmText),
                      ),
                      sectionTitle(
                        'Personal Information',
                        Icons.person_outline,
                      ),
                      inputField(
                          'Full Name', Icons.person_outline, nameController),
                      dateOfBirthField(),
                      inputField(
                        'Email Address',
                        Icons.email_outlined,
                        emailController,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      inputField(
                        'Phone Number',
                        Icons.phone_outlined,
                        phoneController,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(15),
                        ],
                      ),
                      inputField(
                        'Password',
                        Icons.lock_outline,
                        passwordController,
                        password: true,
                      ),
                      inputField(
                        'Confirm Password',
                        Icons.lock_reset_outlined,
                        confirmPasswordController,
                        password: true,
                      ),
                      sectionTitle(
                        'Contact Information',
                        Icons.location_on_outlined,
                      ),
                      inputField(
                        'Street Address',
                        Icons.home_outlined,
                        addressController,
                      ),
                      inputField(
                        'City',
                        Icons.location_city_outlined,
                        cityController,
                      ),
                      inputField(
                        'Emergency Contact Name',
                        Icons.contact_phone_outlined,
                        emergencyNameController,
                      ),
                      inputField(
                        'Emergency Contact Number',
                        Icons.phone_in_talk_outlined,
                        emergencyPhoneController,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(15),
                        ],
                      ),
                      sectionTitle(
                        'Health Information',
                        Icons.health_and_safety_outlined,
                      ),
                      bloodTypeField(),
                      inputField(
                        'Allergies',
                        Icons.warning_amber_outlined,
                        allergyController,
                      ),
                      inputField(
                        'Medical Conditions',
                        Icons.medical_information_outlined,
                        conditionController,
                      ),
                      inputField(
                        'Current Medication',
                        Icons.medication_outlined,
                        medicationController,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: rose,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          onPressed: createAccount,
                          child: const Text(
                            'Create Account',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

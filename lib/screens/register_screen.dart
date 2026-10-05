import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'email_verification_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController nameController = TextEditingController();
  final TextEditingController dobController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  final TextEditingController addressController = TextEditingController();
  final TextEditingController cityController = TextEditingController();

  final TextEditingController emergencyNameController = TextEditingController();

  final TextEditingController emergencyPhoneController =
      TextEditingController();

  final TextEditingController bloodController = TextEditingController();
  final TextEditingController allergyController = TextEditingController();
  final TextEditingController conditionController = TextEditingController();
  final TextEditingController medicationController = TextEditingController();

  // ============================================================
  // DISPOSE
  // ============================================================

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

  // ============================================================
  // NORMAL INPUT FIELD
  // ============================================================

  Widget inputField(
    String label,
    IconData icon,
    TextEditingController controller, {
    bool password = false,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        obscureText: password,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(
            icon,
            color: const Color(0xFF959B7D),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(
              color: Color(0xFFE89CB0),
              width: 2,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DATE OF BIRTH
  // ============================================================

  Widget dateOfBirthField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: dobController,
        readOnly: true,
        onTap: _selectDateOfBirth,
        decoration: InputDecoration(
          labelText: "Date of Birth",
          prefixIcon: const Icon(
            Icons.calendar_today,
            color: Color(0xFF959B7D),
          ),
          suffixIcon: const Icon(
            Icons.arrow_drop_down,
            color: Color(0xFF959B7D),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(
              color: Color(0xFFE89CB0),
              width: 2,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DATE PICKER
  // ============================================================

  Future<void> _selectDateOfBirth() async {
    final now = DateTime.now();

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(
        now.year - 18,
        now.month,
        now.day,
      ),
      firstDate: DateTime(1900),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFE89CB0),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF959B7D),
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
        dobController.text = "$day/$month/$year";
      });
    }
  }

  // ============================================================
  // BLOOD TYPE DROPDOWN
  // ============================================================

  Widget bloodTypeField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField<String>(
        initialValue:
            bloodController.text.isEmpty ? null : bloodController.text,
        decoration: InputDecoration(
          labelText: "Blood Type 🩸",
          prefixIcon: const Icon(
            Icons.bloodtype,
            color: Color(0xFF959B7D),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
        ),
        items: const [
          DropdownMenuItem(
            value: "A+",
            child: Text("A+"),
          ),
          DropdownMenuItem(
            value: "A-",
            child: Text("A-"),
          ),
          DropdownMenuItem(
            value: "B+",
            child: Text("B+"),
          ),
          DropdownMenuItem(
            value: "B-",
            child: Text("B-"),
          ),
          DropdownMenuItem(
            value: "AB+",
            child: Text("AB+"),
          ),
          DropdownMenuItem(
            value: "AB-",
            child: Text("AB-"),
          ),
          DropdownMenuItem(
            value: "O+",
            child: Text("O+"),
          ),
          DropdownMenuItem(
            value: "O-",
            child: Text("O-"),
          ),
        ],
        onChanged: (value) {
          if (value != null) {
            bloodController.text = value;
          }
        },
      ),
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 25,
        bottom: 10,
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Color(0xFF959B7D),
        ),
      ),
    );
  }

  // ============================================================
  // VALIDATE FORM
  // ============================================================

  bool validateForm() {
    if (nameController.text.trim().isEmpty ||
        dobController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        phoneController.text.trim().isEmpty ||
        passwordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty) {
      _showMessage("Please complete all required personal information.");
      return false;
    }

    if (passwordController.text != confirmPasswordController.text) {
      _showMessage("Passwords do not match.");
      return false;
    }

    if (passwordController.text.length < 8) {
      _showMessage("Password must be at least 8 characters.");
      return false;
    }

    if (!emailController.text.contains("@") ||
        !emailController.text.contains(".")) {
      _showMessage("Please enter a valid email address.");
      return false;
    }

    if (phoneController.text.length < 10) {
      _showMessage("Please enter a valid phone number.");
      return false;
    }

    return true;
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ============================================================
  // CREATE ACCOUNT
  // ============================================================

  void createAccount() {
    if (!validateForm()) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EmailVerificationScreen(
          email: emailController.text.trim(),
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ========================================================
          // BACKGROUND
          // ========================================================

          Image.asset(
            'assets/images/backgrounds/background.jpeg',
            fit: BoxFit.cover,
            height: double.infinity,
            width: double.infinity,
          ),

          Container(
            color: Colors.white.withValues(alpha: 0.25),
          ),

          // ========================================================
          // CONTENT
          // ========================================================

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(25),
              child: Column(
                children: [
                  // ==================================================
                  // LOGO
                  // ==================================================

                  Image.asset(
                    'assets/images/logo/logo.png',
                    height: 100,
                  ),

                  const SizedBox(height: 15),

                  const Text(
                    "Create Your Her Health Account 🌸",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF959B7D),
                    ),
                  ),

                  // ==================================================
                  // PERSONAL INFORMATION
                  // ==================================================

                  sectionTitle("👤 Personal Information"),

                  inputField(
                    "Full Name",
                    Icons.person,
                    nameController,
                  ),

                  // DATE PICKER
                  dateOfBirthField(),

                  // EMAIL
                  inputField(
                    "Email Address",
                    Icons.email,
                    emailController,
                    keyboardType: TextInputType.emailAddress,
                  ),

                  // PHONE — NUMBERS ONLY
                  inputField(
                    "Phone Number",
                    Icons.phone,
                    phoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(15),
                    ],
                  ),

                  // PASSWORD
                  inputField(
                    "Password",
                    Icons.lock,
                    passwordController,
                    password: true,
                  ),

                  // CONFIRM PASSWORD
                  inputField(
                    "Confirm Password",
                    Icons.lock_outline,
                    confirmPasswordController,
                    password: true,
                  ),

                  // ==================================================
                  // CONTACT INFORMATION
                  // ==================================================

                  sectionTitle("🏠 Contact Information"),

                  inputField(
                    "Street Address",
                    Icons.home,
                    addressController,
                  ),

                  inputField(
                    "City",
                    Icons.location_city,
                    cityController,
                  ),

                  inputField(
                    "Emergency Contact Name",
                    Icons.contact_phone,
                    emergencyNameController,
                  ),

                  // EMERGENCY PHONE — NUMBERS ONLY
                  inputField(
                    "Emergency Contact Number",
                    Icons.phone_in_talk,
                    emergencyPhoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(15),
                    ],
                  ),

                  // ==================================================
                  // HEALTH INFORMATION
                  // ==================================================

                  sectionTitle("❤️ Health Information"),

                  // BLOOD TYPE — DROPDOWN
                  bloodTypeField(),

                  inputField(
                    "Allergies ⚠️",
                    Icons.warning,
                    allergyController,
                  ),

                  inputField(
                    "Medical Conditions",
                    Icons.medical_information,
                    conditionController,
                  ),

                  inputField(
                    "Current Medication 💊",
                    Icons.medication,
                    medicationController,
                  ),

                  const SizedBox(height: 30),

                  // ==================================================
                  // CREATE ACCOUNT BUTTON
                  // ==================================================

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE89CB0),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: createAccount,
                      child: const Text(
                        "Create Account 🌸",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Classes/areas.dart';
import 'RegisterAddress.dart';

class CRegister extends StatefulWidget {
  const CRegister({Key? key}) : super(key: key);

  @override
  State<CRegister> createState() => _CRegisterState();
}

class _CRegisterState extends State<CRegister> {
  final CollectionReference appUsers = FirebaseFirestore.instance.collection('appUsers');
  final CollectionReference areas = FirebaseFirestore.instance.collection('Areas');
  final _formKey = GlobalKey<FormState>();
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController accountNumberController = TextEditingController();
  String? selectedArea;
  List<Areas> areasList = [];
  bool? isPersonalAccount;
  String? paymentMethod;
  bool _obscurePassword = true;

  void _next() {
    if (_formKey.currentState!.validate()) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CustomerAddress(
              name: nameController.text,
              email: emailController.text,
              phone: phoneController.text,
              isPersonalAccount: isPersonalAccount,
              password: passwordController.text,
              paymentMethod: paymentMethod,
              accountNumber: accountNumberController.text
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Builder(
        builder: (BuildContext context) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(-0.16, -0.99),
                end: Alignment(0.16, 0.99),
                colors: [Color(0xFF0F6C35), Color(0xC4E5E5E5)],
              ),
            ),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: screenHeight * 0.1),
                    buildHeader(screenWidth, screenHeight),
                    buildTextField('Name', nameController, 'Please enter your name'),
                    buildTextField('Email', emailController, 'Please enter your Email'),
                    buildPasswordField(),
                    buildTextField('Phone', phoneController, 'Please enter your Phone Number', isPhone: true),
                    buildRadioRow('Personal Account', true),
                    buildRadioRow('Company Account', false),
                    buildTextField('Account Number', accountNumberController, 'Please enter your account number', isAccountNumber: true),
                    buildPaymentMethodRadio('JazzCash'),
                    buildPaymentMethodRadio('EasyPaisa'),
                    SizedBox(height: screenHeight * 0.05),
                    ElevatedButton(
                      onPressed: _next,
                      child: const Text('Next'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget buildHeader(double screenWidth, double screenHeight) => Container(
    width: screenWidth * 0.9,
    height: screenHeight * 0.07,
    decoration: ShapeDecoration(
      color: const Color(0xFF00401A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
    ),
    child: Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        Expanded(
          child: const Center(
            child: Text(
              'Register',
              style: TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'Poppins', fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    ),
  );

  Widget buildTextField(String label, TextEditingController controller, String? validatorMessage, {bool isPhone = false, bool isAccountNumber = false}) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
    child: TextFormField(
      controller: controller,
      keyboardType: isPhone || isAccountNumber ? TextInputType.number : TextInputType.text,
      maxLength: isPhone || isAccountNumber ? 11 : null,
      decoration: InputDecoration(
        hintText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
        filled: true,
        fillColor: Colors.white,
        counterText: "", // Hide the counter
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return validatorMessage;
        }
        if (isPhone || isAccountNumber) {
          if (value.length != 11) {
            return 'Must be exactly 11 digits';
          }
        }
        return null;
      },
    ),
  );

  Widget buildPasswordField() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
    child: TextFormField(
      controller: passwordController,
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        hintText: 'Password',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
        filled: true,
        fillColor: Colors.white,
        suffixIcon: IconButton(
          icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your Password';
        }
        if (value.length < 6) {
          return 'Password must be at least 6 characters long';
        }
        return null;
      },
    ),
  );

  Widget buildRadioRow(String label, bool value) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Radio<bool>(
        value: value,
        groupValue: isPersonalAccount,
        onChanged: (bool? newValue) {
          setState(() => isPersonalAccount = newValue);
        },
      ),
      Text(label, style: const TextStyle(fontSize: 16)),
    ],
  );

  Widget buildPaymentMethodRadio(String method) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Radio<String>(
        value: method,
        groupValue: paymentMethod,
        onChanged: (String? newValue) {
          setState(() => paymentMethod = newValue);
        },
      ),
      Text(method, style: const TextStyle(fontSize: 16)),
    ],
  );
}

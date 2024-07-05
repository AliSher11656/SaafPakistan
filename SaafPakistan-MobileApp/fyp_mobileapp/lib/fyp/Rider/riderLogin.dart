import 'package:flutter/material.dart';
import '../Customer/Login.dart';
import 'Dashboard.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RLogin extends StatefulWidget {
  const RLogin({Key? key}) : super(key: key);

  @override
  State<RLogin> createState() => _RLoginState();
}

class _RLoginState extends State<RLogin> {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool isLoading = false;

  // Function to show a SnackBar with a given message
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 2),
    ));
  }

  Future<void> login() async {
    setState(() {
      isLoading = true;
    });

    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      _showSnackBar('Please enter a valid email address');
      setState(() {
        isLoading = false;
      });
      return;
    }

    if (password.length < 6) {
      _showSnackBar('Password must be at least 6 characters long');
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );

      User? user = userCredential.user;
      if (user != null) {
        Map<String, dynamic> userData = await getUserData(user.uid);

        if (userData.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Dashboard(
                uid: user.uid,
              ),
            ),
          );

          // Clear text fields after successful login
          emailController.clear();
          passwordController.clear();
        } else {
          // Show SnackBar for user data not found
          _showSnackBar('User data not found');
        }
      }
    } catch (e) {
      print('Error during login: $e');
      emailController.clear();
      passwordController.clear();
      // Show SnackBar for incorrect email or password
      _showSnackBar('Incorrect email or password entered');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<Map<String, dynamic>> getUserData(String uid) async {
    try {
      DocumentSnapshot documentSnapshot =
      await _firestore.collection('rider').doc(uid).get();
      if (documentSnapshot.exists) {
        return documentSnapshot.data() as Map<String, dynamic>;
      } else {
        print('User data not found');
        return {};
      }
    } catch (e) {
      print('Error fetching user data: $e');
      return {};
    }
  }

  void navigateToCustomerLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CLogin()),
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return Stack(
      children: [
      Scaffold(
      key: scaffoldKey,
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(16.0),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-0.16, -0.99),
              end: Alignment(0.16, 0.99),
              colors: [Color(0xC4E5E5E5), Color(0xC4E5E5E5)],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: screenHeight * 0.17),
              const Text(
                'Welcome to',
                style: TextStyle(
                  color: Color(0xFF111111),
                  fontSize: 18,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: screenHeight * 0.02),
              const Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Saaf',
                      style: TextStyle(
                        color: Color(0xFF00401A),
                        fontSize: 36,
                        fontFamily: 'Anton',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(
                      text: 'Pakistan',
                      style: TextStyle(
                        color: Color(0xFF00401A),
                        fontSize: 36,
                        fontFamily: 'Anton',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: screenHeight * 0.02),
              SizedBox(
                width: screenWidth * 0.9,
                child: const Text(
                  'Rider',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF111111),
                    fontSize: 18,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    height: 0.08,
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.15),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  hintText: 'E-mail',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.05),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Password',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.1),
              GestureDetector(
                onTap: isLoading ? null : login,
                child: Container(
                  width: 150,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isLoading ? Colors.grey : Color(0xFF00401A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      'Login',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.02),
              SizedBox(height: screenHeight * 0.07),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text(
                    'Rider?',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  Switch(
                    value: true,
                    onChanged: (value) {
                      navigateToCustomerLogin();
                    },
                    activeColor: Color(0xFF00401A),
                  ),
                ],
              ),
              SizedBox(height: screenHeight * 0.05),
            ],
          ),
        ),
      ),
    ),
    if (isLoading)
    Positioned.fill(
    child: Container(
    color: Colors.black.withOpacity(0.5),
    child: Center(
    child: CircularProgressIndicator(),
    ),
    ),
    ),
    ],
    );
    }
}
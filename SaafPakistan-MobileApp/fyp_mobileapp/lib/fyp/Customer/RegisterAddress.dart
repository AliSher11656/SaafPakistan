import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'Login.dart';
import '../Classes/areas.dart';
import 'package:tplmapsflutterplugin/TplMapsView.dart';

import 'RegisterMap.dart'; // Import TPL Maps

class CustomerAddress extends StatefulWidget {
  final String name;
  final String email;
  final String phone;
  final bool? isPersonalAccount;
  final String password;
  final String? paymentMethod;
  final String accountNumber;

  const CustomerAddress({
    Key? key,
    required this.name,
    required this.email,
    required this.phone,
    required this.isPersonalAccount,
    required this.password,
    required this.paymentMethod,
    required this.accountNumber,
  }) : super(key: key);

  @override
  State<CustomerAddress> createState() => _CustomerAddressState();
}

class _CustomerAddressState extends State<CustomerAddress> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CollectionReference appUsers = FirebaseFirestore.instance.collection('appUsers');
  final CollectionReference areas = FirebaseFirestore.instance.collection('Areas');
  String? selectedArea;
  List<Areas> areasList = [];
  String address = '';
  String latitude = '';
  String longitude = '';
  bool _isMapVisible = true; // Flag to control map visibility

  @override
  void initState() {
    super.initState();
    getAreas();
  }

  Future<void> getAreas() async {
    QuerySnapshot querySnapshot = await areas.get();
    setState(() {
      areasList = querySnapshot.docs
          .map((doc) => Areas.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  void _register() async {
    if (selectedArea == null || address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    Map<String, dynamic> userData = {
      'name': widget.name,
      'email': widget.email,
      'phone': widget.phone,
      'area': selectedArea,
      'paymentMethod': widget.paymentMethod,
      'paymentNumber': widget.accountNumber,
      'accountType': widget.isPersonalAccount == true ? 'Personal' : 'Company',
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
    };

    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: widget.email,
        password: widget.password,
      );

      String userId = userCredential.user!.uid;

      await appUsers.doc(userId).set(userData);

      // Create entry in leaderboard table
      Map<String, dynamic> leaderboardData = {
        'accountType': userData['accountType'],
        'cus': userData['name'],
        'points': 0.0,
        'wasteRecycled': 0.0,
        'uid': userId,
      };
      // Add entry to 'leaderboard' collection
      await FirebaseFirestore.instance.collection('leaderboards').doc(userId).set(leaderboardData);

      // Add entry to 'friends' collection
      Map<String, dynamic> friendData = {
        'name': userData['name'],
        'status': "Friend",
      };
      await FirebaseFirestore.instance
          .collection('friends')
          .doc(userId)
          .collection('addedFriends')
          .doc(userId)
          .set(friendData);

      print('Registration successful for user with ID: $userId');

      // Hide the map and navigate to login screen
      setState(() {
        _isMapVisible = false;
      });

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CLogin()),
      );
    } catch (e) {
      print('Error during registration: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error during registration: $e')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(-0.16, -0.99),
            end: Alignment(0.16, 0.99),
            colors: [Color(0xFF0F6C35), Color(0xC4E5E5E5)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: screenHeight * 0.1),
            Container(
              width: screenWidth * 0.9,
              height: screenHeight * 0.07,
              decoration: ShapeDecoration(
                color: const Color(0xFF00401A),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9)),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: screenWidth * 0.1,
                    height: screenHeight * 0.07,
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  SizedBox(
                    width: screenWidth * 0.7,
                    height: screenHeight * 0.5,
                    child: const Center(
                      child: Text(
                        'Register',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          height: 0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: screenHeight * 0.03),
            DropdownButtonFormField<String>(
              value: selectedArea,
              onChanged: (newValue) {
                setState(() {
                  selectedArea = newValue;
                });
              },
              items: areasList.map((Areas area) {
                return DropdownMenuItem<String>(
                  value: area.location,
                  child: Text(area.location),
                );
              }).toList(),
              decoration: InputDecoration(
                labelText: 'Select Area',
                contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
            SizedBox(height: screenHeight * 0.04),
            _isMapVisible
                ? Expanded(
                  child: Container(
              width: screenWidth * 0.9,
              height: screenHeight * 0.5,
              child: Maps(
                  onAddressSelected: (selectedAddress, lat, lng) {
                    setState(() {
                      address = selectedAddress;
                      latitude = lat;
                      longitude = lng;
                    });
                  },
              ),
            ),
                )
                : Container(),
            SizedBox(height: screenHeight * 0.02),
            ElevatedButton(
              onPressed: _register,
              child: const Text('Register'),
            ),
          ],
        ),
      ),
    );
  }
}

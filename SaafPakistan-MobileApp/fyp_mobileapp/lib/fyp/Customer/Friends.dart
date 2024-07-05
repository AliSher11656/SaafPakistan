import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Friends extends StatefulWidget {
  const Friends({super.key});

  @override
  State<Friends> createState() => _FriendsState();
}

class _FriendsState extends State<Friends> {
  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.only(left: 10, right: 10),
        width: double.infinity,
        height: double.infinity,
        color: const Color(0xFFCCCCCC).withOpacity(0.3),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: screenHeight * 0.1),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "Friends",
                    style: TextStyle(
                        color: Color(0xFF00401A),
                        fontWeight: FontWeight.bold,
                        fontSize: 30),
                  ),
                  SizedBox(width: screenWidth * 0.55),
                  IconButton(
                    icon: const Icon(
                      Icons.exit_to_app,
                      color: Colors.black,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  )
                ],
              ),
              SizedBox(height: screenHeight * 0.001),
              const Divider(
                thickness: 1,
                color: Colors.black,
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "Friend Requests",
                      style: TextStyle(
                          color: Color(0xFF00401A),
                          fontWeight: FontWeight.bold,
                          fontSize: 18),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(
                          color: Color(0xFF00401A),// Border color
                          width: 2, // Border width
                        ),// Background color
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.search,
                          color: Color(0xFF00401A),
                          size: 30,
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    )
                  ],
                ),
              ),

            ]
        ),
      ),
    );
  }
}

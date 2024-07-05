import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'Dashboard.dart';

class Profile extends StatefulWidget {
  final String uid;

  const Profile({Key? key, required this.uid}) : super(key: key);

  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  late Future<DocumentSnapshot> userData;

  @override
  void initState() {
    super.initState();
    userData = FirebaseFirestore.instance.collection('rider').doc(widget.uid).get();
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(10),
          width: double.infinity,
          height: screenHeight * 1.5,
          color: const Color(0xFFCCCCCC).withOpacity(0.3),
          child: FutureBuilder<DocumentSnapshot>(
            future: userData,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text('Error: ${snapshot.error}'),
                );
              }

              var userData = snapshot.data!;

              return Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: screenHeight * 0.03),
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0,right:8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          "Profile",
                          style: TextStyle(
                            color: Color(0xFF00401A),
                            fontWeight: FontWeight.bold,
                            fontSize: 30,
                          ),
                        ),
                        Spacer(),
                        IconButton(
                          icon: const Icon(
                            Icons.exit_to_app,
                            color: Colors.black,
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  Column(
                      children: [
                        buildDisplayField("Name", userData['name']),
                        buildDisplayField("Email", userData['email']),
                        buildDisplayField("Phone", userData['phone']),
                        buildDisplayField("Home Address", userData['address']),
                        buildDisplayField("Vehicle Number", userData['vehicleNumber']),
                      ],
                    ),
                  SizedBox(height: screenHeight * 0.20),
                  Container(
                    width: screenWidth * 0.87,
                    height: screenHeight * 0.06,
                    decoration: ShapeDecoration(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 25.0),
                          child: IconButton(
                            icon: const Icon(
                              Icons.home,
                              color: Colors.black,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => Dashboard(
                                    uid: widget.uid,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        Container(
                          height: screenHeight * 0.05,
                          width: 1,
                          color: Colors.green,
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.menu,
                            color: Colors.black,
                          ),
                          onPressed: () {
                          },
                        ),
                        Container(
                          height: screenHeight * 0.05,
                          width: 1,
                          color: Colors.green,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 25.0),
                          child: IconButton(
                            icon: const Icon(
                              Icons.person,
                              color: Colors.blue,

                            ),
                            onPressed: () {
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }


  Widget buildDisplayField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 30,
            decoration: ShapeDecoration(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: Text(
                '$label',
                style: TextStyle(
                  color: Color(0xFF00401A),
                  fontSize: 15,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
          // Add some vertical space between label and value
          Container(
            height: 50,
            decoration: ShapeDecoration(
              color: Colors.grey[400],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Text(
                value,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

}
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fyp_mobileapp/fyp/Customer/Login.dart';
import 'Leaderboards.dart';
import 'Profile.dart';
import 'whyRecycle.dart';
import 'SchedulePickup.dart';
import 'Orders.dart';

class Dashboard extends StatefulWidget {
  final String uid;

  const Dashboard({
    Key? key,
    required this.uid,
  }) : super(key: key);

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  late String uid;
  String? userName;
  String? accountType;
  late List<Map<String, dynamic>> statsList = [];
  late List<Map<String, dynamic>> organizationList = [];
  bool statsLoading = true;
  bool organizationsLoading = true;

  @override
  void initState() {
    super.initState();
    uid = widget.uid;

    displayUserInfo();
    displayStats();
    fetchTopOrganizations();
    checkAndHandleRiderPickup();
  }

  Future<void> displayUserInfo() async {
    setState(() {
      statsLoading = true;
    });

    try {
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('appUsers')
          .doc(uid)
          .get();

      if (userSnapshot.exists) {
        var data = userSnapshot.data() as Map<String, dynamic>; // Safely cast to Map
        String userName = data['name'] ?? ''; // Default to empty string if null
        String accountType = data['accountType'] ?? ''; // Default to empty string if null

        setState(() {
          this.userName = userName;
          this.accountType = accountType;
          statsLoading = false;
        });
      } else {
        setState(() {
          statsLoading = false;
        });
        print('User data not found');
      }
    } catch (error) {
      print('Error fetching user data: $error');
      setState(() {
        statsLoading = false;
      });
    }
  }

  Future<void> checkAndHandleRiderPickup() async {
    try {
      QuerySnapshot ordersSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('customer', isEqualTo: uid)
          .where('status', isEqualTo: 3)
          .get();

      if (ordersSnapshot.docs.isNotEmpty) {
        QueryDocumentSnapshot orderSnapshot = ordersSnapshot.docs.first;
        double pickupPrice = orderSnapshot['pickupPrice'];
        double pickupWeight = orderSnapshot['pickupWeight'];

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("Confirm Rider Pick-Up"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Pickup Price: $pickupPrice"),
                  Text("Pickup Weight: $pickupWeight"),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    orderSnapshot.reference.update({'status': 1});
                  },
                  child: Text("Cancel"),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    orderSnapshot.reference.update({'status': 2});
                  },
                  child: Text("Confirm"),
                ),
              ],
            );
          },
        );
      }
    } catch (error) {
      print('Error checking and handling rider pickup: $error');
    }
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => CLogin()),
      );
    } catch (e) {
      print('Error logging out: $e');
    }
  }

  Future<void> displayStats() async {
    setState(() {
      statsLoading = true;
    });

    try {
      QuerySnapshot ordersSnapshot = await FirebaseFirestore.instance
          .collection('userStats')
          .where('customerId', isEqualTo: uid)
          .get();

      statsList = ordersSnapshot.docs.map((stats) {
        var data = stats.data() as Map<String, dynamic>; // Safely cast to Map

        double parseDouble(String? value) {
          return value != null ? double.tryParse(value) ?? 0.0 : 0.0;
        }

        return {
          'cashEarned': parseDouble(data['cashEarned'] as String?), // Parse from string to double
          'wasteRecycled': parseDouble(data['wasteRecycled'] as String?), // Parse from string to double
          'co2eReduced': parseDouble(data['co2eReduced'] as String?), // Parse from string to double
        };
      }).toList();

      setState(() {
        statsLoading = false;
      });
    } catch (error) {
      print('Error fetching stats: $error');
      setState(() {
        statsLoading = false;
      });
    }
  }

  Future<void> fetchTopOrganizations() async {
    setState(() {
      organizationsLoading = true;
    });

    try {
      QuerySnapshot organizationsSnapshot = await FirebaseFirestore.instance
          .collection('leaderboards')
          .where('accountType', isEqualTo: 'Company')
          .orderBy('wasteRecycled', descending: true)
          .limit(3)
          .get();


      organizationList = organizationsSnapshot.docs.map((organization) {
        return {
          'organizationName': organization['cus'],
          'wasteRecycled': organization['wasteRecycled'] ?? 0,
        };
      }).toList();

      setState(() {
        organizationsLoading = false;
      });
    } catch (error) {
      print('Error fetching top organizations: $error');
      setState(() {
        organizationsLoading = false;
      });
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      statsLoading = true;
      organizationsLoading = true;
    });
    await displayStats();
    await fetchTopOrganizations();
    setState(() {
      statsLoading = false;
      organizationsLoading = false;
    });

    checkAndHandleRiderPickup();
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;
    Map<String, dynamic> stats = statsList.isNotEmpty ? statsList.first : {};

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          child: Container(
            color: const Color(0xFFCCCCCC).withOpacity(0.3),
            padding: const EdgeInsets.only(left: 10, right: 10),
            child: Column(
              children: [
                SizedBox(height: screenHeight * 0.06),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      width: screenWidth * 0.8,
                      height: screenHeight * 0.07,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          statsLoading || userName == null
                              ? Text("")
                              : Text(
                            'Hi, ${userName}',
                            style: TextStyle(
                              color: Color(0xFF050505),
                              fontSize: 18,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w500,
                              height: 0.08,
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.025),
                          statsLoading
                              ? Container()
                              : Text(
                            'Lets Paint Pakistan Green!',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w300,
                              height: 0.12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.exit_to_app,
                        color: Colors.black,
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text("Confirm Logout"),
                              content: Text("Are you sure you want to logout?"),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: Text("Cancel"),
                                ),
                                TextButton(
                                  onPressed: () {
                                    _logout();
                                    Navigator.of(context).pop();
                                  },
                                  child: Text("Logout"),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    )
                  ],
                ),
                const Divider(
                  thickness: 1,
                  color: Colors.black,
                ),
                SizedBox(height: screenHeight * 0.01),
                Container(
                  width: screenWidth * 0.87,
                  height: screenHeight * 0.12,
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
                      SizedBox(
                        height: screenHeight * 0.021,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              child: Text(
                                'WASTE RECYCLED',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 10,
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w400,
                                  height: screenHeight * 0.0001,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.recycling,
                                color: Color(0xFF00401A),
                              ),
                              onPressed: () {},
                            ),
                            SizedBox(
                              height: screenHeight * 0.004,
                            ),
                            SizedBox(
                              child: Text(
                                '${stats['wasteRecycled'] ?? 0} Kgs',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 10,
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w300,
                                  height: screenHeight * 0.0001,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: screenHeight * 0.1,
                        width: 1,
                        color: Color(0xFF00401A),
                        margin: EdgeInsets.only(right: 12, left: 8),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(
                                child: Text(
                                  'CASH EARNED',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 10,
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w400,
                                    height: screenHeight * 0.0001,
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: screenHeight * 0.015,
                              ),
                              Text(
                                'PKR',
                                style: TextStyle(
                                  color: Color(0xFF00401A),
                                  fontSize: 20.0, // You can adjust the font size as needed
                                ),
                              ),
                              SizedBox(
                                height: screenHeight * 0.015,
                              ),
                              SizedBox(
                                child: Text(
                                  '${stats['cashEarned'] ?? 0} PKR',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 10,
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w300,
                                    height: screenHeight * 0.0001,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        height: screenHeight * 0.1,
                        width: 1,
                        color: Color(0xFF00401A),
                        margin: EdgeInsets.only(right: 20, left: 8),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 20.0),
                        child: Container(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(
                                child: Text(
                                  'CO2e REDUCED',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 10,
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w400,
                                    height: screenHeight * 0.0001,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: SvgPicture.asset(
                                  "assets/icons/co2.svg",
                                  color: Color(0xFF00401A),
                                ),
                                onPressed: () {},
                              ),
                              SizedBox(
                                height: screenHeight * 0.004,
                              ),
                              SizedBox(
                                child: Text(
                                  '${stats['co2eReduced'] ?? 0} Kgs',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 10,
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w300,
                                    height: screenHeight * 0.0001,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                SizedBox(height: screenHeight * 0.01),
                const Divider(
                  thickness: 1,
                  color: Colors.black,
                ),
                SizedBox(height: screenHeight * 0.03),
                Padding(
                  padding: const EdgeInsets.only(
                    left: 16.0,
                    right: 16.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Schedule Pickup',
                              style: TextStyle(
                                color: Color(0xFF00401A),
                                fontSize: 16,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600,
                                height: 0.09,
                                letterSpacing: 0.37,
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.01),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => SchedulePickup(
                                          uid: widget.uid,
                                          accountType: accountType ?? '',
                                        )));
                              },
                              child: Container(
                                width: screenWidth * 0.4,
                                height: screenHeight * 0.245,
                                decoration: ShapeDecoration(
                                  color: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: SvgPicture.asset(
                                  "assets/icons/Pickup.svg",
                                ),
                              ),
                            ),
                          ]),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Why Recycle?',
                            style: TextStyle(
                              color: Color(0xFF00401A),
                              fontSize: 16,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              height: 0.09,
                              letterSpacing: 0.37,
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.01),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => WhyRecycle(
                                    uid: widget.uid,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              width: screenWidth * 0.4,
                              height: screenHeight * 0.09,
                              decoration: ShapeDecoration(
                                color: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Image.asset("assets/images/why.png"),
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.05),
                          const Text(
                            'Leaderboards',
                            style: TextStyle(
                              color: Color(0xFF00401A),
                              fontSize: 16,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              height: 0.09,
                              letterSpacing: 0.37,
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.01),
                          Container(
                            width: screenWidth * 0.4,
                            height: screenHeight * 0.09,
                            decoration: ShapeDecoration(
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: IconButton(
                              icon: SvgPicture.asset(
                                "assets/icons/leader.svg",
                                color: Color(0xFF00401A),
                                height: 45,
                                width: 45,
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => Leaderboards(
                                      uid: widget.uid,
                                      accountType: accountType ?? '',
                                      userName: userName ?? '',
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
                SizedBox(height: screenHeight * 0.01),
                const Divider(
                  thickness: 1,
                  color: Colors.black,
                ),
                SizedBox(height: screenHeight * 0.02),
                organizationsLoading
                    ? const CircularProgressIndicator()
                    : Padding(
                  padding: EdgeInsets.only(left: 16.0, right: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Green Organizations',
                        style: TextStyle(
                          color: Color(0xFF00401A),
                          fontSize: 16,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          height: 0.09,
                          letterSpacing: 0.37,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: screenHeight * 0.005),
                organizationsLoading
                    ? CircularProgressIndicator()
                    : GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Leaderboards(
                          uid: widget.uid,
                          accountType: accountType ?? '',
                          userName: userName ?? '',
                          initialTabIndex: 0, // Assuming the Organizations tab is the third tab
                        ),
                      ),
                    );
                  },
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 10),
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 5,
                          blurRadius: 7,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Table(
                      columnWidths: const {
                        0: FlexColumnWidth(1.2),
                        1: FlexColumnWidth(3),
                        2: FlexColumnWidth(3),
                      },
                      children: [
                        TableRow(
                          decoration: BoxDecoration(
                            color: Color(0xFF00401A),
                            borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                          ),
                          children: const [
                            TableCell(
                              child: Padding(
                                padding: EdgeInsets.all(12.0),
                                child: Text(
                                  'Rank',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                            TableCell(
                              child: Padding(
                                padding: EdgeInsets.all(12.0),
                                child: Text(
                                  'Organization Name',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                            TableCell(
                              child: Padding(
                                padding: EdgeInsets.all(12.0),
                                child: Text(
                                  'Waste Recycled (kgs)',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ],
                        ),
                        for (int index = 0; index < organizationList.length; index++)
                          TableRow(
                            decoration: BoxDecoration(
                              color: index % 2 == 0 ? Colors.grey[100] : Colors.white,
                              borderRadius: index == organizationList.length - 1
                                  ? BorderRadius.vertical(bottom: Radius.circular(10))
                                  : BorderRadius.zero,
                            ),
                            children: [
                              TableCell(
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      color: Colors.black,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                              TableCell(
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Text(
                                    '${organizationList[index]['organizationName']}',
                                    style: TextStyle(
                                      color: Colors.black,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                              TableCell(
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Text(
                                    '${organizationList[index]['wasteRecycled']}',
                                    style: TextStyle(
                                      color: Colors.black,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.01),
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
                            color: Colors.blue,
                          ),
                          onPressed: () {},
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
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Orders(uid: widget.uid),
                            ),
                          );
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
                            color: Colors.black,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => Profile(uid: widget.uid),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

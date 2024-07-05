import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fyp_mobileapp/fyp/Rider/riderLogin.dart';
import 'Profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'OrderDetails.dart';
import 'Orders.dart';

class Dashboard extends StatefulWidget {
  final String uid;

  const Dashboard({Key? key, required this.uid}) : super(key: key);

  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  late String userName;
  late String uid;
  late String riderArea; // Add riderArea property
  late List<Map<String, dynamic>> ordersList = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize instance variables
    uid = widget.uid;
    setState(() {
      isLoading = false;
    });

    getRiderName();
    displayRiderArea();
    checkInprocessOrders();
  }

  Future<void> getRiderName() async {
    setState(() {
      isLoading = true;
    });

    try {
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('rider')
          .doc(uid)
          .get();

      if (userSnapshot.exists) {
        var data = userSnapshot.data() as Map<String, dynamic>; // Safely cast to Map
        String userName = data['name'] ?? ''; // Default to empty string if null

        setState(() {
          this.userName = userName;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        print('User data not found');
      }
    } catch (error) {
      print('Error fetching user data: $error');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> checkInprocessOrders() async {
    try {
      // Fetch orders with status 3
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('status', isEqualTo: 3)
          .get();

      // Check if there are any orders with status 3
      if (snapshot.docs.isNotEmpty) {
        // Get the first order with status 3
        DocumentSnapshot orderSnapshot = snapshot.docs.first;
        String orderId = orderSnapshot['orderid'];

        // Show dialog with loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return StatefulBuilder(
              builder: (context, setState) {
                return AlertDialog(
                  title: Text('Waiting for Approval'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () async {
                          try {
                            // Update the status of the order to 0 (cancelled)
                            await orderSnapshot.reference.update({'status': 0});
                          } catch (error) {
                            print('Error updating order status: $error');
                          }
                          // Cancel the function
                          Navigator.pop(context);
                        },
                        child: Text('Cancel'),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );

        // Check status in the database until it becomes 2
        bool isApproved = false;
        while (!isApproved) {
          await Future.delayed(Duration(seconds: 1)); // Check every second
          // Fetch the latest status
          DocumentSnapshot updatedSnapshot = await FirebaseFirestore.instance
              .collection('orders')
              .doc(orderSnapshot.id)
              .get();
          int updatedStatus = updatedSnapshot['status'];
          if (updatedStatus == 2) {
            isApproved = true;
          }
        }

        // Once status is 2, update the dialog
        Navigator.pop(context); // Close the previous dialog
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Pick-Up Completed'),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
      }
    } catch (error) {
      print('Error fetching orders: $error');
    }
  }

  Future<void> displayRiderArea() async {
    try {
      // Fetch Rider document based on rider's UID
      DocumentSnapshot riderSnapshot = await FirebaseFirestore.instance
          .collection('rider')
          .doc(uid) // Assuming UID is the document ID for the rider
          .get();

      // Get the area reference from the Rider document
      DocumentReference areaReference = riderSnapshot['area'];

      // Fetch the area value from the reference
      DocumentSnapshot areaSnapshot = await areaReference.get();

      // Set the riderArea value
      setState(() {
        riderArea = areaSnapshot['location'];
      });

      // Now, you can call the displayOrders function with the riderArea
      displayOrders();
    } catch (error) {
      // Handle any errors that might occur during the process
      print('Error fetching rider area: $error');
    }
  }

  Future<void> displayOrders() async {

    try {
      // Fetch orders from the 'orders' collection
      QuerySnapshot ordersSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('status', isEqualTo: 0)
          .where('area' , isEqualTo: riderArea)
          .get();

      // Process and store orders in a list
      ordersList = ordersSnapshot.docs.map((order) {
        return {
          'orderid': order['orderid'],
          'address': order['address'],
          'totalWeight': order['totalWeight'],
          'phoneNumber': order['phoneNumber'],
          'orderDate': order['orderDate'].toDate(),
          'status': order['status'], // Add status to the map
        };
      }).toList();

      // Sort ordersList by order date in ascending order
      ordersList.sort((a, b) => a['orderDate'].compareTo(b['orderDate']));

      // Trigger a rebuild to display the orders
      setState(() {
        isLoading = false;
      });
    } catch (error) {
      // Handle any errors that might occur during the process
      print('Error fetching orders: $error');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _confirmSignOut() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirm Sign Out"),
          content: Text("Are you sure you want to sign out?"),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => RLogin()),
                );
              },
              child: Text("Sign Out"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await displayOrders();
        },
        child: Container(
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
                  Container(
                    padding: const EdgeInsets.all(10),
                    width: screenWidth * 0.8,
                    height: screenHeight * 0.08,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        isLoading || userName == null
                            ? Text("")
                            : Text(
                          'Hi, $userName',
                          style: TextStyle(
                            color: Color(0xFF050505),
                            fontSize: 18,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w500,
                            height: 0.08,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.025),
                        Text(
                          'Let\'s Paint Pakistan Green!',
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
                      _confirmSignOut();
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
                padding: const EdgeInsets.only(left: 10.0),
                child: Row(
                  children: [
                    Text(
                      "Orders",
                      style: TextStyle(
                          color: Color(0xFF00401A),
                          fontWeight: FontWeight.bold,
                          fontSize: 18),
                    )
                  ],
                ),
              ),
              Expanded(
                child: isLoading
                    ? Center(child: CircularProgressIndicator())
                    : ordersList.isEmpty
                    ? Center(
                    child: Text('No Orders To Pickup',
                        style: TextStyle(
                            color: Color(0xFF00401A), fontSize: 25)))
                    : ListView.builder(
                  itemCount: ordersList.length,
                  itemBuilder: (context, index) {
                    Map<String, dynamic> order = ordersList[index];

                    return Expanded(
                      child: Container(
                        margin: EdgeInsets.symmetric(vertical: 3),
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          title: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    child: Text(
                                      'ORDER ID: ${order['orderid']}',
                                      style: TextStyle(
                                          color: Color(0xFF00401A),
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  Container(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        // Handle Pick Up action
                                        setState(() {
                                          // Assuming you have an OrderDetailsPage defined
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  OrderDetails(
                                                    orderId:
                                                    order['orderid'],
                                                    uid: uid,
                                                  ),
                                            ),
                                          );
                                        });
                                      },
                                      style: ElevatedButton.styleFrom(
                                        primary: Colors.white,
                                        side: BorderSide(
                                            color: Color(0xFF00401A),
                                            width: 2),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                          BorderRadius.circular(
                                              8.0),
                                        ),
                                        minimumSize: Size(80, 30),
                                      ),
                                      child: Text(
                                        "PICK UP",
                                        style: TextStyle(
                                          color: Color(0xFF00401A),
                                        ),
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                height: 5,
                              ),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    color: Colors.red,
                                  ),
                                  SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      'Address: ${order['address']}',
                                      overflow: TextOverflow.visible,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(
                                height: 5,
                              ),
                              Row(
                                children: [
                                  Icon(
                                    Icons.assignment,
                                    color: Colors.blue,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                      'Total Weight: ${order['totalWeight']} kgs'),
                                ],
                              ),
                              SizedBox(
                                height: 5,
                              ),
                              Row(
                                children: [
                                  Icon(
                                    Icons.phone,
                                    color: Colors.green,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                      'Phone Number: ${order['phoneNumber']}'),
                                ],
                              ),
                              SizedBox(
                                height: 5,
                              ),
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    color: Colors.orange,
                                  ),
                                  SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                        'Order Date: ${order['orderDate']}'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
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
                            builder: (context) =>
                                Orders(uid: widget.uid, area: riderArea),
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
                              builder: (context) => Profile(uid: uid),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: screenHeight * 0.03),
            ],
          ),
        ),
      ),
    );
  }
}

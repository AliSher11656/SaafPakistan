import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:tplmapsflutterplugin/TplMapsView.dart';
import '../../main.dart';
import 'ConfirmOrder.dart';
import 'RiderMap.dart';
import 'Dashboard.dart';

class OrderDetails extends StatefulWidget {
  final String orderId;
  final String uid;

  const OrderDetails({Key? key, required this.orderId, required this.uid}) : super(key: key);

  @override
  _OrderDetailsState createState() => _OrderDetailsState();
}

class _OrderDetailsState extends State<OrderDetails> {
  late RiderOrderProvider riderOrderProvider;
  late TextEditingController quantityController = TextEditingController();
  TextEditingController cancelReasonController = TextEditingController();
  String? destinationLat;
  String? destinationLng;
  Map<String, dynamic>? orderDetails;

  @override
  void initState() {
    super.initState();
    riderOrderProvider = Provider.of<RiderOrderProvider>(context, listen: false);
    quantityController = TextEditingController();
    fetchOrderDetails();
  }

  @override
  void dispose() {
    quantityController.dispose();
    super.dispose();
  }

  Future<void> fetchOrderDetails() async {
    try {
      QuerySnapshot orderDocs = await FirebaseFirestore.instance
          .collection('orders')
          .where('orderid', isEqualTo: widget.orderId)
          .get();

      if (orderDocs.docs.isNotEmpty) {
        Map<String, dynamic> fetchedOrderDetails = orderDocs.docs.first.data() as Map<String, dynamic>;

        String customerId = fetchedOrderDetails['customer'];
        DocumentSnapshot customerDoc = await FirebaseFirestore.instance
            .collection('appUsers')
            .doc(customerId)
            .get();

        if (customerDoc.exists) {
          Map<String, dynamic> customerData = customerDoc.data() as Map<String, dynamic>;
          setState(() {
            destinationLat = customerData['latitude'];
            destinationLng = customerData['longitude'];
            orderDetails = fetchedOrderDetails;
          });
        }
      } else {
        print('Order with ID ${widget.orderId} not found.');
      }
    } catch (error) {
      print('Error fetching order details: $error');
    }
  }

  Future<void> showConfirmationDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmation'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure you want to confirm this order?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('No'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Dashboard(
                      uid: widget.uid,
                    ),
                  ),
                );// Close the confirmation dialog
                await confirmOrder(); // Call the confirmOrder function
              },
              child: Text('Yes'),
            ),
          ],
        );
      },
    );
  }

  Future<void> confirmOrder() async {
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .where('orderid', isEqualTo: widget.orderId)
          .get()
          .then((QuerySnapshot querySnapshot) {
        querySnapshot.docs.forEach((doc) {
          // Update the 'status' field to 1 for the specific order
          doc.reference.update({
            'finalRecyclables': riderOrderProvider.recyclableItems,
            'status': 3,
          });
        });
      });

      // Show success pop-up
      showSuccessPopUp();

      // Wait for 5 seconds and then pop the Navigator
      await Future.delayed(Duration(seconds: 5));
      Navigator.pop(context);
    } catch (error) {
      print('Error confirming order: $error');
    }
  }

  void showSuccessPopUp() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Success'),
          content: Text('Order confirmed successfully!'),
          actions: <Widget>[
            TextButton(
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
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showCancelDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap button to close dialog
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cancel Order'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                const Text('Please enter a reason for cancellation:'),
                TextField(
                  controller: cancelReasonController,
                  decoration: const InputDecoration(hintText: "Enter reason here"),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel Order'),
              onPressed: () {
                if (cancelReasonController.text.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Dashboard(
                        uid: widget.uid,
                      ),
                    ),
                  ); // Close the dialog
                  cancelOrder(cancelReasonController.text); // Proceed to cancel the order
                }
              },
            ),
            TextButton(
              child: const Text('Go Back'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog without cancelling
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> cancelOrder(String reason) async {
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .where('orderid', isEqualTo: widget.orderId)
          .get()
          .then((QuerySnapshot querySnapshot) {
        querySnapshot.docs.forEach((doc) {
          doc.reference.update({
            'status': 1, // Assuming 1 means cancelled
            'cancelReason': reason, // Store the cancellation reason
          });
        });
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order cancelled successfully!'),
        ),
      );
    } catch (error) {
      print('Error cancelling order: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error cancelling order. Please try again.'),
        ),
      );
    }
  }

  void _showReceiptConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF00401A), // Set background color
          title: Text(
            'Generate Receipt?',
            style: TextStyle(color: Colors.white), // Set text color
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10), // Set border radius
                  border: Border.all(color: Colors.white), // Set border color
                ),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white), // Set text color
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ConfirmOrder(orderId: widget.orderId , uid: widget.uid)), // Navigate to ConfirmOrder.dart
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10), // Set border radius
                  border: Border.all(color: Colors.white), // Set border color
                ),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Text(
                  'OK',
                  style: TextStyle(color: Colors.white), // Set text color
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _callback(TplMapsViewController controller) {
    controller.showBuildings(false);
    controller.showZoomControls(false);
    controller.setTrafficEnabled(false);
    controller.enablePOIs(true);
    controller.setMyLocationEnabled(true);
    controller.myLocationButtonEnabled(true);
    controller.showsCompass(true);
    controller.setCameraPositionAnimated(33.698047971892045, 73.06930062598059, 14.0);
    controller.addMarker(33.705349, 73.069788);
    controller.addMarker(33.698047971892045, 73.06930062598059);
    controller.setMapMode(MapMode.DEFAULT);
    bool isBuildingsEnabled = controller.isBuildingEnabled;
    print("isBuildingsEnabled: $isBuildingsEnabled");
    bool isTrafficEnabled = controller.isTrafficEnabled;
    print("isTrafficEnabled: $isTrafficEnabled");
    bool isPOIsEnabled = controller.isPOIsEnabled;
    print("isPOIsEnabled: $isPOIsEnabled");
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;

    return ChangeNotifierProvider(
      create: (context) => riderOrderProvider,
      child: Scaffold(
        body: orderDetails == null
            ? Center(child: CircularProgressIndicator())
            : Container(
          padding: const EdgeInsets.only(left: 10, right: 10),
          width: double.infinity,
          height: double.infinity,
          color: const Color(0xFFCCCCCC).withOpacity(0.3),
          child: Column(
            children: [
              SizedBox(height: screenHeight * 0.05),
              Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "Current Order",
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
                ],
              ),
              const Divider(
                thickness: 1,
                color: Colors.black,
              ),
              Container(
                padding: EdgeInsets.all(15.0),
                margin: EdgeInsets.all(20.0),
                height: screenHeight * 0.30,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 5,
                      blurRadius: 7,
                      offset: Offset(0, 3), // changes position of shadow
                    ),
                  ],
                ),
                child: Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 5),
                      Row(
                        mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                              child: Text(
                                'ORDER ID: ${orderDetails!['orderid']}',
                                style: TextStyle(
                                    color: Color(0xFF00401A),
                                    fontWeight: FontWeight.bold),
                              )),
                        ],
                      ),
                      SizedBox(height: 5),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: Colors.red,
                          ),
                          SizedBox(width: 8),
                          Flexible(child: Text('Address: ${orderDetails!['address']}')),
                        ],
                      ),
                      SizedBox(height: 5),
                      Row(
                        children: [
                          Icon(
                            Icons.assignment,
                            color: Colors.blue,
                          ),
                          SizedBox(width: 8),
                          Text('Total Weight: ${orderDetails!['totalWeight']} kgs'),
                        ],
                      ),
                      SizedBox(height: 5),
                      Row(
                        children: [
                          Icon(
                            Icons.phone,
                            color: Colors.green,
                          ),
                          SizedBox(width: 8),
                          Text('Phone Number: ${orderDetails!['phoneNumber']}'),
                        ],
                      ),
                      SizedBox(height: 5),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            color: Colors.orange,
                          ),
                          SizedBox(width: 8),
                          Flexible(child: Text('Order Date: ${orderDetails!['orderDate'].toDate()}')),
                        ],
                      ),
                      SizedBox(height: 5),
                      Row(
                        children: [
                          Container(
                            alignment: Alignment.centerLeft,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10), // Set border radius
                              border: Border.all(color: Colors.black), // Set black border color
                            ),
                            child: TextButton(
                              onPressed: () {
                                _showReceiptConfirmationDialog(context); // Show confirmation dialog
                              },
                              child: Text(
                                'Receipt',
                                style: TextStyle(
                                  color: Color(0xFF00401A),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 150),
                          Container(
                            alignment: Alignment.centerLeft,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10), // Set border radius
                              border: Border.all(color: Colors.black), // Set black border color
                            ),
                            child: TextButton(
                              onPressed: () {
                                _showCancelDialog(context); // Show confirmation dialog
                              },
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  color: Color(0xFF00401A),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (destinationLat != null && destinationLng != null)
                Expanded(
                  child: Container(
                    width: double.infinity,
                    child: RegisterMaps(
                      destinationLat: double.parse(destinationLat!),
                      destinationLng: double.parse(destinationLng!),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

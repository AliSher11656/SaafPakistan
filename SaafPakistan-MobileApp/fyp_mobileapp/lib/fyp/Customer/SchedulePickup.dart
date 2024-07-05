import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:decimal/decimal.dart';
import '../../main.dart';
import 'OrderConfirmation.dart';
import 'Dashboard.dart';

class SchedulePickup extends StatefulWidget {
  final String uid;
  final String accountType;

  const SchedulePickup({Key? key, required this.uid, required this.accountType}) : super(key: key);

  @override
  State<SchedulePickup> createState() => _SchedulePickupState();
}

class _SchedulePickupState extends State<SchedulePickup> {
  late ScheduleProvider scheduleProvider;
  List<DocumentSnapshot> recyclables = [];
  Decimal subtotal = Decimal.zero;
  Decimal totalWeight = Decimal.zero;
  late String uid;
  late String accountType;
  bool isIncrementing = false;
  bool isDecrementing = false;

  @override
  void initState() {
    super.initState();
    scheduleProvider = Provider.of<ScheduleProvider>(context, listen: false);
    uid = widget.uid;
    accountType = widget.accountType;
    fetchRecyclablesData();
  }

  Future<void> fetchRecyclablesData() async {
    try {
      QuerySnapshot querySnapshot =
      await FirebaseFirestore.instance.collection('recyclables').get();

      recyclables = querySnapshot.docs;

      // Reset subtotal and totalWeight
      subtotal = Decimal.zero;
      totalWeight = Decimal.zero;

      // Perform calculations
      for (int index = 0; index < scheduleProvider.items.length; index++) {
        var recyclable = recyclables[index];
        Decimal itemPrice = Decimal.parse(recyclable['price'].toString());

        Decimal itemTotalPrice =
            scheduleProvider.items[index].quantity * itemPrice;
        subtotal += itemTotalPrice;
        totalWeight += scheduleProvider.items[index].quantity;
      }

      // Trigger a rebuild to update UI immediately
      setState(() {});
    } catch (error) {
      print('Error fetching recyclables: $error');
    }
  }

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
            SizedBox(height: screenHeight * 0.06),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "Schedule Pickup",
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
                    scheduleProvider.resetQuantities();
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            SizedBox(height: screenHeight * 0.02),
            Divider(
              thickness: 1,
              color: Colors.black,
            ),
            SizedBox(height: screenHeight * 0.02),
            recyclables.isEmpty
                ? CircularProgressIndicator()
                : Expanded(
              child: ListView.builder(
                itemCount: recyclables.length,
                itemBuilder: (context, index) {
                  var recyclable = recyclables[index];
                  String itemName = recyclable['item'];
                  Decimal itemPrice = Decimal.parse((accountType == 'Personal'
                      ? recyclable['price']
                      : recyclable['bizPrice']).toString());

                  return Container(
                    margin: EdgeInsets.symmetric(vertical: 3),
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            GestureDetector(
                              onTap: () {
                                scheduleProvider.decreaseQuantity(index);
                                fetchRecyclablesData();
                              },
                              onLongPressStart: (_) => _startDecrement(index),
                              onLongPressEnd: (_) => _stopDecrement(),
                              child: Icon(Icons.remove, color: Color(0xFF00401A)),
                            ),
                            Text(
                              '${scheduleProvider.items[index].quantity.toString()} kgs',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                scheduleProvider.increaseQuantity(index);
                                fetchRecyclablesData();
                              },
                              onLongPressStart: (_) => _startIncrement(index),
                              onLongPressEnd: (_) => _stopIncrement(),
                              child: Icon(Icons.add, color: Color(0xFF00401A)),
                            ),
                            SizedBox(
                              width: 50,
                            ),
                            Text(
                              itemName,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Rs. $itemPrice',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: screenHeight * 0.02),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Estimated Subtotal:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Rs. $subtotal',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: screenHeight * 0.02),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Estimated Total Weight:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$totalWeight kg',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: screenHeight * 0.03),
            Container(
              padding: EdgeInsets.only(
                  right: screenWidth * 0.1,
                  left: screenWidth * 0.1,
                  top: screenHeight * 0.009),
              width: screenWidth * 1,
              height: screenHeight * 0.15,
              decoration: ShapeDecoration(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                  ),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Estimated Total:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Rs. ${scheduleProvider.calculateTotalPrice()}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: screenHeight * 0.03),
                  GestureDetector(
                    onTap: () {
                      submitFunction();
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Color(0xFF00401A),
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 10.0, horizontal: 20.0),
                        child: Text(
                          'Confirm Pickup',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  void _startIncrement(int index) {
    setState(() {
      isIncrementing = true;
    });
    _incrementContinuously(index);
  }

  void _stopIncrement() {
    setState(() {
      isIncrementing = false;
    });
  }

  void _incrementContinuously(int index) async {
    while (isIncrementing) {
      await Future.delayed(Duration(milliseconds: 100));
      scheduleProvider.increaseQuantity(index);
      fetchRecyclablesData();
    }
  }

  void _startDecrement(int index) {
    setState(() {
      isDecrementing = true;
    });
    _decrementContinuously(index);
  }

  void _stopDecrement() {
    setState(() {
      isDecrementing = false;
    });
  }

  void _decrementContinuously(int index) async {
    while (isDecrementing) {
      await Future.delayed(Duration(milliseconds: 100));
      scheduleProvider.decreaseQuantity(index);
      fetchRecyclablesData();
    }
  }

  void submitFunction() async {
    try {
      // Fetch customer details
      DocumentSnapshot userSnapshot =
      await FirebaseFirestore.instance.collection('appUsers').doc(uid).get();

      String customerArea = userSnapshot['area'];
      String customerAddress = userSnapshot['address'];
      String customerPhoneNumber = userSnapshot['phone'];
      DateTime orderDate = DateTime.now();

      // Fetch the last orderId from the orders collection
      QuerySnapshot lastOrderSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .orderBy('orderid', descending: true)
          .limit(1)
          .get();

      String lastOrderId = '0000'; // Default value if no orders exist yet

      if (lastOrderSnapshot.docs.isNotEmpty) {
        lastOrderId = lastOrderSnapshot.docs.first['orderid'];
      }

      // Increment and format orderId to always have 4 digits
      int incrementedOrderId = int.parse(lastOrderId) + 1;
      String formattedOrderId = incrementedOrderId.toString().padLeft(4, '0');

      // Get the list of selected recyclables from the provider
      List<Map<String, dynamic>> selectedRecyclables = [];
      for (int index = 0; index < scheduleProvider.items.length; index++) {
        var recyclable = recyclables[index];
        String itemName = recyclable['item'];
        Decimal itemPrice = Decimal.parse(recyclable['price'].toString());
        Decimal quantity = scheduleProvider.items[index].quantity;

        selectedRecyclables.add({
          'item': itemName,
          'price': itemPrice.toDouble(), // Converting Decimal back to double for Firestore compatibility
          'quantity': quantity.toDouble(),
        });
      }

      // Check minimum weight criteria
      if (totalWeight < Decimal.fromInt(5)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Minimum order criteria not fulfilled. Total weight must be at least 5 kg.'),
            duration: Duration(seconds: 3),
          ),
        );
        return; // Exit the function if the condition is not met
      }

      // Create a new order document in the orders collection
      await FirebaseFirestore.instance.collection('orders').add({
        'customer': widget.uid,
        'area': customerArea,
        'totalWeight': totalWeight.toDouble(),
        'totalPrice': subtotal.toDouble(),
        'phoneNumber': customerPhoneNumber,
        'orderDate': orderDate,
        'orderid': formattedOrderId,
        'recyclables': selectedRecyclables,
        'status': 0,
        'address': customerAddress,
        'paymentStatus': "unPaid",
        'pickupPrice': 0,
        'pickupWeight': 0
      });

      // Reset the quantities after successful order submission
      scheduleProvider.resetQuantities();
      fetchRecyclablesData();

      // Navigate to the OrderConfirmation screen
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => OrderConfirmation()),
      );

      // Schedule the double pop to return to the main screen after confirmation
      Future.delayed(const Duration(seconds: 2), () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Dashboard(
              uid: widget.uid,
            ),
          ),
        );
      });
    } catch (error) {
      print('Error submitting order: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit the order. Please try again.'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
}

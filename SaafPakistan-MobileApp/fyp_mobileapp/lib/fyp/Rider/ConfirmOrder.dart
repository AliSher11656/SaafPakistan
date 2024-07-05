import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import 'package:decimal/decimal.dart';
import 'Dashboard.dart';

class ConfirmOrder extends StatefulWidget {
  final String uid;
  final String orderId;

  const ConfirmOrder({Key? key, required this.uid, required this.orderId}) : super(key: key);

  @override
  State<ConfirmOrder> createState() => _ConfirmOrderState();
}

class _ConfirmOrderState extends State<ConfirmOrder> {
  late ScheduleProvider scheduleProvider;
  List<DocumentSnapshot> recyclables = [];
  Decimal subtotal = Decimal.zero;
  Decimal totalWeight = Decimal.zero;
  late String uid;
  bool isIncrementing = false;
  bool isDecrementing = false;

  @override
  void initState() {
    super.initState();
    scheduleProvider = Provider.of<ScheduleProvider>(context, listen: false);
    uid = widget.uid;
    fetchRecyclablesData();
  }

  @override
  void dispose() {
    scheduleProvider.resetQuantities();
    super.dispose();
  }

  Future<void> fetchRecyclablesData() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('recyclables').get();

      recyclables = querySnapshot.docs;

      // Reset subtotal and totalWeight
      subtotal = Decimal.zero;
      totalWeight = Decimal.zero;

      // Perform calculations
      for (int index = 0; index < scheduleProvider.items.length; index++) {
        var recyclable = recyclables[index];
        Decimal itemPrice = Decimal.parse(recyclable['price'].toString());

        Decimal itemTotalPrice = scheduleProvider.items[index].quantity * itemPrice;
        subtotal += itemTotalPrice;
        totalWeight += scheduleProvider.items[index].quantity;
      }

      // Trigger a rebuild to update UI immediately
      setState(() {});
    } catch (error) {
      print('Error fetching recyclables: $error');
    }
  }

  Decimal calculateCarbonEmissionsReduced() {
    Decimal totalCarbonEmissions = Decimal.zero;

    for (int index = 0; index < scheduleProvider.items.length; index++) {
      var recyclable = recyclables[index];
      String itemName = recyclable['item'];
      Decimal itemWeight = scheduleProvider.items[index].quantity;

      Decimal emissionFactor;
      switch (itemName.toLowerCase()) {
        case 'paper':
          emissionFactor = Decimal.parse('0.46');
          break;
        case 'metal':
          emissionFactor = Decimal.parse('5.86');
          break;
        case 'glass':
          emissionFactor = Decimal.parse('0.31');
          break;
        case 'plastic':
          emissionFactor = Decimal.parse('1.02');
          break;
        case 'cardboard':
          emissionFactor = Decimal.parse('1.2'); // Accurate factor
          break;
        default:
          emissionFactor = Decimal.zero;
      }

      Decimal itemCarbonReduction = itemWeight * emissionFactor;
      totalCarbonEmissions += itemCarbonReduction;
    }

    return totalCarbonEmissions;
  }

  void startIncrementing(int index) {
    isIncrementing = true;
    incrementQuantity(index);
  }

  void incrementQuantity(int index) async {
    while (isIncrementing) {
      scheduleProvider.increaseQuantity(index);
      fetchRecyclablesData();
      await Future.delayed(Duration(milliseconds: 200));
    }
  }

  void startDecrementing(int index) {
    isDecrementing = true;
    decrementQuantity(index);
  }

  void decrementQuantity(int index) async {
    while (isDecrementing) {
      scheduleProvider.decreaseQuantity(index);
      fetchRecyclablesData();
      await Future.delayed(Duration(milliseconds: 200));
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
                  "Confirm Order",
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
            SizedBox(height: screenHeight * 0.02),
            Divider(thickness: 1, color: Colors.black),
            SizedBox(height: screenHeight * 0.02),
            recyclables.isEmpty
                ? CircularProgressIndicator()
                : Expanded(
              child: ListView.builder(
                itemCount: recyclables.length,
                itemBuilder: (context, index) {
                  var recyclable = recyclables[index];
                  String itemName = recyclable['item'];
                  Decimal itemPrice = Decimal.parse(recyclable['price'].toString());

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
                              onLongPressStart: (_) {
                                startDecrementing(index);
                              },
                              onLongPressEnd: (_) {
                                isDecrementing = false;
                              },
                              child: Icon(Icons.remove, color: Color(0xFF00401A)),
                            ),
                            Text(
                              '${scheduleProvider.items[index].quantity} kgs',
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
                              onLongPressStart: (_) {
                                startIncrementing(index);
                              },
                              onLongPressEnd: (_) {
                                isIncrementing = false;
                              },
                              child: Icon(Icons.add, color: Color(0xFF00401A)),
                            ),
                            SizedBox(width: 50),
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
                  'Subtotal:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Rs. ${subtotal.toString()}',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: screenHeight * 0.02),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Weight:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${totalWeight.toString()} kg',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: screenHeight * 0.03),
            Container(
              padding: EdgeInsets.only(right: screenWidth * 0.1, left: screenWidth * 0.1, top: screenHeight * 0.009),
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
                        'Total:',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Rs. ${scheduleProvider.calculateTotalPrice()}',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  SizedBox(height: screenHeight * 0.03),
                  GestureDetector(
                    onTap: submitFunction,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Color(0xFF00401A),
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
                        child: Text(
                          'Generate Receipt',
                          style: TextStyle(color: Colors.white, fontSize: 16.0, fontWeight: FontWeight.bold),
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

  void submitFunction() async {
    print('Starting to fetch orders...');
    bool isCancelled = false;

    try {
      QuerySnapshot orderSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('orderid', isEqualTo: widget.orderId)
          .get();

      if (orderSnapshot.docs.isEmpty) {
        print('Error: Order not found');
        return;
      }

      for (var doc in orderSnapshot.docs) {
        await doc.reference.update({
          'pickupWeight': totalWeight.toDouble(),
          'pickupPrice': subtotal.toDouble(),
          'status': 3,
        });
        print('Status changed to 3');
      }

      print('Showing dialog for waiting approval...');
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Waiting for Approval'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    print('Canceling order...');
                    await FirebaseFirestore.instance
                        .collection('orders')
                        .where('orderid', isEqualTo: widget.orderId)
                        .get()
                        .then((QuerySnapshot querySnapshot) {
                      querySnapshot.docs.forEach((doc) async {
                        await doc.reference.update({
                          'status': 0,
                          'pickupWeight': 0,
                          'pickupPrice': 0,
                        });
                      });
                    });
                    isCancelled = true;
                    Navigator.pop(context);
                  },
                  child: Text('Cancel'),
                ),
              ],
            ),
          );
        },
      );

      print('Monitoring approval status...');
      bool isApproved = false;
      while (!isApproved && !isCancelled) {
        await Future.delayed(Duration(seconds: 1));
        QuerySnapshot snapshot = await FirebaseFirestore.instance
            .collection('orders')
            .where('orderid', isEqualTo: widget.orderId)
            .get();
        var status = (snapshot.docs.first.data() as Map<String, dynamic>)['status'];
        print('Current status: $status');
        if (status == 2) {
          isApproved = true;
          Navigator.pop(context);
        }
      }

      if (isApproved && !isCancelled) {
        print('Approval confirmed, updating database...');
        for (var doc in orderSnapshot.docs) {
          var docData = doc.data() as Map<String, dynamic>;

          String uid = docData['customer'] ?? '';
          if (uid.isEmpty) {
            print('Error: UID is empty or null');
            continue;
          }

          DocumentSnapshot leaderboardDoc = await FirebaseFirestore.instance
              .collection('leaderboards')
              .doc(uid)
              .get();
          var leaderboardData = leaderboardDoc.data() as Map<String, dynamic>?;
          if (leaderboardData != null) {
            double currentPoints = (leaderboardData['points'] ?? 0).toDouble();
            double newPoints = (subtotal * Decimal.fromInt(2)).toDouble() + currentPoints;
            await FirebaseFirestore.instance
                .collection('leaderboards')
                .doc(uid)
                .update({'points': newPoints});
          } else {
            print('Error: Leaderboard data is null for UID: $uid');
          }

          Decimal carbonEmissionsReduced = calculateCarbonEmissionsReduced();

          QuerySnapshot userStatsSnapshot = await FirebaseFirestore.instance
              .collection('userStats')
              .where('customerId', isEqualTo: uid)
              .get();

          if (userStatsSnapshot.docs.isNotEmpty) {
            var userStatsDoc = userStatsSnapshot.docs.first;
            var userStatsData = userStatsDoc.data() as Map<String, dynamic>;

            Decimal currentCO2eReduced = Decimal.parse((userStatsData['co2eReduced'] ?? '0').toString());
            Decimal newCO2eReduced = currentCO2eReduced + carbonEmissionsReduced;
            await userStatsDoc.reference.update({'co2eReduced': newCO2eReduced.toString()});

            Decimal currentWasteRecycled = Decimal.parse((userStatsData['wasteRecycled'] ?? '0').toString());
            Decimal newWasteRecycled = currentWasteRecycled + totalWeight;
            await userStatsDoc.reference.update({'wasteRecycled': newWasteRecycled.toString()});

            Decimal currentCashEarned = Decimal.parse((userStatsData['cashEarned'] ?? '0').toString());
            Decimal newCashEarned = currentCashEarned + subtotal;
            await userStatsDoc.reference.update({'cashEarned': newCashEarned.toString()});
          } else {
            await FirebaseFirestore.instance.collection('userStats').add({
              'customerId': uid,
              'co2eReduced': carbonEmissionsReduced.toString(),
              'wasteRecycled': totalWeight.toString(),
              'cashEarned': subtotal.toString(),
            });
          }

          DocumentSnapshot updatedLeaderboardDoc = await FirebaseFirestore.instance
              .collection('leaderboards')
              .doc(uid)
              .get();
          var updatedLeaderboardData = updatedLeaderboardDoc.data() as Map<String, dynamic>?;
          if (updatedLeaderboardData != null) {
            double currentLeaderboardWasteRecycled = (updatedLeaderboardData['wasteRecycled'] ?? 0).toDouble();
            double newLeaderboardWasteRecycled = currentLeaderboardWasteRecycled + totalWeight.toDouble();
            await updatedLeaderboardDoc.reference.update({'wasteRecycled': newLeaderboardWasteRecycled});
          } else {
            await FirebaseFirestore.instance.collection('leaderboards').doc(uid).set({
              'wasteRecycled': totalWeight.toDouble(),
            });
          }
        }

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Pick-Up Completed'),
              actions: [
                ElevatedButton(
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
    } catch (error) {
      print('Error updating order: $error');
      Navigator.pop(context);
    }
  }
}

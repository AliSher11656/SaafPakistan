import 'package:flutter/material.dart';
import 'Profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'Dashboard.dart';

class Orders extends StatefulWidget {
  final String uid;
  final String area;

  const Orders({Key? key, required this.uid, required this.area}) : super(key: key);

  @override
  _OrdersState createState() => _OrdersState();
}

class _OrdersState extends State<Orders> {
  late String uid;
  late String area;
  late List<Map<String, dynamic>> ordersList = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    uid = widget.uid;
    area = widget.area;

    displayOrders();
  }

  Future<void> displayOrders() async {
    try {
      setState(() {
        isLoading = true;
      });

      QuerySnapshot ordersSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('area', isEqualTo: area)
          .where('status', isEqualTo: 2)
          .orderBy('orderDate', descending: true)
          .get();

      ordersList = ordersSnapshot.docs.map((order) {
        DateTime orderDate = order['orderDate'].toDate();
        bool paymentStatus = ((order['paymentStatus'] as String?)?.toLowerCase() == 'paid');

        return {
          'orderid': order['orderid'],
          'totalWeight': order['totalWeight'],
          'totalPrice': order['totalPrice'],
          'orderDate': orderDate,
          'status': order['status'],
          'pickupPrice': order['pickupPrice'] ?? 0.0,
          'pickupWeight': order['pickupWeight'] ?? 0.0,
          'paymentStatus': paymentStatus,
        };


      }).toList();

      setState(() {
        isLoading = false;
      });
    } catch (error) {
      print('Error fetching orders: $error');
      setState(() {
        isLoading = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Container(
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
                  "Order History",
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
            SizedBox(height: screenHeight * 0.001),
            const Divider(
              thickness: 1,
              color: Colors.black,
            ),
            Expanded(
              child: isLoading
                  ? Center(child: CircularProgressIndicator())
                  : ordersList.isEmpty
                  ? Center(child: Text('No Orders To Pickup', style: TextStyle(color: Color(0xFF00401A), fontSize: 25)))
                  : ListView.builder(
                itemCount: ordersList.length,
                itemBuilder: (context, index) {
                  Map<String, dynamic> order = ordersList[index];

                  return GestureDetector(
                    onTap: () {

                    },
                    child: Container(
                      margin: EdgeInsets.symmetric(vertical: 3),
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    padding: EdgeInsets.all(8.0),
                                    child: Text(
                                      "Completed",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  )
                                ]),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 5),
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  color: Colors.orange,
                                ),
                                SizedBox(width: 8),
                                Text('Order Date: ${order['orderDate']}'),
                              ],
                            ),
                            SizedBox(height: 5),
                            Row(
                              children: [
                                Icon(
                                  Icons.attach_money_outlined,
                                  color: Colors.red,
                                ),
                                SizedBox(width: 8),
                                Text('Pickup Price ${order['pickupPrice']}'),
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
                                Text('Pickup Weight: ${order['pickupWeight']} kgs'),
                              ],
                            ),
                            SizedBox(height: 5),
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
                        color: Colors.black,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Dashboard(
                              uid: uid,
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
                      color: Colors.blue,
                    ),
                    onPressed: () {},
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
    );
  }
}
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'Profile.dart';
import 'OrderDetails.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'Dashboard.dart';

class Orders extends StatefulWidget {
  final String uid;

  const Orders({Key? key, required this.uid}) : super(key: key);

  @override
  _OrdersState createState() => _OrdersState();
}

class _OrdersState extends State<Orders> with SingleTickerProviderStateMixin {
  late String uid;
  late List<Map<String, dynamic>> ordersList = [];
  late List<Map<String, dynamic>> rewardsList = [];
  bool isLoadingOrders = false;
  bool isLoadingRewards = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    uid = widget.uid;
    _tabController = TabController(length: 2, vsync: this);
    displayOrders();
    displayRewards();
  }

  Future<void> displayOrders() async {
    try {
      setState(() {
        isLoadingOrders = true;
      });

      QuerySnapshot ordersSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('customer', isEqualTo: uid)
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
        isLoadingOrders = false;
      });
    } catch (error) {
      print('Error fetching orders: $error');
      setState(() {
        isLoadingOrders = false;
      });
    }
  }

  Future<void> displayRewards() async {
    try {
      setState(() {
        isLoadingRewards = true;
      });

      QuerySnapshot rewardsSnapshot = await FirebaseFirestore.instance
          .collection('rewards')
          .where('customer', isEqualTo: uid)
          .orderBy('rewardDate', descending: true)
          .get();



        rewardsList = rewardsSnapshot.docs.map((reward) {
          DateTime rewardDate = reward['rewardDate'].toDate();
          String monthName = DateFormat.MMMM().format(rewardDate);

          return {
            'reward': reward['reward'],
            'points': reward['points'],
            'rewardDate': rewardDate,
            'rank': reward['rank'],
            'description': 'Reward for achieving rank ${reward['rank']} in the month of $monthName.',
          };
      }).toList();

      setState(() {
        isLoadingRewards = false;
      });
    } catch (error) {
      print('Error fetching rewards: $error');
      setState(() {
        isLoadingRewards = false;
      });
    }
  }

  Widget buildCancelButton(String orderId, int status) {
    if (status == 0) {
      return ElevatedButton(
        onPressed: () {
          showCancelConfirmationDialog(orderId);
        },
        style: ElevatedButton.styleFrom(
          primary: Colors.white,
          side: BorderSide(color: Color(0xFF00401A), width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          minimumSize: Size(80, 30),
        ),
        child: Text(
          "CANCEL",
          style: TextStyle(color: Color(0xFF00401A)),
        ),
      );
    } else if (status == 1) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(8.0),
        ),
        padding: EdgeInsets.all(8.0),
        child: Text(
          "Cancelled",
          style: TextStyle(color: Colors.white),
        ),
      );
    } else if (status == 2) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.circular(8.0),
        ),
        padding: EdgeInsets.all(8.0),
        child: Text(
          "Completed",
          style: TextStyle(color: Colors.white),
        ),
      );
    } else if (status == 3) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.circular(8.0),
        ),
        padding: EdgeInsets.all(8.0),
        child: Text(
          "In Process",
          style: TextStyle(color: Colors.white),
        ),
      );
    } else {
      return SizedBox.shrink();
    }
  }

  Future<void> showCancelConfirmationDialog(String orderId) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Cancel Order Confirmation'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure you want to cancel this order?'),
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
              onPressed: () {
                cancelOrder(orderId);
                Navigator.of(context).pop();
              },
              child: Text('Yes'),
            ),
          ],
        );
      },
    );
  }

  Future<void> cancelOrder(String orderId) async {
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .where('orderid', isEqualTo: orderId)
          .get()
          .then((querySnapshot) {
        querySnapshot.docs.forEach((doc) {
          doc.reference.update({'status': 1});
        });
      });

      displayOrders();
    } catch (error) {
      print('Error cancelling order: $error');
    }
  }

  Future<void> showProof(String orderId) async {
    try {
      // Query the orders collection to get the document ID
      QuerySnapshot ordersSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('orderid', isEqualTo: orderId)
          .get();

      if (ordersSnapshot.docs.isEmpty) {
        print('Order not found');
        return;
      }

      // Assume the first matching document is the one we want
      String orderDocId = ordersSnapshot.docs.first.id;

      // Use the orderDocId to query the payments collection
      QuerySnapshot paymentSnapshot = await FirebaseFirestore.instance
          .collection('payments')
          .where('orderDocid', isEqualTo: orderDocId)
          .get();

      if (paymentSnapshot.docs.isEmpty) {
        print('Payment proof not found');
        return;
      }

      // Assume the first matching document is the one we want
      String? fileUrl = paymentSnapshot.docs.first['fileUrl'];

      // Show the payment proof in a dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Payment Proof'),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  if (fileUrl != null)
                    Image.network(fileUrl)
                  else
                    Text('No proof of payment available.'),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: Text('Close'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    } catch (error) {
      print('Error fetching payment proof: $error');
    }
  }

  Widget buildOrdersTab() {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return isLoadingOrders
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 20),
              Text(
                "Orders",
                style: TextStyle(
                    color: Color(0xFF00401A),
                    fontWeight: FontWeight.bold,
                    fontSize: 30),
              ),

            ],
          ),
          SizedBox(height: 10),
          Expanded(
            child: ordersList.isNotEmpty
                ? ListView.builder(
              itemCount: ordersList.length,
              itemBuilder: (context, index) {
                final order = ordersList[index];
                return Card(
                  elevation: 4.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order ID: ${order['orderid']}',
                          style: TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8.0),
                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Price: \Rs. ${order['totalPrice']}',
                                ),
                                Text(
                                  'Total Weight: ${order['totalWeight']} kg',
                                ),
                                Text(
                                  'Order Date: ${order['orderDate']}',
                                ),
                                buildCancelButton(
                                    order['orderid'],
                                    order['status']),
                              ],
                            ),
                            Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.end,
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    showProof(order['orderid']);
                                  },
                                  style:
                                  ElevatedButton.styleFrom(
                                    primary: Color(0xFF00401A),
                                    shape:
                                    RoundedRectangleBorder(
                                      borderRadius:
                                      BorderRadius.circular(
                                          8.0),
                                    ),
                                    minimumSize: Size(80, 30),
                                  ),
                                  child: Text('Proof'),
                                ),
                                Text(
                                  order['paymentStatus']
                                      ? "Paid"
                                      : "Unpaid",
                                  style: TextStyle(
                                    color:
                                    order['paymentStatus']
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            )
                : Center(
              child: Text(
                'No orders found.',
                style: TextStyle(fontSize: 16.0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildRewardsTab() {
    return isLoadingRewards
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
          SizedBox(height: 20),
          Text(
            "Rewards",
            style: TextStyle(
                color: Color(0xFF00401A),
                fontWeight: FontWeight.bold,
                fontSize: 30),
          ),
          SizedBox(height: 10),
          Expanded(
            child: rewardsList.isNotEmpty
                ? ListView.builder(
              itemCount: rewardsList.length,
              itemBuilder: (context, index) {
                final reward = rewardsList[index];
                return Card(
                  elevation: 4.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    side: BorderSide(color: Colors.grey[200]!, width: 1.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reward: \Rs.${reward['reward']}',
                          style: TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo,
                          ),
                        ),
                        SizedBox(height: 12.0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Points: ${reward['points']}',
                                  style: TextStyle(
                                    fontSize: 14.0,
                                    color: Colors.black87,
                                  ),
                                ),
                                SizedBox(height: 4.0),
                                Text(
                                  'Rank: ${reward['rank']}',
                                  style: TextStyle(
                                    fontSize: 14.0,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Reward Date:',
                                  style: TextStyle(
                                    fontSize: 14.0,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  '${reward['rewardDate']}',
                                  style: TextStyle(
                                    fontSize: 14.0,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 8.0),
                        Divider(color: Colors.grey[300], thickness: 1.0),
                        SizedBox(height: 8.0),
                        Text(
                          'Description:',
                          style: TextStyle(
                            fontSize: 14.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 4.0),
                        Text(
                          '${reward['description']}',
                          style: TextStyle(
                            fontSize: 14.0,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            )
                : Center(
              child: Text(
                'No rewards yet.',
                style: TextStyle(fontSize: 16.0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          SizedBox(height: 50),
          TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: 'Orders'),
              Tab(text: 'Rewards'),
            ],
            indicatorColor: Color(0xFF00401A),
            labelColor: Color(0xFF00401A),
            unselectedLabelColor: Colors.grey,
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                buildOrdersTab(),
                buildRewardsTab(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '',
          ),
        ],
        selectedItemColor: Color(0xFF00401A),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => Dashboard(uid: widget.uid)),
              );
              break;
            case 1:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => Orders(uid: widget.uid)),
              );
              break;
            case 2:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => Profile(uid: widget.uid)),
              );
              break;
          }
        },
      ),
    );
  }
}

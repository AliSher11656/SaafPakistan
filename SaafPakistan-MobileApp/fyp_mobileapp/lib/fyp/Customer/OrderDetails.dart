import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderDetails extends StatelessWidget {
  final String orderId;

  const OrderDetails({Key? key, required this.orderId}) : super(key: key);

  Future<Map<String, dynamic>> getOrderDetails() async {
    try {
      QuerySnapshot orderDocs = await FirebaseFirestore.instance
          .collection('orders')
          .where('orderid', isEqualTo: orderId)
          .get();

      if (orderDocs.docs.isNotEmpty) {
        Map<String, dynamic> orderDetails = orderDocs.docs.first.data() as Map<String, dynamic>;
        return orderDetails;
      } else {
        print('Order with ID $orderId not found.');
        return {};
      }
    } catch (error) {
      print('Error fetching order details: $error');
      return {};
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
        child: FutureBuilder<Map<String, dynamic>>(
          future: getOrderDetails(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Text('Error fetching order details.'));
            }

            Map<String, dynamic> orderDetails = snapshot.data!;

            return Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: screenHeight * 0.05),
                Row(
                  children: [
                    Text(
                      'Order ID: ${orderDetails['orderid']}',
                      style: TextStyle(
                        color: Color(0xFF00401A),
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.4),
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
                SizedBox(height: screenHeight * 0.01),
                const Divider(
                  thickness: 1,
                  color: Colors.black,
                ),
                SizedBox(height: screenHeight * 0.01),
                Row(
                  children: [
                    Text(
                      'Total Price: ${orderDetails['totalPrice']}',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: screenHeight * 0.01),
                Row(
                  children: [
                    Text(
                      'Total Weight: ${orderDetails['totalWeight']} kgs',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: screenHeight * 0.01),
                Row(
                  children: [
                    Text(
                      'Order Date: ${orderDetails['orderDate'].toDate()}',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: screenHeight * 0.01),
                const Divider(
                  thickness: 1,
                  color: Colors.black,
                ),
                SizedBox(height: screenHeight * 0.01),
                Text(
                  'Recyclables:',
                  style: TextStyle(
                    color: Color(0xFF00401A),
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                SizedBox(height: screenHeight * 0.01),
                Expanded(
                  child: ListView.builder(
                    itemCount: orderDetails['recyclables'].length,
                    itemBuilder: (context, index) {
                      Map<String, dynamic> recyclable = orderDetails['recyclables'][index];

                      return Container(
                        margin: EdgeInsets.symmetric(vertical: 5),
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
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Item: ${recyclable['item']}',
                                    style: TextStyle(
                                      color: Color(0xFF00401A),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Total: PKR ${recyclable['price'] * recyclable['quantity']}',
                                    style: TextStyle(
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 5),
                              Row(
                                children: [
                                  Text(
                                    'Quantity: ${recyclable['quantity']} kgs',
                                    style: TextStyle(
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                            ],
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

                          },
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: screenHeight * 0.02),
              ],
            );
          },
        ),
      ),
    );
  }
}
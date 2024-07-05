import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'Profile.dart';
import 'Orders.dart';

class WhyRecycle extends StatefulWidget {
  final String uid;

  const WhyRecycle({Key? key, required this.uid}) : super(key: key);

  @override
  State<WhyRecycle> createState() => _WhyRecycleState();
}

class _WhyRecycleState extends State<WhyRecycle> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 1.5,
        color: const Color(0xFFCCCCCC).withOpacity(0.3),
        child: FutureBuilder(
          future: FirebaseFirestore.instance.collection('tips').get(),
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

            var tipsData =
            snapshot.data as QuerySnapshot<Map<String, dynamic>>;

            return Padding(
              padding: const EdgeInsets.only(right: 8.0, left: 8.0, top: 8.0),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.only(top: 50, bottom: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          "Why Recycle",
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
                  const Divider(
                    thickness: 1,
                    color: Colors.black,
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: tipsData.size,
                      itemBuilder: (context, index) {
                        var tip = tipsData.docs[index];
                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 8.0),
                          child: ListTile(
                            title: Text(
                              tip['title'] ?? 'No Title',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle:
                            Text(tip['description'] ?? 'No Description'),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                  Padding(
                    padding: const EdgeInsets.only(right: 20.0, left: 25.0, top: 8.0),
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.87,
                      height: MediaQuery.of(context).size.height * 0.06,
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
                                Navigator.pop(context);
                              },
                            ),
                          ),
                          Container(
                            height: MediaQuery.of(context).size.height * 0.05,
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
                            height: MediaQuery.of(context).size.height * 0.05,
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
                                    builder: (context) =>
                                        Profile(uid: widget.uid),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

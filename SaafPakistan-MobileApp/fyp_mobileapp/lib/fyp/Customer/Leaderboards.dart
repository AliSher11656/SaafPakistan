import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Leaderboards extends StatefulWidget {
  final String uid;
  final String accountType;
  final String userName;
  final int initialTabIndex;

  const Leaderboards({
    Key? key,
    required this.uid,
    required this.accountType,
    required this.userName,
    this.initialTabIndex = 0,
  }) : super(key: key);

  @override
  State<Leaderboards> createState() => _LeaderboardsState();
}

class _LeaderboardsState extends State<Leaderboards> with SingleTickerProviderStateMixin {
  late String uid;
  late String tabAccountType;
  late String userName;
  late List<Map<String, dynamic>> leaderboardsList = [];
  bool userPositionFixed = false;
  ScrollController _scrollController = ScrollController();
  Map<String, dynamic>? userLeaderboardData;
  bool _isLoading = false;
  late TabController _tabController;

  // Define tabs
  final List<Tab> tabs = <Tab>[
    Tab(
      child: Text(
        'City',
        style: TextStyle(
          color: Color(0xFF050505),
          fontSize: 16,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    Tab(
      child: Text(
        'Organization',
        style: TextStyle(
          color: Color(0xFF050505),
          fontSize: 16,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    Tab(
      child: Text(
        'Friends',
        style: TextStyle(
          color: Color(0xFF050505),
          fontSize: 16,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
  ];

  @override
  void initState() {
    super.initState();
    uid = widget.uid;
    userName = widget.userName;
    tabAccountType = widget.accountType;
    displayLeaderboards(tabAccountType);
    _scrollController.addListener(() {
      setState(() {
        userPositionFixed = _isUserPositionBelowScreen();
      });
    });
    _tabController = TabController(
      length: tabs.length,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    _tabController.addListener(_handleTabSelection);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabSelection() {
    setState(() {
      switch (_tabController.index) {
        case 0:
          tabAccountType = 'Personal';
          displayLeaderboards(tabAccountType);
          break;
        case 1:
          tabAccountType = 'Company';
          displayLeaderboards(tabAccountType);
          break;
        case 2:
          tabAccountType = 'Friends';
          friendLeaderboards();
          break;
      }
    });
  }

  Future<void> friendLeaderboards() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Step 1: Retrieve friends' UIDs
      List<String> friendIds = [];
      QuerySnapshot friendSnapshot = await FirebaseFirestore.instance
          .collection('friends')
          .doc(uid) // Current user's UID
          .collection('addedFriends')
          .get();

      friendSnapshot.docs.forEach((doc) {
        friendIds.add(doc.id);
      });

      // Step 2: Fetch leaderboard data for these friends
      List<Map<String, dynamic>> friendsLeaderboardData = [];
      for (String friendId in friendIds) {
        DocumentSnapshot friendLeaderboard = await FirebaseFirestore.instance
            .collection('leaderboards')
            .doc(friendId)
            .get();

        if (friendLeaderboard.exists) {
          Map<String, dynamic> data = friendLeaderboard.data() as Map<String, dynamic>;

          // Handle points as double or string
          double points;
          if (data['points'] is String) {
            points = double.parse(data['points']);
          } else if (data['points'] is double) {
            points = data['points'];
          } else {
            points = 0.0; // default value in case of unexpected format
          }

          friendsLeaderboardData.add({
            'rank': 0, // Temporary rank, will sort later
            'cus': data['cus'],
            'points': points,
            'uid': friendId,
          });
        }
      }

      // Step 3: Sort data by points
      friendsLeaderboardData.sort((a, b) => b['points'].compareTo(a['points']));

      // Assign ranks based on sorted order
      int rank = 1;
      for (var data in friendsLeaderboardData) {
        data['rank'] = rank++;
      }

      setState(() {
        leaderboardsList = friendsLeaderboardData;
        userPositionFixed = _isUserPositionBelowScreen();
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      print('Error fetching friends leaderboards: $error');
    }
  }


  bool _isUserPositionBelowScreen() {
    if (_scrollController.hasClients &&
        userLeaderboardData != null &&
        leaderboardsList.isNotEmpty) {
      int userIndex =
      leaderboardsList.indexWhere((element) => element['uid'] == uid);
      if (userIndex == -1) {
        return true;
      }
      double userItemPosition =
          userIndex * (MediaQuery.of(context).size.height * 0.1);
      double minVisiblePixel = _scrollController.position.pixels;
      double maxVisiblePixel =
          minVisiblePixel + _scrollController.position.viewportDimension;

      bool isUserVisible = userItemPosition >= minVisiblePixel &&
          userItemPosition <= maxVisiblePixel;

      return !isUserVisible;
    }
    return false;
  }

  Future<void> displayLeaderboards(String accountType) async {
    try {
      setState(() {
        _isLoading = true;
      });

      QuerySnapshot ordersSnapshot = await FirebaseFirestore.instance
          .collection('leaderboards')
          .orderBy('points', descending: true)
          .where("accountType", isEqualTo: accountType)
          .get();

      List<Map<String, dynamic>> sortedLeaderboardsList = [];
      int rank = 1;
      ordersSnapshot.docs.forEach((leaderboardDoc) {
        sortedLeaderboardsList.add({
          'rank': rank,
          'cus': leaderboardDoc['cus'] ?? 'Unknown',
          'points': leaderboardDoc['points']?.toString() ?? '0',
          'uid': leaderboardDoc['uid'],
        });
        rank++;
      });

      leaderboardsList = sortedLeaderboardsList;

      userLeaderboardData = leaderboardsList.firstWhere(
            (element) => element['uid'] == uid,
        orElse: () => {'rank': 0, 'cus': 'Unknown', 'points': '0', 'uid': ''},
      );

      setState(() {
        userPositionFixed = _isUserPositionBelowScreen();
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      print('Error fetching leaderboards: $error');
    }
  }

  void _showFriendsSearchDialog() {
    String searchQuery = '';
    List<Map<String, dynamic>> searchResults = [];
    Map<String, bool> requestSentMap = {};
    Map<String, bool> isAlreadyFriendMap = {};

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Add Friends",
                    style: TextStyle(
                      color: Color(0xFF00401A),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.clear),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
              content: SizedBox(
                width: 400,
                height: 300,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Divider(thickness: 1, color: Colors.black),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        onChanged: (value) async {
                          searchQuery = value;
                          if (searchQuery.isNotEmpty) {
                            try {
                              var snapshot = await FirebaseFirestore.instance
                                  .collection('appUsers')
                                  .where("phone", isGreaterThanOrEqualTo: searchQuery)
                                  .where("phone", isLessThanOrEqualTo: searchQuery + '\uf8ff')
                                  .get();

                              List<Map<String, dynamic>> filteredResults = [];
                              for (var doc in snapshot.docs) {
                                if (doc.id != uid) {
                                  filteredResults.add({
                                    "uid": doc.id,
                                    "name": doc.data()['name'] ?? 'Unknown'
                                  });
                                }
                              }

                              for (var friend in filteredResults) {
                                var friendRequestDoc = await FirebaseFirestore.instance
                                    .collection('friends')
                                    .doc(uid)
                                    .collection('pendingSentRequests')
                                    .doc(friend['uid'])
                                    .get();

                                requestSentMap[friend['uid']] = friendRequestDoc.exists;

                                var friendCheckDoc = await FirebaseFirestore.instance
                                    .collection('friends')
                                    .doc(uid)
                                    .collection('addedFriends')
                                    .doc(friend['uid'])
                                    .get();

                                isAlreadyFriendMap[friend['uid']] = friendCheckDoc.exists;
                              }

                              setState(() {
                                searchResults = filteredResults;
                              });
                            } catch (e) {
                              print("Error fetching search results: $e");
                            }
                          } else {
                            setState(() {
                              searchResults = [];
                              requestSentMap.clear();
                              isAlreadyFriendMap.clear();
                            });
                          }
                        },
                        decoration: InputDecoration(
                          hintText: "Enter Phone Number",
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    Expanded(
                      child: ListView.builder(
                        itemCount: searchResults.length,
                        itemBuilder: (context, index) {
                          var friend = searchResults[index];
                          bool requestSent = requestSentMap[friend['uid']] ?? false;
                          bool isAlreadyFriend = isAlreadyFriendMap[friend['uid']] ?? false;
                          return ListTile(
                            title: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(friend['name'],
                                    style: TextStyle(fontWeight: FontWeight.bold)),
                                Text(friend['uid'],
                                    style: TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                            trailing: isAlreadyFriend ? Icon(Icons.check) :
                            requestSent ? Icon(Icons.check) : IconButton(
                              icon: Icon(Icons.person_add),
                              onPressed: () async {
                                await FirebaseFirestore.instance
                                    .collection('friends')
                                    .doc(uid)
                                    .collection('pendingSentRequests')
                                    .doc(friend['uid'])
                                    .set({
                                  'uid': friend['uid'],
                                  'name': friend['name'],
                                  'status': 'Request sent'
                                });

                                await FirebaseFirestore.instance
                                    .collection('friends')
                                    .doc(friend['uid'])
                                    .collection('pendingReceivedRequests')
                                    .doc(uid)
                                    .set({
                                  'uid': uid,
                                  'name': userName,
                                  'status': 'Request received'
                                });

                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Friend request sent!")));
                                setState(() {
                                  requestSentMap[friend['uid']] = true;
                                });
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showFriendsRequestDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            Stream<QuerySnapshot> sentRequests = FirebaseFirestore.instance
                .collection('friends')
                .doc(uid)
                .collection('pendingSentRequests')
                .snapshots();

            Stream<QuerySnapshot> receivedRequests = FirebaseFirestore.instance
                .collection('friends')
                .doc(uid)
                .collection('pendingReceivedRequests')
                .snapshots();

            return AlertDialog(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Friend Requests",
                    style: TextStyle(
                      color: Color(0xFF00401A),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.clear),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
              content: Container(
                width: 400,
                height: 300,
                child: DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      TabBar(
                        indicatorColor: Colors.green,
                        labelColor: Colors.black,
                        unselectedLabelColor: Colors.grey,
                        tabs: [
                          Tab(text: 'Sent Requests'),
                          Tab(text: 'Received Requests'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            StreamBuilder<QuerySnapshot>(
                              stream: sentRequests,
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) return CircularProgressIndicator();
                                return ListView(
                                  children: snapshot.data!.docs.map((doc) {
                                    return ListTile(
                                      title: Text(doc['name']),
                                      trailing: IconButton(
                                        icon: Icon(Icons.close),
                                        onPressed: () {
                                          FirebaseFirestore.instance
                                              .collection('friends')
                                              .doc(uid)
                                              .collection('pendingSentRequests')
                                              .doc(doc.id)
                                              .delete();

                                          FirebaseFirestore.instance
                                              .collection('friends')
                                              .doc(doc.id)
                                              .collection('pendingReceivedRequests')
                                              .doc(uid)
                                              .delete();
                                        },
                                      ),
                                    );
                                  }).toList(),
                                );
                              },
                            ),
                            StreamBuilder<QuerySnapshot>(
                              stream: receivedRequests,
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) return CircularProgressIndicator();
                                return ListView(
                                  children: snapshot.data!.docs.map((doc) {
                                    return ListTile(
                                      title: Text(doc['name']),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: Icon(Icons.check),
                                            onPressed: () {
                                              FirebaseFirestore.instance
                                                  .collection('friends')
                                                  .doc(uid)
                                                  .collection('addedFriends')
                                                  .doc(doc.id)
                                                  .set({'name': doc['name'], 'status': 'Friend'});

                                              FirebaseFirestore.instance
                                                  .collection('friends')
                                                  .doc(doc.id)
                                                  .collection('addedFriends')
                                                  .doc(uid)
                                                  .set({'name': userName, 'status': 'Friend'});

                                              doc.reference.delete();
                                              FirebaseFirestore.instance
                                                  .collection('friends')
                                                  .doc(doc.id)
                                                  .collection('pendingSentRequests')
                                                  .doc(uid)
                                                  .delete();
                                            },
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.clear),
                                            onPressed: () {
                                              doc.reference.delete();

                                              FirebaseFirestore.instance
                                                  .collection('friends')
                                                  .doc(doc.id)
                                                  .collection('pendingSentRequests')
                                                  .doc(uid)
                                                  .delete();
                                            },
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  int _initialTabIndex() {
    switch (widget.accountType) {
      case 'Personal':
        return 0;
      case 'Company':
        return 1;
      case 'Friends':
        return 2;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;
    int initialTabIndex = _initialTabIndex();

    return DefaultTabController(
      length: tabs.length,
      initialIndex: initialTabIndex,
      child: Scaffold(
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 10, right: 10, top: 30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "LeaderBoards",
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
            Divider(
              thickness: 1,
              color: Colors.black,
            ),
            TabBar(
              controller: _tabController,
              tabs: tabs,
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildLeaderboard(screenHeight, screenWidth),
                  _buildLeaderboard(screenHeight, screenWidth),
                  _buildFriendsLeaderboard(screenHeight, screenWidth),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboard(double screenHeight, double screenWidth) {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.only(left: 10, right: 10),
          width: double.infinity,
          height: double.infinity,
          color: const Color(0xFFCCCCCC).withOpacity(0.3),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: screenHeight * 0.01),
              if (leaderboardsList != null && leaderboardsList.length > 2)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        child: Padding(
                          padding: const EdgeInsets.all(7.0),
                          child: Column(
                            children: [
                              Container(
                                child: Padding(
                                  padding: const EdgeInsets.all(15.0),
                                  child: Text(
                                    " 2",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 30,
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                width: screenWidth * 0.17,
                                height: screenHeight * 0.08,
                                decoration: BoxDecoration(
                                  color: Colors.cyan,
                                  borderRadius: BorderRadius.circular(100),
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.01),
                              Container(
                                child: Text(
                                  leaderboardsList[1]['cus'] ?? '',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w900,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.01),
                              Container(
                                child: Text(
                                  leaderboardsList[1]['points']?.toString() ?? '',
                                  style: TextStyle(
                                    color: Colors.cyan,
                                    fontSize: 14,
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                        width: screenWidth * 0.3,
                        height: screenHeight * 0.18,
                        decoration: BoxDecoration(
                          color: Color(0xFF00401A),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(10),
                            bottomLeft: Radius.circular(10),
                          ),
                        ),
                      ),
                      Container(
                        child: Padding(
                          padding: const EdgeInsets.all(7.0),
                          child: Column(
                            children: [
                              Container(
                                child: Padding(
                                  padding: const EdgeInsets.all(15.0),
                                  child: Text(
                                    " 1",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 30,
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                width: screenWidth * 0.17,
                                height: screenHeight * 0.08,
                                decoration: BoxDecoration(
                                  color: Colors.yellow[800],
                                  borderRadius: BorderRadius.circular(100),
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.01),
                              Container(
                                child: Text(
                                  leaderboardsList.isNotEmpty ? leaderboardsList[0]['cus'] ?? '' : '',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w900,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.01),
                              Container(
                                child: Text(
                                  leaderboardsList.isNotEmpty ? leaderboardsList[0]['points']?.toString() ?? '' : '',
                                  style: TextStyle(
                                    color: Colors.yellow[800],
                                    fontSize: 14,
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                        width: screenWidth * 0.3,
                        height: screenHeight * 0.23,
                        decoration: BoxDecoration(
                          color: Color(0xFF00401A),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(10),
                            topRight: Radius.circular(10),
                          ),
                        ),
                      ),
                      Container(
                        child: Padding(
                          padding: const EdgeInsets.all(7.0),
                          child: Column(
                            children: [
                              Container(
                                child: Padding(
                                  padding: const EdgeInsets.all(15.0),
                                  child: Text(
                                    " 3",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 30,
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                width: screenWidth * 0.17,
                                height: screenHeight * 0.08,
                                decoration: BoxDecoration(
                                  color: Colors.pinkAccent,
                                  borderRadius: BorderRadius.circular(100),
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.01),
                              Container(
                                child: Text(
                                  leaderboardsList[2]['cus'] ?? '',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.01),
                              Container(
                                child: Text(
                                  leaderboardsList[2]['points']?.toString() ?? '',
                                  style: TextStyle(
                                    color: Colors.pinkAccent,
                                    fontSize: 14,
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                        width: screenWidth * 0.3,
                        height: screenHeight * 0.18,
                        decoration: BoxDecoration(
                          color: Color(0xFF00401A),
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(10),
                            bottomRight: Radius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  itemExtent: screenHeight * 0.1,
                  itemCount: leaderboardsList.length,
                  itemBuilder: (context, index) {
                    Map<String, dynamic> leaderboards = leaderboardsList[index];
                    bool isCurrentUser = leaderboards['uid'] == uid;

                    return Container(
                      margin: EdgeInsets.symmetric(vertical: 3),
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isCurrentUser ? Color(0xFF00401A) : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                                  child: Text(
                                    '${leaderboards['rank']}',
                                    style: TextStyle(
                                      color: isCurrentUser ? Colors.white : Color(0xFF00401A),
                                      fontSize: 30,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${leaderboards['cus']}',
                                          style: TextStyle(
                                            color: isCurrentUser ? Colors.white : Color(0xFF00401A),
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          overflow: TextOverflow.visible,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                                  child: Text(
                                    '${leaderboards['points']} points',
                                    style: TextStyle(
                                      color: isCurrentUser ? Colors.greenAccent : Color(0xFF00401A),
                                      fontSize: 16,
                                      fontWeight: FontWeight.normal,
                                    ),
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
            ],
          ),
        ),
        if (userPositionFixed &&
            userLeaderboardData != null &&
            tabAccountType == widget.accountType)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: userLeaderboardData?['points'] != '0'
                ? Container(
              margin: EdgeInsets.symmetric(vertical: 3),
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Color(0xFF00401A),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 9.0),
                      child: Text(
                        '${userLeaderboardData!['rank']}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    child: Text(
                      '${userLeaderboardData!['cus']}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Text(
                        '${userLeaderboardData!['points']} points',
                        style: TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 16,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
                : Container(
              margin: EdgeInsets.symmetric(vertical: 3),
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Color(0xFF00401A),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Order now to earn points & see leaderboard!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        if (_isLoading)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFriendsLeaderboard(double screenHeight, double screenWidth) {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.only(left: 10, right: 10),
          width: double.infinity,
          height: double.infinity,
          color: const Color(0xFFCCCCCC).withOpacity(0.3),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8.0, right: 8.0, top: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ElevatedButton(
                            onPressed: () {
                              _showFriendsRequestDialog();
                            },
                            style: ElevatedButton.styleFrom(
                              primary: Colors.white,
                              side: BorderSide(color: Color(0xFF00401A), width: 2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              minimumSize: Size(80, 50),
                            ),
                            child: Container(
                              child: Row(
                                children: [
                                  Text(
                                    "Friends Requests",
                                    style: TextStyle(
                                        color: Color(0xFF00401A),
                                        fontWeight: FontWeight.w900,
                                        fontSize: 17),
                                  ),
                                  SizedBox(width: screenWidth * 0.0),
                                  Icon(
                                    Icons.people_alt_outlined,
                                    color: Color(0xFF00401A),
                                  )
                                ],
                              ),
                            )),
                        ElevatedButton(
                            onPressed: () {
                              _showFriendsSearchDialog();
                            },
                            style: ElevatedButton.styleFrom(
                              primary: Colors.white,
                              side: BorderSide(color: Color(0xFF00401A), width: 2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              minimumSize: Size(70, 50),
                            ),
                            child: Container(
                              child: Row(
                                children: [
                                  Text(
                                    "Add Friends",
                                    style: TextStyle(
                                        color: Color(0xFF00401A),
                                        fontWeight: FontWeight.w900,
                                        fontSize: 17),
                                  ),
                                  SizedBox(width: screenWidth * 0.02),
                                  Icon(
                                    Icons.people_alt_outlined,
                                    color: Color(0xFF00401A),
                                  )
                                ],
                              ),
                            )),
                      ],
                    )
                  ],
                ),
              ),
              SizedBox(height: screenHeight * 0.01),
              if (leaderboardsList != null && leaderboardsList.length > 2)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        child: Padding(
                          padding: const EdgeInsets.all(7.0),
                          child: Column(
                            children: [
                              Container(
                                child: Padding(
                                  padding: const EdgeInsets.all(15.0),
                                  child: Text(
                                    " 2",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 30,
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                width: screenWidth * 0.17,
                                height: screenHeight * 0.08,
                                decoration: BoxDecoration(
                                  color: Colors.cyan,
                                  borderRadius: BorderRadius.circular(100),
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.01),
                              Container(
                                child: Text(
                                  leaderboardsList[1]['cus'] ?? '',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.01),
                              Container(
                                child: Text(
                                  leaderboardsList[1]['points']?.toString() ?? '',
                                  style: TextStyle(
                                    color: Colors.cyan,
                                    fontSize: 16,
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                        width: screenWidth * 0.3,
                        height: screenHeight * 0.17,
                        decoration: BoxDecoration(
                          color: Color(0xFF00401A),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(10),
                            bottomLeft: Radius.circular(10),
                          ),
                        ),
                      ),
                      Container(
                        child: Padding(
                          padding: const EdgeInsets.all(7.0),
                          child: Column(
                            children: [
                              Container(
                                child: Padding(
                                  padding: const EdgeInsets.all(15.0),
                                  child: Text(
                                    " 1",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 30,
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                width: screenWidth * 0.17,
                                height: screenHeight * 0.08,
                                decoration: BoxDecoration(
                                  color: Colors.yellow[800],
                                  borderRadius: BorderRadius.circular(100),
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.01),
                              Container(
                                child: Text(
                                  leaderboardsList.isNotEmpty ? leaderboardsList[0]['cus'] ?? '' : '',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.01),
                              Container(
                                child: Text(
                                  leaderboardsList.isNotEmpty ? leaderboardsList[0]['points']?.toString() ?? '' : '',
                                  style: TextStyle(
                                    color: Colors.yellow[800],
                                    fontSize: 16,
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                        width: screenWidth * 0.3,
                        height: screenHeight * 0.23,
                        decoration: BoxDecoration(
                          color: Color(0xFF00401A),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(10),
                            topRight: Radius.circular(10),
                          ),
                        ),
                      ),
                      Container(
                        child: Padding(
                          padding: const EdgeInsets.all(7.0),
                          child: Column(
                            children: [
                              Container(
                                child: Padding(
                                  padding: const EdgeInsets.all(15.0),
                                  child: Text(
                                    " 3",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 30,
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                width: screenWidth * 0.17,
                                height: screenHeight * 0.08,
                                decoration: BoxDecoration(
                                  color: Colors.pinkAccent,
                                  borderRadius: BorderRadius.circular(100),
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.01),
                              Container(
                                child: Text(
                                  leaderboardsList[2]['cus'] ?? '',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w900,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.01),
                              Container(
                                child: Text(
                                  leaderboardsList[2]['points']?.toString() ?? '',
                                  style: TextStyle(
                                    color: Colors.pinkAccent,
                                    fontSize: 16,
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                        width: screenWidth * 0.3,
                        height: screenHeight * 0.17,
                        decoration: BoxDecoration(
                          color: Color(0xFF00401A),
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(10),
                            bottomRight: Radius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  itemExtent: screenHeight * 0.1,
                  itemCount: leaderboardsList.length,
                  itemBuilder: (context, index) {
                    Map<String, dynamic> leaderboards = leaderboardsList[index];
                    bool isCurrentUser = leaderboards['uid'] == uid;

                    return Container(
                      margin: EdgeInsets.symmetric(vertical: 3),
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isCurrentUser ? Color(0xFF00401A) : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  child: Text(
                                    '${leaderboards['rank']}',
                                    style: TextStyle(
                                      color: isCurrentUser
                                          ? Colors.white
                                          : Color(0xFF00401A),
                                      fontSize: 30,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Container(
                                  child: Text(
                                    '${leaderboards['cus']}',
                                    style: TextStyle(
                                      color: isCurrentUser
                                          ? Colors.white
                                          : Color(0xFF00401A),
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Container(
                                  child: Text(
                                    '${leaderboards['points']} points',
                                    style: TextStyle(
                                      color: isCurrentUser
                                          ? Colors.greenAccent
                                          : Color(0xFF00401A),
                                      fontSize: 16,
                                      fontWeight: FontWeight.normal,
                                    ),
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
            ],
          ),
        ),
        if (userPositionFixed &&
            userLeaderboardData != null &&
            tabAccountType == widget.accountType)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: userLeaderboardData?['points'] != '0'
                ? Container(
              margin: EdgeInsets.symmetric(vertical: 3),
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Color(0xFF00401A),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 9.0),
                      child: Text(
                        '${userLeaderboardData!['rank']}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    child: Text(
                      '${userLeaderboardData!['cus']}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Text(
                        '${userLeaderboardData!['points']} points',
                        style: TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 16,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
                : Container(
              margin: EdgeInsets.symmetric(vertical: 3),
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Color(0xFF00401A),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Order now to earn points & see leaderboard!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        if (_isLoading)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ),
      ],
    );
  }
}

class OrganizationContainer extends StatelessWidget {
  final List<Map<String, dynamic>> organizationList;
  final String uid;
  final String accountType;
  final String userName;

  OrganizationContainer({
    required this.organizationList,
    required this.uid,
    required this.accountType,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Leaderboards(
              uid: uid,
              accountType: accountType,
              userName: userName,
              initialTabIndex: 1,
            ),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 3),
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Table(
          border: TableBorder.all(),
          columnWidths: const {
            0: FlexColumnWidth(2),
            1: FlexColumnWidth(4),
            2: FlexColumnWidth(4),
          },
          children: [
            const TableRow(
              children: [
                TableCell(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'Rank',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                TableCell(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'Organization Name',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                TableCell(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'Waste Recycled (kgs)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            for (int index = 0; index < organizationList.length; index++)
              TableRow(
                children: [
                  TableCell(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        '${index + 1}',
                      ),
                    ),
                  ),
                  TableCell(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        '${organizationList[index]['organizationName']}',
                      ),
                    ),
                  ),
                  TableCell(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        '${organizationList[index]['wasteRecycled'].toString()}',
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

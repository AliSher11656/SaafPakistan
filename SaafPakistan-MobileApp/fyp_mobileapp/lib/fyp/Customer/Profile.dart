import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'Orders.dart';
import 'Dashboard.dart';

class Profile extends StatefulWidget {
  final String uid;

  const Profile({Key? key, required this.uid}) : super(key: key);

  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  late Future<DocumentSnapshot> userDataFuture;
  bool isEditing = false;
  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController phoneController;
  late TextEditingController areaController;
  late TextEditingController addressController;
  late TextEditingController accountNumberController;

  String? selectedPaymentMethod;
  List<String> paymentMethods = ['JazzCash', 'EasyPaisa'];
  List<String> areas = [];
  bool isAreasLoading = true;
  String? selectedArea;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    emailController = TextEditingController();
    phoneController = TextEditingController();
    areaController = TextEditingController();
    addressController = TextEditingController();
    accountNumberController = TextEditingController();
    fetchUserData();
    fetchAreas();
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    areaController.dispose();
    addressController.dispose();
    accountNumberController.dispose();
    super.dispose();
  }

  void fetchUserData() async {
    userDataFuture = FirebaseFirestore.instance.collection('appUsers').doc(widget.uid).get();
    userDataFuture.then((DocumentSnapshot snapshot) {
      if (snapshot.exists) {
        Map<String, dynamic> userData = snapshot.data() as Map<String, dynamic>;
        nameController.text = userData['name'] ?? '';
        emailController.text = userData['email'] ?? '';
        phoneController.text = userData['phone'] ?? '';
        selectedArea = userData['area'] ?? '';
        addressController.text = userData['address'] ?? '';
        accountNumberController.text = userData['paymentNumber'] ?? '';
        selectedPaymentMethod = userData['paymentMethod'] ?? paymentMethods[0];
      }
    });
  }

  void fetchAreas() async {
    isAreasLoading = true;
    var areaSnapshot = await FirebaseFirestore.instance.collection('Areas').get();
    setState(() {
      areas = areaSnapshot.docs.map((doc) => doc['location'] as String).toList();
      if (areas.isNotEmpty && selectedArea == null) {
        selectedArea = areas[0];
      }
      isAreasLoading = false;
    });
  }

  Future<void> saveData() async {
    await FirebaseFirestore.instance.collection('appUsers').doc(widget.uid).update({
      'name': nameController.text,
      'email': emailController.text,
      'phone': phoneController.text,
      'area': selectedArea,
      'address': addressController.text,
      'paymentMethod': selectedPaymentMethod,
      'accountNumber': accountNumberController.text,
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("Profile updated successfully!"),
    ));

    setState(() {
      isEditing = false;
    });
  }

  Future<void> _deleteAccount() async {
    try {
      // Delete from appUsers collection
      await FirebaseFirestore.instance.collection('appUsers').doc(widget.uid).delete();

      // Delete from leaderboards collection
      await FirebaseFirestore.instance.collection('leaderboards').doc(widget.uid).delete();

      // Delete from friends collection
      await FirebaseFirestore.instance.collection('friends').doc(widget.uid).delete();

      // Delete the user from FirebaseAuth
      var user = FirebaseAuth.instance.currentUser;
      await user?.delete();

      // Navigate back to the first route
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      print('Error deleting account: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to delete account.'),
      ));
    }
  }


  Future<void> _showDeleteConfirmationDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap button to close dialog
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Account'),
          content: Text('Are you sure you want to delete your account? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _deleteAccount();
                Navigator.of(context).pop();
              },
              child: Text('Delete'),
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
      body: Container(
        padding: const EdgeInsets.only(left: 10, right: 10),
        width: double.infinity,
        height: double.infinity,
        color: const Color(0xFFCCCCCC).withOpacity(0.3),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.only(top: 50, bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "Profile",
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
            Expanded(
              child: SingleChildScrollView(
                child: FutureBuilder<DocumentSnapshot>(
                  future: userDataFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError || !snapshot.hasData || snapshot.data!.data() == null) {
                      return Center(child: Text('Error fetching user data.'));
                    }
                    return buildUserProfile(snapshot.data!);
                  },
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Container(
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
                                uid: widget.uid,
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
                          color: Colors.blue,
                        ),
                        onPressed: () {

                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildUserProfile(DocumentSnapshot userData) {
    double screenHeight = MediaQuery.of(context).size.height;
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(height: screenHeight * 0.05),
        if (isEditing)
          buildEditableFields(),
        if (!isEditing)
          buildDisplayFields(userData),
        SizedBox(height: 20),
        if (isEditing)
          ElevatedButton.icon(
            onPressed: saveData,
            style: ElevatedButton.styleFrom(primary: Colors.green),
            icon: Icon(Icons.save),
            label: Text('Save Changes'),
          ),
        if (!isEditing)
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                isEditing = true;
              });
            },
            style: ElevatedButton.styleFrom(primary: Colors.blue),
            icon: Icon(Icons.edit),
            label: Text('Edit Profile'),
          ),
        SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: _showDeleteConfirmationDialog,
          style: ElevatedButton.styleFrom(primary: Colors.red),
          icon: Icon(Icons.delete),
          label: Text('Delete Account'),
        ),
      ],
    );
  }

  Widget buildEditableFields() {
    return Column(
      children: [
        buildEditableField("Name", nameController),
        buildEditableField("Email", emailController),
        buildEditableField("Phone", phoneController),
        buildDropdownField("Area", selectedArea, areas, (String? newValue) {
          setState(() {
            selectedArea = newValue;
          });
        }),
        buildEditableField("Address", addressController),
        buildDropdownField("Payment Method", selectedPaymentMethod, paymentMethods, (String? newValue) {
          setState(() {
            selectedPaymentMethod = newValue;
          });
        }),
        buildEditableField("Account Number", accountNumberController),
      ],
    );
  }

  Widget buildDropdownField(String label, String? value, List<String> options, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        items: options.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget buildDisplayFields(DocumentSnapshot userData) {
    return Column(
      children: [
        buildDisplayField("Name", userData['name']),
        buildDisplayField("Email", userData['email']),
        buildDisplayField("Phone", userData['phone']),
        buildDisplayField("Area", userData['area']),
        buildDisplayField("Address", userData['address']),
        buildDisplayField("Payment Method", userData['paymentMethod']),
        buildDisplayField("Account Number", userData['paymentNumber']),
      ],
    );
  }

  Widget buildEditableField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          SizedBox(height: 4),
          TextFormField(
            controller: controller,
            decoration: InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDisplayField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
